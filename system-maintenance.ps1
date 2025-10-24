# Windows System Maintenance Script
$ErrorActionPreference = "Stop"

$LogFile = "$env:USERPROFILE\Desktop\SystemMaintenanceLog.txt"
Write-Output "=== System Maintenance Started: $(Get-Date) ===" | Out-File -FilePath $LogFile -Append

# Check Windows Updates
Write-Output "Checking for Windows updates..." | Out-File -FilePath $LogFile -Append
try {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-Module PSWindowsUpdate -Force -Confirm:$false
    }
    Import-Module PSWindowsUpdate
    
    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
    if ($updates.Count -gt 0) {
        Write-Output "Installing $($updates.Count) updates..." | Out-File -FilePath $LogFile -Append
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
    } else {
        Write-Output "No updates available." | Out-File -FilePath $LogFile -Append
    }
} catch {
    Write-Output "Update check failed: $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
}

# Clear Temporary Files
Write-Output "Clearing temporary files..." | Out-File -FilePath $LogFile -Append
$TempPaths = @(
    "$env:LOCALAPPDATA\Temp\*",
    "$env:TEMP\*",
    "C:\Windows\Temp\*"
)
foreach ($path in $TempPaths) {
    try {
        $removed = Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "Cleared: $path" | Out-File -FilePath $LogFile -Append
    } catch {
        Write-Output "Could not clear: $path" | Out-File -FilePath $LogFile -Append
    }
}

# System File Check
Write-Output "Running system file check..." | Out-File -FilePath $LogFile -Append
try {
    sfc /scannow | Out-File -FilePath $LogFile -Append
} catch {
    Write-Output "SFC scan failed: $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
}

# Disk Cleanup
Write-Output "Running disk cleanup..." | Out-File -FilePath $LogFile -Append
try {
    cleanmgr /sagerun:1 | Out-File -FilePath $LogFile -Append
} catch {
    Write-Output "Disk cleanup failed: $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
}

# Network Reset
Write-Output "Resetting network components..." | Out-File -FilePath $LogFile -Append
try {
    ipconfig /flushdns | Out-File -FilePath $LogFile -Append
    netsh winsock reset | Out-File -FilePath $LogFile -Append
} catch {
    Write-Output "Network reset failed: $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
}

Write-Output "=== System maintenance completed: $(Get-Date) ===" | Out-File -FilePath $LogFile -Append
Write-Host "Maintenance completed. Log saved to: $LogFile" -ForegroundColor Green