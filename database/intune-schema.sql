-- eSIM Business Manager Portal - Database Schema with Intune Integration
-- PostgreSQL 14+ Compatible

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    tenant_id VARCHAR(255) UNIQUE NOT NULL, -- Azure AD Tenant ID
    domain VARCHAR(255) NOT NULL,
    country_code CHAR(2) DEFAULT 'MM',
    timezone VARCHAR(50) DEFAULT 'Asia/Yangon',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Departments table
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    manager_email VARCHAR(255),
    budget_limit DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(organization_id, code)
);

-- Users table (synced from Azure AD)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    azure_user_id VARCHAR(255) UNIQUE NOT NULL, -- Azure AD User ID
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    job_title VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'end_user', -- admin, it_staff, end_user
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Devices table (synced from Intune)
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    intune_device_id VARCHAR(255) UNIQUE NOT NULL, -- Intune Device ID
    device_name VARCHAR(255) NOT NULL,
    model VARCHAR(255),
    manufacturer VARCHAR(255),
    os_version VARCHAR(100),
    serial_number VARCHAR(255),
    imei VARCHAR(20),
    compliance_state VARCHAR(50), -- compliant, noncompliant, unknown
    enrollment_date TIMESTAMP WITH TIME ZONE,
    last_sync TIMESTAMP WITH TIME ZONE,
    is_managed BOOLEAN DEFAULT true,
    device_category VARCHAR(100),
    ownership VARCHAR(50), -- corporate, personal
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- eSIM Profiles table
CREATE TABLE esim_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    iccid VARCHAR(20) UNIQUE NOT NULL,
    eid VARCHAR(32),
    profile_name VARCHAR(255) NOT NULL,
    carrier VARCHAR(50) NOT NULL, -- MPT, ATOM, U9, MYTEL
    carrier_code VARCHAR(10) NOT NULL, -- 414-01, 414-06, 414-07, 414-09
    msisdn VARCHAR(20),
    plan_name VARCHAR(255),
    data_allowance_mb INTEGER,
    validity_days INTEGER,
    status VARCHAR(50) NOT NULL DEFAULT 'inactive', -- active, inactive, suspended, expired
    activation_code VARCHAR(255),
    qr_code_url TEXT,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    cost_center VARCHAR(100),
    monthly_cost DECIMAL(8,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activated_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Device Profile Assignments table
CREATE TABLE device_profile_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES esim_profiles(id) ON DELETE CASCADE,
    assigned_by UUID NOT NULL REFERENCES users(id),
    assignment_type VARCHAR(50) NOT NULL DEFAULT 'manual', -- manual, automatic, migration
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, active, failed, removed
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activated_at TIMESTAMP WITH TIME ZONE,
    removed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    UNIQUE(device_id, profile_id)
);

-- Activation Tasks table
CREATE TABLE activation_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    assignment_id UUID NOT NULL REFERENCES device_profile_assignments(id) ON DELETE CASCADE,
    task_type VARCHAR(50) NOT NULL, -- activation, migration, deactivation
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, failed
    initiated_by UUID NOT NULL REFERENCES users(id),
    intune_command_id VARCHAR(255), -- Intune command reference
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Migration History table
CREATE TABLE migration_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    from_profile_id UUID REFERENCES esim_profiles(id) ON DELETE SET NULL,
    to_profile_id UUID NOT NULL REFERENCES esim_profiles(id) ON DELETE CASCADE,
    migration_type VARCHAR(50) NOT NULL, -- sim_to_esim, esim_to_esim
    initiated_by UUID NOT NULL REFERENCES users(id),
    status VARCHAR(50) NOT NULL, -- pending, completed, failed
    migration_reason TEXT,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit Logs table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL, -- profile, device, user, assignment
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- activation_success, activation_failed, migration_complete, compliance_alert
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) DEFAULT 'info', -- info, warning, error, success
    is_read BOOLEAN DEFAULT false,
    related_resource_type VARCHAR(50),
    related_resource_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- Reports table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    generated_by UUID NOT NULL REFERENCES users(id),
    report_type VARCHAR(50) NOT NULL, -- usage, compliance, cost, inventory
    title VARCHAR(255) NOT NULL,
    parameters JSONB,
    file_path TEXT,
    file_format VARCHAR(10), -- pdf, xlsx, csv
    status VARCHAR(20) DEFAULT 'generating', -- generating, completed, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Intune Sync Status table
CREATE TABLE intune_sync_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    sync_type VARCHAR(50) NOT NULL, -- devices, users, compliance
    last_sync_at TIMESTAMP WITH TIME ZONE,
    next_sync_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, running, completed, failed
    records_processed INTEGER DEFAULT 0,
    errors_count INTEGER DEFAULT 0,
    error_details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_users_azure_user_id ON users(azure_user_id);
CREATE INDEX idx_devices_organization_id ON devices(organization_id);
CREATE INDEX idx_devices_intune_device_id ON devices(intune_device_id);
CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_esim_profiles_organization_id ON esim_profiles(organization_id);
CREATE INDEX idx_esim_profiles_iccid ON esim_profiles(iccid);
CREATE INDEX idx_esim_profiles_status ON esim_profiles(status);
CREATE INDEX idx_device_profile_assignments_device_id ON device_profile_assignments(device_id);
CREATE INDEX idx_device_profile_assignments_profile_id ON device_profile_assignments(profile_id);
CREATE INDEX idx_activation_tasks_status ON activation_tasks(status);
CREATE INDEX idx_audit_logs_organization_id ON audit_logs(organization_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_esim_profiles_updated_at BEFORE UPDATE ON esim_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();