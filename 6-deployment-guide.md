# eSIM Enterprise Management Portal - Deployment Guide

## Admin Account
**Email**: admin@mdm.esim.com.mm

## Deployment Steps

### 1. Initial Setup
```powershell
# Run as Administrator
.\1-setup-intune-tenant.ps1
```
Creates device groups for:
- MPT, ATOM, OOREDOO, MYTEL carriers
- Windows, iOS, Android platforms

### 2. eSIM Profile Configuration
```powershell
.\2-create-esim-profiles.ps1
```
Creates carrier-specific eSIM profiles with:
- APN settings
- MCC/MNC codes
- Local UI enablement

### 3. Compliance Policies
```powershell
.\3-compliance-policies.ps1
```
Implements security policies:
- Password requirements
- Encryption mandates
- OS version controls

### 4. Automation Setup
```powershell
# Import automation module
Import-Module .\4-automation-scripts.ps1

# Deploy eSIM to device
Deploy-eSIMProfile -DeviceId "device-id" -Carrier "MPT" -ICCID "iccid-value"

# Bulk assign carrier
Bulk-AssignCarrier -DeviceIds @("id1","id2") -Carrier "OOREDOO"
```

### 5. Monitoring Dashboard
```powershell
# Import monitoring module
Import-Module .\5-monitoring-dashboard.ps1

# Show dashboard
Show-eSIMDashboard

# Export reports
Export-eSIMReport -OutputPath "C:\Reports"
```

## Myanmar Carrier Details

| Carrier | MCC | MNC | APN | Network |
|---------|-----|-----|-----|---------|
| MPT | 414 | 01 | internet | Myanmar Posts and Telecommunications |
| ATOM | 414 | 06 | internet | Atom Myanmar |
| OOREDOO | 414 | 05 | internet | Ooredoo Myanmar |
| MYTEL | 414 | 09 | internet | MyTel Myanmar |

## Device Groups Created
- `eSIM-MPT-Devices`
- `eSIM-ATOM-Devices`
- `eSIM-OOREDOO-Devices`
- `eSIM-MYTEL-Devices`
- `eSIM-Windows-Devices`
- `eSIM-iOS-Devices`
- `eSIM-Android-Devices`

## Required Permissions
- DeviceManagementConfiguration.ReadWrite.All
- DeviceManagementManagedDevices.ReadWrite.All
- Group.ReadWrite.All
- DeviceManagementApps.ReadWrite.All

## Operational Tasks

### Daily Operations
1. Run dashboard: `Show-eSIMDashboard`
2. Check compliance status
3. Review failed deployments

### Weekly Reports
1. Export device report: `Export-eSIMReport`
2. Review carrier distribution
3. Update profiles if needed

### Monthly Maintenance
1. Update compliance policies
2. Review automation scripts
3. Audit access logs

## Troubleshooting

### Common Issues
1. **Profile deployment fails**: Check device eSIM capability
2. **Compliance violations**: Review security policies
3. **Carrier assignment errors**: Verify MCC/MNC codes

### Support Contacts
- **Technical**: admin@mdm.esim.com.mm
- **Carrier Support**: Contact respective carrier technical teams