-- Enterprise Setup Tracking Schema for eSIM Enterprise Management Portal
-- Tracks complete Microsoft Entra ID and Intune setup process

-- Enterprise setup logs table
CREATE TABLE IF NOT EXISTS enterprise_setup_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id VARCHAR(255) NOT NULL,
    admin_account VARCHAR(255) NOT NULL,
    setup_type VARCHAR(50) NOT NULL CHECK (setup_type IN ('full_setup', 'phase_setup', 'validation', 'auto_fix')),
    setup_results JSONB NOT NULL,
    phases JSONB NOT NULL,
    success_rate DECIMAL(5,2),
    total_errors INTEGER DEFAULT 0,
    total_fixed INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Phase execution tracking
CREATE TABLE IF NOT EXISTS setup_phase_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setup_log_id UUID REFERENCES enterprise_setup_logs(id) ON DELETE CASCADE,
    phase_number INTEGER NOT NULL CHECK (phase_number BETWEEN 1 AND 7),
    phase_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'running', 'completed', 'failed')),
    errors JSONB DEFAULT '[]'::jsonb,
    fixed JSONB DEFAULT '[]'::jsonb,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Carrier group management
CREATE TABLE IF NOT EXISTS carrier_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carrier_name VARCHAR(50) NOT NULL,
    carrier_code VARCHAR(10) NOT NULL,
    mcc VARCHAR(3) NOT NULL,
    mnc VARCHAR(3) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    group_id VARCHAR(255), -- Microsoft Graph Group ID
    group_name VARCHAR(255) NOT NULL,
    membership_rule TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'created', 'active', 'failed')),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(carrier_code),
    UNIQUE(group_name)
);

-- Compliance policies tracking
CREATE TABLE IF NOT EXISTS compliance_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_name VARCHAR(255) NOT NULL,
    policy_id VARCHAR(255), -- Microsoft Graph Policy ID
    policy_type VARCHAR(50) NOT NULL,
    description TEXT,
    configuration JSONB NOT NULL,
    assigned_groups JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'created', 'assigned', 'active', 'failed')),
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(policy_name)
);

-- Company Portal configuration
CREATE TABLE IF NOT EXISTS company_portal_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_name VARCHAR(255) NOT NULL,
    contact_it_name VARCHAR(255),
    contact_it_email VARCHAR(255),
    contact_it_phone VARCHAR(50),
    logo_url TEXT,
    branding_config JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'configured', 'active', 'failed')),
    last_updated_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- System validation results
CREATE TABLE IF NOT EXISTS system_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    validation_type VARCHAR(50) NOT NULL,
    component VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('valid', 'invalid', 'warning', 'error')),
    message TEXT,
    details JSONB,
    recommendations JSONB DEFAULT '[]'::jsonb,
    auto_fixable BOOLEAN DEFAULT FALSE,
    fixed BOOLEAN DEFAULT FALSE,
    validated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_enterprise_setup_logs_tenant ON enterprise_setup_logs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_enterprise_setup_logs_created_at ON enterprise_setup_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_setup_phase_executions_setup_log_id ON setup_phase_executions(setup_log_id);
CREATE INDEX IF NOT EXISTS idx_setup_phase_executions_phase_number ON setup_phase_executions(phase_number);
CREATE INDEX IF NOT EXISTS idx_carrier_groups_carrier_code ON carrier_groups(carrier_code);
CREATE INDEX IF NOT EXISTS idx_carrier_groups_status ON carrier_groups(status);
CREATE INDEX IF NOT EXISTS idx_compliance_policies_status ON compliance_policies(status);
CREATE INDEX IF NOT EXISTS idx_system_validations_component ON system_validations(component);
CREATE INDEX IF NOT EXISTS idx_system_validations_status ON system_validations(status);

-- RLS Policies
ALTER TABLE enterprise_setup_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE setup_phase_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE carrier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_portal_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_validations ENABLE ROW LEVEL SECURITY;

-- Allow admins to manage all enterprise setup data
CREATE POLICY "Admins can manage enterprise setup logs" ON enterprise_setup_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage phase executions" ON setup_phase_executions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage carrier groups" ON carrier_groups
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage compliance policies" ON compliance_policies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can manage company portal config" ON company_portal_config
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Admins can view system validations" ON system_validations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Functions for enterprise setup management
CREATE OR REPLACE FUNCTION get_setup_summary()
RETURNS TABLE (
    total_setups INTEGER,
    successful_setups INTEGER,
    failed_setups INTEGER,
    avg_success_rate DECIMAL(5,2),
    last_setup_date TIMESTAMPTZ,
    active_carrier_groups INTEGER,
    active_policies INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_setups,
        COUNT(CASE WHEN success_rate >= 100 THEN 1 END)::INTEGER as successful_setups,
        COUNT(CASE WHEN success_rate < 100 OR success_rate IS NULL THEN 1 END)::INTEGER as failed_setups,
        AVG(success_rate) as avg_success_rate,
        MAX(completed_at) as last_setup_date,
        (SELECT COUNT(*)::INTEGER FROM carrier_groups WHERE status = 'active') as active_carrier_groups,
        (SELECT COUNT(*)::INTEGER FROM compliance_policies WHERE status = 'active') as active_policies
    FROM enterprise_setup_logs;
END;
$$ LANGUAGE plpgsql;

-- Function to get phase statistics
CREATE OR REPLACE FUNCTION get_phase_statistics()
RETURNS TABLE (
    phase_number INTEGER,
    phase_name VARCHAR(100),
    total_executions INTEGER,
    successful_executions INTEGER,
    failed_executions INTEGER,
    avg_duration_seconds DECIMAL(10,2),
    success_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        spe.phase_number,
        spe.phase_name,
        COUNT(*)::INTEGER as total_executions,
        COUNT(CASE WHEN spe.status = 'completed' THEN 1 END)::INTEGER as successful_executions,
        COUNT(CASE WHEN spe.status = 'failed' THEN 1 END)::INTEGER as failed_executions,
        AVG(spe.duration_seconds) as avg_duration_seconds,
        (COUNT(CASE WHEN spe.status = 'completed' THEN 1 END)::DECIMAL / COUNT(*)::DECIMAL * 100) as success_rate
    FROM setup_phase_executions spe
    GROUP BY spe.phase_number, spe.phase_name
    ORDER BY spe.phase_number;
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

CREATE TRIGGER update_enterprise_setup_logs_updated_at
    BEFORE UPDATE ON enterprise_setup_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_setup_phase_executions_updated_at
    BEFORE UPDATE ON setup_phase_executions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_carrier_groups_updated_at
    BEFORE UPDATE ON carrier_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compliance_policies_updated_at
    BEFORE UPDATE ON compliance_policies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_company_portal_config_updated_at
    BEFORE UPDATE ON company_portal_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default carrier groups
INSERT INTO carrier_groups (carrier_name, carrier_code, mcc, mnc, display_name, group_name, membership_rule) VALUES
('MPT', 'MPT', '414', '01', 'Myanmar Posts and Telecommunications', 'Group_MPT_eSIM', '(device.devicePhysicalIds -any (_ -contains "[OrderID]:eSIM_MPT"))'),
('ATOM', 'ATOM', '414', '06', 'Atom Myanmar', 'Group_ATOM_eSIM', '(device.devicePhysicalIds -any (_ -contains "[OrderID]:eSIM_ATOM"))'),
('MYTEL', 'MYTEL', '414', '09', 'MyTel Myanmar', 'Group_MYTEL_eSIM', '(device.devicePhysicalIds -any (_ -contains "[OrderID]:eSIM_MYTEL"))')
ON CONFLICT (carrier_code) DO NOTHING;

-- Insert default company portal configuration
INSERT INTO company_portal_config (
    organization_name,
    contact_it_name,
    contact_it_email,
    contact_it_phone,
    branding_config
) VALUES (
    'eSIM Enterprise Management',
    'IT Support',
    'support@mdm.esim.com.mm',
    '+95-1-234-5678',
    '{"displayName": "eSIM Enterprise Management", "showDisplayNameNextToLogo": true, "showLogo": true}'::jsonb
) ON CONFLICT DO NOTHING;