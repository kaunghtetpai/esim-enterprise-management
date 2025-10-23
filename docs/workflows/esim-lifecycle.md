# eSIM Profile Lifecycle Workflow

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    eSIM Profile Lifecycle                       │
└─────────────────────────────────────────────────────────────────┘

1. Profile Creation
   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐
   │   Admin     │───▶│  Create     │───▶│   Profile Store     │
   │  Creates    │    │  Profile    │    │   (Database)        │
   │  Profile    │    │             │    │                     │
   └─────────────┘    └─────────────┘    └─────────────────────┘

2. Device Assignment via Intune
   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐
   │   Admin     │───▶│   Intune    │───▶│    Target Device    │
   │  Assigns    │    │ Graph API   │    │   (Managed by       │
   │  Profile    │    │             │    │    Intune)          │
   └─────────────┘    └─────────────┘    └─────────────────────┘

3. Activation Process
   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐
   │   Intune    │───▶│   Device    │───▶│   Myanmar Carrier   │
   │  Sends      │    │ Downloads   │    │   (MPT/ATOM/U9/     │
   │ Activation  │    │  Profile    │    │    MYTEL)           │
   │  Command    │    │             │    │                     │
   └─────────────┘    └─────────────┘    └─────────────────────┘

4. Migration Workflow
   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐
   │   Admin     │───▶│  Migration  │───▶│   Remove Old +      │
   │ Initiates   │    │   Service   │    │   Install New       │
   │ Migration   │    │             │    │                     │
   └─────────────┘    └─────────────┘    └─────────────────────┘

5. Monitoring & Compliance
   ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐
   │   Intune    │───▶│ Compliance  │───▶│   Notifications     │
   │ Monitors    │    │   Check     │    │   & Alerts          │
   │  Device     │    │             │    │                     │
   └─────────────┘    └─────────────┘    └─────────────────────┘
```

## Detailed Workflow Steps

### 1. Profile Creation
**Steps**:
1. Admin logs into portal with Azure AD credentials
2. Fills profile creation form (carrier, plan, department)
3. System generates ICCID and activation code
4. Profile stored with status "inactive"
5. Audit log entry created

### 2. Device Assignment
**Steps**:
1. Admin selects Intune-managed device
2. System validates eSIM compatibility
3. Assignment record created with status "pending"
4. Intune Graph API called to prepare device
5. Notification sent to device user

### 3. Activation Process
**Steps**:
1. Device receives eSIM profile via Intune
2. User confirms installation
3. Device contacts Myanmar carrier for activation
4. Carrier validates and provisions service
5. Status synced back to portal

### 4. Migration Scenarios
- **SIM to eSIM**: Physical SIM replaced with eSIM
- **eSIM to eSIM**: Change carrier or plan

### 5. Compliance Monitoring
- Device compliance status sync from Intune
- Profile usage monitoring
- Policy violation detection
- Automatic remediation actions

## Integration Points

### Microsoft Intune
- Device inventory and management
- eSIM profile deployment
- Compliance monitoring
- User authentication (Azure AD)

### Myanmar Carriers
- Profile provisioning (GSMA SGP.22/SGP.32)
- Activation code validation
- Service activation/deactivation
- Usage reporting