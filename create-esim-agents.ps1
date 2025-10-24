# Create AI Agents for eSIM Enterprise Management Portal
Write-Host "=== Creating eSIM AI Agents ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "Application.ReadWrite.All",
    "Directory.ReadWrite.All",
    "Policy.ReadWrite.All"
)

# 1. eSIM Device Management Agent
$deviceAgent = @{
    displayName = "eSIM Device Management Agent"
    description = "AI assistant for managing eSIM devices across Myanmar carriers"
    signInAudience = "AzureADMyOrg"
    api = @{
        requestedAccessTokenVersion = 2
        oauth2PermissionScopes = @(
            @{
                id = [System.Guid]::NewGuid().ToString()
                adminConsentDescription = "Manage eSIM devices and profiles"
                adminConsentDisplayName = "eSIM.DeviceManagement"
                isEnabled = $true
                type = "Admin"
                value = "eSIM.DeviceManagement"
            }
        )
    }
    requiredResourceAccess = @(
        @{
            resourceAppId = "00000003-0000-0000-c000-000000000000"
            resourceAccess = @(
                @{ id = "9241abd9-d0e6-425a-bd4f-47ba86e767a4"; type = "Role" }
            )
        }
    )
}

# 2. eSIM Carrier Integration Agent
$carrierAgent = @{
    displayName = "eSIM Carrier Integration Agent"
    description = "AI assistant for Myanmar carrier integrations (MPT, ATOM, OOREDOO, MYTEL)"
    signInAudience = "AzureADMyOrg"
    api = @{
        requestedAccessTokenVersion = 2
        oauth2PermissionScopes = @(
            @{
                id = [System.Guid]::NewGuid().ToString()
                adminConsentDescription = "Integrate with Myanmar carriers"
                adminConsentDisplayName = "eSIM.CarrierIntegration"
                isEnabled = $true
                type = "Admin"
                value = "eSIM.CarrierIntegration"
            }
        )
    }
}

# 3. eSIM Support Agent
$supportAgent = @{
    displayName = "eSIM Support Agent"
    description = "AI assistant for eSIM troubleshooting and user support"
    signInAudience = "AzureADMyOrg"
    api = @{
        requestedAccessTokenVersion = 2
        oauth2PermissionScopes = @(
            @{
                id = [System.Guid]::NewGuid().ToString()
                adminConsentDescription = "Provide eSIM support and troubleshooting"
                adminConsentDisplayName = "eSIM.Support"
                isEnabled = $true
                type = "User"
                value = "eSIM.Support"
            }
        )
    }
}

# Create the agents
$agents = @($deviceAgent, $carrierAgent, $supportAgent)
$createdAgents = @()

foreach ($agent in $agents) {
    try {
        $result = New-MgApplication -BodyParameter $agent
        $createdAgents += $result
        Write-Host "✅ Created agent: $($agent.displayName)" -ForegroundColor Green
        Write-Host "   App ID: $($result.AppId)" -ForegroundColor White
    } catch {
        Write-Host "❌ Failed to create $($agent.displayName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Agent Configuration Summary ===" -ForegroundColor Cyan
foreach ($agent in $createdAgents) {
    Write-Host "Agent: $($agent.DisplayName)" -ForegroundColor Yellow
    Write-Host "  App ID: $($agent.AppId)" -ForegroundColor White
    Write-Host "  Object ID: $($agent.Id)" -ForegroundColor White
}

Write-Host "`n🤖 AI Agent Capabilities:" -ForegroundColor Cyan
Write-Host "✅ Device Management: Automate eSIM provisioning" -ForegroundColor Green
Write-Host "✅ Carrier Integration: Connect with Myanmar carriers" -ForegroundColor Green  
Write-Host "✅ Support Assistant: Help with troubleshooting" -ForegroundColor Green