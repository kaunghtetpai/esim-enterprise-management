# Microsoft Graph PowerShell SDK Setup

## Installation

### Install Graph SDK
```powershell
# Run installation script
.\scripts\Install-GraphSDK.ps1

# Install Beta version
.\scripts\Install-GraphSDK.ps1 -Beta

# Force reinstall
.\scripts\Install-GraphSDK.ps1 -Force
```

### Manual Installation
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Microsoft.Graph.Authentication
Install-Module Microsoft.Graph.DeviceManagement
Install-Module Microsoft.Graph.Identity.DirectoryManagement
Install-Module Microsoft.Graph.Users
```

## Authentication

### Interactive Authentication
```powershell
.\scripts\Connect-GraphAPI.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -Interactive
```

### App-Only Authentication
```powershell
.\scripts\Connect-GraphAPI.ps1 -TenantId "your-tenant-id" -ClientId "your-client-id" -ClientSecret "your-secret"
```

### Required Scopes
- DeviceManagementManagedDevices.ReadWrite.All
- DeviceManagementConfiguration.ReadWrite.All
- Directory.Read.All
- User.Read.All

## eSIM Management

### List Managed Devices
```powershell
.\scripts\Manage-eSIMProfiles.ps1 -Action List
```

### Create eSIM Profile
```powershell
.\scripts\Manage-eSIMProfiles.ps1 -Action Create -ProfileName "MPT-Profile" -ICCID "12345678901234567890" -Carrier "MPT" -ActivationCode "LPA:1$activation.code"
```

### Deploy Profile to Device
```powershell
.\scripts\Manage-eSIMProfiles.ps1 -Action Deploy -DeviceId "device-guid" -ICCID "12345678901234567890"
```

### Remove Profile
```powershell
.\scripts\Manage-eSIMProfiles.ps1 -Action Remove -DeviceId "device-guid" -ICCID "12345678901234567890"
```

### Check Profile Status
```powershell
.\scripts\Manage-eSIMProfiles.ps1 -Action Status -DeviceId "device-guid" -ICCID "12345678901234567890"
```

## API Integration

### Connect to Graph
```bash
POST /api/v1/graph/connect
{
  "tenantId": "your-tenant-id",
  "clientId": "your-client-id",
  "clientSecret": "your-secret"
}
```

### Get Managed Devices
```bash
GET /api/v1/graph/devices
```

### Create eSIM Profile
```bash
POST /api/v1/graph/profiles
{
  "profileName": "MPT-Profile",
  "iccid": "12345678901234567890",
  "carrier": "MPT",
  "activationCode": "LPA:1$activation.code"
}
```

### Deploy Profile
```bash
POST /api/v1/graph/profiles/{profileId}/deploy
{
  "deviceId": "device-guid"
}
```

### Remove Profile
```bash
DELETE /api/v1/graph/profiles/{iccid}/device/{deviceId}
```

### Get Profile Status
```bash
GET /api/v1/graph/profiles/{iccid}/device/{deviceId}/status
```

## Environment Variables
```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-id
AZURE_CLIENT_SECRET=your-client-secret
GRAPH_SDK_BETA=false
```

## Troubleshooting

### Common Issues
1. **Execution Policy**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
2. **Module Not Found**: Ensure PowerShell modules are installed
3. **Authentication Failed**: Verify tenant ID, client ID, and permissions
4. **Device Not Found**: Check device is Intune-managed and Windows-based

### Error Codes
- MISSING_CREDENTIALS: Tenant ID or Client ID not provided
- GRAPH_AUTH_FAILED: Authentication with Microsoft Graph failed
- INVALID_ICCID_FORMAT: ICCID must be 19-20 digits
- INVALID_CARRIER: Carrier must be MPT, ATOM, U9, or MYTEL
- DEPLOYMENT_FAILED: eSIM profile deployment failed
- SDK_INSTALL_FAILED: Graph SDK installation failed