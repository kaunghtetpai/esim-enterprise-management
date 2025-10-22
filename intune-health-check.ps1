# Microsoft Intune Health Check and Update Script
# Tenant: MDM.esim.com.mm
# Purpose: Comprehensive health check and optimization for eSIM Profile Management integration

param(
    [switch]$GenerateReport,
    [switch]$AutoUpdate,
    [switch]$PrepareForePM,
    [string]$OutputPath = "C:\IntuneHealthCheck"
)

# Required modules and permissions
$RequiredScopes = @(
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementManagedDevices.ReadWrite.All", 
    "Group.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess",
    "Directory.ReadWrite.All"
)

function Initialize-HealthCheck {
    Write-Host "=== Intune Health Check Initialization ===" -ForegroundColor Cyan
    
    # Connect to Microsoft Graph
    try {
        Connect-MgGraph -Scopes $RequiredScopes
        Write-Host "+ Connected to Microsoft Graph" -ForegroundColor Green
    } catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        exit 1
    }
    
    # Create output directory
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
}

function Get-ConfigurationProfiles {
    Write-Host "`n1. Analyzing Configuration Profiles..." -ForegroundColor Yellow
    
    $profiles = Get-MgDeviceManagementDeviceConfiguration -All
    $results = @{
        Total = $profiles.Count
        Windows = ($profiles | Where-Object { $_.'@odata.type' -like "*windows*" }).Count
        iOS = ($profiles | Where-Object { $_.'@odata.type' -like "*ios*" }).Count
        Android = ($profiles | Where-Object { $_.'@odata.type' -like "*android*" }).Count
        Deprecated = @()
        Unused = @()
    }
    
    foreach ($profile in $profiles) {
        # Check for deprecated settings
        if ($profile.CreatedDateTime -lt (Get-Date).AddYears(-2)) {
            $results.Deprecated += $profile
        }
        
        # Check assignments
        $assignments = Get-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $profile.Id
        if (!$assignments) {
            $results.Unused += $profile
        }
    }
    
    Write-Host "  Total Profiles: $($results.Total)" -ForegroundColor White
    Write-Host "  Windows: $($results.Windows) | iOS: $($results.iOS) | Android: $($results.Android)" -ForegroundColor White
    Write-Host "  Deprecated: $($results.Deprecated.Count) | Unused: $($results.Unused.Count)" -ForegroundColor $(if($results.Deprecated.Count -gt 0 -or $results.Unused.Count -gt 0){"Red"}else{"Green"})
    
    return $results
}

function Get-CompliancePolicies {
    Write-Host "`n2. Analyzing Compliance Policies..." -ForegroundColor Yellow
    
    $policies = Get-MgDeviceManagementDeviceCompliancePolicy -All
    $results = @{
        Total = $policies.Count
        Windows = ($policies | Where-Object { $_.'@odata.type' -like "*windows*" }).Count
        iOS = ($policies | Where-Object { $_.'@odata.type' -like "*ios*" }).Count
        Android = ($policies | Where-Object { $_.'@odata.type' -like "*android*" }).Count
        Issues = @()
    }
    
    foreach ($policy in $policies) {
        $assignments = Get-MgDeviceManagementDeviceCompliancePolicyAssignment -DeviceCompliancePolicyId $policy.Id
        if (!$assignments) {
            $results.Issues += @{
                Policy = $policy.DisplayName
                Issue = "No assignments"
                Id = $policy.Id
            }
        }
    }
    
    Write-Host "  Total Policies: $($results.Total)" -ForegroundColor White
    Write-Host "  Issues Found: $($results.Issues.Count)" -ForegroundColor $(if($results.Issues.Count -gt 0){"Red"}else{"Green"})
    
    return $results
}

function Get-DeviceGroups {
    Write-Host "`n3. Analyzing Device Groups..." -ForegroundColor Yellow
    
    $groups = Get-MgGroup -All | Where-Object { $_.DisplayName -like "*eSIM*" -or $_.DisplayName -like "*device*" }
    $results = @{
        Total = $groups.Count
        Dynamic = ($groups | Where-Object { $_.GroupTypes -contains "DynamicMembership" }).Count
        Static = ($groups | Where-Object { $_.GroupTypes -notcontains "DynamicMembership" }).Count
        Empty = @()
        Carriers = @()
    }
    
    foreach ($group in $groups) {
        $members = Get-MgGroupMember -GroupId $group.Id
        if (!$members) {
            $results.Empty += $group
        }
        
        if ($group.DisplayName -match "(MPT|ATOM|U9|MYTEL)") {
            $results.Carriers += $group
        }
    }
    
    Write-Host "  Total Groups: $($results.Total)" -ForegroundColor White
    Write-Host "  Dynamic: $($results.Dynamic) | Static: $($results.Static)" -ForegroundColor White
    Write-Host "  Empty Groups: $($results.Empty.Count)" -ForegroundColor $(if($results.Empty.Count -gt 0){"Yellow"}else{"Green"})
    Write-Host "  Carrier Groups: $($results.Carriers.Count)" -ForegroundColor White
    
    return $results
}

function Test-GraphAPIHealth {
    Write-Host "`n4. Testing Graph API Connection..." -ForegroundColor Yellow
    
    $results = @{
        Connected = $false
        Permissions = @()
        Errors = @()
    }
    
    try {
        $context = Get-MgContext
        $results.Connected = $true
        $results.Permissions = $context.Scopes
        
        # Test key endpoints
        $testEndpoints = @(
            "/deviceManagement",
            "/groups",
            "/identity/conditionalAccess/policies"
        )
        
        foreach ($endpoint in $testEndpoints) {
            try {
                Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0$endpoint" -Method GET | Out-Null
                Write-Host "  + $endpoint accessible" -ForegroundColor Green
            } catch {
                $results.Errors += "Failed to access $endpoint"
                Write-Host "  - $endpoint failed" -ForegroundColor Red
            }
        }
    } catch {
        $results.Errors += $_.Exception.Message
    }
    
    return $results
}

function Update-DeprecatedPolicies {
    param($ConfigProfiles, $CompliancePolicies)
    
    if (!$AutoUpdate) {
        Write-Host "`n5. Deprecated Policy Analysis (Read-Only Mode)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n5. Updating Deprecated Policies..." -ForegroundColor Yellow
    
    $updated = 0
    
    # Archive deprecated configuration profiles
    foreach ($profile in $ConfigProfiles.Deprecated) {
        try {
            $newName = "$($profile.DisplayName) - ARCHIVED $(Get-Date -Format 'yyyy-MM-dd')"
            Update-MgDeviceManagementDeviceConfiguration -DeviceConfigurationId $profile.Id -DisplayName $newName
            $updated++
            Write-Host "  + Archived: $($profile.DisplayName)" -ForegroundColor Green
        } catch {
            Write-Host "  - Failed to archive: $($profile.DisplayName)" -ForegroundColor Red
        }
    }
    
    Write-Host "  Updated $updated deprecated policies" -ForegroundColor White
}

function Initialize-ePMIntegration {
    if (!$PrepareForePM) {
        return
    }
    
    Write-Host "`n6. Preparing for eSIM Profile Management Integration..." -ForegroundColor Yellow
    
    $carriers = @("MPT", "ATOM", "U9", "MYTEL")
    $createdGroups = 0
    
    foreach ($carrier in $carriers) {
        $groupName = "eSIM Devices - $carrier"
        
        # Check if group exists
        $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'"
        
        if (!$existingGroup) {
            $groupParams = @{
                DisplayName = $groupName
                Description = "Dynamic group for $carrier eSIM devices"
                MailNickname = "esim$($carrier.ToLower())devices"
                GroupTypes = @("DynamicMembership")
                MembershipRule = "(device.deviceModel -contains `"eSIM`") and (device.extensionAttribute1 -eq `"$carrier`")"
                MembershipRuleProcessingState = "On"
                MailEnabled = $false
                SecurityEnabled = $true
            }
            
            try {
                New-MgGroup -BodyParameter $groupParams | Out-Null
                $createdGroups++
                Write-Host "  + Created group: $groupName" -ForegroundColor Green
            } catch {
                Write-Host "  - Failed to create group: $groupName" -ForegroundColor Red
            }
        } else {
            Write-Host "  + Group exists: $groupName" -ForegroundColor Green
        }
    }
    
    Write-Host "  Created $createdGroups new carrier groups" -ForegroundColor White
}

function Export-HealthReport {
    param($ConfigProfiles, $CompliancePolicies, $DeviceGroups, $APIHealth)
    
    if (!$GenerateReport) {
        return
    }
    
    Write-Host "`n7. Generating Health Report..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $reportData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Tenant = "MDM.esim.com.mm"
        ConfigurationProfiles = $ConfigProfiles
        CompliancePolicies = $CompliancePolicies
        DeviceGroups = $DeviceGroups
        APIHealth = $APIHealth
        Summary = @{
            TotalIssues = $ConfigProfiles.Deprecated.Count + $ConfigProfiles.Unused.Count + $CompliancePolicies.Issues.Count + $DeviceGroups.Empty.Count
            HealthScore = 100 - (($ConfigProfiles.Deprecated.Count + $ConfigProfiles.Unused.Count + $CompliancePolicies.Issues.Count) * 5)
        }
    }
    
    # Export JSON report
    $jsonFile = Join-Path $OutputPath "intune-health-report-$timestamp.json"
    $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
    
    # Export CSV summary
    $csvData = @()
    $csvData += [PSCustomObject]@{
        Category = "Configuration Profiles"
        Total = $ConfigProfiles.Total
        Issues = $ConfigProfiles.Deprecated.Count + $ConfigProfiles.Unused.Count
        Status = if($ConfigProfiles.Deprecated.Count + $ConfigProfiles.Unused.Count -eq 0){"Healthy"}else{"Needs Attention"}
    }
    $csvData += [PSCustomObject]@{
        Category = "Compliance Policies"
        Total = $CompliancePolicies.Total
        Issues = $CompliancePolicies.Issues.Count
        Status = if($CompliancePolicies.Issues.Count -eq 0){"Healthy"}else{"Needs Attention"}
    }
    $csvData += [PSCustomObject]@{
        Category = "Device Groups"
        Total = $DeviceGroups.Total
        Issues = $DeviceGroups.Empty.Count
        Status = if($DeviceGroups.Empty.Count -eq 0){"Healthy"}else{"Needs Attention"}
    }
    
    $csvFile = Join-Path $OutputPath "intune-health-summary-$timestamp.csv"
    $csvData | Export-Csv -Path $csvFile -NoTypeInformation
    
    Write-Host "  + JSON Report: $jsonFile" -ForegroundColor Green
    Write-Host "  + CSV Summary: $csvFile" -ForegroundColor Green
    Write-Host "  Health Score: $($reportData.Summary.HealthScore)%" -ForegroundColor $(if($reportData.Summary.HealthScore -ge 80){"Green"}elseif($reportData.Summary.HealthScore -ge 60){"Yellow"}else{"Red"})
}

# Main execution
try {
    Initialize-HealthCheck
    
    $configProfiles = Get-ConfigurationProfiles
    $compliancePolicies = Get-CompliancePolicies  
    $deviceGroups = Get-DeviceGroups
    $apiHealth = Test-GraphAPIHealth
    
    Update-DeprecatedPolicies -ConfigProfiles $configProfiles -CompliancePolicies $compliancePolicies
    Initialize-ePMIntegration
    Export-HealthReport -ConfigProfiles $configProfiles -CompliancePolicies $compliancePolicies -DeviceGroups $deviceGroups -APIHealth $apiHealth
    
    Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
    Write-Host "Run with -GenerateReport to export detailed reports" -ForegroundColor White
    Write-Host "Run with -AutoUpdate to automatically fix issues" -ForegroundColor White
    Write-Host "Run with -PrepareForePM to create eSIM carrier groups" -ForegroundColor White
    
} catch {
    Write-Error "Health check failed: $($_.Exception.Message)"
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}