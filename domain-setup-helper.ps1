# Domain Setup Helper for mdm.esim.com.mm
Write-Host "=== Domain Setup Helper ===" -ForegroundColor Cyan

Connect-MgGraph -Scopes "Domain.ReadWrite.All"

# Check current domains
Write-Host "Current domains in tenant:" -ForegroundColor Yellow
$domains = Get-MgDomain
foreach ($domain in $domains) {
    $status = if ($domain.IsVerified) { "✅ Verified" } else { "⚠️ Pending" }
    Write-Host "- $($domain.Id): $status" -ForegroundColor White
}

# Check if mdm.esim.com.mm exists
$targetDomain = "mdm.esim.com.mm"
$existingDomain = $domains | Where-Object { $_.Id -eq $targetDomain }

if ($existingDomain) {
    Write-Host "`nDomain $targetDomain status:" -ForegroundColor Green
    Write-Host "- Verified: $($existingDomain.IsVerified)" -ForegroundColor White
    Write-Host "- Default: $($existingDomain.IsDefault)" -ForegroundColor White
    
    if (!$existingDomain.IsVerified) {
        Write-Host "`nDNS Records needed for verification:" -ForegroundColor Yellow
        try {
            $verificationRecords = Get-MgDomainVerificationDnsRecord -DomainId $targetDomain
            foreach ($record in $verificationRecords) {
                Write-Host "Type: $($record.RecordType)" -ForegroundColor Cyan
                Write-Host "Name: $($record.Label)" -ForegroundColor White
                Write-Host "Value: $($record.Text)" -ForegroundColor White
                Write-Host "---" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Could not retrieve DNS records: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "`nDomain $targetDomain not found in tenant" -ForegroundColor Red
    Write-Host "Add it manually at: https://admin.microsoft.com/domains" -ForegroundColor Yellow
}

Write-Host "`n=== DNS Setup Instructions ===" -ForegroundColor Cyan
Write-Host "1. Add these DNS records to your domain registrar:" -ForegroundColor Yellow
Write-Host "   - TXT record for verification" -ForegroundColor White
Write-Host "   - MX record for email (optional)" -ForegroundColor White
Write-Host "2. Wait for DNS propagation (up to 24 hours)" -ForegroundColor White
Write-Host "3. Return to admin center to verify domain" -ForegroundColor White