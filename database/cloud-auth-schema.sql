-- Cloud Authentication Schema for eSIM Enterprise Management Portal
-- Tracks authentication status for GitHub, Vercel, and Microsoft Cloud services

-- Cloud authentication logs table
CREATE TABLE IF NOT EXISTS cloud_auth_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    github_status BOOLEAN DEFAULT FALSE,
    github_user VARCHAR(255),
    github_token_hash VARCHAR(255), -- Hashed token for security
    vercel_status BOOLEAN DEFAULT FALSE,
    vercel_user VARCHAR(255),
    vercel_team VARCHAR(255),
    microsoft_graph_status BOOLEAN DEFAULT FALSE,
    microsoft_graph_user VARCHAR(255),
    microsoft_graph_scopes TEXT[],
    intune_status BOOLEAN DEFAULT FALSE,
    intune_user VARCHAR(255),
    intune_authority VARCHAR(100),
    all_services_authenticated BOOLEAN GENERATED ALWAYS AS (
        github_status AND vercel_status AND microsoft_graph_status AND intune_status
    ) STORED,
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Authentication events table
CREATE TABLE IF NOT EXISTS auth_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service VARCHAR(50) NOT NULL CHECK (service IN ('github', 'vercel', 'microsoft_graph', 'intune')),
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('login', 'logout', 'refresh', 'error', 'validation')),
    user_identifier VARCHAR(255),
    success BOOLEAN NOT NULL,
    error_message TEXT,
    ip_address INET,
    user_agent TEXT,
    session_duration INTEGER, -- in seconds
    event_data JSONB,
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service synchronization status table
CREATE TABLE IF NOT EXISTS service_sync_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sync_type VARCHAR(50) NOT NULL CHECK (sync_type IN ('github_vercel', 'entra_intune', 'full_system')),
    sync_status VARCHAR(20) NOT NULL CHECK (sync_status IN ('synced', 'drift', 'error', 'pending')),
    issues JSONB DEFAULT '[]'::jsonb,
    auto_fixed JSONB DEFAULT '[]'::jsonb,
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    next_sync_at TIMESTAMPTZ,
    sync_duration_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Carrier groups management table
CREATE TABLE IF NOT EXISTS carrier_groups_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carrier_name VARCHAR(50) NOT NULL,
    group_name VARCHAR(255) NOT NULL,
    group_id VARCHAR(255), -- Microsoft Graph Group ID
    creation_status VARCHAR(20) DEFAULT 'pending' CHECK (creation_status IN ('pending', 'created', 'exists', 'failed')),
    member_count INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(carrier_name, group_name)
);

-- Auto-fix operations table
CREATE TABLE IF NOT EXISTS auto_fix_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type VARCHAR(100) NOT NULL,
    target_service VARCHAR(50) NOT NULL,
    operation_status VARCHAR(20) NOT NULL CHECK (operation_status IN ('pending', 'running', 'completed', 'failed')),
    operation_details JSONB,
    error_message TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- System health snapshots for authentication services
CREATE TABLE IF NOT EXISTS auth_health_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    github_healthy BOOLEAN DEFAULT FALSE,
    vercel_healthy BOOLEAN DEFAULT FALSE,
    microsoft_graph_healthy BOOLEAN DEFAULT FALSE,
    intune_healthy BOOLEAN DEFAULT FALSE,
    overall_health_score DECIMAL(5,2) GENERATED ALWAYS AS (
        (CASE WHEN github_healthy THEN 25 ELSE 0 END +
         CASE WHEN vercel_healthy THEN 25 ELSE 0 END +
         CASE WHEN microsoft_graph_healthy THEN 25 ELSE 0 END +
         CASE WHEN intune_healthy THEN 25 ELSE 0 END)
    ) STORED,
    response_times JSONB, -- Service response times
    error_counts JSONB, -- Error counts per service
    snapshot_data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_cloud_auth_logs_checked_at ON cloud_auth_logs(checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_cloud_auth_logs_all_authenticated ON cloud_auth_logs(all_services_authenticated);
CREATE INDEX IF NOT EXISTS idx_auth_events_service ON auth_events(service);
CREATE INDEX IF NOT EXISTS idx_auth_events_event_type ON auth_events(event_type);
CREATE INDEX IF NOT EXISTS idx_auth_events_occurred_at ON auth_events(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_sync_status_sync_type ON service_sync_status(sync_type);
CREATE INDEX IF NOT EXISTS idx_service_sync_status_status ON service_sync_status(sync_status);
CREATE INDEX IF NOT EXISTS idx_carrier_groups_status_carrier ON carrier_groups_status(carrier_name);
CREATE INDEX IF NOT EXISTS idx_auto_fix_operations_status ON auto_fix_operations(operation_status);
CREATE INDEX IF NOT EXISTS idx_auth_health_snapshots_created_at ON auth_health_snapshots(created_at DESC);

-- RLS Policies
ALTER TABLE cloud_auth_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_sync_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE carrier_groups_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_fix_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_health_snapshots ENABLE ROW LEVEL SECURITY;

-- Allow admins to manage all authentication data
CREATE POLICY "Admins can manage cloud auth logs" ON cloud_auth_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage auth events" ON auth_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage sync status" ON service_sync_status
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage carrier groups status" ON carrier_groups_status
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage auto-fix operations" ON auto_fix_operations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can view auth health snapshots" ON auth_health_snapshots
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin', 'developer')
        )
    );

-- Functions for authentication analytics
CREATE OR REPLACE FUNCTION get_auth_summary(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    total_auth_checks INTEGER,
    successful_auths INTEGER,
    failed_auths INTEGER,
    success_rate DECIMAL(5,2),
    most_recent_full_auth TIMESTAMPTZ,
    services_status JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_auth_checks,
        COUNT(CASE WHEN all_services_authenticated THEN 1 END)::INTEGER as successful_auths,
        COUNT(CASE WHEN NOT all_services_authenticated THEN 1 END)::INTEGER as failed_auths,
        (COUNT(CASE WHEN all_services_authenticated THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL * 100) as success_rate,
        MAX(CASE WHEN all_services_authenticated THEN checked_at END) as most_recent_full_auth,
        jsonb_build_object(
            'github', AVG(CASE WHEN github_status THEN 1 ELSE 0 END),
            'vercel', AVG(CASE WHEN vercel_status THEN 1 ELSE 0 END),
            'microsoft_graph', AVG(CASE WHEN microsoft_graph_status THEN 1 ELSE 0 END),
            'intune', AVG(CASE WHEN intune_status THEN 1 ELSE 0 END)
        ) as services_status
    FROM cloud_auth_logs
    WHERE checked_at >= NOW() - INTERVAL '1 day' * days_back;
END;
$$ LANGUAGE plpgsql;

-- Function to get sync health summary
CREATE OR REPLACE FUNCTION get_sync_health_summary()
RETURNS TABLE (
    github_vercel_status VARCHAR(20),
    entra_intune_status VARCHAR(20),
    last_successful_sync TIMESTAMPTZ,
    pending_issues INTEGER,
    auto_fixed_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(
            (SELECT sync_status FROM service_sync_status 
             WHERE sync_type = 'github_vercel' 
             ORDER BY last_sync_at DESC LIMIT 1), 
            'unknown'::VARCHAR(20)
        ) as github_vercel_status,
        COALESCE(
            (SELECT sync_status FROM service_sync_status 
             WHERE sync_type = 'entra_intune' 
             ORDER BY last_sync_at DESC LIMIT 1), 
            'unknown'::VARCHAR(20)
        ) as entra_intune_status,
        MAX(sss.last_sync_at) as last_successful_sync,
        SUM(jsonb_array_length(sss.issues))::INTEGER as pending_issues,
        SUM(jsonb_array_length(sss.auto_fixed))::INTEGER as auto_fixed_count
    FROM service_sync_status sss
    WHERE sss.last_sync_at >= NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Function to detect authentication anomalies
CREATE OR REPLACE FUNCTION detect_auth_anomalies()
RETURNS TABLE (
    anomaly_type VARCHAR(100),
    service VARCHAR(50),
    severity VARCHAR(20),
    description TEXT,
    detected_at TIMESTAMPTZ,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Detect frequent authentication failures
    SELECT 
        'frequent_auth_failures'::VARCHAR(100) as anomaly_type,
        ae.service,
        'high'::VARCHAR(20) as severity,
        'Multiple authentication failures detected in the last hour' as description,
        MAX(ae.occurred_at) as detected_at,
        'Check service credentials and network connectivity' as recommendation
    FROM auth_events ae
    WHERE ae.event_type = 'login' 
    AND ae.success = FALSE
    AND ae.occurred_at >= NOW() - INTERVAL '1 hour'
    GROUP BY ae.service
    HAVING COUNT(*) >= 3
    
    UNION ALL
    
    -- Detect services that haven't been authenticated recently
    SELECT 
        'stale_authentication'::VARCHAR(100) as anomaly_type,
        unnest(ARRAY['github', 'vercel', 'microsoft_graph', 'intune']) as service,
        'medium'::VARCHAR(20) as severity,
        'Service authentication is older than 24 hours' as description,
        NOW() as detected_at,
        'Re-authenticate to ensure service availability' as recommendation
    WHERE NOT EXISTS (
        SELECT 1 FROM cloud_auth_logs cal
        WHERE cal.checked_at >= NOW() - INTERVAL '24 hours'
        AND cal.all_services_authenticated = TRUE
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_service_sync_status_updated_at
    BEFORE UPDATE ON service_sync_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_carrier_groups_status_updated_at
    BEFORE UPDATE ON carrier_groups_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default carrier groups
INSERT INTO carrier_groups_status (carrier_name, group_name, creation_status) VALUES
('MPT', 'Group_MPT_eSIM', 'pending'),
('ATOM', 'Group_ATOM_eSIM', 'pending'),
('MYTEL', 'Group_MYTEL_eSIM', 'pending')
ON CONFLICT (carrier_name, group_name) DO NOTHING;

-- Insert initial sync status records
INSERT INTO service_sync_status (sync_type, sync_status, last_sync_at) VALUES
('github_vercel', 'pending', NOW()),
('entra_intune', 'pending', NOW()),
('full_system', 'pending', NOW())
ON CONFLICT DO NOTHING;