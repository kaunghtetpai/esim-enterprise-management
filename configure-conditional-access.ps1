# Configure Conditional Access for eSIM devices
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

$policy = @{
    displayName = "eSIM Device Compliance Required"
    state = "enabled"
    conditions = @{
        applications = @{ includeApplications = @("All") }
        users = @{ includeGroups = @((Get-MgGroup -Filter "startswith(displayName,'eSIM')").Id) }
        platforms = @{ includePlatforms = @("windows", "iOS", "android") }
    }
    grantControls = @{
        operator = "AND"
        builtInControls = @("mfa", "compliantDevice")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $policy
Write-Host "Conditional Access policy created" -ForegroundColor Green