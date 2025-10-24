@echo off
echo === Intel eUICC/eSIM Hardware Driver Installation ===
echo.

echo Checking for Intel eUICC hardware...
powershell -Command "Get-PnpDevice | Where-Object {$_.FriendlyName -like '*eUICC*' -or $_.FriendlyName -like '*eSIM*'}"

echo.
echo Opening Device Manager for manual driver installation...
devmgmt.msc

echo.
echo Opening Intel Driver Assistant...
start https://www.intel.com/content/www/us/en/support/detect.html

echo.
echo Manual steps:
echo 1. In Device Manager, look for devices with yellow warning icons
echo 2. Right-click unknown Intel devices
echo 3. Select "Update driver"
echo 4. Choose "Search automatically for drivers"
echo.
pause