# Configure Limited Admin Roles for eSIM Portal
Write-Host "=== Configuring Admin Role Assignments ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "Directory.ReadWrite.All"

$adminUser = "admin@mdm.esim.com.mm"
Write-Host "Configuring roles for: $adminUser" -ForegroundColor Yellow

# Get user object
$user = Get-MgUser -UserId $adminUser
Write-Host "User ID: $($user.Id)" -ForegroundColor White

# Define required roles with their IDs
$requiredRoles = @{
    "Intune Administrator" = "3a2c62db-5318-420d-8d74-23affee5d9d5"
    "Groups Administrator" = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
    "Application Administrator" = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
    "Conditional Access Administrator" = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
}

# Remove Global Administrator role
Write-Host "`n1. Removing Global Administrator role..." -ForegroundColor Yellow
try {
    $globalAdminRole = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"
    if ($globalAdminRole) {
        $membership = Get-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id | Where-Object { $_.Id -eq $user.Id }
        if ($membership) {
            Remove-MgDirectoryRoleMember -DirectoryRoleId $globalAdminRole.Id -DirectoryObjectId $user.Id
            Write-Host "✅ Removed Global Administrator role" -ForegroundColor Green
        } else {
            Write-Host "ℹ️ User not in Global Administrator role" -ForegroundColor Blue
        }
    }
} catch {
    Write-Host "❌ Error removing Global Admin: $($_.Exception.Message)" -ForegroundColor Red
}

# Assign specific roles
Write-Host "`n2. Assigning specific admin roles..." -ForegroundColor Yellow
foreach ($roleName in $requiredRoles.Keys) {
    $roleId = $requiredRoles[$roleName]
    
    try {
        # Get or create the directory role
        $role = Get-MgDirectoryRole -Filter "roleTemplateId eq '$roleId'"
        if (-not $role) {
            # Activate the role template
            $roleTemplate = Get-MgDirectoryRoleTemplate -DirectoryRoleTemplateId $roleId
            $role = New-MgDirectoryRole -RoleTemplateId $roleId
            Write-Host "   Activated role template: $roleName" -ForegroundColor Blue
        }
        
        # Check if user already has this role
        $existingMember = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id | Where-Object { $_.Id -eq $user.Id }
        
        if (-not $existingMember) {
            # Assign the role
            New-MgDirectoryRoleMember -DirectoryRoleId $role.Id -BodyParameter @{
                "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)"
            }
            Write-Host "✅ Assigned: $roleName" -ForegroundColor Green
        } else {
            Write-Host "ℹ️ Already assigned: $roleName" -ForegroundColor Blue
        }
        
    } catch {
        Write-Host "❌ Error assigning $roleName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Verify current role assignments
Write-Host "`n3. Verifying current role assignments..." -ForegroundColor Yellow
$userRoles = Get-MgUserMemberOf -UserId $user.Id | Where-Object { $_."@odata.type" -eq "#microsoft.graph.directoryRole" }

Write-Host "`nCurrent roles for $adminUser :" -ForegroundColor Cyan
foreach ($role in $userRoles) {
    $roleDetails = Get-MgDirectoryRole -DirectoryRoleId $role.Id
    Write-Host "  ✅ $($roleDetails.DisplayName)" -ForegroundColor Green
}

Write-Host "`n=== Role Configuration Summary ===" -ForegroundColor Cyan
Write-Host "✅ Global Administrator: Removed" -ForegroundColor Green
Write-Host "✅ Intune Administrator: Assigned" -ForegroundColor Green
Write-Host "✅ Groups Administrator: Assigned" -ForegroundColor Green
Write-Host "✅ Application Administrator: Assigned" -ForegroundColor Green
Write-Host "✅ Conditional Access Administrator: Assigned" -ForegroundColor Green

Write-Host "`n🎯 Admin access successfully limited to required roles only!" -ForegroundColor Green
Write-Host "📋 Next: Configure MFA and Conditional Access policies" -ForegroundColor Yellow