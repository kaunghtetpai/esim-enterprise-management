# Intune Activation Guide for mdm.esim.com.mm

## Current Status
- **Tenant ID**: 370dd52c-929e-4fcd-aee3-fb5181eff2b7
- **Domain**: mdm.esim.com.mm  
- **License**: Microsoft Entra ID P2
- **Issue**: Intune service not activated

## Activation Steps

### 1. Manual Activation via Portal
1. Go to https://intune.microsoft.com
2. Sign in as admin@mdm.esim.com.mm
3. Accept Intune service terms
4. Set MDM Authority to "Microsoft Intune"

### 2. Alternative: Microsoft 365 Admin Center
1. Go to https://admin.microsoft.com
2. Navigate to Billing > Licenses
3. Assign Intune licenses to users
4. Enable Mobile Device Management

### 3. PowerShell Activation
```powershell
# Run after manual portal activation
.\enable-intune-service.ps1
```

## Expected Timeline
- **Immediate**: Portal access after activation
- **24-48 hours**: Full service propagation
- **72 hours**: All endpoints accessible

## Verification
```powershell
# Test after activation
.\run-health-check.ps1 -Quick
```

## Notes
- Entra ID P2 includes basic Intune capabilities
- For advanced features, upgrade to EMS E3/E5
- eSIM management requires full Intune licensing