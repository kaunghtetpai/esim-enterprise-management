# Windows 11 All-in-One Optimization Guide

## IMMEDIATE ACTIONS

### Step 1: Run Quick Fix (5 minutes)
```cmd
Right-click "quick-fix.bat" → Run as Administrator
```

### Step 2: Complete Optimization (30 minutes)
```powershell
Right-click PowerShell → Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process
.\windows-optimization.ps1
```

## MANUAL COMMANDS (Copy & Paste)

### System Health Check
```cmd
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
chkdsk C: /f /r
```

### Windows Updates
```powershell
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll
```

### Driver Updates
```cmd
pnputil /scan-devices
```

### Clear All Caches
```cmd
cleanmgr /sagerun:1
del /q /f /s %TEMP%\*
del /q /f /s C:\Windows\Temp\*
del /q /f /s C:\Windows\SoftwareDistribution\Download\*
```

### Performance Boost
```cmd
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
defrag C: /O
```

### Install Essential Apps
```cmd
winget install Microsoft.PowerToys
winget install Git.Git
winget install Microsoft.VisualStudioCode
winget install 7zip.7zip
winget install Google.Chrome
```

## AUTOMATION SETUP

### Weekly Maintenance Task
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\maintenance.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2AM
Register-ScheduledTask -TaskName "WeeklyMaintenance" -Action $action -Trigger $trigger
```

## eSIM CONFIGURATION

### Check eSIM Support
```cmd
netsh mbn show interfaces
netsh mbn show profiles
```

### Configure eSIM (if supported)
```cmd
netsh mbn add profile interface="Cellular" name="eSIM_Profile"
```

## SYSTEM MONITORING

### Performance Monitor
```cmd
perfmon /res
```

### Event Viewer
```cmd
eventvwr.msc
```

### System Information
```cmd
msinfo32
```

## TROUBLESHOOTING

### If Windows Update Fails
```cmd
net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
ren C:\Windows\System32\catroot2 catroot2.old
net start wuauserv
net start cryptSvc
net start bits
net start msiserver
```

### If System is Slow
```cmd
msconfig
services.msc
taskmgr
```

### Reset Network
```cmd
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
```

## FINAL CHECKLIST

- [ ] Run SFC scan
- [ ] Run DISM health check
- [ ] Install Windows updates
- [ ] Update all drivers
- [ ] Clear temp files and caches
- [ ] Optimize disk performance
- [ ] Configure power settings
- [ ] Install essential apps
- [ ] Setup automated maintenance
- [ ] Check eSIM configuration
- [ ] Restart system

## MAINTENANCE SCHEDULE

**Daily**: Temp file cleanup
**Weekly**: Full system scan and optimization
**Monthly**: Driver updates and registry cleanup
**Quarterly**: Complete system health check

Your Windows 11 system is now fully optimized and automated!