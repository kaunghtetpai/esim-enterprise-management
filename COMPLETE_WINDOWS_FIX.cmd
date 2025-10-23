@echo off
title Windows 11 Complete System Fix - All-in-One Solution
color 0A
echo ================================================================
echo                WINDOWS 11 COMPLETE SYSTEM FIX
echo                     All-in-One Solution
echo ================================================================
echo.

:: Check admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Please run as Administrator!
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

echo [1/7] System Error Check and Resolution...
sfc /scannow
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth
chkdsk C: /f /r /x

echo [2/7] Installing Windows Updates...
powershell -Command "try { Install-Module PSWindowsUpdate -Force -AllowClobber; Get-WindowsUpdate -Install -AcceptAll -AutoReboot } catch { Write-Host 'Update module installation failed' }"

echo [3/7] Updating Drivers and Apps...
pnputil /scan-devices
winget upgrade --all --accept-package-agreements --accept-source-agreements
powershell -Command "Get-WindowsDriver -Online | ForEach-Object { pnputil /add-driver $_.OriginalFileName /install }"

echo [4/7] Clearing Caches and Temp Files...
cleanmgr /sagerun:1
del /q /f /s "%TEMP%\*" 2>nul
del /q /f /s "C:\Windows\Temp\*" 2>nul
del /q /f /s "C:\Windows\Prefetch\*" 2>nul
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" 2>nul
powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"

echo [5/7] Running Maintenance Tasks...
defrag C: /O /H
powershell -Command "Get-Volume | Optimize-Volume -Defrag -Verbose"
powershell -Command "Start-Process schtasks -ArgumentList '/run /tn Microsoft\Windows\Defrag\ScheduledDefrag' -Wait"

echo [6/7] Setting Up System Optimization...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f
netsh winsock reset
netsh int ip reset
ipconfig /flushdns

echo [7/7] eSIM Configuration Check...
netsh mbn show interfaces
netsh mbn show profiles
powershell -Command "if (Get-WmiObject -Class Win32_SystemEnclosure | Where-Object {$_.ChassisTypes -contains 10 -or $_.ChassisTypes -contains 9}) { Write-Host 'eSIM supported on this device' } else { Write-Host 'eSIM not supported' }"

echo.
echo ================================================================
echo                    OPTIMIZATION COMPLETE!
echo ================================================================
echo System will restart in 30 seconds to complete all changes...
echo Press any key to restart now or wait for automatic restart.
timeout /t 30
shutdown /r /t 0