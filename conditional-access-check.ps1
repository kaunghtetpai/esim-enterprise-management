# Conditional Access Policy Health Check
# Zero Trust compliance validation for eSIM environment

function Test-ConditionalAccessPolicies {
    Write-Host "=== Conditional Access Policy Analysis ===" -ForegroundColor Cyan
    
    try {
        $policies = Get-MgIdentityConditionalAccessPolicy -All
        $results = @{
            Total = $policies.Count
            Enabled = ($policies | Where-Object { $_.State -eq "enabled" }).Count
            Disabled = ($policies | Where-Object { $_.State -eq "disabled" }).Count
            ReportOnly = ($policies | Where-Object { $_.State -eq "enabledForReportingButNotEnforced" }).Count
            Issues = @()
            Recommendations = @()
        }
        
        foreach ($policy in $policies) {
            # Check for MFA requirements
            if ($policy.GrantControls.BuiltInControls -contains "mfa") {
                Write-Host "+ MFA Policy: $($policy.DisplayName)" -ForegroundColor Green
            }
            
            # Check for device compliance requirements
            if ($policy.GrantControls.BuiltInControls -contains "compliantDevice") {
                Write-Host "+ Device Compliance Policy: $($policy.DisplayName)" -ForegroundColor Green
            }
            
            # Check for risky sign-in policies
            if ($policy.Conditions.SignInRiskLevels) {
                Write-Host "+ Risk-based Policy: $($policy.DisplayName)" -ForegroundColor Green
            }
            
            # Identify potential issues
            if ($policy.State -eq "disabled" -and $policy.DisplayName -like "*eSIM*") {
                $results.Issues += @{
                    Policy = $policy.DisplayName
                    Issue = "eSIM-related policy is disabled"
                    Recommendation = "Enable policy for eSIM device protection"
                }
            }
        }
        
        # Generate recommendations
        $mfaPolicies = $policies | Where-Object { $_.GrantControls.BuiltInControls -contains "mfa" }
        if ($mfaPolicies.Count -eq 0) {
            $results.Recommendations += "Create MFA requirement policy for all users"
        }
        
        $deviceCompliancePolicies = $policies | Where-Object { $_.GrantControls.BuiltInControls -contains "compliantDevice" }
        if ($deviceCompliancePolicies.Count -eq 0) {
            $results.Recommendations += "Create device compliance requirement policy"
        }
        
        Write-Host "`nSummary:" -ForegroundColor Yellow
        Write-Host "  Total Policies: $($results.Total)" -ForegroundColor White
        Write-Host "  Enabled: $($results.Enabled) | Disabled: $($results.Disabled) | Report-Only: $($results.ReportOnly)" -ForegroundColor White
        Write-Host "  Issues: $($results.Issues.Count)" -ForegroundColor $(if($results.Issues.Count -gt 0){"Red"}else{"Green"})
        Write-Host "  Recommendations: $($results.Recommendations.Count)" -ForegroundColor $(if($results.Recommendations.Count -gt 0){"Yellow"}else{"Green"})
        
        return $results
        
    } catch {
        Write-Error "Failed to analyze Conditional Access policies: $($_.Exception.Message)"
        return $null
    }
}

function New-eSIMConditionalAccessPolicy {
    param(
        [string]$PolicyName = "eSIM Device Compliance Policy",
        [switch]$ReportOnlyMode
    )
    
    $policyState = if ($ReportOnlyMode) { "enabledForReportingButNotEnforced" } else { "enabled" }
    
    $policy = @{
        displayName = $PolicyName
        state = $policyState
        conditions = @{
            applications = @{
                includeApplications = @("All")
            }
            users = @{
                includeGroups = @("eSIM-MPT-Devices", "eSIM-ATOM-Devices", "eSIM-U9-Devices", "eSIM-MYTEL-Devices")
            }
            platforms = @{
                includePlatforms = @("windows", "iOS", "android")
            }
        }
        grantControls = @{
            operator = "AND"
            builtInControls = @("mfa", "compliantDevice")
        }
    }
    
    try {
        $createdPolicy = New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
        Write-Host "+ Created Conditional Access Policy: $PolicyName" -ForegroundColor Green
        return $createdPolicy
    } catch {
        Write-Error "Failed to create policy: $($_.Exception.Message)"
        return $null
    }
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"
    Test-ConditionalAccessPolicies
    Disconnect-MgGraph
}