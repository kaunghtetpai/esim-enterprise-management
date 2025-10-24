# Download Essential Drivers for Acer SF314-59
Write-Host "=== Driver Download for Acer SF314-59 ===" -ForegroundColor Cyan

$downloadPath = "$env:USERPROFILE\Desktop\Drivers"
New-Item -Path $downloadPath -ItemType Directory -Force | Out-Null

# Essential drivers with direct download links
$drivers = @(
    @{
        Name = "Intel Chipset Driver"
        Url = "https://downloadmirror.intel.com/30553/eng/chipset-10.1.18836.8283-public-mup.exe"
        File = "intel-chipset.exe"
    },
    @{
        Name = "Intel Graphics Driver"
        Url = "https://downloadmirror.intel.com/30196/a08/igfx_win10_100.9079.exe"
        File = "intel-graphics.exe"
    },
    @{
        Name = "Realtek Audio Driver"
        Url = "https://www.realtek.com/en/component/zoo/category/pc-audio-codecs-high-definition-audio-codecs-software"
        File = "realtek-audio-info.txt"
    }
)

foreach ($driver in $drivers) {
    try {
        Write-Host "Downloading $($driver.Name)..." -ForegroundColor Yellow
        $outputFile = Join-Path $downloadPath $driver.File
        
        if ($driver.File -eq "realtek-audio-info.txt") {
            "Visit: $($driver.Url)" | Out-File $outputFile
            Write-Host "✅ Info saved: $($driver.File)" -ForegroundColor Green
        } else {
            Invoke-WebRequest -Uri $driver.Url -OutFile $outputFile -UserAgent "Mozilla/5.0"
            if (Test-Path $outputFile) {
                Write-Host "✅ Downloaded: $($driver.File)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "❌ Failed: $($driver.Name)" -ForegroundColor Red
    }
}

Write-Host "`nDrivers saved to: $downloadPath" -ForegroundColor Cyan
Write-Host "=== Download Complete ===" -ForegroundColor Cyan