# Manual eSIM configuration check
Write-Host "=== eSIM Configuration Check ===" -ForegroundColor Cyan

# Check if eSIM is supported
$esimSupport = Get-WmiObject -Namespace "root\cimv2\mdm\dmmap" -Class "MDM_eUICCs" -ErrorAction SilentlyContinue
if ($esimSupport) {
    Write-Host "eSIM supported" -ForegroundColor Green
} else {
    Write-Host "eSIM not supported on this device" -ForegroundColor Red
}

# Check cellular settings
netsh mbn show profiles
netsh mbn show interfaces