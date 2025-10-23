# Windows 11 All-in-One System Optimization Script
# Run as Administrator

Write-Host "Starting Windows 11 Complete System Optimization..." -ForegroundColor Green

# 1. System Error Check and Resolution
Write-Host "1. Checking and resolving system errors..." -ForegroundColor Yellow
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
chkdsk C: /f /r /x

# 2. Windows Updates
Write-Host "2. Installing Windows Updates..." -ForegroundColor Yellow
Install-Module PSWindowsUpdate -Force -AllowClobber
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

# 3. Driver Updates
Write-Host "3. Updating drivers..." -ForegroundColor Yellow
pnputil /scan-devices
Get-WindowsDriver -Online | Where-Object {$_.BootCritical -eq $false} | ForEach-Object {
    pnputil /add-driver $_.OriginalFileName /install
}

# 4. Clear Caches and Temp Files
Write-Host "4. Clearing caches and temporary files..." -ForegroundColor Yellow
cleanmgr /sagerun:1
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

# 5. System Maintenance
Write-Host "5. Running system maintenance..." -ForegroundColor Yellow
defrag C: /O
Get-Volume | Optimize-Volume -Defrag
schtasks /run /tn "Microsoft\Windows\Defrag\ScheduledDefrag"

# 6. Performance Optimization
Write-Host "6. Optimizing system performance..." -ForegroundColor Yellow
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

# 7. eSIM Configuration Check
Write-Host "7. Checking eSIM support..." -ForegroundColor Yellow
$esimSupport = Get-WmiObject -Class Win32_SystemEnclosure | Select-Object -ExpandProperty ChassisTypes
if ($esimSupport -contains 10 -or $esimSupport -contains 9) {
    Write-Host "eSIM supported - Configuring..." -ForegroundColor Green
    netsh mbn show profiles
    netsh mbn show interfaces
} else {
    Write-Host "eSIM not supported on this device" -ForegroundColor Red
}

# 8. Install Essential Tools
Write-Host "8. Installing optimization tools..." -ForegroundColor Yellow
winget install Microsoft.PowerToys
winget install 9WZDNCRFJ3T2  # Microsoft Store
winget install Git.Git
winget install Microsoft.VisualStudioCode

# 9. Setup Automation
Write-Host "9. Setting up automation..." -ForegroundColor Yellow
$taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Windows\System32\maintenance.ps1"
$taskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2AM
Register-ScheduledTask -TaskName "WeeklyMaintenance" -Action $taskAction -Trigger $taskTrigger -RunLevel Highest

Write-Host "Windows 11 optimization complete!" -ForegroundColor Green
Write-Host "System will restart in 60 seconds..." -ForegroundColor Yellow
shutdown /r /t 60