# eSIM Enterprise Management - Complete System Error Check
# Comprehensive system validation and error detection

param(
    [switch]$QuickCheck,
    [switch]$FullScan,
    [switch]$AutoFix,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$VerbosePreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# Initialize error tracking
$SystemErrors = @()
$FixedErrors = @()

function Write-Status {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "Warning" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        "Error"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        default   { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
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
        # Check if Supabase connection is working
        $env:SUPABASE_URL = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { "https://your-project.supabase.co" }
        $env:SUPABASE_ANON_KEY = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { "your-anon-key" }
        
        if (-not $env:SUPABASE_URL -or $env:SUPABASE_URL -eq "https://your-project.supabase.co") {
            Add-SystemError "Database" "Critical" "Supabase URL not configured" @{
                Variable = "SUPABASE_URL"
                Current = $env:SUPABASE_URL
            }
            return $false
        }
        
        # Test connection with curl
        $response = curl -s -o /dev/null -w "%{http_code}" "$($env:SUPABASE_URL)/rest/v1/" -H "apikey: $($env:SUPABASE_ANON_KEY)"
        if ($response -eq "200") {
            Write-Status "Database connection successful" "Success"
            return $true
        } else {
            Add-SystemError "Database" "High" "Database connection failed" @{
                ResponseCode = $response
                URL = $env:SUPABASE_URL
            }
            return $false
        }
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

function Test-APIEndpoints {
    Write-Status "Checking API endpoints..." "Info"
    $endpoints = @(
        "http://localhost:8000/api/v1/health",
        "http://localhost:8000/api/v1/profiles",
        "http://localhost:8000/api/v1/devices",
        "http://localhost:8000/api/v1/activation-codes"
    )
    
    $allHealthy = $true
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint -Method GET -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Verbose "✓ $endpoint - OK"
            } else {
                Add-SystemError "API" "Medium" "Endpoint returned non-200 status" @{
                    Endpoint = $endpoint
                    StatusCode = $response.StatusCode
                }
                $allHealthy = $false
            }
        } catch {
            Add-SystemError "API" "Medium" "Endpoint unreachable: $endpoint" @{
                Endpoint = $endpoint
                Error = $_.Exception.Message
            }
            $allHealthy = $false
        }
    }
    
    if ($allHealthy) {
        Write-Status "All API endpoints healthy" "Success"
    }
    return $allHealthy
}

function Test-NetworkConnectivity {
    Write-Status "Checking network connectivity..." "Info"
    $hosts = @(
        "graph.microsoft.com",
        "login.microsoftonline.com",
        "supabase.com",
        "github.com"
    )
    
    $allConnected = $true
    foreach ($host in $hosts) {
        try {
            $ping = Test-NetConnection -ComputerName $host -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($ping) {
                Write-Verbose "✓ $host - Connected"
            } else {
                Add-SystemError "Network" "Medium" "Cannot reach host: $host" @{
                    Host = $host
                    Port = 443
                }
                $allConnected = $false
            }
        } catch {
            Add-SystemError "Network" "Medium" "Network test failed for $host" @{
                Host = $host
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
        } elseif ($usedPercent -gt 80) {
            Add-SystemError "Disk" "Medium" "Disk space low on drive $($drive.DeviceID)" @{
                Drive = $drive.DeviceID
                UsedPercent = [math]::Round($usedPercent, 1)
                FreeSpace = [math]::Round($drive.FreeSpace / 1GB, 2)
            }
        }
    }
    
    # Check memory usage
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $memoryUsedPercent = (($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100
    
    if ($memoryUsedPercent -gt 90) {
        Add-SystemError "Memory" "High" "Memory usage critical" @{
            UsedPercent = [math]::Round($memoryUsedPercent, 1)
            FreeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        }
    } elseif ($memoryUsedPercent -gt 80) {
        Add-SystemError "Memory" "Medium" "Memory usage high" @{
            UsedPercent = [math]::Round($memoryUsedPercent, 1)
            FreeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        }
    }
    
    Write-Status "System resources checked" "Success"
}

function Test-RequiredModules {
    Write-Status "Checking required PowerShell modules..." "Info"
    $requiredModules = @(
        "Microsoft.Graph",
        "Microsoft.Graph.Authentication",
        "Microsoft.Graph.DeviceManagement"
    )
    
    $allInstalled = $true
    foreach ($module in $requiredModules) {
        $installed = Get-Module -ListAvailable -Name $module
        if ($installed) {
            Write-Verbose "✓ $module - Installed (Version: $($installed[0].Version))"
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

function Test-EnvironmentVariables {
    Write-Status "Checking environment variables..." "Info"
    $requiredVars = @(
        "SUPABASE_URL",
        "SUPABASE_ANON_KEY",
        "AZURE_CLIENT_ID",
        "AZURE_CLIENT_SECRET",
        "AZURE_TENANT_ID"
    )
    
    $allSet = $true
    foreach ($var in $requiredVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ($value -and $value -ne "your-$($var.ToLower().Replace('_', '-'))") {
            Write-Verbose "✓ $var - Set"
        } else {
            Add-SystemError "Configuration" "Medium" "Environment variable not set: $var" @{
                Variable = $var
                Required = $true
            }
            $allSet = $false
        }
    }
    
    if ($allSet) {
        Write-Status "Environment variables configured" "Success"
    }
    return $allSet
}

function Repair-DatabaseConnection {
    Write-Status "Attempting to repair database connection..." "Info"
    try {
        # Reset connection string
        if ($env:SUPABASE_URL -and $env:SUPABASE_ANON_KEY) {
            # Test with fresh connection
            $testUrl = "$($env:SUPABASE_URL)/rest/v1/"
            $response = Invoke-WebRequest -Uri $testUrl -Headers @{ "apikey" = $env:SUPABASE_ANON_KEY } -Method GET -TimeoutSec 10
            
            if ($response.StatusCode -eq 200) {
                Write-Status "Database connection repaired" "Success"
                return $true
            }
        }
        return $false
    } catch {
        Write-Status "Database repair failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Repair-GraphConnection {
    Write-Status "Attempting to repair Graph connection..." "Info"
    try {
        Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All", "User.Read" -NoWelcome
        $context = Get-MgContext
        
        if ($context -and $context.Account) {
            Write-Status "Graph connection repaired" "Success"
            return $true
        }
        return $false
    } catch {
        Write-Status "Graph repair failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Repair-DiskSpace {
    Write-Status "Attempting to free disk space..." "Info"
    try {
        # Clean temp files
        $tempPath = $env:TEMP
        Get-ChildItem -Path $tempPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        
        # Clean logs older than 30 days
        $logsPath = "logs"
        if (Test-Path $logsPath) {
            Get-ChildItem -Path $logsPath -Filter "*.log" -Recurse | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        
        Write-Status "Disk cleanup completed" "Success"
        return $true
    } catch {
        Write-Status "Disk cleanup failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Start-AutoFix {
    Write-Status "Starting automatic error fixing..." "Info"
    
    foreach ($error in $SystemErrors | Where-Object { -not $_.Fixed }) {
        $fixed = $false
        
        switch ($error.Type) {
            "Database" {
                $fixed = Repair-DatabaseConnection
            }
            "Authentication" {
                $fixed = Repair-GraphConnection
            }
            "Disk" {
                $fixed = Repair-DiskSpace
            }
            "Module" {
                try {
                    $moduleName = $error.Details.Module
                    Install-Module -Name $moduleName -Force -AllowClobber
                    $fixed = $true
                    Write-Status "Installed module: $moduleName" "Success"
                } catch {
                    Write-Status "Failed to install module: $moduleName" "Error"
                }
            }
        }
        
        if ($fixed) {
            $error.Fixed = $true
            $FixedErrors += $error
        }
    }
    
    Write-Status "Auto-fix completed. Fixed $($FixedErrors.Count) errors." "Success"
}

function Show-ErrorReport {
    Write-Host "`n" -NoNewline
    Write-Host "=== SYSTEM ERROR REPORT ===" -ForegroundColor Cyan
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
    
    if ($SystemErrors.Count -eq 0) {
        Write-Host "✓ No system errors detected!" -ForegroundColor Green
        return
    }
    
    $criticalErrors = $SystemErrors | Where-Object { $_.Severity -eq "Critical" }
    $highErrors = $SystemErrors | Where-Object { $_.Severity -eq "High" }
    $mediumErrors = $SystemErrors | Where-Object { $_.Severity -eq "Medium" }
    $lowErrors = $SystemErrors | Where-Object { $_.Severity -eq "Low" }
    
    Write-Host "Total Errors: $($SystemErrors.Count)" -ForegroundColor Yellow
    if ($criticalErrors) { Write-Host "Critical: $($criticalErrors.Count)" -ForegroundColor Red }
    if ($highErrors) { Write-Host "High: $($highErrors.Count)" -ForegroundColor Red }
    if ($mediumErrors) { Write-Host "Medium: $($mediumErrors.Count)" -ForegroundColor Yellow }
    if ($lowErrors) { Write-Host "Low: $($lowErrors.Count)" -ForegroundColor Gray }
    
    Write-Host "`nDetailed Errors:" -ForegroundColor Cyan
    foreach ($error in $SystemErrors) {
        $color = switch ($error.Severity) {
            "Critical" { "Red" }
            "High" { "Red" }
            "Medium" { "Yellow" }
            "Low" { "Gray" }
        }
        
        $status = if ($error.Fixed) { "FIXED" } else { "OPEN" }
        Write-Host "[$($error.Severity)] $($error.Type): $($error.Message) [$status]" -ForegroundColor $color
        
        if ($Verbose -and $error.Details) {
            Write-Host "  Details: $($error.Details | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
    }
    
    if ($FixedErrors.Count -gt 0) {
        Write-Host "`nFixed Errors: $($FixedErrors.Count)" -ForegroundColor Green
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
    Test-APIEndpoints | Out-Null
    Test-NetworkConnectivity | Out-Null
    Test-SystemResources
    Test-RequiredModules | Out-Null
    Test-EnvironmentVariables | Out-Null
} else {
    # Default comprehensive check
    Write-Status "Running comprehensive system check..." "Info"
    Test-DatabaseConnection | Out-Null
    Test-GraphConnection | Out-Null
    Test-APIEndpoints | Out-Null
    Test-NetworkConnectivity | Out-Null
    Test-SystemResources
    Test-RequiredModules | Out-Null
    Test-EnvironmentVariables | Out-Null
}

if ($AutoFix -and $SystemErrors.Count -gt 0) {
    Start-AutoFix
}

Show-ErrorReport

# Exit with appropriate code
if ($SystemErrors | Where-Object { $_.Severity -eq "Critical" -and -not $_.Fixed }) {
    exit 2  # Critical errors
} elseif ($SystemErrors | Where-Object { -not $_.Fixed }) {
    exit 1  # Other errors
} else {
    exit 0  # All good or all fixed
}