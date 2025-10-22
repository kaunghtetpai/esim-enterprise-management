@echo off
echo Running system repair commands as Administrator...
echo.
echo Running SFC scan...
sfc /scannow
echo.
echo Running DISM health restore...
dism /online /cleanup-image /restorehealth
echo.
echo System repair complete.
pause