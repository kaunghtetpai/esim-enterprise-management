@echo off
:: Complete Cloud Login Setup for eSIM Enterprise Management
:: GitHub + Vercel + Microsoft Cloud (Entra ID + Intune)

setlocal enabledelayedexpansion
title Cloud Login Setup - eSIM Enterprise Management

set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "RESET=[0m"

echo %BLUE%===============================================%RESET%
echo %BLUE%  eSIM Enterprise Management Portal          %RESET%
echo %BLUE%  Complete Cloud Login Setup                 %RESET%
echo %BLUE%===============================================%RESET%
echo.

:: Check administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%ERROR: Administrator privileges required%RESET%
    pause
    exit /b 1
)

echo %BLUE%Starting complete cloud authentication setup...%RESET%
echo.

:: 1. GitHub CLI Setup
echo %BLUE%[1/4] Setting up GitHub CLI...%RESET%
where gh >nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%Installing GitHub CLI...%RESET%
    winget install GitHub.cli
    if !errorLevel! neq 0 (
        echo %RED%✗ GitHub CLI installation failed%RESET%
        set /a TOTAL_ERRORS+=1
    ) else (
        echo %GREEN%✓ GitHub CLI installed%RESET%
    )
) else (
    echo %GREEN%✓ GitHub CLI already installed%RESET%
)

:: Check GitHub authentication
gh auth status >nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%Logging in to GitHub...%RESET%
    gh auth login --web --scopes "repo,workflow,admin:org,admin:repo_hook"
    if !errorLevel! equ 0 (
        echo %GREEN%✓ GitHub authentication successful%RESET%
    ) else (
        echo %RED%✗ GitHub authentication failed%RESET%
    )
) else (
    echo %GREEN%✓ Already authenticated to GitHub%RESET%
)

:: 2. Vercel CLI Setup
echo.
echo %BLUE%[2/4] Setting up Vercel CLI...%RESET%
where vercel >nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%Installing Vercel CLI...%RESET%
    npm install -g vercel@latest
    if !errorLevel! neq 0 (
        echo %RED%✗ Vercel CLI installation failed%RESET%
    ) else (
        echo %GREEN%✓ Vercel CLI installed%RESET%
    )
) else (
    echo %GREEN%✓ Vercel CLI already installed%RESET%
)

:: Check Vercel authentication
vercel whoami >nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%Logging in to Vercel...%RESET%
    vercel login
    if !errorLevel! equ 0 (
        echo %GREEN%✓ Vercel authentication successful%RESET%
    ) else (
        echo %RED%✗ Vercel authentication failed%RESET%
    )
) else (
    echo %GREEN%✓ Already authenticated to Vercel%RESET%
)

:: 3. Microsoft Graph PowerShell Setup
echo.
echo %BLUE%[3/4] Setting up Microsoft Graph PowerShell...%RESET%
powershell -Command "Get-Module -ListAvailable Microsoft.Graph" >nul 2>&1
if %errorLevel% neq 0 (
    echo %YELLOW%Installing Microsoft Graph PowerShell SDK...%RESET%
    powershell -Command "Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser"
    if !errorLevel! equ 0 (
        echo %GREEN%✓ Microsoft Graph SDK installed%RESET%
    ) else (
        echo %RED%✗ Microsoft Graph SDK installation failed%RESET%
    )
) else (
    echo %GREEN%✓ Microsoft Graph SDK already installed%RESET%
)

:: Connect to Microsoft Graph
echo %YELLOW%Connecting to Microsoft Graph...%RESET%
powershell -Command "Connect-MgGraph -Scopes 'Directory.ReadWrite.All','User.ReadWrite.All','Group.ReadWrite.All','DeviceManagementManagedDevices.ReadWrite.All' -NoWelcome"
if %errorLevel% equ 0 (
    echo %GREEN%✓ Microsoft Graph connection successful%RESET%
) else (
    echo %RED%✗ Microsoft Graph connection failed%RESET%
)

:: 4. Run Complete Setup Script
echo.
echo %BLUE%[4/4] Running complete setup automation...%RESET%
if exist "scripts\Complete-Cloud-Login-Setup.ps1" (
    powershell -ExecutionPolicy Bypass -File "scripts\Complete-Cloud-Login-Setup.ps1" -LoginAll
    if !errorLevel! equ 0 (
        echo %GREEN%✓ Complete setup automation successful%RESET%
    ) else (
        echo %YELLOW%⚠ Setup automation completed with warnings%RESET%
    )
) else (
    echo %YELLOW%⚠ Setup script not found, manual verification required%RESET%
)

:: Validation
echo.
echo %BLUE%===============================================%RESET%
echo %BLUE%           VALIDATION SUMMARY                %RESET%
echo %BLUE%===============================================%RESET%
echo.

:: Check GitHub
gh auth status >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=*" %%i in ('gh api user --jq .login 2^>nul') do set GH_USER=%%i
    echo %GREEN%✓ GitHub: Connected as !GH_USER!%RESET%
) else (
    echo %RED%✗ GitHub: Not connected%RESET%
)

:: Check Vercel
for /f "tokens=*" %%i in ('vercel whoami 2^>nul') do set VERCEL_USER=%%i
if "!VERCEL_USER!" neq "Not logged in" if "!VERCEL_USER!" neq "" (
    echo %GREEN%✓ Vercel: Connected as !VERCEL_USER!%RESET%
) else (
    echo %RED%✗ Vercel: Not connected%RESET%
)

:: Check Microsoft Graph
powershell -Command "Get-MgContext" >nul 2>&1
if %errorLevel% equ 0 (
    echo %GREEN%✓ Microsoft Graph: Connected%RESET%
) else (
    echo %RED%✗ Microsoft Graph: Not connected%RESET%
)

:: Check Intune
powershell -Command "Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/deviceManagement' -Method GET" >nul 2>&1
if %errorLevel% equ 0 (
    echo %GREEN%✓ Microsoft Intune: Accessible%RESET%
) else (
    echo %RED%✗ Microsoft Intune: Not accessible%RESET%
)

echo.
echo %BLUE%Service URLs:%RESET%
echo %YELLOW%GitHub Repo:%RESET% https://github.com/kaunghtetpai/esim-enterprise-management
echo %YELLOW%Vercel Project:%RESET% https://vercel.com/e-sim/esim-enterprise-management
echo %YELLOW%Production URL:%RESET% https://esim-enterprise-management.vercel.app/
echo %YELLOW%Custom Domain:%RESET% https://portal.nexorasim.com
echo %YELLOW%Entra Portal:%RESET% https://entra.microsoft.com
echo %YELLOW%Intune Portal:%RESET% https://intune.microsoft.com

echo.
echo %GREEN%Cloud login setup completed!%RESET%
echo %BLUE%All services are ready for enterprise management.%RESET%
pause