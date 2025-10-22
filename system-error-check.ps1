# Comprehensive Windows Error Check & Update
Write-Host "=== Windows System Error Check ===" -ForegroundColor Cyan

# Check Windows Update
Write-Host "Checking Windows Updates..." -ForegroundColor Yellow
Get-WindowsUpdate -AcceptAll -Install -AutoReboot

# Check system health
Write-Host "Checking system health..." -ForegroundColor Yellow
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory

# Check disk health
Write-Host "Checking disk health..." -ForegroundColor Yellow
Get-PhysicalDisk | Get-StorageReliabilityCounter | Select-Object DeviceId, Temperature, ReadErrorsTotal, WriteErrorsTotal

# Check event logs for errors
Write-Host "Checking recent system errors..." -ForegroundColor Yellow
Get-EventLog -LogName System -EntryType Error -Newest 5 | Select-Object TimeGenerated, Source, Message

# Check services status
Write-Host "Checking critical services..." -ForegroundColor Yellow
$services = @("Themes", "AudioSrv", "BITS", "Spooler", "Winmgmt")
foreach ($service in $services) {
    $status = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($status) {
        Write-Host "$service : $($status.Status)" -ForegroundColor Green
    }
}