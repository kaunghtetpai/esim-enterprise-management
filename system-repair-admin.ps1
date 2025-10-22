# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Restart as administrator
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "Running system repair as Administrator..." -ForegroundColor Green

# Run SFC scan
Write-Host "Starting SFC scan..." -ForegroundColor Yellow
sfc /scannow

# Run DISM health restore
Write-Host "Starting DISM health restore..." -ForegroundColor Yellow
dism /online /cleanup-image /restorehealth

Write-Host "System repair completed!" -ForegroundColor Green
Read-Host "Press Enter to exit"