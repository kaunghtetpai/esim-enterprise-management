# eSIM Portal - App Registrations Summary

## Created Applications

### 1. eSIM Enterprise Management Portal (Web App)
- **App ID**: `8a9e053b-9ba9-4425-9225-856b63270328`
- **Type**: Web Application
- **Purpose**: Main portal interface for eSIM management
- **Redirect URIs**: 
  - `https://esim.mdm.esim.com.mm/auth/callback`
  - `https://localhost:3000/auth/callback`

### 2. eSIM Portal API (Backend)
- **App ID**: `caa93f5a-89a5-48dd-822b-06b676976dc8`
- **Type**: API Application
- **Purpose**: Backend services for device management
- **Permissions**: DeviceManagement, Group management

### 3. Myanmar Carrier Integration Apps

#### MPT Integration
- **App ID**: `87dcd2b1-5872-4c52-8b7e-ddcb85a635a8`
- **Carrier**: Myanmar Posts and Telecommunications
- **MCC/MNC**: 414-01

#### ATOM Integration  
- **App ID**: `a367a42c-569c-457b-8504-d2d4a78fb798`
- **Carrier**: Atom Myanmar
- **MCC/MNC**: 414-06

#### OOREDOO Integration
- **App ID**: `93d6e427-2d0b-4015-97e7-12d1a4ec4fcf`
- **Carrier**: Ooredoo Myanmar
- **MCC/MNC**: 414-05

#### MYTEL Integration
- **App ID**: `fc44dae1-3016-4169-abf0-a9e6fc852d78`
- **Carrier**: MyTel Myanmar
- **MCC/MNC**: 414-09

## Enterprise Applications Created

### Service Principals
- **eSIM Portal**: `c05ec9e4-c5ce-4130-a474-2425d2b49559`
- **eSIM API**: `67e15f74-eb91-4a75-90e7-37e7028f8f74`

## Required Permissions

### Microsoft Graph API Permissions
- `User.Read` - Basic user profile access
- `Directory.ReadWrite.All` - Directory management
- `Group.ReadWrite.All` - Device group management
- `DeviceManagementManagedDevices.ReadWrite.All` - Device management
- `DeviceManagementConfiguration.ReadWrite.All` - Configuration profiles

## Next Steps

1. **Admin Consent**: Grant admin consent for API permissions
2. **Client Secrets**: Generate client secrets for applications
3. **Certificates**: Upload certificates for production authentication
4. **Conditional Access**: Apply policies to protect applications

## Configuration URLs

- **App Registrations**: https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps
- **Enterprise Applications**: https://entra.microsoft.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade
- **API Permissions**: Configure in each app registration

## Security Recommendations

- Enable MFA for all service accounts
- Use certificate-based authentication for production
- Implement least-privilege access principles
- Regular audit of application permissions