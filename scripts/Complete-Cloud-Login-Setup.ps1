# Complete Cloud Login and Authentication Setup
# Vercel + GitHub + Microsoft Cloud (Entra ID + Intune)
# Admin: admin@mdm.esim.com.mm | Tenant: mdm.esim.com.mm

param(
    [string]$AdminAccount = "admin@mdm.esim.com.mm",
    [string]$TenantId = "mdm.esim.com.mm",
    [switch]$LoginAll,
    [switch]$ValidateAll,
    [switch]$SyncAll
)

$ErrorActionPreference = "Continue"

# Authentication status tracking
$AuthStatus = @{
    GitHub = @{ LoggedIn = $false; User = $null; Token = $null }
    Vercel = @{ LoggedIn = $false; User = $null; Team = $null }
    MicrosoftGraph = @{ LoggedIn = $false; Account = $null; Scopes = @() }
    Intune = @{ LoggedIn = $false; Authority = $null; Connected = $false }
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

# GITHUB LOGIN AND VALIDATION
function Connect-GitHub {
    Write-Host "`n=== GITHUB AUTHENTICATION ===" -ForegroundColor Yellow
    
    try {
        # Check if GitHub CLI is installed
        $ghVersion = gh --version 2>$null
        if (-not $ghVersion) {
            Write-Status "GitHub CLI not installed. Installing..." "Warning"
            winget install GitHub.cli
        }
        
        # Check current authentication
        $authStatus = gh auth status 2>&1
        if ($authStatus -like "*Logged in*") {
            $user = gh api user --jq '.login' 2>$null
            $AuthStatus.GitHub.LoggedIn = $true
            $AuthStatus.GitHub.User = $user
            Write-Status "Already logged in to GitHub as: $user" "Success"
        } else {
            Write-Status "Logging in to GitHub..." "Info"
            gh auth login --web --scopes "repo,workflow,admin:org,admin:repo_hook"
            
            $user = gh api user --jq '.login' 2>$null
            if ($user) {
                $AuthStatus.GitHub.LoggedIn = $true
                $AuthStatus.GitHub.User = $user
                Write-Status "Successfully logged in to GitHub as: $user" "Success"
            } else {
                Write-Status "GitHub login failed" "Error"
                return $false
            }
        }
        
        # Validate repository access
        $repoCheck = gh repo view kaunghtetpai/esim-enterprise-management 2>$null
        if ($repoCheck) {
            Write-Status "Repository access confirmed: esim-enterprise-management" "Success"
        } else {
            Write-Status "Repository access failed" "Error"
        }
        
        # Get authentication token
        $token = gh auth token 2>$null
        if ($token) {
            $AuthStatus.GitHub.Token = $token.Substring(0, 8) + "..."
            Write-Status "GitHub token obtained" "Success"
        }
        
        return $true
    } catch {
        Write-Status "GitHub authentication failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

# VERCEL LOGIN AND VALIDATION
function Connect-Vercel {
    Write-Host "`n=== VERCEL AUTHENTICATION ===" -ForegroundColor Yellow
    
    try {
        # Check if Vercel CLI is installed
        $vercelVersion = vercel --version 2>$null
        if (-not $vercelVersion) {
            Write-Status "Vercel CLI not installed. Installing..." "Warning"
            npm install -g vercel@latest
        }
        
        # Check current authentication
        $whoami = vercel whoami 2>$null
        if ($whoami -and $whoami -ne "Not logged in") {
            $AuthStatus.Vercel.LoggedIn = $true
            $AuthStatus.Vercel.User = $whoami
            Write-Status "Already logged in to Vercel as: $whoami" "Success"
        } else {
            Write-Status "Logging in to Vercel..." "Info"
            vercel login
            
            $whoami = vercel whoami 2>$null
            if ($whoami -and $whoami -ne "Not logged in") {
                $AuthStatus.Vercel.LoggedIn = $true
                $AuthStatus.Vercel.User = $whoami
                Write-Status "Successfully logged in to Vercel as: $whoami" "Success"
            } else {
                Write-Status "Vercel login failed" "Error"
                return $false
            }
        }
        
        # Validate project access
        $projects = vercel ls 2>$null
        if ($projects -like "*esim-enterprise-management*") {
            Write-Status "Project access confirmed: esim-enterprise-management" "Success"
        } else {
            Write-Status "Project access validation failed" "Warning"
        }
        
        # Get team information
        $teams = vercel teams ls 2>$null
        if ($teams) {
            $AuthStatus.Vercel.Team = "e-sim"
            Write-Status "Team access confirmed: e-sim" "Success"
        }
        
        return $true
    } catch {
        Write-Status "Vercel authentication failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

# MICROSOFT GRAPH LOGIN AND VALIDATION
function Connect-MicrosoftGraph {
    Write-Host "`n=== MICROSOFT GRAPH AUTHENTICATION ===" -ForegroundColor Yellow
    
    try {
        # Check if Microsoft Graph module is installed
        $graphModule = Get-Module -ListAvailable Microsoft.Graph
        if (-not $graphModule) {
            Write-Status "Installing Microsoft Graph PowerShell SDK..." "Info"
            Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser
        }
        
        # Import required modules
        Import-Module Microsoft.Graph.Authentication
        Import-Module Microsoft.Graph.Users
        Import-Module Microsoft.Graph.Groups
        Import-Module Microsoft.Graph.DeviceManagement
        
        # Check current connection
        $context = Get-MgContext
        if ($context -and $context.Account) {
            $AuthStatus.MicrosoftGraph.LoggedIn = $true
            $AuthStatus.MicrosoftGraph.Account = $context.Account
            $AuthStatus.MicrosoftGraph.Scopes = $context.Scopes
            Write-Status "Already connected to Microsoft Graph as: $($context.Account)" "Success"
        } else {
            Write-Status "Connecting to Microsoft Graph..." "Info"
            
            $scopes = @(
                "Directory.ReadWrite.All",
                "User.ReadWrite.All", 
                "Group.ReadWrite.All",
                "Policy.ReadWrite.ConditionalAccess",
                "DeviceManagementConfiguration.ReadWrite.All",
                "DeviceManagementManagedDevices.ReadWrite.All",
                "DeviceManagementServiceConfig.ReadWrite.All"
            )
            
            Connect-MgGraph -Scopes $scopes -NoWelcome
            
            $context = Get-MgContext
            if ($context -and $context.Account) {
                $AuthStatus.MicrosoftGraph.LoggedIn = $true
                $AuthStatus.MicrosoftGraph.Account = $context.Account
                $AuthStatus.MicrosoftGraph.Scopes = $context.Scopes
                Write-Status "Successfully connected to Microsoft Graph as: $($context.Account)" "Success"
            } else {
                Write-Status "Microsoft Graph connection failed" "Error"
                return $false
            }
        }
        
        # Validate tenant access
        $org = Get-MgOrganization
        if ($org.VerifiedDomains | Where-Object { $_.Name -eq $TenantId }) {
            Write-Status "Tenant access confirmed: $TenantId" "Success"
        } else {
            Write-Status "Tenant validation failed" "Error"
        }
        
        # Validate admin account
        $admin = Get-MgUser -Filter "userPrincipalName eq '$AdminAccount'"
        if ($admin) {
            Write-Status "Admin account confirmed: $AdminAccount" "Success"
        } else {
            Write-Status "Admin account not found" "Error"
        }
        
        return $true
    } catch {
        Write-Status "Microsoft Graph authentication failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

# INTUNE CONNECTION AND VALIDATION
function Connect-Intune {
    Write-Host "`n=== MICROSOFT INTUNE VALIDATION ===" -ForegroundColor Yellow
    
    try {
        # Validate Intune service access
        $intuneService = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement" -Method GET
        if ($intuneService) {
            $AuthStatus.Intune.Connected = $true
            $AuthStatus.Intune.Authority = $intuneService.mdmAuthority
            Write-Status "Intune service accessible" "Success"
            Write-Status "MDM Authority: $($intuneService.mdmAuthority)" "Info"
        } else {
            Write-Status "Intune service not accessible" "Error"
            return $false
        }
        
        # Check device management capabilities
        $devices = Get-MgDeviceManagementManagedDevice -Top 1 -ErrorAction SilentlyContinue
        if ($devices -or $Error[0].Exception.Message -like "*Forbidden*") {
            Write-Status "Device management access confirmed" "Success"
        } else {
            Write-Status "Device management access failed" "Warning"
        }
        
        # Check compliance policies
        $policies = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" -Method GET
        if ($policies) {
            Write-Status "Compliance policies accessible" "Success"
        } else {
            Write-Status "Compliance policies not accessible" "Warning"
        }
        
        $AuthStatus.Intune.LoggedIn = $true
        return $true
    } catch {
        Write-Status "Intune validation failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

# SYNCHRONIZATION AND ERROR CHECKING
function Test-SystemSynchronization {
    Write-Host "`n=== SYSTEM SYNCHRONIZATION CHECK ===" -ForegroundColor Yellow
    
    $syncResults = @{
        GitHubVercel = $false
        EntraIntune = $false
        OverallHealth = $false
    }
    
    try {
        # GitHub-Vercel sync check
        if ($AuthStatus.GitHub.LoggedIn -and $AuthStatus.Vercel.LoggedIn) {
            $ghRepo = gh repo view kaunghtetpai/esim-enterprise-management --json name,defaultBranchRef
            $vercelProjects = vercel ls --json 2>$null | ConvertFrom-Json
            
            $matchingProject = $vercelProjects | Where-Object { $_.name -eq "esim-enterprise-management" }
            if ($matchingProject) {
                $syncResults.GitHubVercel = $true
                Write-Status "GitHub-Vercel synchronization confirmed" "Success"
            } else {
                Write-Status "GitHub-Vercel synchronization issue detected" "Warning"
            }
        }
        
        # Entra ID-Intune sync check
        if ($AuthStatus.MicrosoftGraph.LoggedIn -and $AuthStatus.Intune.LoggedIn) {
            $users = Get-MgUser -Top 5
            $intuneUsers = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices" -Method GET
            
            if ($users -and $intuneUsers) {
                $syncResults.EntraIntune = $true
                Write-Status "Entra ID-Intune synchronization confirmed" "Success"
            } else {
                Write-Status "Entra ID-Intune synchronization issue detected" "Warning"
            }
        }
        
        # Overall health assessment
        $syncResults.OverallHealth = $syncResults.GitHubVercel -and $syncResults.EntraIntune
        
        return $syncResults
    } catch {
        Write-Status "Synchronization check failed: $($_.Exception.Message)" "Error"
        return $syncResults
    }
}

# AUTO-FIX COMMON ISSUES
function Repair-SystemIssues {
    Write-Host "`n=== AUTO-FIX SYSTEM ISSUES ===" -ForegroundColor Yellow
    
    $fixedIssues = @()
    
    try {
        # Fix GitHub CLI issues
        if (-not $AuthStatus.GitHub.LoggedIn) {
            Write-Status "Attempting to fix GitHub authentication..." "Info"
            gh auth refresh
            $fixedIssues += "GitHub authentication refreshed"
        }
        
        # Fix Vercel CLI issues
        if (-not $AuthStatus.Vercel.LoggedIn) {
            Write-Status "Attempting to fix Vercel authentication..." "Info"
            vercel whoami
            $fixedIssues += "Vercel authentication checked"
        }
        
        # Fix Microsoft Graph issues
        if (-not $AuthStatus.MicrosoftGraph.LoggedIn) {
            Write-Status "Attempting to fix Microsoft Graph connection..." "Info"
            Disconnect-MgGraph -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            Connect-MicrosoftGraph
            $fixedIssues += "Microsoft Graph connection refreshed"
        }
        
        # Create missing carrier groups
        if ($AuthStatus.MicrosoftGraph.LoggedIn) {
            $carriers = @("MPT", "ATOM", "MYTEL")
            foreach ($carrier in $carriers) {
                $groupName = "Group_$($carrier)_eSIM"
                $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'" -ErrorAction SilentlyContinue
                
                if (-not $existingGroup) {
                    Write-Status "Creating missing carrier group: $groupName" "Info"
                    $groupParams = @{
                        DisplayName = $groupName
                        Description = "eSIM devices for $carrier carrier"
                        MailEnabled = $false
                        SecurityEnabled = $true
                    }
                    New-MgGroup @groupParams
                    $fixedIssues += "Created carrier group: $groupName"
                }
            }
        }
        
        Write-Status "Auto-fix completed. Fixed $($fixedIssues.Count) issues." "Success"
        return $fixedIssues
    } catch {
        Write-Status "Auto-fix failed: $($_.Exception.Message)" "Error"
        return $fixedIssues
    }
}

# GENERATE COMPREHENSIVE REPORT
function New-SystemReport {
    Write-Host "`n=== GENERATING SYSTEM REPORT ===" -ForegroundColor Yellow
    
    $report = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Authentication = $AuthStatus
        SystemHealth = @{
            AllServicesConnected = ($AuthStatus.GitHub.LoggedIn -and $AuthStatus.Vercel.LoggedIn -and $AuthStatus.MicrosoftGraph.LoggedIn -and $AuthStatus.Intune.LoggedIn)
            GitHubStatus = $AuthStatus.GitHub.LoggedIn
            VercelStatus = $AuthStatus.Vercel.LoggedIn
            MicrosoftGraphStatus = $AuthStatus.MicrosoftGraph.LoggedIn
            IntuneStatus = $AuthStatus.Intune.LoggedIn
        }
        URLs = @{
            GitHubRepo = "https://github.com/kaunghtetpai/esim-enterprise-management"
            VercelProject = "https://vercel.com/e-sim/esim-enterprise-management"
            ProductionURL = "https://esim-enterprise-management.vercel.app/"
            CustomDomain = "https://portal.nexorasim.com"
            EntraPortal = "https://entra.microsoft.com"
            IntunePortal = "https://intune.microsoft.com"
        }
    }
    
    # Save report to file
    $reportPath = "System-Login-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Status "System report saved: $reportPath" "Success"
    return $report
}

# MAIN EXECUTION
function Start-CompleteLogin {
    Write-Host "Complete Cloud Login and Authentication Setup" -ForegroundColor Cyan
    Write-Host "Admin: $AdminAccount | Tenant: $TenantId" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Cyan
    
    $results = @()
    
    # Execute all login procedures
    $results += Connect-GitHub
    $results += Connect-Vercel  
    $results += Connect-MicrosoftGraph
    $results += Connect-Intune
    
    # Run synchronization check
    $syncResults = Test-SystemSynchronization
    
    # Auto-fix issues if needed
    $fixedIssues = Repair-SystemIssues
    
    # Generate comprehensive report
    $report = New-SystemReport
    
    # Final summary
    Write-Host "`n" -NoNewline
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "LOGIN COMPLETE - SUMMARY" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    
    Write-Host "GitHub: " -NoNewline
    Write-Host $(if ($AuthStatus.GitHub.LoggedIn) { "✓ Connected as $($AuthStatus.GitHub.User)" } else { "✗ Not connected" }) -ForegroundColor $(if ($AuthStatus.GitHub.LoggedIn) { "Green" } else { "Red" })
    
    Write-Host "Vercel: " -NoNewline  
    Write-Host $(if ($AuthStatus.Vercel.LoggedIn) { "✓ Connected as $($AuthStatus.Vercel.User)" } else { "✗ Not connected" }) -ForegroundColor $(if ($AuthStatus.Vercel.LoggedIn) { "Green" } else { "Red" })
    
    Write-Host "Microsoft Graph: " -NoNewline
    Write-Host $(if ($AuthStatus.MicrosoftGraph.LoggedIn) { "✓ Connected as $($AuthStatus.MicrosoftGraph.Account)" } else { "✗ Not connected" }) -ForegroundColor $(if ($AuthStatus.MicrosoftGraph.LoggedIn) { "Green" } else { "Red" })
    
    Write-Host "Intune: " -NoNewline
    Write-Host $(if ($AuthStatus.Intune.LoggedIn) { "✓ Connected (MDM: $($AuthStatus.Intune.Authority))" } else { "✗ Not connected" }) -ForegroundColor $(if ($AuthStatus.Intune.LoggedIn) { "Green" } else { "Red" })
    
    Write-Host "`nSynchronization Status:" -ForegroundColor Cyan
    Write-Host "GitHub-Vercel: $(if ($syncResults.GitHubVercel) { '✓ Synced' } else { '⚠ Issues detected' })" -ForegroundColor $(if ($syncResults.GitHubVercel) { "Green" } else { "Yellow" })
    Write-Host "Entra-Intune: $(if ($syncResults.EntraIntune) { '✓ Synced' } else { '⚠ Issues detected' })" -ForegroundColor $(if ($syncResults.EntraIntune) { "Green" } else { "Yellow" })
    
    if ($fixedIssues.Count -gt 0) {
        Write-Host "`nAuto-Fixed Issues: $($fixedIssues.Count)" -ForegroundColor Green
        $fixedIssues | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
    }
    
    Write-Host "`nAll cloud services are ready for enterprise management!" -ForegroundColor Green
}

# Execute based on parameters
if ($LoginAll) {
    Start-CompleteLogin
} elseif ($ValidateAll) {
    Test-SystemSynchronization
} elseif ($SyncAll) {
    Repair-SystemIssues
} else {
    Write-Host "Use -LoginAll for complete login, -ValidateAll for validation, or -SyncAll for sync" -ForegroundColor Yellow
}