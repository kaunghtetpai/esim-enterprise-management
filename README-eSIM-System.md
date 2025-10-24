# eSIM Manager - Comprehensive System Documentation

## Overview
A complete eSIM management system for iOS and Android devices with domain monitoring, secure transfer workflows, device management, and real-time reporting.

## System Components

### 1. Core Management System (`esim-manager-system.ps1`)
**Central platform for eSIM operations**
- Domain health monitoring for 6 critical endpoints
- eSIM transfer workflow management
- Myanmar carrier integration (MPT, ATOM, OOREDOO, MYTEL)
- Device compliance validation
- Profile deployment automation

**Usage:**
```powershell
# Monitor system status
.\esim-manager-system.ps1 -Action monitor

# Transfer eSIM profile
.\esim-manager-system.ps1 -Action transfer -DeviceId "device123" -CarrierCode "MPT"

# Deploy eSIM profile
.\esim-manager-system.ps1 -Action deploy -DeviceId "device123" -CarrierCode "OOREDOO"

# Generate dashboard
.\esim-manager-system.ps1 -Action dashboard
```

### 2. API Monitoring System (`esim-api-monitor.ps1`)
**Domain and API endpoint monitoring**
- Tracks 6 critical domains with geolocation
- DNS resolution and IP tracking
- Port connectivity testing
- Response time monitoring
- Continuous monitoring mode

**Monitored Domains:**
- `thl-mcs-d-odccsm.firebaseio.com` (USA-Missouri)
- `support.google.com` (USA-California)
- `simtransfer.goog` (Location unknown)
- `migrate.google` (USA-California)
- `httpstat.us` (USA-Iowa)
- `carrier-qrcless-demo.appspot.com` (Ireland-Dublin)

**Usage:**
```powershell
# Single test
.\esim-api-monitor.ps1

# Continuous monitoring
.\esim-api-monitor.ps1 continuous

# Quick test
.\esim-api-monitor.ps1 test

# Generate HTML report
.\esim-api-monitor.ps1 -OutputFormat html
```

### 3. Device Management System (`esim-device-management.ps1`)
**Intune integration for iOS and Android**
- Device enrollment and compliance monitoring
- Platform-specific eSIM configuration
- OEMConfig for Android devices
- Mobile configuration profiles for iOS
- Automated profile deployment

**Features:**
- iOS compliance policies (minimum iOS 15.0)
- Android compliance policies (minimum Android 10.0)
- Carrier-specific profile deployment
- Device health monitoring
- Compliance reporting

### 4. Transfer Workflow System (`esim-transfer-workflow.ps1`)
**Secure eSIM profile transfers**
- Device eligibility validation
- Compliance and encryption checks
- SM-DP+ server connectivity testing
- Profile backup and recovery
- Audit logging and transfer history

**Security Features:**
- Device compliance verification
- Encryption state validation
- Recent sync requirements
- Platform version checks
- Complete audit trail

**Usage:**
```powershell
# Transfer eSIM profile
.\esim-transfer-workflow.ps1 -Action transfer -SourceDevice "dev1" -TargetDevice "dev2" -CarrierCode "MPT"

# View transfer history
.\esim-transfer-workflow.ps1 -Action history

# Test device eligibility
.\esim-transfer-workflow.ps1 -Action test -SourceDevice "dev1"
```

### 5. System Dashboard (`esim-system-dashboard.html`)
**Real-time monitoring and control interface**
- System health overview with progress indicators
- Domain status monitoring
- Device compliance tracking
- Myanmar carrier status
- Transfer activity logs
- Geographic distribution mapping
- Quick action buttons

**Dashboard Features:**
- Real-time status updates
- Interactive controls
- Alert management
- Transfer monitoring
- Device compliance overview
- Carrier status tracking

## Myanmar Carrier Configuration

### Supported Carriers
| Carrier | MCC | MNC | SM-DP+ Server |
|---------|-----|-----|---------------|
| MPT | 414 | 01 | mpt-smdp.com.mm |
| ATOM | 414 | 06 | atom-smdp.com.mm |
| OOREDOO | 414 | 05 | ooredoo-smdp.com.mm |
| MYTEL | 414 | 09 | mytel-smdp.com.mm |

## System Requirements

### Prerequisites
- Windows PowerShell 5.1 or PowerShell 7+
- Microsoft Graph PowerShell SDK
- Microsoft Intune subscription
- EMS E3 license (required for full functionality)
- Network connectivity to carrier SM-DP+ servers

### Required Permissions
- `DeviceManagementManagedDevices.ReadWrite.All`
- `DeviceManagementConfiguration.ReadWrite.All`
- `DeviceManagementApps.ReadWrite.All`
- `Directory.ReadWrite.All`
- `Policy.ReadWrite.ConditionalAccess`

## Installation and Setup

### 1. Initial Setup
```powershell
# Install Microsoft Graph PowerShell
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Run system health check
.\error-check-update.ps1
```

### 2. Deploy eSIM System
```powershell
# Create device groups and applications
.\1-setup-intune-tenant.ps1

# Deploy eSIM profiles
.\2-create-esim-profiles.ps1

# Start eSIM management system
.\esim-manager-system.ps1 -Action monitor
```

### 3. Configure Monitoring
```powershell
# Start continuous API monitoring
.\esim-api-monitor.ps1 continuous

# Open dashboard
Start-Process "esim-system-dashboard.html"
```

## Security and Compliance

### Transfer Security
- Device compliance validation
- Encryption requirement enforcement
- SM-DP+ server authentication
- Profile backup before transfer
- Complete audit logging

### Data Protection
- Encrypted profile storage
- Secure API communications
- Access control via Intune
- Audit trail maintenance
- GDPR compliance ready

## Monitoring and Alerting

### Health Checks
- Domain availability monitoring
- SM-DP+ server connectivity
- Device compliance status
- Transfer success rates
- System performance metrics

### Logging
- Transfer audit logs (`esim-transfer-logs/`)
- API monitoring logs (`api-monitoring-log.json`)
- System health reports
- Error tracking and resolution

## Troubleshooting

### Common Issues
1. **EMS E3 License Missing**
   - Purchase Enterprise Mobility + Security E3
   - Assign to admin user
   - Re-run health check

2. **Device Not Compliant**
   - Check device encryption
   - Verify recent sync
   - Update compliance policies

3. **SM-DP+ Connectivity Issues**
   - Test network connectivity
   - Verify carrier server status
   - Check firewall rules

### Support Commands
```powershell
# System health check
.\error-check-update.ps1

# Device compliance report
.\esim-device-management.ps1

# Transfer history
.\esim-transfer-workflow.ps1 -Action history

# API status test
.\esim-api-monitor.ps1 test
```

## API Integration

### REST API Endpoints
The system can be extended with REST API endpoints for:
- Device enrollment
- Profile deployment
- Transfer initiation
- Status monitoring
- Report generation

### Webhook Support
Configure webhooks for:
- Transfer completion notifications
- Device compliance alerts
- System health warnings
- Carrier status changes

## Future Enhancements

### Planned Features
- Interactive geographic mapping
- Advanced analytics and reporting
- Multi-tenant support
- API rate limiting and throttling
- Enhanced security policies
- Automated testing framework

### Integration Roadmap
- Cloud-hosted API deployment
- Third-party carrier integration
- Advanced device analytics
- Machine learning for predictive maintenance
- Mobile app for administrators

## Support and Maintenance

### Regular Tasks
- Weekly health checks
- Monthly compliance reviews
- Quarterly security audits
- Annual license renewals

### Monitoring Schedule
- Real-time: System health, transfers
- Hourly: API endpoints, device sync
- Daily: Compliance reports, error logs
- Weekly: Performance analysis, capacity planning

---

**System Status**: 75% Operational (EMS E3 license required for 100%)  
**Last Updated**: Current  
**Version**: 1.0  
**Support**: admin@mdm.esim.com.mm