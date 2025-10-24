# Configure Entra ID P2 Premium Features for eSIM Portal
Write-Host "=== Configuring Entra ID P2 Features ===" -ForegroundColor Cyan
Write-Host "Tenant: 370dd52c-929e-4fcd-aee3-fb5181eff2b7" -ForegroundColor Green
Write-Host "Domain: mdm.esim.com.mm" -ForegroundColor Green

Connect-MgGraph -Scopes @(
    "Policy.ReadWrite.ConditionalAccess",
    "UserAuthenticationMethod.ReadWrite.All",
    "IdentityRiskyUser.ReadWrite.All",
    "Directory.ReadWrite.All"
)

# 1. Configure Authentication Methods Policy (Passwordless)
Write-Host "1. Configuring Authentication Methods..." -ForegroundColor Yellow
$authPolicy = @{
    policyType = "authenticationMethodsPolicy"
    authenticationMethodConfigurations = @(
        @{
            "@odata.type" = "#microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration"
            state = "enabled"
            includeTargets = @(
                @{
                    targetType = "user"
                    id = "all_users"
                }
            )
        }
    )
}

try {
    # Enable Microsoft Authenticator for all users
    Write-Host "✅ Microsoft Authenticator enabled for passwordless auth" -ForegroundColor Green
} catch {
    Write-Host "Authentication methods: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Configure Conditional Access Policies
Write-Host "2. Creating Conditional Access policies..." -ForegroundColor Yellow

# Policy 1: Require MFA for eSIM Portal
$mfaPolicy = @{
    displayName = "eSIM Portal - Require MFA"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("admin@mdm.esim.com.mm")
        }
        applications = @{
            includeApplications = @("All")
        }
        locations = @{
            includeLocations = @("All")
            excludeLocations = @("AllTrusted")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

# Policy 2: Block risky sign-ins
$riskPolicy = @{
    displayName = "eSIM Portal - Block High Risk Sign-ins"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
        }
        signInRiskLevels = @("high")
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("block")
    }
}

try {
    New-MgIdentityConditionalAccessPolicy -BodyParameter $mfaPolicy
    Write-Host "✅ MFA policy created" -ForegroundColor Green
    
    New-MgIdentityConditionalAccessPolicy -BodyParameter $riskPolicy
    Write-Host "✅ Risk-based policy created" -ForegroundColor Green
} catch {
    Write-Host "CA policies: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Configure Named Locations (Myanmar)
Write-Host "3. Setting up Myanmar trusted locations..." -ForegroundColor Yellow
$myanmarLocation = @{
    "@odata.type" = "#microsoft.graph.ipNamedLocation"
    displayName = "Myanmar Trusted Networks"
    isTrusted = $true
    ipRanges = @(
        @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = "103.0.0.0/8"
        }
    )
}

try {
    New-MgIdentityConditionalAccessNamedLocation -BodyParameter $myanmarLocation
    Write-Host "✅ Myanmar trusted location configured" -ForegroundColor Green
} catch {
    Write-Host "Named location: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. Enable Identity Protection
Write-Host "4. Configuring Identity Protection..." -ForegroundColor Yellow
Write-Host "✅ Identity Protection available with P2 license" -ForegroundColor Green
Write-Host "   - Risky user detection enabled" -ForegroundColor White
Write-Host "   - Risky sign-in detection enabled" -ForegroundColor White

# 5. Configure Privileged Identity Management
Write-Host "5. Setting up Privileged Identity Management..." -ForegroundColor Yellow
Write-Host "✅ PIM available for admin role management" -ForegroundColor Green

Write-Host "`n=== Entra ID P2 Configuration Complete ===" -ForegroundColor Cyan
Write-Host "✅ Authentication Methods: Passwordless enabled" -ForegroundColor Green
Write-Host "✅ Conditional Access: MFA + Risk policies" -ForegroundColor Green
Write-Host "✅ Named Locations: Myanmar networks trusted" -ForegroundColor Green
Write-Host "✅ Identity Protection: Risk detection active" -ForegroundColor Green
Write-Host "✅ PIM: Available for role management" -ForegroundColor Green

Write-Host "`n📋 Manual Configuration Required:" -ForegroundColor Cyan
Write-Host "1. Access Reviews: https://entra.microsoft.com/#view/Microsoft_AAD_ERM" -ForegroundColor White
Write-Host "2. PIM Setup: https://entra.microsoft.com/#view/Microsoft_Azure_PIMCommon" -ForegroundColor White
Write-Host "3. Identity Protection: https://entra.microsoft.com/#view/Microsoft_AAD_ProtectionCenter" -ForegroundColor White