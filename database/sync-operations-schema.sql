-- Sync Operations Schema for Vercel-GitHub Integration
-- Tracks synchronization status and operations

-- Sync operations log table
CREATE TABLE IF NOT EXISTS sync_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN ('status_check', 'full_update', 'api_validation', 'issue_fix', 'deployment_sync')),
    operation_status VARCHAR(20) NOT NULL CHECK (operation_status IN ('pending', 'running', 'completed', 'failed')),
    updated_services TEXT[],
    errors TEXT[],
    github_status BOOLEAN DEFAULT FALSE,
    vercel_status BOOLEAN DEFAULT FALSE,
    api_validation_results JSONB,
    performed_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- API endpoint health tracking
CREATE TABLE IF NOT EXISTS api_health_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    endpoint VARCHAR(255) NOT NULL,
    status_code INTEGER,
    response_time_ms INTEGER,
    is_healthy BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- GitHub Vercel sync status (enhanced)
CREATE TABLE IF NOT EXISTS github_vercel_sync_enhanced (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_name VARCHAR(255) NOT NULL,
    github_connected BOOLEAN DEFAULT FALSE,
    github_user VARCHAR(255),
    github_last_commit VARCHAR(255),
    github_branch VARCHAR(100),
    vercel_connected BOOLEAN DEFAULT FALSE,
    vercel_user VARCHAR(255),
    vercel_project VARCHAR(255),
    vercel_last_deploy TIMESTAMPTZ,
    sync_status VARCHAR(20) DEFAULT 'unknown' CHECK (sync_status IN ('synced', 'drift', 'error', 'unknown')),
    issues TEXT[],
    auto_fixes_applied TEXT[],
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    next_sync_scheduled TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Deployment tracking
CREATE TABLE IF NOT EXISTS deployment_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id VARCHAR(255) UNIQUE NOT NULL,
    source VARCHAR(50) NOT NULL CHECK (source IN ('github', 'vercel', 'manual')),
    trigger_type VARCHAR(50) NOT NULL,
    commit_sha VARCHAR(40),
    branch VARCHAR(100),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'building', 'ready', 'error', 'canceled')),
    url TEXT,
    build_time_seconds INTEGER,
    deploy_time_seconds INTEGER,
    error_details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Error tracking for sync operations
CREATE TABLE IF NOT EXISTS sync_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    error_type VARCHAR(100) NOT NULL,
    error_source VARCHAR(50) NOT NULL CHECK (error_source IN ('github', 'vercel', 'api', 'sync', 'deployment')),
    error_message TEXT NOT NULL,
    error_details JSONB,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    resolved BOOLEAN DEFAULT FALSE,
    resolution_notes TEXT,
    occurred_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sync_operations_type ON sync_operations(operation_type);
CREATE INDEX IF NOT EXISTS idx_sync_operations_status ON sync_operations(operation_status);
CREATE INDEX IF NOT EXISTS idx_sync_operations_performed_at ON sync_operations(performed_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_health_checks_endpoint ON api_health_checks(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_health_checks_checked_at ON api_health_checks(checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_github_vercel_sync_enhanced_repo ON github_vercel_sync_enhanced(repository_name);
CREATE INDEX IF NOT EXISTS idx_github_vercel_sync_enhanced_status ON github_vercel_sync_enhanced(sync_status);
CREATE INDEX IF NOT EXISTS idx_deployment_tracking_status ON deployment_tracking(status);
CREATE INDEX IF NOT EXISTS idx_deployment_tracking_created_at ON deployment_tracking(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_errors_source ON sync_errors(error_source);
CREATE INDEX IF NOT EXISTS idx_sync_errors_severity ON sync_errors(severity);
CREATE INDEX IF NOT EXISTS idx_sync_errors_resolved ON sync_errors(resolved);

-- RLS Policies
ALTER TABLE sync_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE github_vercel_sync_enhanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE deployment_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_errors ENABLE ROW LEVEL SECURITY;

-- Allow admins to manage sync data
CREATE POLICY "Admins can manage sync operations" ON sync_operations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage API health checks" ON api_health_checks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin', 'developer')
        )
    );

CREATE POLICY "Admins can manage sync status" ON github_vercel_sync_enhanced
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage deployment tracking" ON deployment_tracking
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage sync errors" ON sync_errors
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

-- Functions for sync analytics
CREATE OR REPLACE FUNCTION get_sync_summary(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    total_operations INTEGER,
    successful_operations INTEGER,
    failed_operations INTEGER,
    success_rate DECIMAL(5,2),
    avg_duration_seconds DECIMAL(10,2),
    last_successful_sync TIMESTAMPTZ,
    current_sync_status VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_operations,
        COUNT(CASE WHEN so.operation_status = 'completed' THEN 1 END)::INTEGER as successful_operations,
        COUNT(CASE WHEN so.operation_status = 'failed' THEN 1 END)::INTEGER as failed_operations,
        (COUNT(CASE WHEN so.operation_status = 'completed' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL * 100) as success_rate,
        AVG(so.duration_seconds) as avg_duration_seconds,
        MAX(CASE WHEN so.operation_status = 'completed' THEN so.completed_at END) as last_successful_sync,
        COALESCE(
            (SELECT sync_status FROM github_vercel_sync_enhanced ORDER BY last_sync_at DESC LIMIT 1),
            'unknown'::VARCHAR(20)
        ) as current_sync_status
    FROM sync_operations so
    WHERE so.performed_at >= NOW() - INTERVAL '1 day' * days_back;
END;
$$ LANGUAGE plpgsql;

-- Function to get API health summary
CREATE OR REPLACE FUNCTION get_api_health_summary()
RETURNS TABLE (
    total_endpoints INTEGER,
    healthy_endpoints INTEGER,
    unhealthy_endpoints INTEGER,
    health_percentage DECIMAL(5,2),
    avg_response_time_ms DECIMAL(10,2),
    last_check_time TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT ahc.endpoint)::INTEGER as total_endpoints,
        COUNT(DISTINCT CASE WHEN ahc.is_healthy THEN ahc.endpoint END)::INTEGER as healthy_endpoints,
        COUNT(DISTINCT CASE WHEN NOT ahc.is_healthy THEN ahc.endpoint END)::INTEGER as unhealthy_endpoints,
        (COUNT(DISTINCT CASE WHEN ahc.is_healthy THEN ahc.endpoint END)::DECIMAL / COUNT(DISTINCT ahc.endpoint)::DECIMAL * 100) as health_percentage,
        AVG(ahc.response_time_ms) as avg_response_time_ms,
        MAX(ahc.checked_at) as last_check_time
    FROM api_health_checks ahc
    WHERE ahc.checked_at >= NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;

-- Function to detect sync anomalies
CREATE OR REPLACE FUNCTION detect_sync_anomalies()
RETURNS TABLE (
    anomaly_type VARCHAR(100),
    severity VARCHAR(20),
    description TEXT,
    detected_at TIMESTAMPTZ,
    recommendation TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Detect frequent sync failures
    SELECT 
        'frequent_sync_failures'::VARCHAR(100) as anomaly_type,
        'high'::VARCHAR(20) as severity,
        'Multiple sync operations have failed in the last hour' as description,
        NOW() as detected_at,
        'Check GitHub and Vercel connectivity and credentials' as recommendation
    WHERE EXISTS (
        SELECT 1 FROM sync_operations so
        WHERE so.operation_status = 'failed'
        AND so.performed_at >= NOW() - INTERVAL '1 hour'
        GROUP BY DATE_TRUNC('hour', so.performed_at)
        HAVING COUNT(*) >= 3
    )
    
    UNION ALL
    
    -- Detect API health degradation
    SELECT 
        'api_health_degradation'::VARCHAR(100) as anomaly_type,
        'medium'::VARCHAR(20) as severity,
        'API endpoint health has degraded significantly' as description,
        NOW() as detected_at,
        'Check deployment status and server health' as recommendation
    WHERE EXISTS (
        SELECT 1 FROM api_health_checks ahc
        WHERE ahc.checked_at >= NOW() - INTERVAL '30 minutes'
        GROUP BY ahc.endpoint
        HAVING AVG(CASE WHEN ahc.is_healthy THEN 1 ELSE 0 END) < 0.8
    )
    
    UNION ALL
    
    -- Detect stale sync status
    SELECT 
        'stale_sync_status'::VARCHAR(100) as anomaly_type,
        'medium'::VARCHAR(20) as severity,
        'Sync status has not been updated recently' as description,
        NOW() as detected_at,
        'Run manual sync check and update operations' as recommendation
    WHERE NOT EXISTS (
        SELECT 1 FROM github_vercel_sync_enhanced gvse
        WHERE gvse.last_sync_at >= NOW() - INTERVAL '2 hours'
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_github_vercel_sync_enhanced_updated_at
    BEFORE UPDATE ON github_vercel_sync_enhanced
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_deployment_tracking_updated_at
    BEFORE UPDATE ON deployment_tracking
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert initial sync status
INSERT INTO github_vercel_sync_enhanced (
    repository_name,
    github_connected,
    vercel_connected,
    sync_status
) VALUES (
    'kaunghtetpai/esim-enterprise-management',
    FALSE,
    FALSE,
    'unknown'
) ON CONFLICT DO NOTHING;