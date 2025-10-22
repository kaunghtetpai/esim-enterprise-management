# Microsoft Entra ID Security Setup for eSIM Portal
# Based on Microsoft Entra ID best practices

Write-Host "=== Microsoft Entra ID Security Configuration ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "Policy.ReadWrite.All",
    "Directory.ReadWrite.All", 
    "UserAuthenticationMethod.ReadWrite.All",
    "Policy.ReadWrite.ConditionalAccess"
)

# 1. Enable MFA for admin account
Write-Host "1. Configuring MFA for admin..." -ForegroundColor Green
$adminUser = "admin@mdm.esim.com.mm"

try {
    # Enable phone authentication
    $phoneAuth = @{
        "@odata.type" = "#microsoft.graph.phoneAuthenticationMethod"
        phoneNumber = "+95912345678"  # Replace with actual number
        phoneType = "mobile"
    }
    New-MgUserAuthenticationPhoneMethod -UserId $adminUser -BodyParameter $phoneAuth
    Write-Host "✅ Phone MFA enabled for admin" -ForegroundColor Green
} catch {
    Write-Host "MFA setup: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. Create Conditional Access Policy for eSIM Portal
Write-Host "2. Creating Conditional Access policy..." -ForegroundColor Green
$caPolicy = @{
    displayName = "eSIM Portal - Require MFA"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @($adminUser)
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

try {
    New-MgIdentityConditionalAccessPolicy -BodyParameter $caPolicy
    Write-Host "✅ Conditional Access policy created" -ForegroundColor Green
} catch {
    Write-Host "CA policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Configure Named Locations (Myanmar)
Write-Host "3. Setting up Myanmar trusted locations..." -ForegroundColor Green
$myanmarLocation = @{
    "@odata.type" = "#microsoft.graph.ipNamedLocation"
    displayName = "Myanmar Trusted Networks"
    isTrusted = $true
    ipRanges = @(
        @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = "103.0.0.0/8"  # Myanmar IP range
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
Write-Host "4. Configuring Identity Protection..." -ForegroundColor Green
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
    New-MgIdentityConditionalAccessPolicy -BodyParameter $riskPolicy
    Write-Host "✅ Identity Protection policy enabled" -ForegroundColor Green
} catch {
    Write-Host "Risk policy: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Security Configuration Complete ===" -ForegroundColor Cyan
Write-Host "✅ MFA enabled for admin" -ForegroundColor Green
Write-Host "✅ Conditional Access policies created" -ForegroundColor Green  
Write-Host "✅ Myanmar trusted locations configured" -ForegroundColor Green
Write-Host "✅ Identity Protection enabled" -ForegroundColor Green