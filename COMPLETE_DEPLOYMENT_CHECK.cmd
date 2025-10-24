@echo off
setlocal enabledelayedexpansion

echo ========================================
echo COMPLETE DEPLOYMENT ERROR CHECK SYSTEM
echo ========================================

:: Check GitHub Repository Status
echo [1/10] Checking GitHub Repository...
git remote -v
if !errorlevel! neq 0 (
    echo ERROR: GitHub repository not connected
    exit /b 1
)

:: Check Vercel Deployment Status
echo [2/10] Checking Vercel Deployment...
vercel --version >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Vercel CLI not installed
    npm install -g vercel
)

:: Check Microsoft Cloud Authentication
echo [3/10] Checking Microsoft Cloud Authentication...
az account show >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Azure CLI not authenticated
    az login
)

:: Check Intune PowerShell Module
echo [4/10] Checking Intune PowerShell Module...
powershell -Command "Get-Module -ListAvailable Microsoft.Graph.Intune" >nul 2>&1
if !errorlevel! neq 0 (
    echo Installing Microsoft Graph Intune module...
    powershell -Command "Install-Module Microsoft.Graph.Intune -Force"
)

:: Install All Dependencies
echo [5/10] Installing Dependencies...
call npm install
if !errorlevel! neq 0 (
    echo ERROR: Root dependencies installation failed
    exit /b 1
)

cd frontend
call npm install
if !errorlevel! neq 0 (
    echo ERROR: Frontend dependencies installation failed
    exit /b 1
)

cd ..\backend
call npm install
if !errorlevel! neq 0 (
    echo ERROR: Backend dependencies installation failed
    exit /b 1
)

cd ..

:: Build All Projects
echo [6/10] Building Projects...
call npm run build
if !errorlevel! neq 0 (
    echo ERROR: Build process failed
    exit /b 1
)

:: Deploy to Vercel
echo [7/10] Deploying to Vercel...
vercel --prod --yes
if !errorlevel! neq 0 (
    echo ERROR: Vercel deployment failed
    exit /b 1
)

:: Sync with GitHub
echo [8/10] Syncing with GitHub...
git add .
git commit -m "Complete deployment update with error checking"
git push origin main
if !errorlevel! neq 0 (
    echo ERROR: GitHub sync failed
    exit /b 1
)

:: Check Microsoft Intune Connection
echo [9/10] Checking Microsoft Intune Connection...
powershell -Command "Connect-MSGraph; Get-IntuneManagedDevice | Select-Object -First 1" >nul 2>&1
if !errorlevel! neq 0 (
    echo WARNING: Intune connection check failed - manual verification required
)

:: Final System Check
echo [10/10] Running Final System Check...
curl -f https://esim-enterprise-management.vercel.app/health >nul 2>&1
if !errorlevel! neq 0 (
    echo ERROR: Deployed application health check failed
    exit /b 1
)

echo ========================================
echo ALL DEPLOYMENTS COMPLETED SUCCESSFULLY
echo GitHub: https://github.com/kaunghtetpai/esim-enterprise-management
echo Vercel: https://vercel.com/e-sim/esim-enterprise-management
echo Production: https://esim-enterprise-management.vercel.app
echo ========================================

pause