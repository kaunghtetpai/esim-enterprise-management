# Connect to Microsoft Graph API
param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [string]$ClientSecret,
    [switch]$Interactive,
    [switch]$Beta
)

try {
    # Import required modules
    Import-Module Microsoft.Graph.Authentication -Force
    
    if ($Beta) {
        Import-Module Microsoft.Graph.Beta.DeviceManagement -Force
    } else {
        Import-Module Microsoft.Graph.DeviceManagement -Force
    }
    
    # Define required scopes for eSIM management
    $scopes = @(
        'DeviceManagementManagedDevices.ReadWrite.All',
        'DeviceManagementConfiguration.ReadWrite.All',
        'Directory.Read.All',
        'User.Read.All'
    )
    
    if ($Interactive) {
        # Interactive authentication
        Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -Scopes $scopes
    } elseif ($ClientSecret) {
        # App-only authentication
        $secureSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($ClientId, $secureSecret)
        Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $credential
    } else {
        throw "Either use -Interactive switch or provide -ClientSecret"
    }
    
    # Verify connection
    $context = Get-MgContext
    Write-Host "Connected to Microsoft Graph successfully" -ForegroundColor Green
    Write-Host "Tenant: $($context.TenantId)" -ForegroundColor Yellow
    Write-Host "Account: $($context.Account)" -ForegroundColor Yellow
    Write-Host "Scopes: $($context.Scopes -join ', ')" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
    exit 1
}