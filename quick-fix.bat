@echo off
echo Windows 11 Quick Fix - All-in-One Solution
echo ==========================================

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator...
) else (
    echo Please run as Administrator!
    pause
    exit
)

:: 1. System File Check
echo 1. Running System File Checker...
sfc /scannow

:: 2. DISM Health Check
echo 2. Running DISM Health Check...
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth

:: 3. Windows Update
echo 3. Checking Windows Updates...
powershell -Command "Install-Module PSWindowsUpdate -Force; Get-WindowsUpdate -Install -AcceptAll"

:: 4. Clear Temp Files
echo 4. Clearing temporary files...
del /q /f /s %TEMP%\*
del /q /f /s C:\Windows\Temp\*
del /q /f /s C:\Windows\Prefetch\*
cleanmgr /sagerun:1

:: 5. Registry Cleanup
echo 5. Registry optimization...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 1 /f

:: 6. Network Reset
echo 6. Network optimization...
netsh winsock reset
netsh int ip reset
ipconfig /flushdns

:: 7. Disk Optimization
echo 7. Disk optimization...
defrag C: /O

:: 8. Install Winget Apps
echo 8. Installing essential apps...
winget install Microsoft.PowerToys
winget install Git.Git
winget install Microsoft.VisualStudioCode

echo All optimizations complete!
echo System restart recommended.
pause