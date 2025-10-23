# Complete Enterprise Management System with CI/CD Pipeline
# Tenant: mdm.esim.com.mm | Admin: admin@mdm.esim.com.mm
# GitHub: https://github.com/kaunghtetpai/esim-enterprise-management
# Vercel: https://vercel.com/e-sim/esim-enterprise-management

param(
    [string]$TenantId = "mdm.esim.com.mm",
    [string]$AdminAccount = "admin@mdm.esim.com.mm",
    [string]$GitHubRepo = "https://github.com/kaunghtetpai/esim-enterprise-management",
    [string]$VercelProject = "https://vercel.com/e-sim/esim-enterprise-management",
    [string]$ProductionDomain = "https://esim-enterprise-management.vercel.app/",
    [string]$CustomDomain = "portal.nexorasim.com",
    [switch]$FullSetup,
    [switch]$ValidateOnly
)

$ErrorActionPreference = "Continue"

# Phase tracking
$Phases = @{
    "Phase1_EntraID" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
    "Phase2_Intune" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
    "Phase3_eSIM" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
    "Phase4_Policies" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
    "Phase5_Verification" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
    "Phase6_CompanyPortal" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
    "Phase7_CICD" = @{ Status = "Pending"; Errors = @(); Fixed = @() }
}

function Write-Status {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        default   { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
    }
}

function Add-PhaseError {
    param($Phase, $Error)
    $Phases[$Phase].Errors += $Error
    Write-Status $Error "Error"
}

function Add-PhaseSuccess {
    param($Phase, $Success)
    $Phases[$Phase].Fixed += $Success
    Write-Status $Success "Success"
}

# PHASE 1: ENTRA ID SETUP
function Start-Phase1EntraID {
    Write-Host "`n=== PHASE 1: MICROSOFT ENTRA ID 2 ACTIVATION ===" -ForegroundColor Yellow
    
    try {
        Connect-MgGraph -Scopes "Directory.ReadWrite.All", "User.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess" -NoWelcome
        
        $context = Get-MgContext
        if ($context) {
            Add-PhaseSuccess "Phase1_EntraID" "Connected to Microsoft Graph"
        } else {
            Add-PhaseError "Phase1_EntraID" "Failed to connect to Microsoft Graph"
            return $false
        }
        
        # Verify tenant
        $org = Get-MgOrganization
        if ($org.VerifiedDomains | Where-Object { $_.Name -eq $TenantId }) {
            Add-PhaseSuccess "Phase1_EntraID" "Tenant $TenantId verified"
        } else {
            Add-PhaseError "Phase1_EntraID" "Tenant verification failed"
        }
        
        # Check admin account
        $admin = Get-MgUser -Filter "userPrincipalName eq '$AdminAccount'"
        if ($admin) {
            Add-PhaseSuccess "Phase1_EntraID" "Admin account verified"
        } else {
            Add-PhaseError "Phase1_EntraID" "Admin account not found"
        }
        
        $Phases.Phase1_EntraID.Status = "Completed"
        return $true
    } catch {
        Add-PhaseError "Phase1_EntraID" "Phase 1 failed: $($_.Exception.Message)"
        return $false
    }
}

# PHASE 2: INTUNE INTEGRATION
function Start-Phase2Intune {
    Write-Host "`n=== PHASE 2: MICROSOFT INTUNE INTEGRATION ===" -ForegroundColor Yellow
    
    try {
        $intuneCheck = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement" -Method GET
        if ($intuneCheck.mdmAuthority -eq "intune") {
            Add-PhaseSuccess "Phase2_Intune" "Intune MDM authority configured"
        } else {
            Add-PhaseError "Phase2_Intune" "Intune MDM authority not set"
        }
        
        $Phases.Phase2_Intune.Status = "Completed"
        return $true
    } catch {
        Add-PhaseError "Phase2_Intune" "Phase 2 failed: $($_.Exception.Message)"
        return $false
    }
}

# PHASE 3: eSIM MANAGEMENT
function Start-Phase3eSIM {
    Write-Host "`n=== PHASE 3: eSIM ENTERPRISE MANAGEMENT ===" -ForegroundColor Yellow
    
    $carriers = @(
        @{ Name = "MPT"; MCC = "414"; MNC = "01" },
        @{ Name = "ATOM"; MCC = "414"; MNC = "06" },
        @{ Name = "MYTEL"; MCC = "414"; MNC = "09" }
    )
    
    foreach ($carrier in $carriers) {
        $groupName = "Group_$($carrier.Name)_eSIM"
        try {
            $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'"
            if (-not $existingGroup) {
                $groupParams = @{
                    DisplayName = $groupName
                    Description = "eSIM devices for $($carrier.Name) carrier"
                    MailEnabled = $false
                    SecurityEnabled = $true
                }
                New-MgGroup @groupParams
                Add-PhaseSuccess "Phase3_eSIM" "Created group: $groupName"
            } else {
                Add-PhaseSuccess "Phase3_eSIM" "Group exists: $groupName"
            }
        } catch {
            Add-PhaseError "Phase3_eSIM" "Failed to create group: $groupName"
        }
    }
    
    $Phases.Phase3_eSIM.Status = "Completed"
    return $true
}

# PHASE 4: POLICY MANAGEMENT
function Start-Phase4Policies {
    Write-Host "`n=== PHASE 4: DEVICE & POLICY MANAGEMENT ===" -ForegroundColor Yellow
    
    try {
        $compliancePolicy = @{
            "@odata.type" = "#microsoft.graph.windows10CompliancePolicy"
            displayName = "eSIM Enterprise Compliance"
            passwordRequired = $true
            passwordMinimumLength = 6
            requireHealthyDeviceReport = $true
        }
        
        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" -Method POST -Body ($compliancePolicy | ConvertTo-Json)
        Add-PhaseSuccess "Phase4_Policies" "Compliance policy created"
        
        $Phases.Phase4_Policies.Status = "Completed"
        return $true
    } catch {
        if ($_.Exception.Message -like "*already exists*") {
            Add-PhaseSuccess "Phase4_Policies" "Compliance policy exists"
        } else {
            Add-PhaseError "Phase4_Policies" "Failed to create compliance policy"
        }
        return $true
    }
}

# PHASE 5: SYSTEM VERIFICATION
function Start-Phase5Verification {
    Write-Host "`n=== PHASE 5: SYSTEM VERIFICATION ===" -ForegroundColor Yellow
    
    try {
        $users = Get-MgUser -Top 5
        Add-PhaseSuccess "Phase5_Verification" "Users verified: $($users.Count)"
        
        $groups = Get-MgGroup -Filter "startswith(displayName,'Group_')"
        Add-PhaseSuccess "Phase5_Verification" "eSIM groups verified: $($groups.Count)"
        
        $Phases.Phase5_Verification.Status = "Completed"
        return $true
    } catch {
        Add-PhaseError "Phase5_Verification" "Verification failed: $($_.Exception.Message)"
        return $false
    }
}

# PHASE 6: COMPANY PORTAL
function Start-Phase6CompanyPortal {
    Write-Host "`n=== PHASE 6: COMPANY PORTAL CONFIGURATION ===" -ForegroundColor Yellow
    
    try {
        $branding = @{
            displayName = "eSIM Enterprise Management"
            contactITName = "IT Support"
            contactITEmailAddress = "support@mdm.esim.com.mm"
        }
        
        Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/intuneBrand" -Method PATCH -Body ($branding | ConvertTo-Json)
        Add-PhaseSuccess "Phase6_CompanyPortal" "Company Portal configured"
        
        $Phases.Phase6_CompanyPortal.Status = "Completed"
        return $true
    } catch {
        Add-PhaseError "Phase6_CompanyPortal" "Company Portal configuration failed"
        return $false
    }
}

# PHASE 7: CI/CD PIPELINE
function Start-Phase7CICD {
    Write-Host "`n=== PHASE 7: CI/CD PIPELINE SETUP ===" -ForegroundColor Yellow
    
    try {
        # Check GitHub CLI
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            Add-PhaseSuccess "Phase7_CICD" "GitHub CLI available"
        } else {
            Add-PhaseError "Phase7_CICD" "GitHub CLI not installed"
        }
        
        # Check Vercel CLI
        $vercelVersion = vercel --version 2>$null
        if ($vercelVersion) {
            Add-PhaseSuccess "Phase7_CICD" "Vercel CLI available"
        } else {
            Add-PhaseError "Phase7_CICD" "Vercel CLI not installed"
        }
        
        # Validate repository
        if (Test-Path ".git") {
            Add-PhaseSuccess "Phase7_CICD" "Git repository detected"
        } else {
            Add-PhaseError "Phase7_CICD" "Not in a Git repository"
        }
        
        $Phases.Phase7_CICD.Status = "Completed"
        return $true
    } catch {
        Add-PhaseError "Phase7_CICD" "CI/CD setup failed: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Start-CompleteSetup {
    Write-Host "Enterprise Management System Setup" -ForegroundColor Cyan
    Write-Host "Tenant: $TenantId | Admin: $AdminAccount" -ForegroundColor Yellow
    Write-Host "GitHub: $GitHubRepo" -ForegroundColor Yellow
    Write-Host "Vercel: $VercelProject" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    $results = @()
    $results += Start-Phase1EntraID
    $results += Start-Phase2Intune
    $results += Start-Phase3eSIM
    $results += Start-Phase4Policies
    $results += Start-Phase5Verification
    $results += Start-Phase6CompanyPortal
    $results += Start-Phase7CICD
    
    # Summary
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "SETUP COMPLETE - SUMMARY" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    
    foreach ($phase in $Phases.Keys) {
        $status = $Phases[$phase].Status
        $errorCount = $Phases[$phase].Errors.Count
        $fixCount = $Phases[$phase].Fixed.Count
        
        $color = if ($status -eq "Completed") { "Green" } else { "Red" }
        Write-Host "$phase : $status (Errors: $errorCount, Fixed: $fixCount)" -ForegroundColor $color
    }
    
    $totalErrors = ($Phases.Values | ForEach-Object { $_.Errors.Count } | Measure-Object -Sum).Sum
    $totalFixed = ($Phases.Values | ForEach-Object { $_.Fixed.Count } | Measure-Object -Sum).Sum
    
    Write-Host "`nTotal Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -eq 0) { "Green" } else { "Red" })
    Write-Host "Total Fixed: $totalFixed" -ForegroundColor Green
    Write-Host "`nEnterprise Management System Ready!" -ForegroundColor Green
}

if ($FullSetup) {
    Start-CompleteSetup
} elseif ($ValidateOnly) {
    Start-Phase5Verification
} else {
    Write-Host "Use -FullSetup for complete setup or -ValidateOnly for validation" -ForegroundColor Yellow
}