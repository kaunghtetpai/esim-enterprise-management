# Install Microsoft Graph PowerShell SDK
param(
    [switch]$Beta,
    [switch]$Force
)

try {
    Write-Host "Installing Microsoft Graph PowerShell SDK..." -ForegroundColor Green
    
    # Install main Graph module
    if ($Beta) {
        Install-Module Microsoft.Graph.Beta -Scope CurrentUser -Force:$Force -AllowClobber
    } else {
        Install-Module Microsoft.Graph -Scope CurrentUser -Force:$Force -AllowClobber
    }
    
    # Install specific modules for eSIM management
    $modules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.DeviceManagement',
        'Microsoft.Graph.Identity.DirectoryManagement',
        'Microsoft.Graph.Users'
    )
    
    foreach ($module in $modules) {
        Write-Host "Installing $module..." -ForegroundColor Yellow
        Install-Module $module -Scope CurrentUser -Force:$Force -AllowClobber
    }
    
    Write-Host "Microsoft Graph SDK installed successfully" -ForegroundColor Green
    
    # Verify installation
    Get-InstalledModule Microsoft.Graph* | Select-Object Name, Version
    
} catch {
    Write-Error "Failed to install Microsoft Graph SDK: $($_.Exception.Message)"
    exit 1
}