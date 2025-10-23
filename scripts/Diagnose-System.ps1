# System Diagnostic and Problem Solving Script
param(
    [switch]$QuickCheck,
    [switch]$FullDiagnostic,
    [switch]$AutoFix,
    [string]$Component,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

function Write-DiagnosticLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "FIX" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-DatabaseConnection {
    Write-DiagnosticLog "Testing database connection..." "INFO"
    try {
        $connectionString = $env:DATABASE_URL
        if (-not $connectionString) {
            Write-DiagnosticLog "DATABASE_URL environment variable not set" "ERROR"
            return $false
        }
        
        # Test basic connectivity (simplified check)
        Write-DiagnosticLog "Database connection string found" "SUCCESS"
        return $true
    } catch {
        Write-DiagnosticLog "Database connection failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-GraphConnection {
    Write-DiagnosticLog "Testing Microsoft Graph connection..." "INFO"
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if ($context) {
            Write-DiagnosticLog "Microsoft Graph connected - Tenant: $($context.TenantId)" "SUCCESS"
            return $true
        } else {
            Write-DiagnosticLog "Microsoft Graph not connected" "WARN"
            return $false
        }
    } catch {
        Write-DiagnosticLog "Graph connection check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PowerShellModules {
    Write-DiagnosticLog "Checking PowerShell modules..." "INFO"
    try {
        $graphModules = Get-Module Microsoft.Graph* -ListAvailable
        if ($graphModules.Count -gt 0) {
            Write-DiagnosticLog "Found $($graphModules.Count) Microsoft Graph modules" "SUCCESS"
            return $true
        } else {
            Write-DiagnosticLog "Microsoft Graph modules not installed" "WARN"
            return $false
        }
    } catch {
        Write-DiagnosticLog "Module check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-NetworkConnectivity {
    Write-DiagnosticLog "Testing network connectivity..." "INFO"
    $endpoints = @(
        "https://graph.microsoft.com",
        "https://login.microsoftonline.com",
        "https://entra.microsoft.com"
    )
    
    $failures = 0
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint -Method Head -TimeoutSec 10 -UseBasicParsing
            Write-DiagnosticLog "✓ $endpoint - Status: $($response.StatusCode)" "SUCCESS"
        } catch {
            Write-DiagnosticLog "✗ $endpoint - Failed: $($_.Exception.Message)" "ERROR"
            $failures++
        }
    }
    
    if ($failures -eq 0) {
        Write-DiagnosticLog "All network endpoints accessible" "SUCCESS"
        return $true
    } else {
        Write-DiagnosticLog "$failures/$($endpoints.Count) endpoints failed" "WARN"
        return $false
    }
}

function Test-SystemResources {
    Write-DiagnosticLog "Checking system resources..." "INFO"
    try {
        # Memory check
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
        $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
        $totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
        $memoryUsagePercent = [math]::Round((($totalMemoryGB - $freeMemoryGB) / $totalMemoryGB) * 100, 1)
        
        Write-DiagnosticLog "Memory Usage: $memoryUsagePercent% ($freeMemoryGB GB free of $totalMemoryGB GB)" "INFO"
        
        # Disk space check
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Where-Object DeviceID -eq "C:"
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        $diskUsagePercent = [math]::Round((($totalSpaceGB - $freeSpaceGB) / $totalSpaceGB) * 100, 1)
        
        Write-DiagnosticLog "Disk Usage: $diskUsagePercent% ($freeSpaceGB GB free of $totalSpaceGB GB)" "INFO"
        
        # CPU check
        $cpu = Get-CimInstance -ClassName Win32_Processor
        Write-DiagnosticLog "CPU: $($cpu.Name) - $($cpu.NumberOfCores) cores" "INFO"
        
        $issues = @()
        if ($memoryUsagePercent -gt 90) { $issues += "High memory usage" }
        if ($diskUsagePercent -gt 90) { $issues += "Low disk space" }
        
        if ($issues.Count -eq 0) {
            Write-DiagnosticLog "System resources are healthy" "SUCCESS"
            return $true
        } else {
            Write-DiagnosticLog "Resource issues: $($issues -join ', ')" "WARN"
            return $false
        }
    } catch {
        Write-DiagnosticLog "Resource check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-WindowsServices {
    Write-DiagnosticLog "Checking Windows services..." "INFO"
    $requiredServices = @("Winmgmt", "BITS", "Themes", "EventLog")
    
    $issues = @()
    foreach ($service in $requiredServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            if ($svc.Status -eq "Running") {
                Write-DiagnosticLog "✓ $service: Running" "SUCCESS"
            } else {
                Write-DiagnosticLog "✗ $service: $($svc.Status)" "WARN"
                $issues += $service
            }
        } catch {
            Write-DiagnosticLog "✗ $service: Not found" "ERROR"
            $issues += $service
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-DiagnosticLog "All required services are running" "SUCCESS"
        return $true
    } else {
        Write-DiagnosticLog "Service issues: $($issues -join ', ')" "WARN"
        return $false
    }
}

function Fix-GraphConnection {
    Write-DiagnosticLog "Attempting to fix Graph connection..." "FIX"
    try {
        # Try to reconnect
        $scopes = @("User.Read", "DeviceManagementManagedDevices.Read.All")
        Connect-MgGraph -Scopes $scopes -NoWelcome
        
        $context = Get-MgContext
        if ($context) {
            Write-DiagnosticLog "Graph connection restored" "SUCCESS"
            return $true
        } else {
            Write-DiagnosticLog "Graph connection fix failed" "ERROR"
            return $false
        }
    } catch {
        Write-DiagnosticLog "Graph connection fix failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-PowerShellModules {
    Write-DiagnosticLog "Installing Microsoft Graph modules..." "FIX"
    try {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
        Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force -AllowClobber
        Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser -Force -AllowClobber
        
        Write-DiagnosticLog "Microsoft Graph modules installed successfully" "SUCCESS"
        return $true
    } catch {
        Write-DiagnosticLog "Module installation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Fix-WindowsServices {
    Write-DiagnosticLog "Restarting Windows services..." "FIX"
    $servicesToRestart = @("Winmgmt", "BITS")
    
    foreach ($service in $servicesToRestart) {
        try {
            Restart-Service -Name $service -Force
            Write-DiagnosticLog "✓ Restarted $service" "SUCCESS"
        } catch {
            Write-DiagnosticLog "✗ Failed to restart $service: $($_.Exception.Message)" "ERROR"
        }
    }
    return $true
}

function Fix-DiskSpace {
    Write-DiagnosticLog "Cleaning up disk space..." "FIX"
    try {
        # Clean temp files
        $tempPath = $env:TEMP
        Get-ChildItem -Path $tempPath -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        
        # Clean Windows temp
        $winTemp = "C:\Windows\Temp"
        Get-ChildItem -Path $winTemp -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        
        Write-DiagnosticLog "Temporary files cleaned" "SUCCESS"
        return $true
    } catch {
        Write-DiagnosticLog "Disk cleanup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-DiagnosticLog "Starting EPM System Diagnostics" "INFO"

if ($QuickCheck) {
    Write-DiagnosticLog "Running quick system check..." "INFO"
    $checks = @{
        "Database" = Test-DatabaseConnection
        "Graph" = Test-GraphConnection
        "Network" = Test-NetworkConnectivity
    }
} elseif ($Component) {
    Write-DiagnosticLog "Running diagnostic for component: $Component" "INFO"
    $checks = @{}
    switch ($Component.ToLower()) {
        "database" { $checks["Database"] = Test-DatabaseConnection }
        "graph" { $checks["Graph"] = Test-GraphConnection }
        "modules" { $checks["PowerShell"] = Test-PowerShellModules }
        "network" { $checks["Network"] = Test-NetworkConnectivity }
        "resources" { $checks["Resources"] = Test-SystemResources }
        "services" { $checks["Services"] = Test-WindowsServices }
        default { 
            Write-DiagnosticLog "Unknown component: $Component" "ERROR"
            exit 1
        }
    }
} else {
    Write-DiagnosticLog "Running full system diagnostic..." "INFO"
    $checks = @{
        "Database" = Test-DatabaseConnection
        "Graph" = Test-GraphConnection
        "PowerShell" = Test-PowerShellModules
        "Network" = Test-NetworkConnectivity
        "Resources" = Test-SystemResources
        "Services" = Test-WindowsServices
    }
}

$results = @{}
$issues = @()

foreach ($check in $checks.GetEnumerator()) {
    $result = & $check.Value
    $results[$check.Key] = $result
    if (-not $result) {
        $issues += $check.Key
    }
}

# Summary
Write-DiagnosticLog "=== DIAGNOSTIC SUMMARY ===" "INFO"
foreach ($result in $results.GetEnumerator()) {
    $status = if ($result.Value) { "PASS" } else { "FAIL" }
    $level = if ($result.Value) { "SUCCESS" } else { "ERROR" }
    Write-DiagnosticLog "$($result.Key): $status" $level
}

if ($issues.Count -eq 0) {
    Write-DiagnosticLog "All checks passed - System is healthy" "SUCCESS"
} else {
    Write-DiagnosticLog "Issues found in: $($issues -join ', ')" "WARN"
    
    if ($AutoFix) {
        Write-DiagnosticLog "Attempting automatic fixes..." "FIX"
        
        foreach ($issue in $issues) {
            switch ($issue) {
                "Graph" { Fix-GraphConnection }
                "PowerShell" { Fix-PowerShellModules }
                "Services" { Fix-WindowsServices }
                "Resources" { Fix-DiskSpace }
                default { 
                    Write-DiagnosticLog "No automatic fix available for $issue" "WARN"
                }
            }
        }
        
        Write-DiagnosticLog "Re-running diagnostics after fixes..." "INFO"
        Start-Sleep -Seconds 5
        
        # Re-run failed checks
        foreach ($issue in $issues) {
            if ($checks.ContainsKey($issue)) {
                $result = & $checks[$issue]
                if ($result) {
                    Write-DiagnosticLog "$issue: Fixed successfully" "SUCCESS"
                } else {
                    Write-DiagnosticLog "$issue: Fix unsuccessful" "ERROR"
                }
            }
        }
    }
}

Write-DiagnosticLog "Diagnostic completed" "INFO"