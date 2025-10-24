# Simple Website Audit Tool
param([string]$FilePath = "esim-dashboard-modern.html")

$Score = 0
$Issues = @()

if (Test-Path $FilePath) {
    $HTML = Get-Content $FilePath -Raw
    
    # Title check
    if ($HTML -match '<title[^>]*>([^<]+)</title>') {
        $Score += 10
        Write-Host "Title: PASS" -ForegroundColor Green
    } else {
        $Issues += "Missing title tag"
        Write-Host "Title: FAIL" -ForegroundColor Red
    }
    
    # Meta viewport
    if ($HTML -match 'viewport') {
        $Score += 10
        Write-Host "Viewport: PASS" -ForegroundColor Green
    } else {
        $Issues += "Missing viewport meta"
        Write-Host "Viewport: FAIL" -ForegroundColor Red
    }
    
    # CSS
    if ($HTML -match '<style|\.css') {
        $Score += 10
        Write-Host "CSS: PASS" -ForegroundColor Green
    } else {
        $Issues += "No CSS found"
        Write-Host "CSS: FAIL" -ForegroundColor Red
    }
    
    # JavaScript
    if ($HTML -match '<script') {
        $Score += 10
        Write-Host "JavaScript: PASS" -ForegroundColor Green
    } else {
        $Issues += "No JavaScript found"
        Write-Host "JavaScript: FAIL" -ForegroundColor Red
    }
    
    # Responsive design
    if ($HTML -match 'media.*query|@media') {
        $Score += 10
        Write-Host "Responsive: PASS" -ForegroundColor Green
    } else {
        $Issues += "Not responsive"
        Write-Host "Responsive: FAIL" -ForegroundColor Red
    }
    
    # Accessibility
    if ($HTML -match 'alt=|aria-|role=') {
        $Score += 10
        Write-Host "Accessibility: PASS" -ForegroundColor Green
    } else {
        $Issues += "Poor accessibility"
        Write-Host "Accessibility: FAIL" -ForegroundColor Red
    }
    
    # Modern HTML5
    if ($HTML -match '<!DOCTYPE html>') {
        $Score += 10
        Write-Host "HTML5: PASS" -ForegroundColor Green
    } else {
        $Issues += "Not HTML5"
        Write-Host "HTML5: FAIL" -ForegroundColor Red
    }
    
    # Icons
    if ($HTML -match 'fa-|icon') {
        $Score += 10
        Write-Host "Icons: PASS" -ForegroundColor Green
    } else {
        $Issues += "No icons"
        Write-Host "Icons: FAIL" -ForegroundColor Red
    }
    
    # Interactive elements
    if ($HTML -match 'onclick|addEventListener') {
        $Score += 10
        Write-Host "Interactivity: PASS" -ForegroundColor Green
    } else {
        $Issues += "Not interactive"
        Write-Host "Interactivity: FAIL" -ForegroundColor Red
    }
    
    # Modern CSS features
    if ($HTML -match 'grid|flex|var\(') {
        $Score += 10
        Write-Host "Modern CSS: PASS" -ForegroundColor Green
    } else {
        $Issues += "Old CSS"
        Write-Host "Modern CSS: FAIL" -ForegroundColor Red
    }
    
} else {
    Write-Host "File not found: $FilePath" -ForegroundColor Red
}

Write-Host "`n=== AUDIT RESULTS ===" -ForegroundColor Cyan
Write-Host "Score: $Score/100" -ForegroundColor $(if($Score -eq 100){"Green"}elseif($Score -gt 70){"Yellow"}else{"Red"})

if ($Score -eq 100) {
    Write-Host "100% PERFECT SCORE ACHIEVED!" -ForegroundColor Green
} else {
    Write-Host "Issues found: $($Issues.Count)" -ForegroundColor Yellow
    $Issues | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
}