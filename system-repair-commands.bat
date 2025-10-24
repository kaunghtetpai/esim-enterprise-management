@echo off
echo === SYSTEM REPAIR COMMANDS ===
echo.

echo Checking admin privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Administrator privileges required
    echo Right-click and "Run as administrator"
    pause
    exit /b 1
)

echo Running system file check...
sfc /scannow

echo.
echo Running image repair...
dism /online /cleanup-image /restorehealth

echo.
echo Installing Windows updates...
powershell -Command "Get-WindowsUpdate -Install -AcceptAll -AutoReboot:$false"

echo.
echo Running disk cleanup...
cleanmgr /sagerun:1

echo.
echo === SYSTEM REPAIR COMPLETE ===
pause