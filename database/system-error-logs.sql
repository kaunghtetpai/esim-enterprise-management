-- System Error Logs Table for EPM Portal
CREATE TABLE IF NOT EXISTS system_error_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    method VARCHAR(10) NOT NULL,
    url TEXT NOT NULL,
    ip INET,
    error_details JSONB NOT NULL,
    request_data JSONB,
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(255),
    severity VARCHAR(20) DEFAULT 'error',
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_system_error_logs_timestamp ON system_error_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_system_error_logs_severity ON system_error_logs(severity);
CREATE INDEX IF NOT EXISTS idx_system_error_logs_resolved ON system_error_logs(resolved);
CREATE INDEX IF NOT EXISTS idx_system_error_logs_user_id ON system_error_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_system_error_logs_url ON system_error_logs USING gin(to_tsvector('english', url));

-- System Health Metrics Table
CREATE TABLE IF NOT EXISTS system_health_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value NUMERIC NOT NULL,
    metric_unit VARCHAR(20),
    threshold_warning NUMERIC,
    threshold_critical NUMERIC,
    status VARCHAR(20) DEFAULT 'normal', -- normal, warning, critical
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for health metrics
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_timestamp ON system_health_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_name ON system_health_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_status ON system_health_metrics(status);

-- API Request Logs Table
CREATE TABLE IF NOT EXISTS api_request_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    request_id VARCHAR(255) UNIQUE,
    method VARCHAR(10) NOT NULL,
    url TEXT NOT NULL,
    status_code INTEGER,
    response_time_ms INTEGER,
    user_id UUID REFERENCES users(id),
    ip INET,
    user_agent TEXT,
    request_size INTEGER,
    response_size INTEGER,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for API logs
CREATE INDEX IF NOT EXISTS idx_api_request_logs_timestamp ON api_request_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_status_code ON api_request_logs(status_code);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_user_id ON api_request_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_request_id ON api_request_logs(request_id);

-- System Configuration Table
CREATE TABLE IF NOT EXISTS system_configuration (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    config_key VARCHAR(255) UNIQUE NOT NULL,
    config_value TEXT NOT NULL,
    config_type VARCHAR(50) DEFAULT 'string', -- string, number, boolean, json
    description TEXT,
    is_sensitive BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

-- Insert default system configurations
INSERT INTO system_configuration (config_key, config_value, config_type, description) VALUES
('max_request_size_mb', '10', 'number', 'Maximum request payload size in MB'),
('rate_limit_per_minute', '100', 'number', 'Maximum requests per minute per IP'),
('session_timeout_minutes', '60', 'number', 'User session timeout in minutes'),
('max_login_attempts', '5', 'number', 'Maximum failed login attempts before lockout'),
('lockout_duration_minutes', '15', 'number', 'Account lockout duration in minutes'),
('enable_audit_logging', 'true', 'boolean', 'Enable comprehensive audit logging'),
('enable_performance_monitoring', 'true', 'boolean', 'Enable system performance monitoring'),
('error_retention_days', '90', 'number', 'Number of days to retain error logs'),
('health_check_interval_seconds', '30', 'number', 'Health check interval in seconds')
ON CONFLICT (config_key) DO NOTHING;

-- Function to clean up old logs
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS void AS $$
DECLARE
    retention_days INTEGER;
BEGIN
    -- Get retention period from configuration
    SELECT config_value::INTEGER INTO retention_days 
    FROM system_configuration 
    WHERE config_key = 'error_retention_days';
    
    IF retention_days IS NULL THEN
        retention_days := 90; -- Default to 90 days
    END IF;
    
    -- Clean up old error logs
    DELETE FROM system_error_logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    -- Clean up old health metrics (keep 30 days)
    DELETE FROM system_health_metrics 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Clean up old API request logs (keep 7 days)
    DELETE FROM api_request_logs 
    WHERE created_at < NOW() - INTERVAL '7 days';
    
    RAISE NOTICE 'Cleaned up logs older than % days', retention_days;
END;
$$ LANGUAGE plpgsql;

-- Create scheduled job to run cleanup (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-logs', '0 2 * * *', 'SELECT cleanup_old_logs();');

-- Function to log system errors
CREATE OR REPLACE FUNCTION log_system_error(
    p_method VARCHAR(10),
    p_url TEXT,
    p_ip INET,
    p_error_details JSONB,
    p_request_data JSONB DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_severity VARCHAR(20) DEFAULT 'error'
)
RETURNS UUID AS $$
DECLARE
    error_id UUID;
BEGIN
    INSERT INTO system_error_logs (
        method, url, ip, error_details, request_data, user_id, severity
    ) VALUES (
        p_method, p_url, p_ip, p_error_details, p_request_data, p_user_id, p_severity
    ) RETURNING id INTO error_id;
    
    RETURN error_id;
END;
$$ LANGUAGE plpgsql;

-- Function to record health metrics
CREATE OR REPLACE FUNCTION record_health_metric(
    p_metric_name VARCHAR(100),
    p_metric_value NUMERIC,
    p_metric_unit VARCHAR(20) DEFAULT NULL,
    p_threshold_warning NUMERIC DEFAULT NULL,
    p_threshold_critical NUMERIC DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    metric_id UUID;
    metric_status VARCHAR(20) := 'normal';
BEGIN
    -- Determine status based on thresholds
    IF p_threshold_critical IS NOT NULL AND p_metric_value >= p_threshold_critical THEN
        metric_status := 'critical';
    ELSIF p_threshold_warning IS NOT NULL AND p_metric_value >= p_threshold_warning THEN
        metric_status := 'warning';
    END IF;
    
    INSERT INTO system_health_metrics (
        metric_name, metric_value, metric_unit, 
        threshold_warning, threshold_critical, status, metadata
    ) VALUES (
        p_metric_name, p_metric_value, p_metric_unit,
        p_threshold_warning, p_threshold_critical, metric_status, p_metadata
    ) RETURNING id INTO metric_id;
    
    RETURN metric_id;
END;
$$ LANGUAGE plpgsql;

-- Function to log API requests
CREATE OR REPLACE FUNCTION log_api_request(
    p_request_id VARCHAR(255),
    p_method VARCHAR(10),
    p_url TEXT,
    p_status_code INTEGER,
    p_response_time_ms INTEGER,
    p_user_id UUID DEFAULT NULL,
    p_ip INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_request_size INTEGER DEFAULT NULL,
    p_response_size INTEGER DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO api_request_logs (
        request_id, method, url, status_code, response_time_ms,
        user_id, ip, user_agent, request_size, response_size, error_message
    ) VALUES (
        p_request_id, p_method, p_url, p_status_code, p_response_time_ms,
        p_user_id, p_ip, p_user_agent, p_request_size, p_response_size, p_error_message
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql;

-- View for error summary
CREATE OR REPLACE VIEW error_summary AS
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    severity,
    COUNT(*) as error_count,
    COUNT(DISTINCT url) as unique_endpoints,
    COUNT(DISTINCT ip) as unique_ips
FROM system_error_logs 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp), severity
ORDER BY hour DESC;

-- View for system health dashboard
CREATE OR REPLACE VIEW system_health_dashboard AS
SELECT 
    metric_name,
    AVG(metric_value) as avg_value,
    MAX(metric_value) as max_value,
    MIN(metric_value) as min_value,
    COUNT(CASE WHEN status = 'critical' THEN 1 END) as critical_count,
    COUNT(CASE WHEN status = 'warning' THEN 1 END) as warning_count,
    MAX(timestamp) as last_recorded
FROM system_health_metrics 
WHERE timestamp >= NOW() - INTERVAL '1 hour'
GROUP BY metric_name
ORDER BY critical_count DESC, warning_count DESC;