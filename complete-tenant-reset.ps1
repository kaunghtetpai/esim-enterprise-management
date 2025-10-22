# Complete Tenant Reset and Rebuild for MDM.esim.com.mm
# WARNING: This will permanently delete all Intune and Entra configurations

param(
    [switch]$Confirm,
    [switch]$SkipDeviceCleanup
)

if (!$Confirm) {
    Write-Host "WARNING: This will permanently delete ALL configurations!" -ForegroundColor Red
    Write-Host "Run with -Confirm to proceed" -ForegroundColor Yellow
    exit
}

Connect-MgGraph -Scopes @(
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All",
    "Group.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "Directory.ReadWrite.All",
    "Application.ReadWrite.All"
)

Write-Host "=== COMPLETE TENANT RESET: MDM.esim.com.mm ===" -ForegroundColor Red

# Phase 1: Intune Cleanup
Write-Host "`n1. Cleaning Intune Configuration..." -ForegroundColor Yellow

try {
    # Remove device configurations
    $configs = Get-MgDeviceManagementDeviceConfiguration -All
    foreach ($config in $configs) {
        Remove-MgDeviceManagementDeviceConfiguration -DeviceConfigurationId $config.Id -Confirm:$false
        Write-Host "  - Removed config: $($config.DisplayName)" -ForegroundColor Gray
    }
    
    # Remove compliance policies
    $policies = Get-MgDeviceManagementDeviceCompliancePolicy -All
    foreach ($policy in $policies) {
        Remove-MgDeviceManagementDeviceCompliancePolicy -DeviceCompliancePolicyId $policy.Id -Confirm:$false
        Write-Host "  - Removed policy: $($policy.DisplayName)" -ForegroundColor Gray
    }
    
    # Remove managed devices
    if (!$SkipDeviceCleanup) {
        $devices = Get-MgDeviceManagementManagedDevice -All
        foreach ($device in $devices) {
            Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -Confirm:$false
            Write-Host "  - Removed device: $($device.DeviceName)" -ForegroundColor Gray
        }
    }
    
    Write-Host "+ Intune cleanup complete" -ForegroundColor Green
} catch {
    Write-Host "- Intune cleanup skipped (service not activated)" -ForegroundColor Yellow
}

# Phase 2: Entra ID Cleanup
Write-Host "`n2. Cleaning Entra ID Configuration..." -ForegroundColor Yellow

# Remove custom groups (keep system groups)
$groups = Get-MgGroup -All | Where-Object { 
    $_.DisplayName -notlike "*admin*" -and 
    $_.DisplayName -notlike "*All Users*" -and
    $_.GroupTypes -notcontains "DynamicMembership" 
}
foreach ($group in $groups) {
    Remove-MgGroup -GroupId $group.Id -Confirm:$false
    Write-Host "  - Removed group: $($group.DisplayName)" -ForegroundColor Gray
}

# Disable Conditional Access policies
$caPolicies = Get-MgIdentityConditionalAccessPolicy -All
foreach ($policy in $caPolicies) {
    Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -State "disabled"
    Write-Host "  - Disabled CA policy: $($policy.DisplayName)" -ForegroundColor Gray
}

Write-Host "+ Entra ID cleanup complete" -ForegroundColor Green