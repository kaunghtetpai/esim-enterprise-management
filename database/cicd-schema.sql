-- CI/CD Pipeline Schema for eSIM Enterprise Management Portal
-- Tracks deployments, builds, and pipeline metrics

-- Deployment logs table
CREATE TABLE IF NOT EXISTS deployment_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id VARCHAR(255) UNIQUE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'building', 'ready', 'error', 'canceled')),
    url TEXT,
    branch VARCHAR(100) DEFAULT 'main',
    commit_sha VARCHAR(40),
    commit_message TEXT,
    build_duration INTEGER, -- in seconds
    deploy_duration INTEGER, -- in seconds
    error_message TEXT,
    build_logs TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ready_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Deployment triggers table
CREATE TABLE IF NOT EXISTS deployment_triggers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id VARCHAR(255) REFERENCES deployment_logs(deployment_id),
    trigger_type VARCHAR(50) NOT NULL CHECK (trigger_type IN ('push', 'pull_request', 'manual', 'scheduled', 'api')),
    triggered_by VARCHAR(255), -- user or system
    branch VARCHAR(100) NOT NULL,
    triggered_at TIMESTAMPTZ DEFAULT NOW(),
    trigger_data JSONB
);

-- Deployment rollbacks table
CREATE TABLE IF NOT EXISTS deployment_rollbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id VARCHAR(255),
    previous_deployment_id VARCHAR(255),
    reason VARCHAR(255),
    rolled_back_by VARCHAR(255),
    rolled_back_at TIMESTAMPTZ DEFAULT NOW(),
    rollback_duration INTEGER, -- in seconds
    success BOOLEAN DEFAULT TRUE,
    error_message TEXT
);

-- Build metrics table
CREATE TABLE IF NOT EXISTS build_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id VARCHAR(255) REFERENCES deployment_logs(deployment_id),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(15,4),
    metric_unit VARCHAR(20),
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pipeline health checks table
CREATE TABLE IF NOT EXISTS pipeline_health_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_id VARCHAR(255) REFERENCES deployment_logs(deployment_id),
    check_name VARCHAR(100) NOT NULL,
    check_type VARCHAR(50) NOT NULL CHECK (check_type IN ('health', 'api', 'performance', 'security')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pass', 'fail', 'warning')),
    response_time INTEGER, -- in milliseconds
    status_code INTEGER,
    error_message TEXT,
    checked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Environment configurations table
CREATE TABLE IF NOT EXISTS environment_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    environment VARCHAR(50) NOT NULL CHECK (environment IN ('development', 'staging', 'production')),
    config_key VARCHAR(255) NOT NULL,
    config_value TEXT,
    is_secret BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(environment, config_key)
);

-- GitHub Vercel sync status table
CREATE TABLE IF NOT EXISTS github_vercel_sync (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_name VARCHAR(255) NOT NULL,
    vercel_project_id VARCHAR(255),
    last_sync_at TIMESTAMPTZ DEFAULT NOW(),
    sync_status VARCHAR(20) DEFAULT 'synced' CHECK (sync_status IN ('synced', 'drift', 'error')),
    issues JSONB DEFAULT '[]'::jsonb,
    auto_fixed JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_deployment_logs_status ON deployment_logs(status);
CREATE INDEX IF NOT EXISTS idx_deployment_logs_created_at ON deployment_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deployment_logs_branch ON deployment_logs(branch);
CREATE INDEX IF NOT EXISTS idx_deployment_triggers_triggered_at ON deployment_triggers(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_deployment_rollbacks_rolled_back_at ON deployment_rollbacks(rolled_back_at DESC);
CREATE INDEX IF NOT EXISTS idx_build_metrics_deployment_id ON build_metrics(deployment_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_health_checks_deployment_id ON pipeline_health_checks(deployment_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_health_checks_status ON pipeline_health_checks(status);
CREATE INDEX IF NOT EXISTS idx_environment_configs_environment ON environment_configs(environment);

-- RLS Policies
ALTER TABLE deployment_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE deployment_triggers ENABLE ROW LEVEL SECURITY;
ALTER TABLE deployment_rollbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE build_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipeline_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE environment_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE github_vercel_sync ENABLE ROW LEVEL SECURITY;

-- Allow admins and CI/CD users to manage deployment data
CREATE POLICY "Admins can manage deployment logs" ON deployment_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage deployment triggers" ON deployment_triggers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage deployment rollbacks" ON deployment_rollbacks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can view build metrics" ON build_metrics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin', 'developer')
        )
    );

CREATE POLICY "Admins can manage health checks" ON pipeline_health_checks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

CREATE POLICY "Admins can manage environment configs" ON environment_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage sync status" ON github_vercel_sync
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role IN ('admin', 'cicd_admin')
        )
    );

-- Functions for CI/CD metrics and reporting
CREATE OR REPLACE FUNCTION get_deployment_metrics(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    total_deployments INTEGER,
    successful_deployments INTEGER,
    failed_deployments INTEGER,
    success_rate DECIMAL(5,2),
    avg_build_time DECIMAL(10,2),
    avg_deploy_time DECIMAL(10,2),
    deployment_frequency DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_deployments,
        COUNT(CASE WHEN dl.status = 'ready' THEN 1 END)::INTEGER as successful_deployments,
        COUNT(CASE WHEN dl.status = 'error' THEN 1 END)::INTEGER as failed_deployments,
        (COUNT(CASE WHEN dl.status = 'ready' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL * 100) as success_rate,
        AVG(dl.build_duration) as avg_build_time,
        AVG(dl.deploy_duration) as avg_deploy_time,
        (COUNT(*)::DECIMAL / days_back::DECIMAL) as deployment_frequency
    FROM deployment_logs dl
    WHERE dl.created_at >= NOW() - INTERVAL '1 day' * days_back;
END;
$$ LANGUAGE plpgsql;

-- Function to get pipeline health summary
CREATE OR REPLACE FUNCTION get_pipeline_health_summary()
RETURNS TABLE (
    total_checks INTEGER,
    passing_checks INTEGER,
    failing_checks INTEGER,
    warning_checks INTEGER,
    health_score DECIMAL(5,2),
    last_check_time TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_checks,
        COUNT(CASE WHEN phc.status = 'pass' THEN 1 END)::INTEGER as passing_checks,
        COUNT(CASE WHEN phc.status = 'fail' THEN 1 END)::INTEGER as failing_checks,
        COUNT(CASE WHEN phc.status = 'warning' THEN 1 END)::INTEGER as warning_checks,
        (COUNT(CASE WHEN phc.status = 'pass' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL * 100) as health_score,
        MAX(phc.checked_at) as last_check_time
    FROM pipeline_health_checks phc
    WHERE phc.checked_at >= NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql;

-- Function to detect deployment anomalies
CREATE OR REPLACE FUNCTION detect_deployment_anomalies()
RETURNS TABLE (
    deployment_id VARCHAR(255),
    anomaly_type VARCHAR(100),
    severity VARCHAR(20),
    description TEXT,
    detected_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    -- Detect long build times (>10 minutes)
    SELECT 
        dl.deployment_id,
        'long_build_time'::VARCHAR(100) as anomaly_type,
        'warning'::VARCHAR(20) as severity,
        'Build time exceeded 10 minutes: ' || dl.build_duration || 's' as description,
        dl.created_at as detected_at
    FROM deployment_logs dl
    WHERE dl.build_duration > 600
    AND dl.created_at >= NOW() - INTERVAL '7 days'
    
    UNION ALL
    
    -- Detect frequent failures
    SELECT 
        dl.deployment_id,
        'frequent_failures'::VARCHAR(100) as anomaly_type,
        'critical'::VARCHAR(20) as severity,
        'Multiple consecutive failures detected' as description,
        dl.created_at as detected_at
    FROM deployment_logs dl
    WHERE dl.status = 'error'
    AND EXISTS (
        SELECT 1 FROM deployment_logs dl2 
        WHERE dl2.created_at < dl.created_at 
        AND dl2.created_at >= dl.created_at - INTERVAL '1 hour'
        AND dl2.status = 'error'
        LIMIT 2
    );
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at timestamp
CREATE TRIGGER update_deployment_logs_updated_at
    BEFORE UPDATE ON deployment_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_environment_configs_updated_at
    BEFORE UPDATE ON environment_configs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_github_vercel_sync_updated_at
    BEFORE UPDATE ON github_vercel_sync
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default environment configurations
INSERT INTO environment_configs (environment, config_key, config_value, is_secret) VALUES
('production', 'NODE_ENV', 'production', FALSE),
('production', 'VERCEL_URL', 'https://esim-enterprise-management.vercel.app', FALSE),
('production', 'CUSTOM_DOMAIN', 'portal.nexorasim.com', FALSE),
('production', 'GITHUB_REPO', 'kaunghtetpai/esim-enterprise-management', FALSE),
('production', 'DEPLOYMENT_REGION', 'sin1', FALSE),
('staging', 'NODE_ENV', 'staging', FALSE),
('development', 'NODE_ENV', 'development', FALSE)
ON CONFLICT (environment, config_key) DO NOTHING;

-- Insert initial GitHub-Vercel sync record
INSERT INTO github_vercel_sync (
    repository_name,
    vercel_project_id,
    sync_status,
    issues
) VALUES (
    'kaunghtetpai/esim-enterprise-management',
    'esim-enterprise-management',
    'synced',
    '[]'::jsonb
) ON CONFLICT DO NOTHING;