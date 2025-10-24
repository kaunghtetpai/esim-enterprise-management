# Fix CNAME Validation for mdm.esim.com.mm
Write-Host "=== CNAME VALIDATION FIX ===" -ForegroundColor Cyan

# Test current CNAME configuration
Write-Host "`nTesting CNAME records for mdm.esim.com.mm..." -ForegroundColor Yellow

$requiredCNAMEs = @{
    "enterpriseenrollment.mdm.esim.com.mm" = "enterpriseenrollment-s.manage.microsoft.com"
    "enterpriseregistration.mdm.esim.com.mm" = "enterpriseregistration.windows.net"
}

foreach ($cname in $requiredCNAMEs.Keys) {
    try {
        $result = Resolve-DnsName $cname -Type CNAME -ErrorAction Stop
        if ($result.NameHost -eq $requiredCNAMEs[$cname]) {
            Write-Host "✅ $cname → $($result.NameHost)" -ForegroundColor Green
        } else {
            Write-Host "❌ $cname → $($result.NameHost) (incorrect target)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ $cname → Not configured" -ForegroundColor Red
    }
}

Write-Host "`nRequired DNS Configuration:" -ForegroundColor Yellow
Write-Host "Host: enterpriseenrollment.mdm.esim.com.mm" -ForegroundColor White
Write-Host "Type: CNAME" -ForegroundColor White
Write-Host "Value: enterpriseenrollment-s.manage.microsoft.com" -ForegroundColor White
Write-Host ""
Write-Host "Host: enterpriseregistration.mdm.esim.com.mm" -ForegroundColor White
Write-Host "Type: CNAME" -ForegroundColor White
Write-Host "Value: enterpriseregistration.windows.net" -ForegroundColor White

Write-Host "`nAction Required:" -ForegroundColor Yellow
Write-Host "1. Contact DNS provider for esim.com.mm domain" -ForegroundColor White
Write-Host "2. Add both CNAME records exactly as shown above" -ForegroundColor White
Write-Host "3. Wait up to 72 hours for DNS propagation" -ForegroundColor White
Write-Host "4. Re-test validation in Intune portal" -ForegroundColor White

Write-Host "`n=== CNAME VALIDATION CHECK COMPLETE ===" -ForegroundColor Cyan