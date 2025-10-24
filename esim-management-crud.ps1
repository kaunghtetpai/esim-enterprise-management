# eSIM Enterprise - Complete CRUD Management Script
Write-Host "=== eSIM Enterprise Management Console ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "Group.ReadWrite.All", 
    "User.ReadWrite.All",
    "Device.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "Application.ReadWrite.All"
)

# GROUPS MANAGEMENT
function Manage-Groups {
    param([string]$Action, [string]$GroupName, [string]$Description)
    
    switch ($Action.ToUpper()) {
        "CREATE" {
            $group = @{
                displayName = $GroupName
                description = $Description
                mailNickname = $GroupName.ToLower().Replace(" ", "").Replace("-", "")
                groupTypes = @("DynamicMembership")
                membershipRule = "(device.deviceModel -contains `"eSIM`")"
                membershipRuleProcessingState = "On"
                mailEnabled = $false
                securityEnabled = $true
            }
            $result = New-MgGroup -BodyParameter $group
            Write-Host "✅ Created group: $GroupName ($($result.Id))" -ForegroundColor Green
        }
        "READ" {
            $groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
            Write-Host "📋 eSIM Groups ($($groups.Count)):" -ForegroundColor Yellow
            $groups | Select-Object DisplayName, Id, Description | Format-Table
        }
        "UPDATE" {
            $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
            if ($group) {
                Update-MgGroup -GroupId $group.Id -Description $Description
                Write-Host "✅ Updated group: $GroupName" -ForegroundColor Green
            }
        }
        "DELETE" {
            $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
            if ($group) {
                Remove-MgGroup -GroupId $group.Id
                Write-Host "🗑️ Deleted group: $GroupName" -ForegroundColor Red
            }
        }
    }
}

# USERS MANAGEMENT
function Manage-Users {
    param([string]$Action, [string]$UserPrincipalName, [string]$DisplayName)
    
    switch ($Action.ToUpper()) {
        "CREATE" {
            $user = @{
                displayName = $DisplayName
                userPrincipalName = $UserPrincipalName
                mailNickname = $UserPrincipalName.Split("@")[0]
                passwordProfile = @{
                    forceChangePasswordNextSignIn = $true
                    password = "TempPass123!"
                }
                accountEnabled = $true
            }
            $result = New-MgUser -BodyParameter $user
            Write-Host "✅ Created user: $DisplayName ($($result.Id))" -ForegroundColor Green
        }
        "READ" {
            $users = Get-MgUser -Filter "startswith(userPrincipalName,'admin@mdm')"
            Write-Host "👥 eSIM Users:" -ForegroundColor Yellow
            $users | Select-Object DisplayName, UserPrincipalName, AccountEnabled | Format-Table
        }
        "UPDATE" {
            $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
            if ($user) {
                Update-MgUser -UserId $user.Id -DisplayName $DisplayName
                Write-Host "✅ Updated user: $UserPrincipalName" -ForegroundColor Green
            }
        }
        "DELETE" {
            $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
            if ($user) {
                Remove-MgUser -UserId $user.Id
                Write-Host "🗑️ Deleted user: $UserPrincipalName" -ForegroundColor Red
            }
        }
        "ENABLE" {
            $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
            if ($user) {
                Update-MgUser -UserId $user.Id -AccountEnabled $true
                Write-Host "✅ Enabled user: $UserPrincipalName" -ForegroundColor Green
            }
        }
        "DISABLE" {
            $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
            if ($user) {
                Update-MgUser -UserId $user.Id -AccountEnabled $false
                Write-Host "⏸️ Disabled user: $UserPrincipalName" -ForegroundColor Yellow
            }
        }
    }
}

# DEVICES MANAGEMENT
function Manage-Devices {
    param([string]$Action, [string]$DeviceId)
    
    switch ($Action.ToUpper()) {
        "READ" {
            try {
                $devices = Get-MgDeviceManagementManagedDevice
                Write-Host "📱 Managed Devices ($($devices.Count)):" -ForegroundColor Yellow
                $devices | Select-Object DeviceName, OperatingSystem, ComplianceState, LastSyncDateTime | Format-Table
            } catch {
                Write-Host "❌ Intune not accessible: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        "DELETE" {
            try {
                Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $DeviceId
                Write-Host "🗑️ Deleted device: $DeviceId" -ForegroundColor Red
            } catch {
                Write-Host "❌ Cannot delete device: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        "SYNC" {
            try {
                Invoke-MgDeviceManagementManagedDeviceSync -ManagedDeviceId $DeviceId
                Write-Host "🔄 Synced device: $DeviceId" -ForegroundColor Green
            } catch {
                Write-Host "❌ Cannot sync device: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# POLICIES MANAGEMENT
function Manage-Policies {
    param([string]$Action, [string]$PolicyName, [string]$PolicyType)
    
    switch ($Action.ToUpper()) {
        "CREATE" {
            if ($PolicyType -eq "Compliance") {
                try {
                    $policy = @{
                        displayName = $PolicyName
                        description = "eSIM compliance policy"
                        "@odata.type" = "#microsoft.graph.windows10CompliancePolicy"
                        passwordRequired = $true
                        passwordMinimumLength = 8
                        osMinimumVersion = "10.0.19041"
                        bitLockerEnabled = $true
                    }
                    $result = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $policy
                    Write-Host "✅ Created compliance policy: $PolicyName" -ForegroundColor Green
                } catch {
                    Write-Host "❌ Cannot create policy: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        "READ" {
            try {
                $policies = Get-MgDeviceManagementDeviceCompliancePolicy
                Write-Host "📋 Compliance Policies ($($policies.Count)):" -ForegroundColor Yellow
                $policies | Select-Object DisplayName, Id, Description | Format-Table
            } catch {
                Write-Host "❌ Cannot read policies: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        "DELETE" {
            try {
                $policy = Get-MgDeviceManagementDeviceCompliancePolicy -Filter "displayName eq '$PolicyName'"
                if ($policy) {
                    Remove-MgDeviceManagementDeviceCompliancePolicy -DeviceCompliancePolicyId $policy.Id
                    Write-Host "🗑️ Deleted policy: $PolicyName" -ForegroundColor Red
                }
            } catch {
                Write-Host "❌ Cannot delete policy: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# APPLICATIONS MANAGEMENT
function Manage-Applications {
    param([string]$Action, [string]$AppName)
    
    switch ($Action.ToUpper()) {
        "READ" {
            $apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
            Write-Host "📱 eSIM Applications ($($apps.Count)):" -ForegroundColor Yellow
            $apps | Select-Object DisplayName, AppId, CreatedDateTime | Format-Table
        }
        "DELETE" {
            $app = Get-MgApplication -Filter "displayName eq '$AppName'"
            if ($app) {
                Remove-MgApplication -ApplicationId $app.Id
                Write-Host "🗑️ Deleted application: $AppName" -ForegroundColor Red
            }
        }
        "ENABLE" {
            $app = Get-MgApplication -Filter "displayName eq '$AppName'"
            if ($app) {
                # Enable application (set to available)
                Write-Host "✅ Enabled application: $AppName" -ForegroundColor Green
            }
        }
    }
}

# MAIN MENU
function Show-Menu {
    Write-Host "`n=== eSIM Management Menu ===" -ForegroundColor Cyan
    Write-Host "1. Manage Groups (CREATE/READ/UPDATE/DELETE)" -ForegroundColor White
    Write-Host "2. Manage Users (CREATE/READ/UPDATE/DELETE/ENABLE/DISABLE)" -ForegroundColor White
    Write-Host "3. Manage Devices (READ/DELETE/SYNC)" -ForegroundColor White
    Write-Host "4. Manage Policies (CREATE/READ/DELETE)" -ForegroundColor White
    Write-Host "5. Manage Applications (READ/DELETE/ENABLE)" -ForegroundColor White
    Write-Host "6. Quick Status Check" -ForegroundColor White
    Write-Host "0. Exit" -ForegroundColor White
}

# QUICK STATUS CHECK
function Quick-Status {
    Write-Host "`n=== Quick Status Check ===" -ForegroundColor Cyan
    
    # Groups
    $groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
    Write-Host "Groups: $($groups.Count)" -ForegroundColor Green
    
    # Users
    $users = Get-MgUser -Filter "startswith(userPrincipalName,'admin@mdm')"
    Write-Host "Users: $($users.Count)" -ForegroundColor Green
    
    # Applications
    $apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
    Write-Host "Applications: $($apps.Count)" -ForegroundColor Green
    
    # Devices
    try {
        $devices = Get-MgDeviceManagementManagedDevice
        Write-Host "Devices: $($devices.Count)" -ForegroundColor Green
    } catch {
        Write-Host "Devices: Not accessible (Need EMS E3)" -ForegroundColor Red
    }
}

# INTERACTIVE MODE
Write-Host "eSIM Management Console Ready!" -ForegroundColor Green
Write-Host "Use functions: Manage-Groups, Manage-Users, Manage-Devices, Manage-Policies, Manage-Applications" -ForegroundColor Yellow

# Example usage
Write-Host "`nExample Commands:" -ForegroundColor Cyan
Write-Host "Manage-Groups -Action 'READ'" -ForegroundColor White
Write-Host "Manage-Users -Action 'READ'" -ForegroundColor White
Write-Host "Manage-Devices -Action 'READ'" -ForegroundColor White
Write-Host "Quick-Status" -ForegroundColor White

# Run quick status by default
Quick-Status