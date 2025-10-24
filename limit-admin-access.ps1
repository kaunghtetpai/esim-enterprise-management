# Limit Admin Access - Remove Global Admin, Assign Specific Roles
Write-Host "=== Limiting Admin Access ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

$adminUser = "admin@mdm.esim.com.mm"
$user = Get-MgUser -UserId $adminUser

Write-Host "Configuring roles for: $($user.DisplayName)" -ForegroundColor Yellow

# Check current roles
Write-Host "`nCurrent roles:" -ForegroundColor Cyan
$currentRoles = Get-MgUserMemberOf -UserId $user.Id | Where-Object { $_."@odata.type" -eq "#microsoft.graph.directoryRole" }
foreach ($role in $currentRoles) {
    $roleInfo = Get-MgDirectoryRole -DirectoryRoleId $role.Id
    Write-Host "  - $($roleInfo.DisplayName)" -ForegroundColor White
}

# Required specific roles
$targetRoles = @(
    "Intune Administrator",
    "Groups Administrator", 
    "Application Administrator",
    "Conditional Access Administrator"
)

Write-Host "`nTarget roles for eSIM Portal:" -ForegroundColor Cyan
foreach ($roleName in $targetRoles) {
    Write-Host "  - $roleName" -ForegroundColor Green
}

Write-Host "`n📋 Manual Steps Required:" -ForegroundColor Yellow
Write-Host "1. Go to: https://entra.microsoft.com/#view/Microsoft_AAD_IAM/RolesManagementMenuBlade" -ForegroundColor White
Write-Host "2. Find user: admin@mdm.esim.com.mm" -ForegroundColor White
Write-Host "3. Remove: Global Administrator role" -ForegroundColor White
Write-Host "4. Assign these roles:" -ForegroundColor White
foreach ($roleName in $targetRoles) {
    Write-Host "   ✅ $roleName" -ForegroundColor Green
}

Write-Host "`n🎯 Benefits of Limited Admin Access:" -ForegroundColor Cyan
Write-Host "✅ Reduced attack surface" -ForegroundColor Green
Write-Host "✅ Principle of least privilege" -ForegroundColor Green
Write-Host "✅ Better security compliance" -ForegroundColor Green
Write-Host "✅ Focused permissions for eSIM management" -ForegroundColor Green

Write-Host "`n⚠️ Important Notes:" -ForegroundColor Yellow
Write-Host "- Keep one Global Admin account for emergencies" -ForegroundColor White
Write-Host "- Test eSIM portal functionality after role changes" -ForegroundColor White
Write-Host "- Document role assignments for compliance" -ForegroundColor White