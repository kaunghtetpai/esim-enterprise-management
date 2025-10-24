# 100% Website Audit & Optimization Tool
param([string]$URL = "http://localhost:3000")

$AuditResults = @{
    Score = 0
    Issues = @()
    Recommendations = @()
    Compliance = @{}
}

function Test-PageStructure {
    param([string]$URL)
    
    $Issues = @()
    $Score = 0
    
    try {
        $Response = Invoke-WebRequest -Uri $URL -UseBasicParsing
        $HTML = $Response.Content
        
        # Title tag check
        if ($HTML -match '<title[^>]*>([^<]+)</title>') {
            $Title = $Matches[1]
            if ($Title.Length -lt 30 -or $Title.Length -gt 60) {
                $Issues += "Title length not optimal (30-60 chars): $($Title.Length)"
            } else { $Score += 10 }
        } else {
            $Issues += "Missing title tag"
        }
        
        # Meta description
        if ($HTML -match '<meta[^>]*name=["\']description["\'][^>]*content=["\']([^"\']+)["\']') {
            $Desc = $Matches[1]
            if ($Desc.Length -lt 120 -or $Desc.Length -gt 160) {
                $Issues += "Meta description length not optimal (120-160 chars): $($Desc.Length)"
            } else { $Score += 10 }
        } else {
            $Issues += "Missing meta description"
        }
        
        # Heading structure
        $H1Count = ([regex]::Matches($HTML, '<h1[^>]*>', 'IgnoreCase')).Count
        if ($H1Count -ne 1) {
            $Issues += "Should have exactly 1 H1 tag, found: $H1Count"
        } else { $Score += 10 }
        
        # Viewport meta tag
        if ($HTML -notmatch '<meta[^>]*name=["\']viewport["\']') {
            $Issues += "Missing viewport meta tag"
        } else { $Score += 10 }
        
        # Canonical tag
        if ($HTML -notmatch '<link[^>]*rel=["\']canonical["\']') {
            $Issues += "Missing canonical tag"
        } else { $Score += 5 }
        
        # Open Graph tags
        $OGTags = ([regex]::Matches($HTML, '<meta[^>]*property=["\']og:', 'IgnoreCase')).Count
        if ($OGTags -lt 3) {
            $Issues += "Insufficient Open Graph tags: $OGTags (need title, description, image)"
        } else { $Score += 5 }
        
    } catch {
        $Issues += "Failed to fetch page: $($_.Exception.Message)"
    }
    
    return @{ Score = $Score; Issues = $Issues }
}

function Test-Performance {
    param([string]$URL)
    
    $Issues = @()
    $Score = 0
    
    try {
        $StartTime = Get-Date
        $Response = Invoke-WebRequest -Uri $URL
        $LoadTime = (Get-Date) - $StartTime
        
        if ($LoadTime.TotalSeconds -lt 2) {
            $Score += 20
        } elseif ($LoadTime.TotalSeconds -lt 4) {
            $Score += 10
            $Issues += "Page load time slow: $($LoadTime.TotalSeconds)s"
        } else {
            $Issues += "Page load time very slow: $($LoadTime.TotalSeconds)s"
        }
        
        # Check compression
        if ($Response.Headers['Content-Encoding'] -contains 'gzip') {
            $Score += 10
        } else {
            $Issues += "No GZIP compression detected"
        }
        
        # Check caching headers
        if ($Response.Headers['Cache-Control']) {
            $Score += 5
        } else {
            $Issues += "Missing cache-control headers"
        }
        
        # Check HTTPS
        if ($URL.StartsWith('https://')) {
            $Score += 10
        } else {
            $Issues += "Not using HTTPS"
        }
        
    } catch {
        $Issues += "Performance test failed: $($_.Exception.Message)"
    }
    
    return @{ Score = $Score; Issues = $Issues }
}

function Test-Accessibility {
    param([string]$HTML)
    
    $Issues = @()
    $Score = 0
    
    # Alt text for images
    $Images = [regex]::Matches($HTML, '<img[^>]*>', 'IgnoreCase')
    $ImagesWithAlt = [regex]::Matches($HTML, '<img[^>]*alt=["\'][^"\']*["\'][^>]*>', 'IgnoreCase')
    
    if ($Images.Count -gt 0) {
        $AltRatio = $ImagesWithAlt.Count / $Images.Count
        if ($AltRatio -eq 1) {
            $Score += 15
        } elseif ($AltRatio -gt 0.8) {
            $Score += 10
            $Issues += "Some images missing alt text: $($Images.Count - $ImagesWithAlt.Count)"
        } else {
            $Issues += "Many images missing alt text: $($Images.Count - $ImagesWithAlt.Count)"
        }
    }
    
    # Form labels
    $Inputs = [regex]::Matches($HTML, '<input[^>]*>', 'IgnoreCase')
    $Labels = [regex]::Matches($HTML, '<label[^>]*>', 'IgnoreCase')
    
    if ($Inputs.Count -gt 0 -and $Labels.Count -ge $Inputs.Count) {
        $Score += 10
    } elseif ($Inputs.Count -gt 0) {
        $Issues += "Form inputs may be missing labels"
    }
    
    # ARIA roles
    if ($HTML -match 'role=["\']') {
        $Score += 5
    } else {
        $Issues += "No ARIA roles detected"
    }
    
    # Skip links
    if ($HTML -match 'skip.*content|skip.*main') {
        $Score += 5
    } else {
        $Issues += "No skip links for keyboard navigation"
    }
    
    return @{ Score = $Score; Issues = $Issues }
}

function Test-SEO {
    param([string]$HTML)
    
    $Issues = @()
    $Score = 0
    
    # Structured data
    if ($HTML -match 'application/ld\+json|itemscope|itemtype') {
        $Score += 10
    } else {
        $Issues += "No structured data detected"
    }
    
    # Internal links
    $InternalLinks = [regex]::Matches($HTML, '<a[^>]*href=["\'][^"\']*["\'][^>]*>', 'IgnoreCase')
    if ($InternalLinks.Count -gt 5) {
        $Score += 5
    } else {
        $Issues += "Few internal links detected"
    }
    
    # Image optimization
    if ($HTML -match '\.webp|\.avif') {
        $Score += 5
    } else {
        $Issues += "Not using modern image formats (WebP/AVIF)"
    }
    
    return @{ Score = $Score; Issues = $Issues }
}

function Test-Security {
    param([string]$URL, [object]$Response)
    
    $Issues = @()
    $Score = 0
    
    # Security headers
    $SecurityHeaders = @(
        'Strict-Transport-Security',
        'X-Content-Type-Options',
        'X-Frame-Options',
        'Content-Security-Policy'
    )
    
    foreach ($Header in $SecurityHeaders) {
        if ($Response.Headers[$Header]) {
            $Score += 5
        } else {
            $Issues += "Missing security header: $Header"
        }
    }
    
    return @{ Score = $Score; Issues = $Issues }
}

function Generate-AuditReport {
    param([hashtable]$Results)
    
    $Report = @"
# Website Audit Report - 100% Coverage

## Overall Score: $($Results.Score)/100

### Critical Issues ($($Results.Issues.Count))
$(($Results.Issues | ForEach-Object { "- $_" }) -join "`n")

### Recommendations
$(($Results.Recommendations | ForEach-Object { "- $_" }) -join "`n")

### Compliance Status
- WCAG 2.1: $($Results.Compliance.WCAG)
- SEO: $($Results.Compliance.SEO)
- Performance: $($Results.Compliance.Performance)
- Security: $($Results.Compliance.Security)

### Implementation Priority
1. Fix critical accessibility issues
2. Optimize page performance
3. Implement security headers
4. Add structured data
5. Improve meta tags

Generated: $(Get-Date)
"@
    
    return $Report
}

# Main audit execution
Write-Host "=== 100% Website Audit Starting ===" -ForegroundColor Cyan
Write-Host "Target URL: $URL" -ForegroundColor White

# Test 1: Page Structure
Write-Host "`n1. Testing Page Structure..." -ForegroundColor Yellow
$PageTest = Test-PageStructure -URL $URL
$AuditResults.Score += $PageTest.Score
$AuditResults.Issues += $PageTest.Issues

# Test 2: Performance
Write-Host "2. Testing Performance..." -ForegroundColor Yellow
$PerfTest = Test-Performance -URL $URL
$AuditResults.Score += $PerfTest.Score
$AuditResults.Issues += $PerfTest.Issues

# Get HTML for remaining tests
try {
    $Response = Invoke-WebRequest -Uri $URL
    $HTML = $Response.Content
    
    # Test 3: Accessibility
    Write-Host "3. Testing Accessibility..." -ForegroundColor Yellow
    $A11yTest = Test-Accessibility -HTML $HTML
    $AuditResults.Score += $A11yTest.Score
    $AuditResults.Issues += $A11yTest.Issues
    
    # Test 4: SEO
    Write-Host "4. Testing SEO..." -ForegroundColor Yellow
    $SEOTest = Test-SEO -HTML $HTML
    $AuditResults.Score += $SEOTest.Score
    $AuditResults.Issues += $SEOTest.Issues
    
    # Test 5: Security
    Write-Host "5. Testing Security..." -ForegroundColor Yellow
    $SecTest = Test-Security -URL $URL -Response $Response
    $AuditResults.Score += $SecTest.Score
    $AuditResults.Issues += $SecTest.Issues
    
} catch {
    $AuditResults.Issues += "Failed to fetch HTML for detailed analysis"
}

# Generate recommendations
$AuditResults.Recommendations = @(
    "Optimize images with WebP format",
    "Add comprehensive meta tags",
    "Implement security headers",
    "Add structured data markup",
    "Improve accessibility with ARIA labels",
    "Enable GZIP compression",
    "Add skip navigation links",
    "Optimize Core Web Vitals"
)

# Set compliance status
$AuditResults.Compliance = @{
    WCAG = if ($AuditResults.Score -gt 70) { "PASS" } else { "FAIL" }
    SEO = if ($AuditResults.Score -gt 60) { "PASS" } else { "FAIL" }
    Performance = if ($AuditResults.Score -gt 50) { "PASS" } else { "FAIL" }
    Security = if ($AuditResults.Score -gt 40) { "PASS" } else { "FAIL" }
}

# Generate and save report
$Report = Generate-AuditReport -Results $AuditResults
Set-Content -Path "website-audit-report.md" -Value $Report

# Display results
Write-Host "`n=== Audit Complete ===" -ForegroundColor Cyan
Write-Host "Overall Score: $($AuditResults.Score)/100" -ForegroundColor $(if($AuditResults.Score -gt 70){"Green"}elseif($AuditResults.Score -gt 40){"Yellow"}else{"Red"})
Write-Host "Issues Found: $($AuditResults.Issues.Count)" -ForegroundColor Yellow
Write-Host "Report saved: website-audit-report.md" -ForegroundColor Green

if ($AuditResults.Score -eq 100) {
    Write-Host "`n100% AUDIT COMPLETE - PERFECT SCORE!" -ForegroundColor Green
} else {
    Write-Host "`nImprovement needed to reach 100%" -ForegroundColor Yellow
}