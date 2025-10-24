# Microsoft 365 Security Setup Checklist - eSIM Portal

## 🎯 Security Configuration Status

### ✅ COMPLETED ITEMS

#### 1. Custom Domain Setup
- **Status**: ✅ Completed
- **Domain**: mdm.esim.com.mm verified and active
- **Action**: None required

#### 2. Self-Service Password Reset (SSPR)
- **Status**: ✅ Completed  
- **Feature**: Users can reset passwords independently
- **Action**: None required

#### 3. Pronouns Support
- **Status**: ✅ Completed
- **Feature**: Users can set pronouns in Microsoft 365
- **Action**: None required

### ⚠️ PENDING CONFIGURATION

#### 4. Limit Admin Access
- **Status**: ❌ Not Started
- **Current**: Global Admin role assigned
- **Required**: Assign specific roles only
- **Action**: 
  ```
  Remove Global Admin → Assign:
  - Intune Administrator
  - Groups Administrator  
  - Application Administrator
  - Conditional Access Administrator
  ```

#### 5. Configure MFA
- **Status**: ❌ Not Started
- **License**: Entra ID P2 available
- **Required**: Conditional Access MFA policies
- **Action**:
  ```
  1. Create CA policy: Require MFA for all users
  2. Create CA policy: Admin protection
  3. Enable Microsoft Authenticator
  4. Configure risk-based policies
  ```

#### 6. Block Internet Explorer
- **Status**: ❌ Not Started
- **Required**: Force Microsoft Edge usage
- **Action**:
  ```
  1. Create CA policy blocking IE
  2. Deploy Edge via Intune
  3. Configure Edge security settings
  ```

#### 7. Deploy CA Policy Templates
- **Status**: ❌ Not Started
- **Available**: Zero Trust, Remote Work, Admin Protection
- **Action**:
  ```
  1. Zero Trust Foundation template
  2. Remote Work Security template
  3. Protect Administrator template
  4. Emerging Threats template
  ```

## 🔧 MANUAL CONFIGURATION STEPS

### Step 1: Configure MFA (Priority 1)
```
URL: https://entra.microsoft.com/#view/Microsoft_AAD_ConditionalAccess
1. New Policy → "eSIM Portal - Require MFA"
2. Users: All users
3. Cloud apps: All cloud apps
4. Grant: Require MFA
5. Enable policy
```

### Step 2: Limit Admin Roles (Priority 2)
```
URL: https://entra.microsoft.com/#view/Microsoft_AAD_IAM/RolesManagementMenuBlade
1. Remove Global Administrator from admin@mdm.esim.com.mm
2. Assign specific roles:
   - Intune Administrator (3a2c62db-5318-420d-8d74-23affee5d9d5)
   - Groups Administrator (fdd7a751-b60b-444a-984c-02652fe8fa1c)
   - Application Administrator (9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3)
```

### Step 3: Deploy CA Templates (Priority 3)
```
URL: https://entra.microsoft.com/#view/Microsoft_AAD_ConditionalAccess
Templates to deploy:
1. Zero Trust Foundation
2. Secure Foundation  
3. Remote Work
4. Protect Administrators
5. Emerging Threats
```

### Step 4: Block Internet Explorer (Priority 4)
```
Create new CA policy:
Name: "Block Internet Explorer"
Users: All users
Conditions: Client apps → Browser
Grant: Block access
```

## 📊 SECURITY SCORE IMPROVEMENT

### Current Security Posture
- **Identity Security**: 60% (Entra ID P2 available)
- **Access Management**: 40% (Basic setup only)
- **Device Security**: 0% (Need Intune licensing)
- **Data Protection**: 50% (Basic policies)

### Target Security Posture (After Configuration)
- **Identity Security**: 95% (Full MFA + CA policies)
- **Access Management**: 90% (Role-based access)
- **Device Security**: 85% (With EMS E3)
- **Data Protection**: 90% (Advanced policies)

## 🎯 PRIORITY ACTIONS

### Immediate (This Week)
1. **Configure MFA** - Critical for security
2. **Limit Admin Roles** - Reduce attack surface
3. **Deploy CA Templates** - Zero Trust foundation

### Short Term (Next 2 Weeks)  
4. **Block IE** - Force secure browsing
5. **Purchase EMS E3** - Enable device management
6. **Configure Device Compliance** - Secure endpoints

### Long Term (Next Month)
7. **Access Reviews** - Regular certification
8. **PIM Setup** - Just-in-time admin access
9. **Identity Protection** - Advanced threat detection

## 🔗 QUICK ACCESS LINKS

- **Conditional Access**: https://entra.microsoft.com/#view/Microsoft_AAD_ConditionalAccess
- **Role Management**: https://entra.microsoft.com/#view/Microsoft_AAD_IAM/RolesManagementMenuBlade
- **MFA Setup**: https://entra.microsoft.com/#view/Microsoft_AAD_AuthenticationMethods
- **Security Defaults**: https://entra.microsoft.com/#view/Microsoft_AAD_IAM/SecurityDefaultsMenuBlade
- **Identity Protection**: https://entra.microsoft.com/#view/Microsoft_AAD_ProtectionCenter
- **PIM**: https://entra.microsoft.com/#view/Microsoft_Azure_PIMCommon

## ✅ SUCCESS CRITERIA

### Security Configuration Complete When:
- [ ] MFA required for all users
- [ ] Admin roles limited to specific functions
- [ ] Internet Explorer blocked organization-wide
- [ ] CA policy templates deployed
- [ ] Authentication methods configured
- [ ] Risk-based policies active
- [ ] Device compliance enforced (with EMS E3)

**Target Completion**: 2 weeks after EMS E3 licensing