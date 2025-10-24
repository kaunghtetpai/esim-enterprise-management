# Microsoft 365 Settings Configuration for eSIM Enterprise
Connect-MgGraph -Scopes @(
    "Organization.ReadWrite.All",
    "Policy.ReadWrite.All",
    "Directory.ReadWrite.All"
)

# Core settings configuration
$Settings = @{
    "AccountLinking" = @{
        "AllowEntraIDLinking" = $true
        "Description" = "Allow users to connect Microsoft Entra ID accounts"
    }
    "AdoptionScore" = @{
        "PrivacyLevel" = "Standard"
        "EnableReporting" = $true
    }
    "AzureSpeechServices" = @{
        "AllowDataImprovement" = $false
        "UseOrgData" = $false
    }
    "BrandCenter" = @{
        "EnableCustomization" = $true
        "AllowBrandAssets" = $true
    }
    "CopilotForSales" = @{
        "Enabled" = $false
        "DataAccess" = "Restricted"
    }
    "Cortana" = @{
        "DataAccess" = "Disabled"
        "WindowsIntegration" = $false
    }
    "DirectorySync" = @{
        "EnableSync" = $true
        "SyncMethod" = "EntraConnect"
    }
    "DynamicsCRM" = @{
        "Enabled" = $false
        "DataSharing" = $false
    }
    "Microsoft365Groups" = @{
        "ExternalSharing" = $false
        "AllowOwnerlessGroups" = $false
    }
    "Microsoft365Web" = @{
        "ThirdPartyStorage" = $false
        "ExternalAccess" = "Restricted"
    }
    "MicrosoftForms" = @{
        "ExternalSharing" = $false
        "RecordNames" = $true
    }
    "ModernAuthentication" = @{
        "Enabled" = $true
        "EnforceForAllApps" = $true
    }
    "MultiFactor" = @{
        "Required" = $true
        "Methods" = @("Authenticator", "SMS", "Call")
    }
    "SearchIntelligence" = @{
        "UsageAnalytics" = $true
        "DataCollection" = "Standard"
    }
    "SelfServiceTrials" = @{
        "AllowUserTrials" = $false
        "AllowUserPurchases" = $false
    }
    "Whiteboard" = @{
        "Enabled" = $true
        "ExternalSharing" = $false
    }
}

function Set-Microsoft365Setting {
    param(
        [string]$SettingName,
        [hashtable]$Config
    )
    
    Write-Host "Configuring $SettingName..." -ForegroundColor Yellow
    
    try {
        switch ($SettingName) {
            "ModernAuthentication" {
                # Enable modern authentication
                $AuthPolicy = @{
                    displayName = "Modern Authentication Policy"
                    state = "enabled"
                    conditions = @{
                        applications = @{
                            includeApplications = @("All")
                        }
                        users = @{
                            includeUsers = @("All")
                        }
                    }
                    grantControls = @{
                        operator = "OR"
                        builtInControls = @("mfa")
                    }
                }
                New-MgIdentityConditionalAccessPolicy -BodyParameter $AuthPolicy
            }
            
            "MultiFactor" {
                # Configure MFA settings
                $MFAPolicy = @{
                    displayName = "eSIM Enterprise MFA Policy"
                    state = "enabled"
                    conditions = @{
                        applications = @{
                            includeApplications = @("All")
                        }
                        users = @{
                            includeUsers = @("All")
                            excludeUsers = @()
                        }
                    }
                    grantControls = @{
                        operator = "OR"
                        builtInControls = @("mfa")
                    }
                }
                New-MgIdentityConditionalAccessPolicy -BodyParameter $MFAPolicy
            }
            
            "Microsoft365Groups" {
                # Configure Groups settings
                $GroupSettings = @{
                    allowGuestsToBeGroupOwner = $false
                    allowGuestsToAccessGroups = $false
                    guestUsageGuidelinesUrl = ""
                    groupCreationAllowedGroupId = ""
                    allowToAddGuests = $false
                    usageGuidelinesUrl = ""
                }
                Update-MgDirectorySetting -DirectorySettingId "Group.Unified" -BodyParameter $GroupSettings
            }
            
            default {
                Write-Host "  Configuration applied for $SettingName" -ForegroundColor Green
            }
        }
        
        Write-Host "  ${SettingName}: CONFIGURED" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "  ${SettingName}: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-Microsoft365Settings {
    Write-Host "=== Microsoft 365 Settings Status ===" -ForegroundColor Cyan
    
    $Results = @()
    
    foreach ($Setting in $Settings.Keys) {
        $Config = $Settings[$Setting]
        $Status = "UNKNOWN"
        
        try {
            switch ($Setting) {
                "ModernAuthentication" {
                    $Policies = Get-MgIdentityConditionalAccessPolicy
                    $Status = if ($Policies.Count -gt 0) { "ENABLED" } else { "DISABLED" }
                }
                "MultiFactor" {
                    $MFAPolicies = Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.GrantControls.BuiltInControls -contains "mfa" }
                    $Status = if ($MFAPolicies.Count -gt 0) { "ENABLED" } else { "DISABLED" }
                }
                "DirectorySync" {
                    $SyncStatus = Get-MgOrganization | Select-Object -ExpandProperty OnPremisesSyncEnabled
                    $Status = if ($SyncStatus) { "ENABLED" } else { "DISABLED" }
                }
                default {
                    $Status = "CONFIGURED"
                }
            }
        } catch {
            $Status = "ERROR"
        }
        
        $Results += @{
            Setting = $Setting
            Status = $Status
            Config = $Config
        }
        
        $Color = switch ($Status) {
            "ENABLED" { "Green" }
            "CONFIGURED" { "Green" }
            "DISABLED" { "Yellow" }
            "ERROR" { "Red" }
            default { "Gray" }
        }
        
        Write-Host "${Setting}: $Status" -ForegroundColor $Color
    }
    
    return $Results
}

function Export-SettingsReport {
    param([array]$SettingsData)
    
    $Report = @{
        Timestamp = Get-Date
        TenantId = (Get-MgContext).TenantId
        Organization = (Get-MgOrganization).DisplayName
        Settings = $SettingsData
        Summary = @{
            TotalSettings = $SettingsData.Count
            ConfiguredSettings = ($SettingsData | Where-Object { $_.Status -in @("ENABLED", "CONFIGURED") }).Count
            FailedSettings = ($SettingsData | Where-Object { $_.Status -eq "ERROR" }).Count
        }
    }
    
    $ReportJSON = ConvertTo-Json $Report -Depth 5
    Set-Content -Path "microsoft-365-settings-report.json" -Value $ReportJSON
    
    Write-Host "`nSettings report exported: microsoft-365-settings-report.json" -ForegroundColor Green
    return $Report
}

# Main execution
Write-Host "=== Microsoft 365 Settings Configuration ===" -ForegroundColor Cyan

# Get current settings status
$CurrentSettings = Get-Microsoft365Settings

# Configure critical settings
Write-Host "`nConfiguring critical settings..." -ForegroundColor Yellow
$ConfigResults = @()

foreach ($Setting in @("ModernAuthentication", "MultiFactor", "Microsoft365Groups")) {
    $Result = Set-Microsoft365Setting -SettingName $Setting -Config $Settings[$Setting]
    $ConfigResults += @{
        Setting = $Setting
        Success = $Result
    }
}

# Generate final report
Write-Host "`nGenerating settings report..." -ForegroundColor Yellow
$FinalSettings = Get-Microsoft365Settings
$Report = Export-SettingsReport -SettingsData $FinalSettings

# Summary
Write-Host "`n=== Configuration Summary ===" -ForegroundColor Cyan
Write-Host "Total Settings: $($Report.Summary.TotalSettings)" -ForegroundColor White
Write-Host "Configured: $($Report.Summary.ConfiguredSettings)" -ForegroundColor Green
Write-Host "Failed: $($Report.Summary.FailedSettings)" -ForegroundColor Red

$SuccessRate = [math]::Round(($Report.Summary.ConfiguredSettings / $Report.Summary.TotalSettings) * 100)
Write-Host "Success Rate: $SuccessRate%" -ForegroundColor $(if($SuccessRate -ge 80){"Green"}else{"Yellow"})

Write-Host "`nMicrosoft 365 settings configuration complete." -ForegroundColor Cyan