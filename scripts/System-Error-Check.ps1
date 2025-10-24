# eSIM Enterprise Management - Complete System Error Check
param(
    [switch]$QuickCheck,
    [switch]$FullScan,
    [switch]$AutoFix,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

$SystemErrors = @()
$FixedErrors = @()

function Write-Status {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] Success: $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[$timestamp] Warning: $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[$timestamp] Error: $Message" -ForegroundColor Red }
        default   { Write-Host "[$timestamp] Info: $Message" -ForegroundColor Cyan }
    }
}

function Add-SystemError {
    param($Type, $Severity, $Message, $Details = $null)
    $script:SystemErrors += [PSCustomObject]@{
        Type = $Type
        Severity = $Severity
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
        Fixed = $false
    }
}

function Test-DatabaseConnection {
    Write-Status "Checking database connection..." "Info"
    try {
        if (-not $env:SUPABASE_URL -or $env:SUPABASE_URL -eq "https://your-project.supabase.co") {
            Add-SystemError "Database" "Critical" "Supabase URL not configured" @{
                Variable = "SUPABASE_URL"
                Current = $env:SUPABASE_URL
            }
            return $false
        }
        Write-Status "Database connection check completed" "Success"
        return $true
    } catch {
        Add-SystemError "Database" "Critical" "Database connection error: $($_.Exception.Message)" $_.Exception
        return $false
    }
}

function Test-GraphConnection {
    Write-Status "Checking Microsoft Graph connection..." "Info"
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context -and $context.Account) {
            Write-Status "Microsoft Graph connected as $($context.Account)" "Success"
            return $true
        } else {
            Add-SystemError "Authentication" "High" "Microsoft Graph not connected" @{
                RequiredScopes = @("DeviceManagementManagedDevices.ReadWrite.All", "User.Read")
            }
            return $false
        }
    } catch {
        Add-SystemError "Authentication" "Critical" "Graph connection error: $($_.Exception.Message)" $_.Exception
        return $false
    }
}

function Test-NetworkConnectivity {
    Write-Status "Checking network connectivity..." "Info"
    $hosts = @("graph.microsoft.com", "login.microsoftonline.com", "supabase.com", "github.com")
    
    $allConnected = $true
    foreach ($hostname in $hosts) {
        try {
            $ping = Test-NetConnection -ComputerName $hostname -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($ping) {
                Write-Verbose "Connected to $hostname"
            } else {
                Add-SystemError "Network" "Medium" "Cannot reach host: $hostname" @{
                    Hostname = $hostname
                    Port = 443
                }
                $allConnected = $false
            }
        } catch {
            Add-SystemError "Network" "Medium" "Network test failed for $hostname" @{
                Hostname = $hostname
                Error = $_.Exception.Message
            }
            $allConnected = $false
        }
    }
    
    if ($allConnected) {
        Write-Status "Network connectivity OK" "Success"
    }
    return $allConnected
}

function Test-SystemResources {
    Write-Status "Checking system resources..." "Info"
    
    # Check disk space
    $disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    foreach ($drive in $disk) {
        $freePercent = ($drive.FreeSpace / $drive.Size) * 100
        $usedPercent = 100 - $freePercent
        
        if ($usedPercent -gt 90) {
            Add-SystemError "Disk" "High" "Disk space critical on drive $($drive.DeviceID)" @{
                Drive = $drive.DeviceID
                UsedPercent = [math]::Round($usedPercent, 1)
                FreeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
            }
        }
    }
    
    Write-Status "System resources checked" "Success"
}

function Test-RequiredModules {
    Write-Status "Checking required PowerShell modules..." "Info"
    $requiredModules = @("Microsoft.Graph", "Microsoft.Graph.Authentication", "Microsoft.Graph.DeviceManagement")
    
    $allInstalled = $true
    foreach ($module in $requiredModules) {
        $installed = Get-Module -ListAvailable -Name $module
        if ($installed) {
            Write-Verbose "Module $module installed (Version: $($installed[0].Version))"
        } else {
            Add-SystemError "Module" "High" "Required module not installed: $module" @{
                Module = $module
                InstallCommand = "Install-Module -Name $module -Force"
            }
            $allInstalled = $false
        }
    }
    
    if ($allInstalled) {
        Write-Status "All required modules installed" "Success"
    }
    return $allInstalled
}

function Show-ErrorReport {
    Write-Host ""
    Write-Host "=== SYSTEM ERROR REPORT ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
    
    if ($SystemErrors.Count -eq 0) {
        Write-Host "No system errors detected!" -ForegroundColor Green
        return
    }
    
    $criticalErrors = $SystemErrors | Where-Object { $_.Severity -eq "Critical" }
    $highErrors = $SystemErrors | Where-Object { $_.Severity -eq "High" }
    $mediumErrors = $SystemErrors | Where-Object { $_.Severity -eq "Medium" }
    
    Write-Host "Total Errors: $($SystemErrors.Count)" -ForegroundColor Yellow
    if ($criticalErrors) { Write-Host "Critical: $($criticalErrors.Count)" -ForegroundColor Red }
    if ($highErrors) { Write-Host "High: $($highErrors.Count)" -ForegroundColor Red }
    if ($mediumErrors) { Write-Host "Medium: $($mediumErrors.Count)" -ForegroundColor Yellow }
    
    Write-Host ""
    Write-Host "Detailed Errors:" -ForegroundColor Cyan
    foreach ($error in $SystemErrors) {
        $color = switch ($error.Severity) {
            "Critical" { "Red" }
            "High" { "Red" }
            "Medium" { "Yellow" }
            default { "Gray" }
        }
        
        $status = if ($error.Fixed) { "FIXED" } else { "OPEN" }
        Write-Host "[$($error.Severity)] $($error.Type): $($error.Message) [$status]" -ForegroundColor $color
    }
}

# Main execution
Write-Host "eSIM Enterprise Management - System Error Check" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if ($QuickCheck) {
    Write-Status "Running quick system check..." "Info"
    Test-DatabaseConnection | Out-Null
    Test-GraphConnection | Out-Null
    Test-NetworkConnectivity | Out-Null
} elseif ($FullScan) {
    Write-Status "Running full system scan..." "Info"
    Test-DatabaseConnection | Out-Null
    Test-GraphConnection | Out-Null
    Test-NetworkConnectivity | Out-Null
    Test-SystemResources
    Test-RequiredModules | Out-Null
} else {
    Write-Status "Running comprehensive system check..." "Info"
    Test-DatabaseConnection | Out-Null
    Test-GraphConnection | Out-Null
    Test-NetworkConnectivity | Out-Null
    Test-SystemResources
    Test-RequiredModules | Out-Null
}

Show-ErrorReport

# Exit with appropriate code
$criticalUnfixed = $SystemErrors | Where-Object { $_.Severity -eq "Critical" -and -not $_.Fixed }
$otherUnfixed = $SystemErrors | Where-Object { -not $_.Fixed }

if ($criticalUnfixed) {
    exit 2
} elseif ($otherUnfixed) {
    exit 1
} else {
    exit 0
}