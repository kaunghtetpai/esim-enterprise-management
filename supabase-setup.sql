-- eSIM Business Manager Portal - Supabase Database Setup
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Organizations table
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    tenant_id VARCHAR(255) UNIQUE NOT NULL,
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

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    azure_user_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    job_title VARCHAR(255),
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL DEFAULT 'end_user',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Devices table
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    intune_device_id VARCHAR(255) UNIQUE NOT NULL,
    device_name VARCHAR(255) NOT NULL,
    model VARCHAR(255),
    manufacturer VARCHAR(255),
    os_version VARCHAR(100),
    serial_number VARCHAR(255),
    imei VARCHAR(20),
    compliance_state VARCHAR(50),
    enrollment_date TIMESTAMP WITH TIME ZONE,
    last_sync TIMESTAMP WITH TIME ZONE,
    is_managed BOOLEAN DEFAULT true,
    device_category VARCHAR(100),
    ownership VARCHAR(50),
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
    carrier VARCHAR(50) NOT NULL,
    carrier_code VARCHAR(10) NOT NULL,
    msisdn VARCHAR(20),
    plan_name VARCHAR(255),
    data_allowance_mb INTEGER,
    validity_days INTEGER,
    status VARCHAR(50) NOT NULL DEFAULT 'inactive',
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

-- Insert sample data
INSERT INTO organizations (name, tenant_id, domain) VALUES 
('Myanmar Telecom Enterprise', 'mte-tenant-001', 'mte.com.mm');

INSERT INTO departments (organization_id, name, code, manager_email) VALUES 
((SELECT id FROM organizations LIMIT 1), 'IT Department', 'IT', 'it.manager@mte.com.mm'),
((SELECT id FROM organizations LIMIT 1), 'Sales Department', 'SALES', 'sales.manager@mte.com.mm');

INSERT INTO esim_profiles (organization_id, iccid, profile_name, carrier, carrier_code, plan_name, data_allowance_mb, monthly_cost, status) VALUES
((SELECT id FROM organizations LIMIT 1), '89860000000000000001', 'MPT Business Plan', 'MPT', '414-01', 'Business 5GB', 5120, 25.00, 'active'),
((SELECT id FROM organizations LIMIT 1), '89860000000000000002', 'ATOM Enterprise', 'ATOM', '414-06', 'Enterprise 10GB', 10240, 45.00, 'active'),
((SELECT id FROM organizations LIMIT 1), '89860000000000000003', 'U9 Corporate', 'U9', '414-07', 'Corporate 3GB', 3072, 18.50, 'inactive'),
((SELECT id FROM organizations LIMIT 1), '89860000000000000004', 'MYTEL Premium', 'MYTEL', '414-09', 'Premium 8GB', 8192, 38.75, 'active');

-- Enable Row Level Security
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE esim_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (adjust as needed)
CREATE POLICY "Enable read access for all users" ON organizations FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON departments FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON users FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON devices FOR SELECT USING (true);
CREATE POLICY "Enable read access for all users" ON esim_profiles FOR SELECT USING (true);