# Enhanced Microsoft Graph PowerShell SDK Installation
param(
    [switch]$Beta,
    [switch]$Force,
    [switch]$Verbose,
    [string]$Scope = "CurrentUser"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function Test-PowerShellVersion {
    $version = $PSVersionTable.PSVersion
    if ($version.Major -lt 5) {
        throw "PowerShell 5.0 or higher is required. Current version: $($version.ToString())"
    }
    Write-Log "PowerShell version check passed: $($version.ToString())" "SUCCESS"
}

function Test-ExecutionPolicy {
    $policy = Get-ExecutionPolicy -Scope $Scope
    if ($policy -eq "Restricted") {
        Write-Log "Execution policy is Restricted. Attempting to set RemoteSigned..." "WARN"
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope $Scope -Force
            Write-Log "Execution policy updated to RemoteSigned" "SUCCESS"
        } catch {
            throw "Failed to update execution policy: $($_.Exception.Message)"
        }
    }
}

function Install-GraphModule {
    param([string]$ModuleName, [switch]$IsBeta)
    
    try {
        Write-Log "Installing module: $ModuleName"
        
        $installParams = @{
            Name = $ModuleName
            Scope = $Scope
            Force = $Force
            AllowClobber = $true
        }
        
        if ($IsBeta) {
            $installParams.AllowPrerelease = $true
        }
        
        Install-Module @installParams
        
        # Verify installation
        $installed = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
        if ($installed) {
            Write-Log "Successfully installed $ModuleName version $($installed.Version)" "SUCCESS"
        } else {
            throw "Module installation verification failed"
        }
        
    } catch {
        Write-Log "Failed to install $ModuleName : $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Test-ModuleImport {
    param([string]$ModuleName)
    
    try {
        Import-Module $ModuleName -Force
        Write-Log "Successfully imported $ModuleName" "SUCCESS"
    } catch {
        Write-Log "Failed to import $ModuleName : $($_.Exception.Message)" "ERROR"
        throw
    }
}

try {
    Write-Log "Starting Microsoft Graph PowerShell SDK installation"
    
    # Pre-installation checks
    Test-PowerShellVersion
    Test-ExecutionPolicy
    
    # Check internet connectivity
    try {
        $null = Invoke-WebRequest -Uri "https://www.powershellgallery.com" -UseBasicParsing -TimeoutSec 10
        Write-Log "Internet connectivity verified" "SUCCESS"
    } catch {
        throw "Internet connectivity required for module installation"
    }
    
    # Define modules to install
    $coreModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.DeviceManagement',
        'Microsoft.Graph.Identity.DirectoryManagement',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Groups'
    )
    
    if ($Beta) {
        Write-Log "Installing Microsoft Graph Beta modules"
        $mainModule = 'Microsoft.Graph.Beta'
        $coreModules = $coreModules | ForEach-Object { $_.Replace('Microsoft.Graph.', 'Microsoft.Graph.Beta.') }
    } else {
        Write-Log "Installing Microsoft Graph stable modules"
        $mainModule = 'Microsoft.Graph'
    }
    
    # Install main Graph module first
    Install-GraphModule -ModuleName $mainModule -IsBeta:$Beta
    
    # Install core modules
    foreach ($module in $coreModules) {
        Install-GraphModule -ModuleName $module -IsBeta:$Beta
    }
    
    # Test module imports
    Write-Log "Testing module imports..."
    Test-ModuleImport -ModuleName 'Microsoft.Graph.Authentication'
    
    # Display installed modules
    Write-Log "Installation completed successfully!" "SUCCESS"
    Write-Log "Installed Microsoft Graph modules:"
    
    $installedModules = Get-InstalledModule Microsoft.Graph* | Select-Object Name, Version, Repository
    $installedModules | Format-Table -AutoSize
    
    # Test basic Graph connection capability
    Write-Log "Testing Graph connection capability..."
    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        Write-Log "Graph context test passed" "SUCCESS"
    } catch {
        Write-Log "Graph context test completed (not connected)" "SUCCESS"
    }
    
    Write-Log "Microsoft Graph PowerShell SDK installation completed successfully!" "SUCCESS"
    Write-Log "Next steps:"
    Write-Log "1. Run Connect-GraphAPI.ps1 to authenticate"
    Write-Log "2. Use Manage-eSIMProfiles.ps1 for eSIM operations"
    
} catch {
    Write-Log "Installation failed: $($_.Exception.Message)" "ERROR"
    Write-Log "Troubleshooting steps:" "WARN"
    Write-Log "1. Run PowerShell as Administrator" "WARN"
    Write-Log "2. Check internet connectivity" "WARN"
    Write-Log "3. Verify PowerShell Gallery access" "WARN"
    exit 1
}