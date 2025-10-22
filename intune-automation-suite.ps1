# Intune Automation Suite - Complete Health Check and Update
# Orchestrates all health check components for MDM.esim.com.mm

param(
    [switch]$FullHealthCheck,
    [switch]$AutoFix,
    [switch]$PrepareePM,
    [switch]$GenerateReports,
    [string]$OutputPath = "C:\IntuneHealthCheck"
)

# Import required modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Banner {
    param([string]$Text, [string]$Color = "Cyan")
    Write-Host "`n$('=' * 60)" -ForegroundColor $Color
    Write-Host $Text.PadLeft(($Text.Length + 60) / 2) -ForegroundColor $Color
    Write-Host $('=' * 60) -ForegroundColor $Color
}

function Initialize-AutomationSuite {
    Write-Banner "Intune Health Check & Automation Suite" "Cyan"
    Write-Host "Tenant: MDM.esim.com.mm" -ForegroundColor Yellow
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    
    # Ensure output directory exists
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
    }
    
    # Connect to Microsoft Graph with all required permissions
    $AllScopes = @(
        "DeviceManagementConfiguration.ReadWrite.All",
        "DeviceManagementManagedDevices.ReadWrite.All",
        "Group.ReadWrite.All",
        "Policy.ReadWrite.ConditionalAccess",
        "Directory.ReadWrite.All",
        "Application.ReadWrite.All"
    )
    
    try {
        Connect-MgGraph -Scopes $AllScopes
        Write-Host "+ Connected to Microsoft Graph with full permissions" -ForegroundColor Green
    } catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        exit 1
    }
}

function Invoke-MainHealthCheck {
    Write-Banner "Main Health Check Execution"
    
    $healthCheckParams = @{
        OutputPath = $OutputPath
    }
    
    if ($GenerateReports) { $healthCheckParams.GenerateReport = $true }
    if ($AutoFix) { $healthCheckParams.AutoUpdate = $true }
    if ($PrepareePM) { $healthCheckParams.PrepareForePM = $true }
    
    # Execute main health check
    & "$ScriptPath\intune-health-check.ps1" @healthCheckParams
}

function Invoke-ConditionalAccessCheck {
    Write-Banner "Conditional Access Policy Check"
    
    # Source the conditional access functions
    . "$ScriptPath\conditional-access-check.ps1"
    
    $caResults = Test-ConditionalAccessPolicies
    
    if ($AutoFix -and $caResults.Recommendations.Count -gt 0) {
        Write-Host "`nCreating recommended Conditional Access policies..." -ForegroundColor Yellow
        
        # Create eSIM-specific CA policy
        New-eSIMConditionalAccessPolicy -PolicyName "eSIM Device Zero Trust Policy" -ReportOnlyMode:(!$AutoFix)
    }
    
    return $caResults
}

function Invoke-DriveProtectionCheck {
    Write-Banner "OneDrive & BitLocker Protection Check"
    
    # Source the drive protection functions
    . "$ScriptPath\onedrive-bitlocker-check.ps1"
    
    $onedriveResults = Test-OneDrivePolicies
    $bitlockerResults = Test-BitLockerPolicies
    $encryptionCompliance = Test-DeviceEncryptionCompliance
    
    if ($AutoFix) {
        if ($onedriveResults.Issues.Count -gt 0) {
            Write-Host "`nCreating OneDrive Known Folder Move policy..." -ForegroundColor Yellow
            New-OneDriveKnownFolderMovePolicy
        }
        
        if ($bitlockerResults.Issues.Count -gt 0) {
            Write-Host "`nCreating BitLocker encryption policy..." -ForegroundColor Yellow
            New-BitLockerEncryptionPolicy
        }
    }
    
    return @{
        OneDrive = $onedriveResults
        BitLocker = $bitlockerResults
        Encryption = $encryptionCompliance
    }
}

function Test-ePMReadiness {
    Write-Banner "eSIM Profile Management (ePM) Readiness Check"
    
    $requiredGroups = @("MPT", "ATOM", "U9", "MYTEL")
    $readinessResults = @{
        CarrierGroups = @{}
        BaselinePolicies = @{}
        AuditLogs = $false
        OverallReadiness = 0
    }
    
    # Check carrier groups
    foreach ($carrier in $requiredGroups) {
        $groupName = "eSIM Devices - $carrier"
        $group = Get-MgGroup -Filter "displayName eq '$groupName'"
        
        if ($group) {
            $members = Get-MgGroupMember -GroupId $group.Id
            $readinessResults.CarrierGroups[$carrier] = @{
                Exists = $true
                MemberCount = $members.Count
                GroupId = $group.Id
            }
            Write-Host "+ $carrier group ready ($($members.Count) members)" -ForegroundColor Green
        } else {
            $readinessResults.CarrierGroups[$carrier] = @{
                Exists = $false
                MemberCount = 0
                GroupId = $null
            }
            Write-Host "- $carrier group missing" -ForegroundColor Red
        }
    }
    
    # Check baseline MDM profiles for each carrier
    foreach ($carrier in $requiredGroups) {
        $policyName = "eSIM Baseline - $carrier"
        $policy = Get-MgDeviceManagementDeviceConfiguration -Filter "displayName eq '$policyName'"
        
        $readinessResults.BaselinePolicies[$carrier] = @{
            Exists = $policy -ne $null
            PolicyId = if ($policy) { $policy.Id } else { $null }
        }
        
        if ($policy) {
            Write-Host "+ $carrier baseline policy exists" -ForegroundColor Green
        } else {
            Write-Host "- $carrier baseline policy missing" -ForegroundColor Red
        }
    }
    
    # Calculate overall readiness percentage
    $totalChecks = ($requiredGroups.Count * 2) + 1  # Groups + Policies + Audit logs
    $passedChecks = 0
    
    foreach ($carrier in $requiredGroups) {
        if ($readinessResults.CarrierGroups[$carrier].Exists) { $passedChecks++ }
        if ($readinessResults.BaselinePolicies[$carrier].Exists) { $passedChecks++ }
    }
    
    $readinessResults.OverallReadiness = [math]::Round(($passedChecks / $totalChecks) * 100, 2)
    
    Write-Host "`nePM Integration Readiness: $($readinessResults.OverallReadiness)%" -ForegroundColor $(
        if ($readinessResults.OverallReadiness -ge 80) { "Green" }
        elseif ($readinessResults.OverallReadiness -ge 60) { "Yellow" }
        else { "Red" }
    )
    
    return $readinessResults
}

function New-CarrierBaselinePolicies {
    param([array]$Carriers = @("MPT", "ATOM", "U9", "MYTEL"))
    
    Write-Host "`nCreating baseline MDM policies for carriers..." -ForegroundColor Yellow
    
    foreach ($carrier in $Carriers) {
        $policyName = "eSIM Baseline - $carrier"
        
        # Check if policy already exists
        $existingPolicy = Get-MgDeviceManagementDeviceConfiguration -Filter "displayName eq '$policyName'"
        if ($existingPolicy) {
            Write-Host "  + Policy exists: $policyName" -ForegroundColor Green
            continue
        }
        
        # Create carrier-specific baseline policy
        $policy = @{
            "@odata.type" = "#microsoft.graph.windows10GeneralConfiguration"
            displayName = $policyName
            description = "Baseline configuration for $carrier eSIM devices"
            privacyAdvertisingId = "blocked"
            privacyAutoAcceptPairingAndConsentPrompts = $false
            privacyBlockInputPersonalization = $true
            startBlockUnpinningAppsFromTaskbar = $true
            startMenuAppListVisibility = "userDefined"
            startMenuHideChangeAccountSettings = $false
            startMenuHideFrequentlyUsedApps = $false
            startMenuHideHibernate = $false
            startMenuHideLock = $false
            startMenuHidePowerButton = $false
            startMenuHideRecentJumpLists = $false
            startMenuHideRecentlyAddedApps = $false
            startMenuHideRestartOptions = $false
            startMenuHideShutDown = $false
            startMenuHideSignOut = $false
            startMenuHideSleep = $false
            startMenuHideSwitchAccount = $false
            startMenuHideUserTile = $false
            startMenuLayoutXml = $null
            startMenuMode = "userDefined"
            startMenuPinnedFolderDocuments = "notConfigured"
            startMenuPinnedFolderDownloads = "notConfigured"
            startMenuPinnedFolderFileExplorer = "notConfigured"
            startMenuPinnedFolderHomeGroup = "notConfigured"
            startMenuPinnedFolderMusic = "notConfigured"
            startMenuPinnedFolderNetwork = "notConfigured"
            startMenuPinnedFolderPersonalFolder = "notConfigured"
            startMenuPinnedFolderPictures = "notConfigured"
            startMenuPinnedFolderSettings = "notConfigured"
            startMenuPinnedFolderVideos = "notConfigured"
        }
        
        try {
            $createdPolicy = New-MgDeviceManagementDeviceConfiguration -BodyParameter $policy
            Write-Host "  + Created policy: $policyName" -ForegroundColor Green
            
            # Assign to carrier group
            $carrierGroup = Get-MgGroup -Filter "displayName eq 'eSIM Devices - $carrier'"
            if ($carrierGroup) {
                $assignment = @{
                    target = @{
                        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                        groupId = $carrierGroup.Id
                    }
                }
                New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $createdPolicy.Id -BodyParameter $assignment
                Write-Host "    + Assigned to $carrier group" -ForegroundColor Green
            }
        } catch {
            Write-Host "  - Failed to create policy: $policyName - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Export-ComprehensiveReport {
    param(
        $HealthCheckResults,
        $ConditionalAccessResults,
        $DriveProtectionResults,
        $ePMReadinessResults
    )
    
    Write-Banner "Generating Comprehensive Report"
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Create comprehensive report object
    $comprehensiveReport = @{
        ReportMetadata = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Tenant = "MDM.esim.com.mm"
            ReportType = "Comprehensive Intune Health Check"
            Version = "1.0"
        }
        ExecutionSummary = @{
            TotalIssuesFound = 0
            CriticalIssues = 0
            WarningIssues = 0
            OverallHealthScore = 0
            ePMReadinessScore = $ePMReadinessResults.OverallReadiness
        }
        DetailedResults = @{
            ConfigurationProfiles = $HealthCheckResults.ConfigurationProfiles
            CompliancePolicies = $HealthCheckResults.CompliancePolicies
            DeviceGroups = $HealthCheckResults.DeviceGroups
            ConditionalAccess = $ConditionalAccessResults
            DriveProtection = $DriveProtectionResults
            ePMReadiness = $ePMReadinessResults
        }
        Recommendations = @()
        NextSteps = @()
    }
    
    # Calculate overall health score and issues
    $totalIssues = 0
    if ($HealthCheckResults.ConfigurationProfiles) {
        $totalIssues += $HealthCheckResults.ConfigurationProfiles.Deprecated.Count + $HealthCheckResults.ConfigurationProfiles.Unused.Count
    }
    if ($HealthCheckResults.CompliancePolicies) {
        $totalIssues += $HealthCheckResults.CompliancePolicies.Issues.Count
    }
    if ($ConditionalAccessResults) {
        $totalIssues += $ConditionalAccessResults.Issues.Count
    }
    
    $comprehensiveReport.ExecutionSummary.TotalIssuesFound = $totalIssues
    $comprehensiveReport.ExecutionSummary.OverallHealthScore = 100 - ($totalIssues * 3)
    
    # Generate recommendations
    if ($ePMReadinessResults.OverallReadiness -lt 100) {
        $comprehensiveReport.Recommendations += "Complete eSIM Profile Management preparation by creating missing carrier groups and baseline policies"
    }
    
    if ($DriveProtectionResults.Encryption.NotEncrypted -gt 0) {
        $comprehensiveReport.Recommendations += "Enable BitLocker encryption on $($DriveProtectionResults.Encryption.NotEncrypted) non-encrypted devices"
    }
    
    # Export reports
    $jsonFile = Join-Path $OutputPath "comprehensive-intune-report-$timestamp.json"
    $comprehensiveReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
    
    # Create executive summary CSV
    $executiveSummary = @(
        [PSCustomObject]@{
            Metric = "Overall Health Score"
            Value = "$($comprehensiveReport.ExecutionSummary.OverallHealthScore)%"
            Status = if($comprehensiveReport.ExecutionSummary.OverallHealthScore -ge 80){"Excellent"}elseif($comprehensiveReport.ExecutionSummary.OverallHealthScore -ge 60){"Good"}else{"Needs Attention"}
        },
        [PSCustomObject]@{
            Metric = "ePM Readiness Score"
            Value = "$($comprehensiveReport.ExecutionSummary.ePMReadinessScore)%"
            Status = if($comprehensiveReport.ExecutionSummary.ePMReadinessScore -ge 80){"Ready"}elseif($comprehensiveReport.ExecutionSummary.ePMReadinessScore -ge 60){"Nearly Ready"}else{"Not Ready"}
        },
        [PSCustomObject]@{
            Metric = "Total Issues Found"
            Value = $comprehensiveReport.ExecutionSummary.TotalIssuesFound
            Status = if($comprehensiveReport.ExecutionSummary.TotalIssuesFound -eq 0){"Clean"}elseif($comprehensiveReport.ExecutionSummary.TotalIssuesFound -le 5){"Minor Issues"}else{"Major Issues"}
        }
    )
    
    $csvFile = Join-Path $OutputPath "executive-summary-$timestamp.csv"
    $executiveSummary | Export-Csv -Path $csvFile -NoTypeInformation
    
    Write-Host "+ Comprehensive Report: $jsonFile" -ForegroundColor Green
    Write-Host "+ Executive Summary: $csvFile" -ForegroundColor Green
    Write-Host "+ Overall Health Score: $($comprehensiveReport.ExecutionSummary.OverallHealthScore)%" -ForegroundColor $(
        if ($comprehensiveReport.ExecutionSummary.OverallHealthScore -ge 80) { "Green" }
        elseif ($comprehensiveReport.ExecutionSummary.OverallHealthScore -ge 60) { "Yellow" }
        else { "Red" }
    )
}

# Main execution flow
try {
    Initialize-AutomationSuite
    
    # Execute health checks based on parameters
    $healthCheckResults = $null
    $conditionalAccessResults = $null
    $driveProtectionResults = $null
    $ePMReadinessResults = $null
    
    if ($FullHealthCheck -or !($PSBoundParameters.Keys.Count -gt 0)) {
        Invoke-MainHealthCheck
        $conditionalAccessResults = Invoke-ConditionalAccessCheck
        $driveProtectionResults = Invoke-DriveProtectionCheck
        $ePMReadinessResults = Test-ePMReadiness
        
        if ($PrepareePM -and $ePMReadinessResults.OverallReadiness -lt 100) {
            New-CarrierBaselinePolicies
            # Re-test readiness after creating policies
            $ePMReadinessResults = Test-ePMReadiness
        }
    }
    
    if ($GenerateReports) {
        Export-ComprehensiveReport -HealthCheckResults $healthCheckResults -ConditionalAccessResults $conditionalAccessResults -DriveProtectionResults $driveProtectionResults -ePMReadinessResults $ePMReadinessResults
    }
    
    Write-Banner "Automation Suite Complete" "Green"
    Write-Host "All health checks completed successfully!" -ForegroundColor Green
    Write-Host "Reports saved to: $OutputPath" -ForegroundColor White
    
} catch {
    Write-Error "Automation suite failed: $($_.Exception.Message)"
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
} finally {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}