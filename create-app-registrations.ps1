# Create Enterprise Applications and App Registrations for eSIM Portal
Write-Host "=== Creating eSIM Portal App Registrations ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes "Application.ReadWrite.All", "Directory.ReadWrite.All"

# 1. eSIM Portal Web Application
$webApp = @{
    displayName = "eSIM Enterprise Management Portal"
    description = "Web portal for managing eSIM profiles across Myanmar carriers"
    signInAudience = "AzureADMyOrg"
    web = @{
        redirectUris = @(
            "https://esim.mdm.esim.com.mm/auth/callback"
            "https://localhost:3000/auth/callback"
        )
        implicitGrantSettings = @{
            enableIdTokenIssuance = $true
            enableAccessTokenIssuance = $true
        }
    }
    requiredResourceAccess = @(
        @{
            resourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
            resourceAccess = @(
                @{ id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; type = "Scope" } # User.Read
                @{ id = "19dbc75e-c2e2-444c-a770-ec69d8559fc7"; type = "Role" } # Directory.ReadWrite.All
                @{ id = "5b567255-7703-4780-807c-7be8301ae99b"; type = "Role" } # Group.ReadWrite.All
            )
        }
    )
}

$createdWebApp = New-MgApplication -BodyParameter $webApp
Write-Host "✅ Created Web App: $($createdWebApp.DisplayName)" -ForegroundColor Green
Write-Host "   App ID: $($createdWebApp.AppId)" -ForegroundColor White

# 2. eSIM API Application
$apiApp = @{
    displayName = "eSIM Portal API"
    description = "Backend API for eSIM device management"
    signInAudience = "AzureADMyOrg"
    api = @{
        requestedAccessTokenVersion = 2
        oauth2PermissionScopes = @(
            @{
                id = [System.Guid]::NewGuid().ToString()
                adminConsentDescription = "Access eSIM management functions"
                adminConsentDisplayName = "eSIM.Manage"
                isEnabled = $true
                type = "Admin"
                userConsentDescription = "Access eSIM management"
                userConsentDisplayName = "eSIM Management"
                value = "eSIM.Manage"
            }
        )
    }
    requiredResourceAccess = @(
        @{
            resourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
            resourceAccess = @(
                @{ id = "5b567255-7703-4780-807c-7be8301ae99b"; type = "Role" } # Group.ReadWrite.All
                @{ id = "9241abd9-d0e6-425a-bd4f-47ba86e767a4"; type = "Role" } # DeviceManagementManagedDevices.ReadWrite.All
                @{ id = "5ac13192-7ace-4fcf-b828-1a26f28068ee"; type = "Role" } # DeviceManagementConfiguration.ReadWrite.All
            )
        }
    )
}

$createdApiApp = New-MgApplication -BodyParameter $apiApp
Write-Host "✅ Created API App: $($createdApiApp.DisplayName)" -ForegroundColor Green
Write-Host "   App ID: $($createdApiApp.AppId)" -ForegroundColor White

# 3. Myanmar Carrier Integration Apps
$carriers = @("MPT", "ATOM", "OOREDOO", "MYTEL")
foreach ($carrier in $carriers) {
    $carrierApp = @{
        displayName = "eSIM $carrier Integration"
        description = "Integration app for $carrier eSIM services"
        signInAudience = "AzureADMyOrg"
        web = @{
            redirectUris = @("https://esim.mdm.esim.com.mm/carrier/$($carrier.ToLower())/callback")
        }
        requiredResourceAccess = @(
            @{
                resourceAppId = $createdApiApp.AppId
                resourceAccess = @(
                    @{ id = $apiApp.api.oauth2PermissionScopes[0].id; type = "Scope" }
                )
            }
        )
    }
    
    $createdCarrierApp = New-MgApplication -BodyParameter $carrierApp
    Write-Host "✅ Created $carrier App: $($createdCarrierApp.AppId)" -ForegroundColor Green
}

# 4. Create Service Principals for Enterprise Applications
Write-Host "`nCreating Enterprise Applications..." -ForegroundColor Yellow

$webAppSP = New-MgServicePrincipal -AppId $createdWebApp.AppId
Write-Host "✅ Enterprise App: eSIM Portal ($($webAppSP.Id))" -ForegroundColor Green

$apiAppSP = New-MgServicePrincipal -AppId $createdApiApp.AppId  
Write-Host "✅ Enterprise App: eSIM API ($($apiAppSP.Id))" -ForegroundColor Green

Write-Host "`n=== App Registration Summary ===" -ForegroundColor Cyan
Write-Host "Web Portal: $($createdWebApp.AppId)" -ForegroundColor White
Write-Host "API Backend: $($createdApiApp.AppId)" -ForegroundColor White
Write-Host "Carrier Apps: 4 created for Myanmar carriers" -ForegroundColor White