-- System Errors Table for eSIM Enterprise Management Portal
-- Tracks all system errors, diagnostics, and auto-fix attempts

-- System errors tracking table
CREATE TABLE IF NOT EXISTS system_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type VARCHAR(50) NOT NULL CHECK (type IN ('database', 'api', 'auth', 'network', 'file', 'memory', 'disk', 'module', 'configuration')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    message TEXT NOT NULL,
    details JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    resolved BOOLEAN DEFAULT FALSE,
    auto_fix_attempted BOOLEAN DEFAULT FALSE,
    auto_fix_successful BOOLEAN DEFAULT FALSE,
    resolution_notes TEXT,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- System health snapshots
CREATE TABLE IF NOT EXISTS system_health_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overall_status VARCHAR(20) NOT NULL CHECK (overall_status IN ('healthy', 'warning', 'critical')),
    database_status BOOLEAN NOT NULL,
    api_status BOOLEAN NOT NULL,
    auth_status BOOLEAN NOT NULL,
    network_status BOOLEAN NOT NULL,
    disk_usage_percent DECIMAL(5,2),
    memory_usage_percent DECIMAL(5,2),
    error_count INTEGER DEFAULT 0,
    critical_error_count INTEGER DEFAULT 0,
    uptime_seconds BIGINT,
    snapshot_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System performance metrics
CREATE TABLE IF NOT EXISTS system_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_type VARCHAR(50) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4),
    metric_unit VARCHAR(20),
    tags JSONB,
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-fix history
CREATE TABLE IF NOT EXISTS auto_fix_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    error_id UUID REFERENCES system_errors(id),
    fix_type VARCHAR(50) NOT NULL,
    fix_description TEXT,
    fix_successful BOOLEAN NOT NULL,
    fix_duration_ms INTEGER,
    fix_details JSONB,
    attempted_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_system_errors_type ON system_errors(type);
CREATE INDEX IF NOT EXISTS idx_system_errors_severity ON system_errors(severity);
CREATE INDEX IF NOT EXISTS idx_system_errors_timestamp ON system_errors(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_system_errors_resolved ON system_errors(resolved);
CREATE INDEX IF NOT EXISTS idx_system_health_snapshots_created_at ON system_health_snapshots(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_performance_metrics_type ON system_performance_metrics(metric_type, metric_name);
CREATE INDEX IF NOT EXISTS idx_system_performance_metrics_recorded_at ON system_performance_metrics(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_auto_fix_history_error_id ON auto_fix_history(error_id);

-- RLS Policies
ALTER TABLE system_errors ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_health_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_fix_history ENABLE ROW LEVEL SECURITY;

-- Allow admins to see all system data
CREATE POLICY "Admins can view all system errors" ON system_errors
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can view all health snapshots" ON system_health_snapshots
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can view all performance metrics" ON system_performance_metrics
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can view all auto-fix history" ON auto_fix_history
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Functions for automatic cleanup
CREATE OR REPLACE FUNCTION cleanup_old_system_data()
RETURNS void AS $$
BEGIN
    -- Delete resolved errors older than 90 days
    DELETE FROM system_errors 
    WHERE resolved = true 
    AND resolved_at < NOW() - INTERVAL '90 days';
    
    -- Delete health snapshots older than 30 days
    DELETE FROM system_health_snapshots 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Delete performance metrics older than 7 days
    DELETE FROM system_performance_metrics 
    WHERE recorded_at < NOW() - INTERVAL '7 days';
    
    -- Delete auto-fix history older than 60 days
    DELETE FROM auto_fix_history 
    WHERE attempted_at < NOW() - INTERVAL '60 days';
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_system_errors_updated_at
    BEFORE UPDATE ON system_errors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to get system health summary
CREATE OR REPLACE FUNCTION get_system_health_summary()
RETURNS TABLE (
    total_errors INTEGER,
    critical_errors INTEGER,
    high_errors INTEGER,
    unresolved_errors INTEGER,
    last_health_check TIMESTAMPTZ,
    overall_status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_errors,
        COUNT(CASE WHEN severity = 'critical' THEN 1 END)::INTEGER as critical_errors,
        COUNT(CASE WHEN severity = 'high' THEN 1 END)::INTEGER as high_errors,
        COUNT(CASE WHEN resolved = false THEN 1 END)::INTEGER as unresolved_errors,
        MAX(shs.created_at) as last_health_check,
        COALESCE(
            (SELECT overall_status FROM system_health_snapshots ORDER BY created_at DESC LIMIT 1),
            'unknown'::VARCHAR(20)
        ) as overall_status
    FROM system_errors se
    LEFT JOIN system_health_snapshots shs ON DATE(se.created_at) = DATE(shs.created_at);
END;
$$ LANGUAGE plpgsql;

-- Insert initial system health snapshot
INSERT INTO system_health_snapshots (
    overall_status,
    database_status,
    api_status,
    auth_status,
    network_status,
    disk_usage_percent,
    memory_usage_percent,
    error_count,
    critical_error_count,
    uptime_seconds,
    snapshot_data
) VALUES (
    'healthy',
    true,
    true,
    true,
    true,
    25.5,
    45.2,
    0,
    0,
    0,
    '{"initialization": true, "version": "1.0.0"}'::jsonb
) ON CONFLICT DO NOTHING;