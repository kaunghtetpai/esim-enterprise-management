-- eSIM Manager Database Schema
-- PostgreSQL implementation for production-ready eSIM platform

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- eUICC Information Table
CREATE TABLE euicc_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    eid VARCHAR(32) UNIQUE NOT NULL,
    euicc_info2 JSONB NOT NULL,
    euicc_configured_addresses TEXT[],
    default_dp_address VARCHAR(255),
    root_ds_address VARCHAR(255) NOT NULL,
    platform_type VARCHAR(50),
    platform_version VARCHAR(50),
    global_platform_version VARCHAR(50),
    rsp_capability JSONB,
    ts102_241_version VARCHAR(50),
    cat_tp_support BOOLEAN DEFAULT false,
    http_support BOOLEAN DEFAULT false,
    https_support BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_eid CHECK (LENGTH(eid) = 32 AND eid ~ '^[0-9A-F]+$')
);

-- eSIM Profiles Table
CREATE TABLE esim_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iccid VARCHAR(20) NOT NULL,
    eid VARCHAR(32) NOT NULL REFERENCES euicc_info(eid),
    isdp_aid VARCHAR(32) NOT NULL,
    profile_state VARCHAR(20) NOT NULL CHECK (profile_state IN ('disabled', 'enabled', 'deleted')),
    profile_nickname VARCHAR(64),
    service_provider_name VARCHAR(64) NOT NULL,
    profile_name VARCHAR(64) NOT NULL,
    icon_type VARCHAR(20),
    icon BYTEA,
    profile_class VARCHAR(20) NOT NULL CHECK (profile_class IN ('test', 'provisioning', 'operational')),
    notification_configuration_info JSONB,
    profile_owner VARCHAR(64),
    dp_aid VARCHAR(32),
    profile_metadata JSONB,
    download_reason VARCHAR(50),
    installation_date TIMESTAMP WITH TIME ZONE,
    activation_date TIMESTAMP WITH TIME ZONE,
    deactivation_date TIMESTAMP WITH TIME ZONE,
    deletion_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_iccid CHECK (LENGTH(iccid) BETWEEN 18 AND 20 AND iccid ~ '^[0-9]+$'),
    CONSTRAINT unique_iccid_per_euicc UNIQUE (eid, iccid)
);

-- MNO/MVNO Information
CREATE TABLE mobile_network_operators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mno_code VARCHAR(10) UNIQUE NOT NULL,
    mno_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(3) NOT NULL,
    mcc VARCHAR(3) NOT NULL,
    mnc VARCHAR(3) NOT NULL,
    smdp_address VARCHAR(255),
    smds_address VARCHAR(255),
    api_endpoint VARCHAR(255),
    api_credentials JSONB,
    certificate_info JSONB,
    supported_technologies TEXT[],
    roaming_agreements TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_mcc CHECK (LENGTH(mcc) = 3 AND mcc ~ '^[0-9]+$'),
    CONSTRAINT valid_mnc CHECK (LENGTH(mnc) BETWEEN 2 AND 3 AND mnc ~ '^[0-9]+$')
);

-- Profile Operations Log
CREATE TABLE profile_operations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    operation_id VARCHAR(64) UNIQUE NOT NULL,
    eid VARCHAR(32) NOT NULL,
    iccid VARCHAR(20),
    operation_type VARCHAR(20) NOT NULL CHECK (operation_type IN ('download', 'install', 'enable', 'disable', 'delete', 'update')),
    operation_status VARCHAR(20) NOT NULL CHECK (operation_status IN ('pending', 'in_progress', 'completed', 'failed', 'cancelled')),
    operation_result JSONB,
    error_code VARCHAR(20),
    error_message TEXT,
    initiated_by VARCHAR(100),
    mno_id UUID REFERENCES mobile_network_operators(id),
    smdp_session_id VARCHAR(64),
    confirmation_code VARCHAR(32),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notification Events
CREATE TABLE notification_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id VARCHAR(64) UNIQUE NOT NULL,
    eid VARCHAR(32) NOT NULL,
    iccid VARCHAR(20),
    event_type VARCHAR(30) NOT NULL,
    event_data JSONB NOT NULL,
    notification_address VARCHAR(255),
    delivery_status VARCHAR(20) DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed')),
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Security Certificates
CREATE TABLE security_certificates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    certificate_type VARCHAR(30) NOT NULL CHECK (certificate_type IN ('ca', 'dp', 'euicc', 'ci')),
    subject_name VARCHAR(255) NOT NULL,
    issuer_name VARCHAR(255) NOT NULL,
    serial_number VARCHAR(64) NOT NULL,
    certificate_data TEXT NOT NULL,
    private_key_data TEXT,
    key_usage TEXT[],
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    is_revoked BOOLEAN DEFAULT false,
    revocation_date TIMESTAMP WITH TIME ZONE,
    revocation_reason VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT unique_certificate UNIQUE (certificate_type, serial_number)
);

-- API Access Tokens
CREATE TABLE api_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_hash VARCHAR(128) UNIQUE NOT NULL,
    client_id VARCHAR(64) NOT NULL,
    client_name VARCHAR(100) NOT NULL,
    scopes TEXT[] NOT NULL,
    rate_limit_per_hour INTEGER DEFAULT 1000,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit Log
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(100),
    client_id VARCHAR(64),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(30) NOT NULL,
    resource_id VARCHAR(64),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System Configuration
CREATE TABLE system_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value JSONB NOT NULL,
    description TEXT,
    is_encrypted BOOLEAN DEFAULT false,
    updated_by VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for Performance
CREATE INDEX idx_euicc_info_eid ON euicc_info(eid);
CREATE INDEX idx_esim_profiles_eid ON esim_profiles(eid);
CREATE INDEX idx_esim_profiles_iccid ON esim_profiles(iccid);
CREATE INDEX idx_esim_profiles_state ON esim_profiles(profile_state);
CREATE INDEX idx_profile_operations_eid ON profile_operations(eid);
CREATE INDEX idx_profile_operations_status ON profile_operations(operation_status);
CREATE INDEX idx_profile_operations_created ON profile_operations(created_at);
CREATE INDEX idx_notification_events_eid ON notification_events(eid);
CREATE INDEX idx_notification_events_status ON notification_events(delivery_status);
CREATE INDEX idx_audit_log_created ON audit_log(created_at);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_api_tokens_hash ON api_tokens(token_hash);

-- Functions and Triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_euicc_info_updated_at BEFORE UPDATE ON euicc_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_esim_profiles_updated_at BEFORE UPDATE ON esim_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mno_updated_at BEFORE UPDATE ON mobile_network_operators FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON system_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS)
ALTER TABLE esim_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_events ENABLE ROW LEVEL SECURITY;

-- Create roles
CREATE ROLE esim_admin;
CREATE ROLE esim_operator;
CREATE ROLE esim_readonly;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO esim_admin;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO esim_operator;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO esim_readonly;

-- Insert default system configuration
INSERT INTO system_config (config_key, config_value, description) VALUES
('system.version', '"1.0.0"', 'System version'),
('security.token_expiry_hours', '24', 'API token expiry in hours'),
('notifications.retry_interval_minutes', '15', 'Notification retry interval'),
('profiles.max_per_euicc', '10', 'Maximum profiles per eUICC'),
('security.require_confirmation_code', 'true', 'Require confirmation code for downloads');

-- Insert Myanmar MNOs
INSERT INTO mobile_network_operators (mno_code, mno_name, country_code, mcc, mnc, smdp_address, is_active) VALUES
('MPT', 'Myanmar Posts and Telecommunications', 'MMR', '414', '01', 'smdp.mpt.com.mm', true),
('ATOM', 'Atom Myanmar', 'MMR', '414', '06', 'smdp.atom.com.mm', true),
('OOREDOO', 'Ooredoo Myanmar', 'MMR', '414', '05', 'smdp.ooredoo.com.mm', true),
('MYTEL', 'MyTel Myanmar', 'MMR', '414', '09', 'smdp.mytel.com.mm', true);