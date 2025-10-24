# eSIM Enterprise - Simple CRUD Operations
Write-Host "=== eSIM CRUD Management ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "Directory.ReadWrite.All",
    "Group.ReadWrite.All", 
    "User.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Application.ReadWrite.All"
)

Write-Host "✅ Connected to Microsoft Graph" -ForegroundColor Green

# READ OPERATIONS
Write-Host "`n📋 READ OPERATIONS" -ForegroundColor Yellow

# Read Groups
Write-Host "`n1. GROUPS:" -ForegroundColor Cyan
$groups = Get-MgGroup -Filter "startswith(displayName,'eSIM')"
Write-Host "Found: $($groups.Count) eSIM groups" -ForegroundColor White
foreach ($group in $groups) {
    Write-Host "  ✅ $($group.DisplayName) ($($group.Id))" -ForegroundColor Green
}

# Read Users
Write-Host "`n2. USERS:" -ForegroundColor Cyan
$users = Get-MgUser -Filter "startswith(userPrincipalName,'admin@mdm')"
Write-Host "Found: $($users.Count) admin users" -ForegroundColor White
foreach ($user in $users) {
    $status = if ($user.AccountEnabled) { "✅ Enabled" } else { "❌ Disabled" }
    Write-Host "  $status $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor White
}

# Read Applications
Write-Host "`n3. APPLICATIONS:" -ForegroundColor Cyan
$apps = Get-MgApplication -Filter "startswith(displayName,'eSIM')"
Write-Host "Found: $($apps.Count) eSIM applications" -ForegroundColor White
foreach ($app in $apps) {
    Write-Host "  ✅ $($app.DisplayName) ($($app.AppId))" -ForegroundColor Green
}

# Read Devices
Write-Host "`n4. DEVICES:" -ForegroundColor Cyan
try {
    $devices = Get-MgDeviceManagementManagedDevice
    Write-Host "Found: $($devices.Count) managed devices" -ForegroundColor White
    foreach ($device in $devices | Select-Object -First 5) {
        Write-Host "  📱 $($device.DeviceName) - $($device.OperatingSystem)" -ForegroundColor White
    }
} catch {
    Write-Host "❌ Devices not accessible: Need EMS E3 license" -ForegroundColor Red
}

# MANAGEMENT FUNCTIONS
Write-Host "`n🛠️ AVAILABLE FUNCTIONS:" -ForegroundColor Yellow

function Create-eSIMGroup {
    param([string]$Name, [string]$Carrier)
    
    $group = @{
        displayName = "eSIM-$Name-Devices"
        description = "Devices with $Carrier eSIM profiles"
        mailNickname = "esim$($Name.ToLower())devices"
        groupTypes = @("DynamicMembership")
        membershipRule = "(device.extensionAttribute1 -eq `"$Carrier`")"
        membershipRuleProcessingState = "On"
        mailEnabled = $false
        securityEnabled = $true
    }
    
    try {
        $result = New-MgGroup -BodyParameter $group
        Write-Host "✅ Created group: eSIM-$Name-Devices" -ForegroundColor Green
        return $result.Id
    } catch {
        Write-Host "❌ Failed to create group: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Delete-eSIMGroup {
    param([string]$GroupName)
    
    $group = Get-MgGroup -Filter "displayName eq '$GroupName'"
    if ($group) {
        try {
            Remove-MgGroup -GroupId $group.Id
            Write-Host "🗑️ Deleted group: $GroupName" -ForegroundColor Red
        } catch {
            Write-Host "❌ Failed to delete group: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Group not found: $GroupName" -ForegroundColor Red
    }
}

function Enable-User {
    param([string]$UserPrincipalName)
    
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    if ($user) {
        try {
            Update-MgUser -UserId $user.Id -AccountEnabled $true
            Write-Host "✅ Enabled user: $UserPrincipalName" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to enable user: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Disable-User {
    param([string]$UserPrincipalName)
    
    $user = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'"
    if ($user) {
        try {
            Update-MgUser -UserId $user.Id -AccountEnabled $false
            Write-Host "⏸️ Disabled user: $UserPrincipalName" -ForegroundColor Yellow
        } catch {
            Write-Host "❌ Failed to disable user: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# EXAMPLE USAGE
Write-Host "`n📖 EXAMPLE COMMANDS:" -ForegroundColor Cyan
Write-Host "Create-eSIMGroup -Name 'TEST' -Carrier 'MPT'" -ForegroundColor White
Write-Host "Delete-eSIMGroup -GroupName 'eSIM-TEST-Devices'" -ForegroundColor White
Write-Host "Enable-User -UserPrincipalName 'admin@mdm.esim.com.mm'" -ForegroundColor White
Write-Host "Disable-User -UserPrincipalName 'admin@mdm.esim.com.mm'" -ForegroundColor White

# SUMMARY
Write-Host "`n📊 SUMMARY:" -ForegroundColor Cyan
Write-Host "Groups: $($groups.Count) ✅" -ForegroundColor Green
Write-Host "Users: $($users.Count) ✅" -ForegroundColor Green
Write-Host "Applications: $($apps.Count) ✅" -ForegroundColor Green
try {
    $deviceCount = (Get-MgDeviceManagementManagedDevice).Count
    Write-Host "Devices: $deviceCount ✅" -ForegroundColor Green
} catch {
    Write-Host "Devices: Not accessible ❌" -ForegroundColor Red
}

Write-Host "`n🎯 CRUD Operations Ready!" -ForegroundColor Green