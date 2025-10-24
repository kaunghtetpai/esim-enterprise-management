# Connect to Microsoft Entra ID and Intune with comprehensive error handling
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [string]$ClientSecret,
    [switch]$Interactive,
    [switch]$Beta,
    [switch]$ValidateOnly
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
            default { "Cyan" }
        }
    )
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..."
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.0 or higher required"
    }
    
    # Check required modules
    $requiredModules = @('Microsoft.Graph.Authentication')
    if ($Beta) {
        $requiredModules += 'Microsoft.Graph.Beta.DeviceManagement'
    } else {
        $requiredModules += 'Microsoft.Graph.DeviceManagement'
    }
    
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            throw "Required module not found: $module. Run Install-GraphSDK-Enhanced.ps1 first."
        }
    }
    
    Write-Log "Prerequisites check passed" "SUCCESS"
}

function Test-TenantConnection {
    param([string]$TenantId)
    
    try {
        Write-Log "Testing tenant connectivity..."
        
        # Test Entra ID endpoint
        $entraUrl = "https://login.microsoftonline.com/$TenantId/.well-known/openid_configuration"
        $response = Invoke-RestMethod -Uri $entraUrl -TimeoutSec 10
        
        if ($response.issuer) {
            Write-Log "Entra ID endpoint accessible: $($response.issuer)" "SUCCESS"
        } else {
            throw "Invalid Entra ID response"
        }
        
        # Test Graph endpoint
        $graphUrl = "https://graph.microsoft.com/v1.0/"
        $null = Invoke-WebRequest -Uri $graphUrl -UseBasicParsing -TimeoutSec 10
        Write-Log "Microsoft Graph endpoint accessible" "SUCCESS"
        
    } catch {
        throw "Tenant connectivity test failed: $($_.Exception.Message)"
    }
}

function Connect-GraphWithValidation {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret,
        [bool]$IsInteractive
    )
    
    try {
        Write-Log "Connecting to Microsoft Graph..."
        
        # Define comprehensive scopes for eSIM management
        $scopes = @(
            'DeviceManagementManagedDevices.ReadWrite.All',
            'DeviceManagementConfiguration.ReadWrite.All',
            'DeviceManagementApps.ReadWrite.All',
            'Directory.Read.All',
            'User.Read.All',
            'Group.Read.All',
            'Policy.Read.All'
        )
        
        if ($IsInteractive) {
            Write-Log "Using interactive authentication..."
            Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -Scopes $scopes
        } else {
            Write-Log "Using client secret authentication..."
            $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
            Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential
        }
        
        # Verify connection
        $context = Get-MgContext
        if (-not $context) {
            throw "Failed to establish Graph context"
        }
        
        Write-Log "Connected to Microsoft Graph successfully" "SUCCESS"
        Write-Log "Tenant: $($context.TenantId)" "SUCCESS"
        Write-Log "Account: $($context.Account)" "SUCCESS"
        Write-Log "App: $($context.AppName)" "SUCCESS"
        Write-Log "Scopes: $($context.Scopes -join ', ')" "SUCCESS"
        
        return $context
        
    } catch {
        throw "Graph connection failed: $($_.Exception.Message)"
    }
}

function Test-GraphPermissions {
    param([object]$Context)
    
    try {
        Write-Log "Testing Graph API permissions..."
        
        # Test basic read permissions
        try {
            $null = Get-MgOrganization -Top 1
            Write-Log "Organization read permission: OK" "SUCCESS"
        } catch {
            Write-Log "Organization read permission: FAILED - $($_.Exception.Message)" "WARN"
        }
        
        # Test device management permissions
        try {
            $devices = Get-MgDeviceManagementManagedDevice -Top 1
            Write-Log "Device management read permission: OK" "SUCCESS"
        } catch {
            Write-Log "Device management read permission: FAILED - $($_.Exception.Message)" "WARN"
        }
        
        # Test user read permissions
        try {
            $null = Get-MgUser -Top 1
            Write-Log "User read permission: OK" "SUCCESS"
        } catch {
            Write-Log "User read permission: FAILED - $($_.Exception.Message)" "WARN"
        }
        
    } catch {
        Write-Log "Permission testing failed: $($_.Exception.Message)" "ERROR"
    }
}

function Get-IntuneServiceStatus {
    try {
        Write-Log "Checking Intune service status..."
        
        # Get Intune service details
        $serviceHealth = Get-MgDeviceManagementManagedDevice -Top 1 -ErrorAction SilentlyContinue
        
        if ($serviceHealth) {
            Write-Log "Intune service: OPERATIONAL" "SUCCESS"
        } else {
            Write-Log "Intune service: NO DEVICES or ACCESS DENIED" "WARN"
        }
        
        # Check device configuration capabilities
        try {
            $configs = Get-MgDeviceManagementDeviceConfiguration -Top 1 -ErrorAction SilentlyContinue
            Write-Log "Device configuration access: OK" "SUCCESS"
        } catch {
            Write-Log "Device configuration access: LIMITED" "WARN"
        }
        
    } catch {
        Write-Log "Intune service check failed: $($_.Exception.Message)" "WARN"
    }
}

function Show-PortalLinks {
    param([string]$TenantId)
    
    Write-Log "Microsoft 365 Admin Portals:"
    Write-Log "Entra ID Admin Center: https://entra.microsoft.com/"
    Write-Log "Intune Admin Center: https://intune.microsoft.com/"
    Write-Log "Microsoft 365 Admin: https://admin.microsoft.com/"
    Write-Log "Azure Portal: https://portal.azure.com/"
    Write-Log "Graph Explorer: https://developer.microsoft.com/graph/graph-explorer"
}

# Main execution
try {
    Write-Log "Starting Microsoft Graph connection process"
    
    # Validate input parameters
    if (-not $TenantId -or -not ($TenantId -match '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')) {
        throw "Valid Tenant ID (GUID format) is required"
    }
    
    if (-not $ClientId -or -not ($ClientId -match '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')) {
        throw "Valid Client ID (GUID format) is required"
    }
    
    if (-not $Interactive -and (-not $ClientSecret -or $ClientSecret.Length -lt 8)) {
        throw "Client Secret (minimum 8 characters) is required for non-interactive authentication"
    }
    
    # Run prerequisite checks
    Test-Prerequisites
    Test-TenantConnection -TenantId $TenantId
    
    if ($ValidateOnly) {
        Write-Log "Validation completed successfully. Skipping connection." "SUCCESS"
        Show-PortalLinks -TenantId $TenantId
        exit 0
    }
    
    # Import required modules
    Write-Log "Importing Microsoft Graph modules..."
    Import-Module Microsoft.Graph.Authentication -Force
    
    if ($Beta) {
        Import-Module Microsoft.Graph.Beta.DeviceManagement -Force
        Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement -Force
    } else {
        Import-Module Microsoft.Graph.DeviceManagement -Force
        Import-Module Microsoft.Graph.Identity.DirectoryManagement -Force
    }
    
    # Connect to Graph
    $context = Connect-GraphWithValidation -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret -IsInteractive:$Interactive
    
    # Test permissions and services
    Test-GraphPermissions -Context $context
    Get-IntuneServiceStatus
    
    # Show portal links
    Show-PortalLinks -TenantId $TenantId
    
    Write-Log "Microsoft Graph connection completed successfully!" "SUCCESS"
    Write-Log "You can now use eSIM management commands" "SUCCESS"
    
} catch {
    Write-Log "Connection failed: $($_.Exception.Message)" "ERROR"
    Write-Log "Troubleshooting steps:" "WARN"
    Write-Log "1. Verify Tenant ID and Client ID are correct" "WARN"
    Write-Log "2. Check app registration permissions in Entra ID" "WARN"
    Write-Log "3. Ensure client secret is valid (if using)" "WARN"
    Write-Log "4. Verify network connectivity to Microsoft services" "WARN"
    Write-Log "5. Check Intune licensing and service availability" "WARN"
    exit 1
}