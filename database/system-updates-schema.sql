-- System Updates and Backups Schema
-- Tracks all system operations and data management

-- System updates log
CREATE TABLE IF NOT EXISTS system_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    update_type VARCHAR(50) NOT NULL CHECK (update_type IN ('full_system', 'partial', 'emergency', 'scheduled')),
    update_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (update_status IN ('pending', 'running', 'completed', 'failed')),
    components_updated TEXT[],
    errors_encountered TEXT[],
    update_duration_seconds INTEGER,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System backups
CREATE TABLE IF NOT EXISTS system_backups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_id VARCHAR(255) UNIQUE NOT NULL,
    backup_type VARCHAR(50) DEFAULT 'full' CHECK (backup_type IN ('full', 'incremental', 'emergency')),
    backup_size_bytes BIGINT,
    backup_data JSONB,
    backup_status VARCHAR(20) DEFAULT 'completed' CHECK (backup_status IN ('pending', 'running', 'completed', 'failed')),
    retention_days INTEGER DEFAULT 90,
    expires_at TIMESTAMPTZ GENERATED ALWAYS AS (created_at + INTERVAL '1 day' * retention_days) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Data cleanup operations
CREATE TABLE IF NOT EXISTS data_cleanup_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cleanup_type VARCHAR(50) NOT NULL CHECK (cleanup_type IN ('old_data', 'resolved_errors', 'expired_logs', 'temp_files')),
    target_tables TEXT[],
    records_deleted INTEGER DEFAULT 0,
    space_freed_bytes BIGINT DEFAULT 0,
    cleanup_criteria JSONB,
    performed_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System maintenance schedule
CREATE TABLE IF NOT EXISTS maintenance_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_type VARCHAR(50) NOT NULL,
    schedule_cron VARCHAR(100),
    last_run TIMESTAMPTZ,
    next_run TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE,
    maintenance_config JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_system_updates_type ON system_updates(update_type);
CREATE INDEX IF NOT EXISTS idx_system_updates_status ON system_updates(update_status);
CREATE INDEX IF NOT EXISTS idx_system_updates_updated_at ON system_updates(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_backups_backup_id ON system_backups(backup_id);
CREATE INDEX IF NOT EXISTS idx_system_backups_created_at ON system_backups(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_backups_expires_at ON system_backups(expires_at);
CREATE INDEX IF NOT EXISTS idx_data_cleanup_operations_type ON data_cleanup_operations(cleanup_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_schedule_next_run ON maintenance_schedule(next_run);

-- RLS Policies
ALTER TABLE system_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_backups ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_cleanup_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage system updates" ON system_updates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage system backups" ON system_backups
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage cleanup operations" ON data_cleanup_operations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage maintenance schedule" ON maintenance_schedule
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Functions
CREATE OR REPLACE FUNCTION cleanup_expired_backups()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM system_backups 
    WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    INSERT INTO data_cleanup_operations (
        cleanup_type,
        target_tables,
        records_deleted,
        cleanup_criteria
    ) VALUES (
        'expired_logs',
        ARRAY['system_backups'],
        deleted_count,
        jsonb_build_object('criteria', 'expired_backups', 'cutoff_date', NOW())
    );
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_system_health_summary()
RETURNS TABLE (
    total_updates INTEGER,
    successful_updates INTEGER,
    failed_updates INTEGER,
    last_backup TIMESTAMPTZ,
    backup_count INTEGER,
    cleanup_operations INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(su.*)::INTEGER as total_updates,
        COUNT(CASE WHEN su.update_status = 'completed' THEN 1 END)::INTEGER as successful_updates,
        COUNT(CASE WHEN su.update_status = 'failed' THEN 1 END)::INTEGER as failed_updates,
        MAX(sb.created_at) as last_backup,
        COUNT(sb.*)::INTEGER as backup_count,
        COUNT(dco.*)::INTEGER as cleanup_operations
    FROM system_updates su
    FULL OUTER JOIN system_backups sb ON DATE(su.updated_at) = DATE(sb.created_at)
    FULL OUTER JOIN data_cleanup_operations dco ON DATE(su.updated_at) = DATE(dco.performed_at)
    WHERE su.updated_at >= NOW() - INTERVAL '7 days'
    OR sb.created_at >= NOW() - INTERVAL '7 days'
    OR dco.performed_at >= NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
CREATE TRIGGER update_maintenance_schedule_updated_at
    BEFORE UPDATE ON maintenance_schedule
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default maintenance schedules
INSERT INTO maintenance_schedule (maintenance_type, schedule_cron, next_run, maintenance_config) VALUES
('daily_cleanup', '0 2 * * *', NOW() + INTERVAL '1 day', '{"cleanup_days": 30, "tables": ["system_errors", "auth_events"]}'::jsonb),
('weekly_backup', '0 3 * * 0', NOW() + INTERVAL '7 days', '{"backup_type": "full", "retention_days": 90}'::jsonb),
('monthly_optimization', '0 4 1 * *', NOW() + INTERVAL '1 month', '{"reindex": true, "vacuum": true}'::jsonb)
ON CONFLICT DO NOTHING;