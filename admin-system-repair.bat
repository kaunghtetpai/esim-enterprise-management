@echo off
echo === ADMIN SYSTEM REPAIR ===
echo.
echo Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Administrator: YES
) else (
    echo Administrator: NO - Please run as Administrator
    pause
    exit
)

echo.
echo 1. System File Check...
sfc /scannow

echo.
echo 2. Image Repair...
dism /online /cleanup-image /restorehealth

echo.
echo 3. Windows Updates...
powershell -Command "Install-Module PSWindowsUpdate -Force -Scope CurrentUser; Get-WUInstall -AcceptAll -AutoReboot:$false"

echo.
echo 4. Registry Cleanup...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "" /f >nul 2>&1
cleanmgr /sagerun:1

echo.
echo === SYSTEM REPAIR COMPLETE ===
pause