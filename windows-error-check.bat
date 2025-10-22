@echo off
echo === Windows System Error Check ===

echo Running System File Checker...
sfc /scannow

echo Running DISM Health Check...
dism /online /cleanup-image /checkhealth
dism /online /cleanup-image /restorehealth

echo Checking disk for errors...
chkdsk C: /f /r

echo Running Windows Memory Diagnostic...
mdsched /f

echo System check complete. Restart required for some fixes.