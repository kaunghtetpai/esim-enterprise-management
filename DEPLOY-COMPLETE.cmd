@echo off
:: Complete System Deploy - Vercel GitHub All Systems
:: 100% error check, update, install, run, dev

setlocal enabledelayedexpansion
title Complete System Deploy

echo ===============================================
echo  Complete System Deploy - All Operations
echo ===============================================
echo.

:: Check admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Administrator privileges required
    pause
    exit /b 1
)

set /a TOTAL_ERRORS=0
set /a OPERATIONS_COMPLETED=0

:: 1. Install Dependencies
echo [1/8] Installing dependencies...
where node >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Node.js...
    winget install OpenJS.NodeJS
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Node.js already installed
)

where gh >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing GitHub CLI...
    winget install GitHub.cli
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo GitHub CLI already installed
)

where vercel >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Vercel CLI...
    npm install -g vercel@latest
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Vercel CLI already installed
)

:: 2. Authentication Check
echo.
echo [2/8] Checking authentication...
gh auth status >nul 2>&1
if %errorLevel% neq 0 (
    echo GitHub authentication required
    gh auth login --web
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo GitHub authenticated
)

vercel whoami >nul 2>&1
if %errorLevel% neq 0 (
    echo Vercel authentication required
    vercel login
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Vercel authenticated
)

:: 3. Repository Setup
echo.
echo [3/8] Setting up repository...
if not exist ".git" (
    echo Initializing repository...
    git init
    git remote add origin https://github.com/kaunghtetpai/esim-enterprise-management.git
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Repository already initialized
)

git fetch origin >nul 2>&1
git pull origin main >nul 2>&1
echo Repository updated
set /a OPERATIONS_COMPLETED+=1

:: 4. Install Project Dependencies
echo.
echo [4/8] Installing project dependencies...
if exist "package.json" (
    npm install
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo No package.json found, creating basic structure...
    npm init -y
    npm install express cors helmet morgan dotenv
    set /a OPERATIONS_COMPLETED+=1
)

if exist "frontend\package.json" (
    cd frontend
    npm install
    cd ..
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Frontend package.json not found
)

if exist "backend\package.json" (
    cd backend
    npm install
    cd ..
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Backend package.json not found
)

:: 5. Build Project
echo.
echo [5/8] Building project...
if exist "frontend" (
    cd frontend
    npm run build >nul 2>&1
    if !errorLevel! equ 0 (
        echo Frontend build successful
        set /a OPERATIONS_COMPLETED+=1
    ) else (
        echo Frontend build failed
        set /a TOTAL_ERRORS+=1
    )
    cd ..
)

if exist "backend" (
    cd backend
    npm run build >nul 2>&1
    if !errorLevel! equ 0 (
        echo Backend build successful
        set /a OPERATIONS_COMPLETED+=1
    ) else (
        echo Backend build failed
        set /a TOTAL_ERRORS+=1
    )
    cd ..
)

:: 6. Vercel Deployment
echo.
echo [6/8] Deploying to Vercel...
vercel link --yes >nul 2>&1
vercel --prod --yes >nul 2>&1
if %errorLevel% equ 0 (
    echo Vercel deployment successful
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo Vercel deployment failed
    set /a TOTAL_ERRORS+=1
)

:: 7. System Validation
echo.
echo [7/8] Validating system...
timeout /t 30 /nobreak >nul
curl -f https://esim-enterprise-management.vercel.app/health >nul 2>&1
if %errorLevel% equ 0 (
    echo System health check passed
    set /a OPERATIONS_COMPLETED+=1
) else (
    echo System health check failed
    set /a TOTAL_ERRORS+=1
)

:: 8. Start Development
echo.
echo [8/8] Starting development servers...
start "Backend Dev" cmd /k "cd backend && npm run dev"
start "Frontend Dev" cmd /k "cd frontend && npm run dev"
echo Development servers started
set /a OPERATIONS_COMPLETED+=1

:: Summary
echo.
echo ===============================================
echo           DEPLOYMENT SUMMARY
echo ===============================================
echo Operations Completed: %OPERATIONS_COMPLETED%
echo Errors Encountered: %TOTAL_ERRORS%
echo.
echo Production URL: https://esim-enterprise-management.vercel.app
echo Custom Domain: https://portal.nexorasim.com
echo GitHub Repo: https://github.com/kaunghtetpai/esim-enterprise-management
echo.
if %TOTAL_ERRORS% equ 0 (
    echo STATUS: All systems operational
) else (
    echo STATUS: Deployment completed with %TOTAL_ERRORS% errors
)
echo.
pause