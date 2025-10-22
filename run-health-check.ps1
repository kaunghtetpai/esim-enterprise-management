# Quick Health Check Execution Script
# Simple wrapper for running Intune health checks

param(
    [switch]$Quick,
    [switch]$Full,
    [switch]$Fix,
    [switch]$PrepareePM,
    [switch]$ReportsOnly
)

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Intune Health Check Launcher ===" -ForegroundColor Cyan
Write-Host "Tenant: MDM.esim.com.mm" -ForegroundColor Yellow

if ($Quick) {
    Write-Host "`nRunning Quick Health Check (Read-Only)..." -ForegroundColor Green
    & "$ScriptPath\intune-health-check.ps1" -GenerateReport
}
elseif ($Full) {
    Write-Host "`nRunning Full Health Check..." -ForegroundColor Green
    & "$ScriptPath\intune-automation-suite.ps1" -FullHealthCheck -GenerateReports
}
elseif ($Fix) {
    Write-Host "`nRunning Health Check with Auto-Fix..." -ForegroundColor Yellow
    Write-Host "WARNING: This will make changes to your Intune configuration!" -ForegroundColor Red
    $confirm = Read-Host "Continue? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        & "$ScriptPath\intune-automation-suite.ps1" -FullHealthCheck -AutoFix -GenerateReports
    }
}
elseif ($PrepareePM) {
    Write-Host "`nPreparing for eSIM Profile Management Integration..." -ForegroundColor Green
    & "$ScriptPath\intune-automation-suite.ps1" -PrepareePM -GenerateReports
}
elseif ($ReportsOnly) {
    Write-Host "`nGenerating Reports Only..." -ForegroundColor Green
    & "$ScriptPath\intune-automation-suite.ps1" -GenerateReports
}
else {
    Write-Host "`nUsage Options:" -ForegroundColor White
    Write-Host "  -Quick      : Quick read-only health check" -ForegroundColor Gray
    Write-Host "  -Full       : Complete health check (read-only)" -ForegroundColor Gray
    Write-Host "  -Fix        : Health check with automatic fixes" -ForegroundColor Gray
    Write-Host "  -PrepareePM : Prepare for eSIM Profile Management" -ForegroundColor Gray
    Write-Host "  -ReportsOnly: Generate reports from current state" -ForegroundColor Gray
    Write-Host "`nExample: .\run-health-check.ps1 -Full" -ForegroundColor Yellow
}