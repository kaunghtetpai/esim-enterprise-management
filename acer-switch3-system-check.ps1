# Acer Switch 3 System Check & eSIM Driver Download
Write-Host "=== Acer Switch 3 System Check ===" -ForegroundColor Cyan

# Check system info
$system = Get-WmiObject -Class Win32_ComputerSystem
Write-Host "Model: $($system.Model)" -ForegroundColor Green

# Check for eSIM hardware
$esimDevices = Get-PnpDevice | Where-Object {$_.FriendlyName -like "*eSIM*" -or $_.FriendlyName -like "*WWAN*"}
if ($esimDevices) {
    Write-Host "eSIM/WWAN devices found:" -ForegroundColor Green
    $esimDevices | Select-Object FriendlyName, Status
} else {
    Write-Host "No eSIM devices detected" -ForegroundColor Yellow
}

# Download Acer Switch 3 drivers
$downloadPath = "C:\AcerDrivers"
New-Item -ItemType Directory -Path $downloadPath -Force

Write-Host "Downloading Acer Switch 3 drivers..." -ForegroundColor Yellow
# Acer official driver URLs (replace with current versions)
$driverUrls = @(
    "https://global-download.acer.com/GDFiles/Driver/Wireless/Wireless_Intel_19.51.13.2_W10x64_A.zip"
    "https://global-download.acer.com/GDFiles/Driver/Modem/Modem_Qualcomm_1.0.3005.0_W10x64_A.zip"
)

foreach ($url in $driverUrls) {
    $fileName = Split-Path $url -Leaf
    $filePath = Join-Path $downloadPath $fileName
    try {
        Invoke-WebRequest -Uri $url -OutFile $filePath -ErrorAction Stop
        Write-Host "Downloaded: $fileName" -ForegroundColor Green
    } catch {
        Write-Host "Failed to download: $fileName" -ForegroundColor Red
    }
}

Write-Host "Drivers saved to: $downloadPath" -ForegroundColor Cyan