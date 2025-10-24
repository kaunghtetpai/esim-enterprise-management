# Acer Swift SF314-59 - Safe System Setup
param([switch]$DryRun)

$ErrorActionPreference = "Continue"
$LogFile = "$env:USERPROFILE\Desktop\AcerSetup_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

Start-Transcript -Path $LogFile
Write-Host "=== Acer SF314-59 Safe Setup Started ===" -ForegroundColor Cyan

# System Information
$SystemInfo = Get-ComputerInfo | Select-Object WindowsProductName, TotalPhysicalMemory, CsModel, CsManufacturer
Write-Host "Model: $($SystemInfo.CsModel)" -ForegroundColor Green
Write-Host "OS: $($SystemInfo.WindowsProductName)" -ForegroundColor Green

# Check for eSIM Hardware
Write-Host "`nChecking for eSIM/WWAN hardware..." -ForegroundColor Yellow
$ESIMDevices = Get-PnpDevice | Where-Object {
    $_.FriendlyName -like "*eSIM*" -or 
    $_.FriendlyName -like "*SIM*" -or
    $_.Class -eq "Net" -and $_.Description -like "*WWAN*"
}

if ($ESIMDevices) {
    Write-Host "Found connectivity hardware:" -ForegroundColor Green
    $ESIMDevices | ForEach-Object { Write-Host "  - $($_.FriendlyName)" -ForegroundColor White }
} else {
    Write-Host "No eSIM/WWAN hardware detected" -ForegroundColor Yellow
}

# Windows Updates
Write-Host "`nChecking Windows Updates..." -ForegroundColor Yellow
if (-not $DryRun) {
    try {
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Install-Module PSWindowsUpdate -Force -Confirm:$false
        }
        Import-Module PSWindowsUpdate
        $Updates = Get-WUList
        if ($Updates) {
            Write-Host "Found $($Updates.Count) updates" -ForegroundColor Green
            Install-WindowsUpdate -AcceptAll -AutoReboot:$false
        } else {
            Write-Host "No updates available" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Update check failed: $($_.Exception.Message)"
    }
}

# System Optimization
Write-Host "`nApplying system optimizations..." -ForegroundColor Yellow
if (-not $DryRun) {
    # Power plan
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Host "High performance power plan activated" -ForegroundColor Green
    
    # Disable unnecessary services
    $ServicesToDisable = @("XboxGipSvc", "XboxNetApiSvc")
    foreach ($Service in $ServicesToDisable) {
        $Svc = Get-Service -Name $Service -ErrorAction SilentlyContinue
        if ($Svc) {
            Set-Service -Name $Service -StartupType Disabled
            Write-Host "Disabled service: $Service" -ForegroundColor Green
        }
    }
}

# Development Tools (Optional)
Write-Host "`nInstalling development tools..." -ForegroundColor Yellow
if (-not $DryRun) {
    try {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        
        $DevTools = @("git", "vscode", "python", "nodejs")
        foreach ($Tool in $DevTools) {
            choco install $Tool -y --no-progress
            Write-Host "Installed: $Tool" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Development tools installation failed: $($_.Exception.Message)"
    }
}

# Security Configuration
Write-Host "`nConfiguring security..." -ForegroundColor Yellow
if (-not $DryRun) {
    # Windows Defender
    Set-MpPreference -DisableRealtimeMonitoring $false
    Write-Host "Windows Defender enabled" -ForegroundColor Green
    
    # Firewall
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
    Write-Host "Firewall enabled for all profiles" -ForegroundColor Green
}

# Final Report
$EndTime = Get-Date
Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "Model: $($SystemInfo.CsModel)" -ForegroundColor White
Write-Host "Memory: $([math]::Round($SystemInfo.TotalPhysicalMemory/1GB,1)) GB" -ForegroundColor White
Write-Host "eSIM Hardware: $(if($ESIMDevices){'Detected'}else{'Not Found'})" -ForegroundColor White
Write-Host "Log saved to: $LogFile" -ForegroundColor White

Stop-Transcript