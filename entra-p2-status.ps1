# Microsoft Entra ID P2 Status Check
Write-Host "=== Microsoft Entra ID P2 Status ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes "Directory.Read.All","User.Read.All" -NoWelcome

$context = Get-MgContext
$org = Get-MgOrganization
$licenses = Get-MgSubscribedSku

Write-Host "`nTenant Information:" -ForegroundColor Yellow
Write-Host "Organization: $($org.DisplayName)" -ForegroundColor White
Write-Host "Tenant ID: $($context.TenantId)" -ForegroundColor White
Write-Host "Account: $($context.Account)" -ForegroundColor White

Write-Host "`nEntra ID P2 License Status:" -ForegroundColor Yellow
$entraSuite = $licenses | Where-Object { $_.SkuPartNumber -eq "Microsoft_Entra_Suite" }
if ($entraSuite) {
    $available = $entraSuite.PrepaidUnits.Enabled - $entraSuite.ConsumedUnits
    Write-Host "✅ Microsoft Entra Suite: $available/$($entraSuite.PrepaidUnits.Enabled) available" -ForegroundColor Green
} else {
    Write-Host "❌ Microsoft Entra Suite not found" -ForegroundColor Red
}

Write-Host "`nAdmin Role Status:" -ForegroundColor Yellow
try {
    $admin = Get-MgUser -UserId $context.Account
    $roles = Get-MgUserMemberOf -UserId $admin.Id | Where-Object { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.directoryRole' }
    Write-Host "Admin Roles: $($roles.Count)" -ForegroundColor White
    foreach ($role in $roles) {
        Write-Host "  - $($role.AdditionalProperties.displayName)" -ForegroundColor Green
    }
} catch {
    Write-Host "Could not retrieve role information" -ForegroundColor Yellow
}

Write-Host "`n=== Status Check Complete ===" -ForegroundColor Cyan