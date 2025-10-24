-- Deployment Errors Table
CREATE TABLE IF NOT EXISTS deployment_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('github', 'vercel', 'azure', 'intune')),
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'ignored')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Deployment Checks Table
CREATE TABLE IF NOT EXISTS deployment_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('github', 'vercel', 'azure', 'intune')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'error', 'warning')),
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_time INTEGER,
    details JSONB DEFAULT '{}'::jsonb
);

-- Platform Sync Table
CREATE TABLE IF NOT EXISTS platform_sync (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(20) NOT NULL UNIQUE CHECK (platform IN ('github', 'vercel', 'azure', 'intune')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('synced', 'pending', 'error')),
    last_sync TIMESTAMP WITH TIME ZONE,
    sync_details JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Intune Devices Table
CREATE TABLE IF NOT EXISTS intune_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(100) NOT NULL UNIQUE,
    device_name VARCHAR(200) NOT NULL,
    user_email VARCHAR(200),
    platform VARCHAR(50),
    compliance_status VARCHAR(50),
    last_sync TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    esim_profiles JSONB DEFAULT '[]'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_deployment_errors_platform ON deployment_errors(platform);
CREATE INDEX IF NOT EXISTS idx_deployment_errors_status ON deployment_errors(status);
CREATE INDEX IF NOT EXISTS idx_deployment_errors_created_at ON deployment_errors(created_at);

CREATE INDEX IF NOT EXISTS idx_deployment_checks_platform ON deployment_checks(platform);
CREATE INDEX IF NOT EXISTS idx_deployment_checks_checked_at ON deployment_checks(checked_at);

CREATE INDEX IF NOT EXISTS idx_platform_sync_platform ON platform_sync(platform);
CREATE INDEX IF NOT EXISTS idx_platform_sync_status ON platform_sync(status);

CREATE INDEX IF NOT EXISTS idx_intune_devices_device_id ON intune_devices(device_id);
CREATE INDEX IF NOT EXISTS idx_intune_devices_user_email ON intune_devices(user_email);
CREATE INDEX IF NOT EXISTS idx_intune_devices_compliance ON intune_devices(compliance_status);

-- Enable Row Level Security
ALTER TABLE deployment_errors ENABLE ROW LEVEL SECURITY;
ALTER TABLE deployment_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_sync ENABLE ROW LEVEL SECURITY;
ALTER TABLE intune_devices ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "deployment_errors_policy" ON deployment_errors FOR ALL USING (true);
CREATE POLICY "deployment_checks_policy" ON deployment_checks FOR ALL USING (true);
CREATE POLICY "platform_sync_policy" ON platform_sync FOR ALL USING (true);
CREATE POLICY "intune_devices_policy" ON intune_devices FOR ALL USING (true);

-- Insert initial platform sync records
INSERT INTO platform_sync (platform, status) VALUES 
('github', 'pending'),
('vercel', 'pending'),
('azure', 'pending'),
('intune', 'pending')
ON CONFLICT (platform) DO NOTHING;