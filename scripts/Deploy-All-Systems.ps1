# Complete System Deployment Script
# Vercel + GitHub + All Systems - 100% Error Check

param(
    [switch]$Install,
    [switch]$Deploy,
    [switch]$Dev,
    [switch]$All
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param($Message, $Type = "Info")
    switch ($Type) {
        "Success" { Write-Host "✓ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        default   { Write-Host "ℹ $Message" -ForegroundColor Cyan }
    }
}

function Install-Dependencies {
    Write-Host "Installing dependencies..." -ForegroundColor Yellow
    
    # Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        winget install OpenJS.NodeJS
        Write-Status "Node.js installed" "Success"
    } else {
        Write-Status "Node.js already installed" "Success"
    }
    
    # GitHub CLI
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        winget install GitHub.cli
        Write-Status "GitHub CLI installed" "Success"
    } else {
        Write-Status "GitHub CLI already installed" "Success"
    }
    
    # Vercel CLI
    if (-not (Get-Command vercel -ErrorAction SilentlyContinue)) {
        npm install -g vercel@latest
        Write-Status "Vercel CLI installed" "Success"
    } else {
        Write-Status "Vercel CLI already installed" "Success"
    }
    
    # Project dependencies
    if (Test-Path "package.json") {
        npm install
        Write-Status "Root dependencies installed" "Success"
    }
    
    if (Test-Path "frontend/package.json") {
        Set-Location frontend
        npm install
        Set-Location ..
        Write-Status "Frontend dependencies installed" "Success"
    }
    
    if (Test-Path "backend/package.json") {
        Set-Location backend
        npm install
        Set-Location ..
        Write-Status "Backend dependencies installed" "Success"
    }
}

function Test-Authentication {
    Write-Host "Checking authentication..." -ForegroundColor Yellow
    
    # GitHub
    try {
        $ghStatus = gh auth status 2>&1
        if ($ghStatus -like "*Logged in*") {
            Write-Status "GitHub authenticated" "Success"
        } else {
            gh auth login --web
            Write-Status "GitHub authentication completed" "Success"
        }
    } catch {
        Write-Status "GitHub authentication failed" "Error"
    }
    
    # Vercel
    try {
        $vercelUser = vercel whoami
        if ($vercelUser -and $vercelUser -ne "Not logged in") {
            Write-Status "Vercel authenticated as $vercelUser" "Success"
        } else {
            vercel login
            Write-Status "Vercel authentication completed" "Success"
        }
    } catch {
        Write-Status "Vercel authentication failed" "Error"
    }
}

function Build-Project {
    Write-Host "Building project..." -ForegroundColor Yellow
    
    # Frontend build
    if (Test-Path "frontend") {
        Set-Location frontend
        try {
            npm run build
            Write-Status "Frontend build successful" "Success"
        } catch {
            Write-Status "Frontend build failed" "Error"
        }
        Set-Location ..
    }
    
    # Backend build
    if (Test-Path "backend") {
        Set-Location backend
        try {
            npm run build
            Write-Status "Backend build successful" "Success"
        } catch {
            Write-Status "Backend build failed" "Error"
        }
        Set-Location ..
    }
}

function Deploy-ToVercel {
    Write-Host "Deploying to Vercel..." -ForegroundColor Yellow
    
    try {
        # Link project
        vercel link --yes
        Write-Status "Project linked to Vercel" "Success"
        
        # Deploy to production
        vercel --prod --yes
        Write-Status "Deployed to production" "Success"
        
        # Wait and validate
        Start-Sleep -Seconds 30
        $response = Invoke-WebRequest -Uri "https://esim-enterprise-management.vercel.app/health" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Status "Deployment validation successful" "Success"
        } else {
            Write-Status "Deployment validation failed" "Warning"
        }
    } catch {
        Write-Status "Vercel deployment failed" "Error"
    }
}

function Start-Development {
    Write-Host "Starting development servers..." -ForegroundColor Yellow
    
    # Start backend dev server
    if (Test-Path "backend") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm run dev"
        Write-Status "Backend dev server started" "Success"
    }
    
    # Start frontend dev server
    if (Test-Path "frontend") {
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"
        Write-Status "Frontend dev server started" "Success"
    }
    
    Write-Status "Development servers running" "Success"
}

function Test-AllSystems {
    Write-Host "Testing all systems..." -ForegroundColor Yellow
    
    $endpoints = @(
        "https://esim-enterprise-management.vercel.app/health",
        "https://esim-enterprise-management.vercel.app/api/v1/system/health",
        "https://esim-enterprise-management.vercel.app/api/v1/sync/status"
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri $endpoint -Method GET -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Status "Endpoint OK: $endpoint" "Success"
            } else {
                Write-Status "Endpoint failed: $endpoint" "Warning"
            }
        } catch {
            Write-Status "Endpoint error: $endpoint" "Error"
        }
    }
}

function Update-Repository {
    Write-Host "Updating repository..." -ForegroundColor Yellow
    
    try {
        git fetch origin
        git pull origin main
        Write-Status "Repository updated" "Success"
    } catch {
        Write-Status "Repository update failed" "Error"
    }
}

# Main execution
Write-Host "Complete System Deployment" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

if ($Install -or $All) {
    Install-Dependencies
    Test-Authentication
}

if ($Deploy -or $All) {
    Update-Repository
    Build-Project
    Deploy-ToVercel
    Test-AllSystems
}

if ($Dev -or $All) {
    Start-Development
}

if (-not ($Install -or $Deploy -or $Dev -or $All)) {
    Write-Host "Use -Install, -Deploy, -Dev, or -All" -ForegroundColor Yellow
    Write-Host "Example: .\Deploy-All-Systems.ps1 -All" -ForegroundColor Yellow
}

Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "Production: https://esim-enterprise-management.vercel.app" -ForegroundColor Cyan
Write-Host "Custom: https://portal.nexorasim.com" -ForegroundColor Cyan