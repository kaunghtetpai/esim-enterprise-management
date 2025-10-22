# eSIM Enterprise Management Portal - Complete Documentation

## Overview
Complete eSIM management solution for Myanmar carriers using Microsoft Intune and Entra ID.

**Domain**: mdm.esim.com.mm  
**Admin**: admin@mdm.esim.com.mm

## Myanmar Carriers Supported
| Carrier | MCC | MNC | APN | Network |
|---------|-----|-----|-----|---------|
| MPT | 414 | 01 | internet | Myanmar Posts and Telecommunications |
| ATOM | 414 | 06 | internet | Atom Myanmar |
| OOREDOO | 414 | 05 | internet | Ooredoo Myanmar |
| MYTEL | 414 | 09 | internet | MyTel Myanmar |

## Architecture Components

### 1. Microsoft Entra ID Security
- **Multi-Factor Authentication**: Required for all admin accounts
- **Conditional Access**: Location-based and risk-based policies
- **Identity Protection**: High-risk sign-in blocking
- **Named Locations**: Myanmar trusted IP ranges

### 2. Microsoft Intune Management
- **Device Groups**: Dynamic groups per carrier and platform
- **Configuration Profiles**: eSIM settings per carrier
- **Compliance Policies**: Security requirements per platform
- **Automation**: PowerShell and Graph API scripts

### 3. Device Groups Created
- `eSIM-MPT-Devices` - MPT carrier devices
- `eSIM-ATOM-Devices` - ATOM carrier devices  
- `eSIM-OOREDOO-Devices` - OOREDOO carrier devices
- `eSIM-MYTEL-Devices` - MYTEL carrier devices
- `eSIM-Windows-Devices` - Windows platform devices
- `eSIM-iOS-Devices` - iOS platform devices
- `eSIM-Android-Devices` - Android platform devices

## Deployment Scripts

### Core Deployment
1. `0-setup-microsoft-account.ps1` - Microsoft 365 tenant setup
2. `1-setup-intune-tenant.ps1` - Device groups creation
3. `2-create-esim-profiles.ps1` - Carrier profile configuration
4. `3-compliance-policies.ps1` - Security and compliance policies
5. `4-automation-scripts.ps1` - Bulk management functions
6. `5-monitoring-dashboard.ps1` - Reporting and monitoring

### Security & Identity
7. `entra-security-setup.ps1` - Entra ID security configuration
8. `verify-licensing.ps1` - License verification
9. `final-deployment.ps1` - Complete deployment orchestration

## Required Licenses
- **Enterprise Mobility + Security E3** (includes Intune)
- **Microsoft Entra ID Premium P1/P2** (for advanced security)

## Security Features

### Multi-Factor Authentication
- Phone-based MFA for admin accounts
- App-based authentication support
- Hardware token compatibility

### Conditional Access Policies
- **Location-based**: Myanmar trusted networks
- **Risk-based**: Block high-risk sign-ins
- **Device compliance**: Require compliant devices
- **Application protection**: Secure app access

### Identity Protection
- **Sign-in risk detection**: Unusual locations, impossible travel
- **User risk detection**: Leaked credentials, suspicious activity
- **Automated remediation**: Force password reset, block access

## Operational Procedures

### Daily Operations
```powershell
# Show dashboard
Show-eSIMDashboard

# Check compliance
Get-MgDeviceManagementDeviceCompliancePolicy
```

### Device Enrollment
```powershell
# Bulk assign carrier
Bulk-AssignCarrier -DeviceIds @("id1","id2") -Carrier "MPT"

# Deploy eSIM profile
Deploy-eSIMProfile -DeviceId "device-id" -Carrier "OOREDOO" -ICCID "iccid"
```

### Monitoring & Reporting
```powershell
# Generate reports
Export-eSIMReport -OutputPath "C:\Reports"

# Send alerts
Send-eSIMAlert -Message "Profile deployment failed" -Severity "Error"
```

## Troubleshooting

### Common Issues
1. **License not found**: Wait 24-48 hours for propagation
2. **Profile deployment fails**: Check device eSIM capability
3. **Compliance violations**: Review security policies
4. **Group membership**: Verify dynamic membership rules

### Support Contacts
- **Technical Support**: admin@mdm.esim.com.mm
- **Microsoft Support**: https://support.microsoft.com
- **Carrier Support**: Contact respective carrier technical teams

## Compliance & Auditing

### Audit Logs
- All device actions logged in Intune
- Sign-in activities in Entra ID
- Policy changes tracked
- Compliance status monitored

### Regulatory Compliance
- Myanmar telecommunications regulations
- Data protection requirements
- Corporate security policies
- International roaming compliance

## Future Enhancements

### Planned Features
- Additional carrier support
- Advanced analytics dashboard
- Automated profile switching
- Cost management integration

### Scalability
- Support for 10,000+ devices
- Multi-tenant architecture
- Regional deployment options
- API integration capabilities

## Quick Reference

### Portal URLs
- **Intune Admin**: https://endpoint.microsoft.com
- **Entra Admin**: https://entra.microsoft.com
- **Microsoft 365**: https://admin.microsoft.com

### PowerShell Commands
```powershell
# Connect to Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Get all eSIM devices
Get-MgDeviceManagementManagedDevice | Where-Object {$_.Model -like "*eSIM*"}

# Show dashboard
Show-eSIMDashboard
```

---
**Document Version**: 1.0  
**Last Updated**: October 2025  
**Maintained By**: eSIM Portal Team