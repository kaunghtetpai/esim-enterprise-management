# Security Management Error Check for Intune Portal
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All", "Policy.Read.All"

Write-Host "=== Security Management Health Check ===" -ForegroundColor Cyan

# Check Endpoint Security policies
try {
    $endpointPolicies = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/intents" -Method GET
    Write-Host "Endpoint Security Policies: $($endpointPolicies.value.Count)" -ForegroundColor Green
} catch {
    Write-Host "Endpoint Security Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Security Baselines
try {
    $baselines = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/templates" -Method GET
    Write-Host "Security Baselines: $($baselines.value.Count)" -ForegroundColor Green
} catch {
    Write-Host "Security Baselines Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check Compliance Policies
try {
    $compliance = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies" -Method GET
    Write-Host "Compliance Policies: $($compliance.value.Count)" -ForegroundColor Green
} catch {
    Write-Host "Compliance Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Security Management check complete" -ForegroundColor Green