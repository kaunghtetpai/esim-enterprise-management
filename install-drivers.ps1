# Auto-install downloaded drivers
$driverPath = "C:\AcerDrivers"
$extractPath = "C:\AcerDrivers\Extracted"

# Extract and install drivers
Get-ChildItem $driverPath -Filter "*.zip" | ForEach-Object {
    $zipFile = $_.FullName
    $extractFolder = Join-Path $extractPath $_.BaseName
    
    # Extract zip
    Expand-Archive -Path $zipFile -DestinationPath $extractFolder -Force
    
    # Find and run installer
    $installer = Get-ChildItem $extractFolder -Recurse -Include "setup.exe", "install.exe" | Select-Object -First 1
    if ($installer) {
        Write-Host "Installing: $($_.BaseName)"
        Start-Process $installer.FullName -ArgumentList "/S" -Wait
    }
}