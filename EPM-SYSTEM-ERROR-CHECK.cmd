@echo off
:: eSIM Enterprise Management Portal - Complete System Error Check
:: Comprehensive system validation and error detection for Windows

setlocal enabledelayedexpansion
title EPM Portal - System Error Check

:: Color codes
set "GREEN=[92m"
set "RED=[91m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "RESET=[0m"

echo %BLUE%===============================================%RESET%
echo %BLUE%  eSIM Enterprise Management Portal          %RESET%
echo %BLUE%  Complete System Error Check                %RESET%
echo %BLUE%===============================================%RESET%
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%ERROR: This script requires administrator privileges%RESET%
    echo %YELLOW%Please run as administrator%RESET%
    pause
    exit /b 1
)

:: Initialize error tracking
set /a TOTAL_ERRORS=0
set /a CRITICAL_ERRORS=0
set /a FIXED_ERRORS=0

:: Create error log
set "ERROR_LOG=%~dp0system-errors-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%.log"
echo System Error Check Log - %date% %time% > "%ERROR_LOG%"

echo %BLUE%Starting comprehensive system check...%RESET%
echo.

:: 1. Check Node.js and npm
echo %BLUE%[1/10] Checking Node.js and npm...%RESET%
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%✗ Node.js not installed or not in PATH%RESET%
    echo ERROR: Node.js not found >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
    set /a CRITICAL_ERRORS+=1
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo %GREEN%✓ Node.js !NODE_VERSION! installed%RESET%
)

npm --version >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%✗ npm not installed or not in PATH%RESET%
    echo ERROR: npm not found >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
) else (
    for /f "tokens=*" %%i in ('npm --version') do set NPM_VERSION=%%i
    echo %GREEN%✓ npm !NPM_VERSION! installed%RESET%
)

:: 2. Check PowerShell and required modules
echo.
echo %BLUE%[2/10] Checking PowerShell and modules...%RESET%
powershell -Command "Get-Module -ListAvailable Microsoft.Graph" >nul 2>&1
if %errorLevel% neq 0 (
    echo %RED%✗ Microsoft.Graph module not installed%RESET%
    echo ERROR: Microsoft.Graph module missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
    
    echo %YELLOW%Attempting to install Microsoft.Graph module...%RESET%
    powershell -Command "Install-Module -Name Microsoft.Graph -Force -AllowClobber" >nul 2>&1
    if !errorLevel! equ 0 (
        echo %GREEN%✓ Microsoft.Graph module installed%RESET%
        set /a FIXED_ERRORS+=1
    ) else (
        echo %RED%✗ Failed to install Microsoft.Graph module%RESET%
        set /a CRITICAL_ERRORS+=1
    )
) else (
    echo %GREEN%✓ Microsoft.Graph module installed%RESET%
)

:: 3. Check project structure
echo.
echo %BLUE%[3/10] Checking project structure...%RESET%
if not exist "package.json" (
    echo %RED%✗ package.json not found%RESET%
    echo ERROR: package.json missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
    set /a CRITICAL_ERRORS+=1
) else (
    echo %GREEN%✓ package.json found%RESET%
)

if not exist "frontend" (
    echo %RED%✗ frontend directory not found%RESET%
    echo ERROR: frontend directory missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
) else (
    echo %GREEN%✓ frontend directory found%RESET%
)

if not exist "backend" (
    echo %RED%✗ backend directory not found%RESET%
    echo ERROR: backend directory missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
) else (
    echo %GREEN%✓ backend directory found%RESET%
)

:: 4. Check environment configuration
echo.
echo %BLUE%[4/10] Checking environment configuration...%RESET%
if not exist ".env" (
    echo %YELLOW%⚠ .env file not found%RESET%
    echo WARNING: .env file missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
    
    if exist ".env.example" (
        echo %YELLOW%Copying .env.example to .env...%RESET%
        copy ".env.example" ".env" >nul 2>&1
        if !errorLevel! equ 0 (
            echo %GREEN%✓ .env file created from example%RESET%
            set /a FIXED_ERRORS+=1
        )
    )
) else (
    echo %GREEN%✓ .env file found%RESET%
)

:: 5. Check dependencies
echo.
echo %BLUE%[5/10] Checking dependencies...%RESET%
if not exist "node_modules" (
    echo %YELLOW%⚠ node_modules not found, installing dependencies...%RESET%
    npm install >nul 2>&1
    if !errorLevel! equ 0 (
        echo %GREEN%✓ Dependencies installed%RESET%
        set /a FIXED_ERRORS+=1
    ) else (
        echo %RED%✗ Failed to install dependencies%RESET%
        echo ERROR: npm install failed >> "%ERROR_LOG%"
        set /a TOTAL_ERRORS+=1
    )
) else (
    echo %GREEN%✓ node_modules found%RESET%
)

:: 6. Check database connection
echo.
echo %BLUE%[6/10] Checking database connection...%RESET%
if exist "backend\src\config\database.ts" (
    echo %GREEN%✓ Database configuration found%RESET%
) else (
    echo %RED%✗ Database configuration missing%RESET%
    echo ERROR: Database config missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
)

:: 7. Check API endpoints
echo.
echo %BLUE%[7/10] Checking API structure...%RESET%
if exist "backend\src\routes" (
    echo %GREEN%✓ API routes directory found%RESET%
) else (
    echo %RED%✗ API routes directory missing%RESET%
    echo ERROR: API routes missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
)

:: 8. Check frontend build
echo.
echo %BLUE%[8/10] Checking frontend configuration...%RESET%
if exist "frontend\package.json" (
    echo %GREEN%✓ Frontend package.json found%RESET%
) else (
    echo %RED%✗ Frontend package.json missing%RESET%
    echo ERROR: Frontend config missing >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
)

:: 9. Check system resources
echo.
echo %BLUE%[9/10] Checking system resources...%RESET%

:: Check disk space
for /f "tokens=3" %%a in ('dir /-c ^| find "bytes free"') do set DISK_FREE=%%a
set /a DISK_FREE_GB=!DISK_FREE!/1073741824
if !DISK_FREE_GB! lss 5 (
    echo %RED%✗ Low disk space: !DISK_FREE_GB!GB free%RESET%
    echo ERROR: Low disk space >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
) else (
    echo %GREEN%✓ Sufficient disk space: !DISK_FREE_GB!GB free%RESET%
)

:: Check memory
for /f "skip=1 tokens=4" %%a in ('wmic OS get TotalVisibleMemorySize /value') do (
    if not "%%a"=="" set TOTAL_MEM=%%a
)
set /a TOTAL_MEM_GB=!TOTAL_MEM!/1048576
if !TOTAL_MEM_GB! lss 4 (
    echo %YELLOW%⚠ Low system memory: !TOTAL_MEM_GB!GB%RESET%
    echo WARNING: Low memory >> "%ERROR_LOG%"
    set /a TOTAL_ERRORS+=1
) else (
    echo %GREEN%✓ Sufficient memory: !TOTAL_MEM_GB!GB%RESET%
)

:: 10. Run PowerShell system check
echo.
echo %BLUE%[10/10] Running PowerShell system diagnostics...%RESET%
if exist "scripts\System-Error-Check.ps1" (
    powershell -ExecutionPolicy Bypass -File "scripts\System-Error-Check.ps1" -QuickCheck
    if !errorLevel! equ 0 (
        echo %GREEN%✓ PowerShell diagnostics passed%RESET%
    ) else (
        echo %YELLOW%⚠ PowerShell diagnostics found issues%RESET%
        set /a TOTAL_ERRORS+=1
    )
) else (
    echo %YELLOW%⚠ PowerShell diagnostic script not found%RESET%
)

:: Summary
echo.
echo %BLUE%===============================================%RESET%
echo %BLUE%           SYSTEM CHECK SUMMARY               %RESET%
echo %BLUE%===============================================%RESET%
echo.
echo Total Errors Found: %TOTAL_ERRORS%
echo Critical Errors: %CRITICAL_ERRORS%
echo Errors Fixed: %FIXED_ERRORS%
echo.

if %CRITICAL_ERRORS% gtr 0 (
    echo %RED%SYSTEM STATUS: CRITICAL - Immediate attention required%RESET%
    echo %RED%The system has critical errors that prevent normal operation%RESET%
) else if %TOTAL_ERRORS% gtr 0 (
    echo %YELLOW%SYSTEM STATUS: WARNING - Some issues detected%RESET%
    echo %YELLOW%The system may function but with reduced reliability%RESET%
) else (
    echo %GREEN%SYSTEM STATUS: HEALTHY - All checks passed%RESET%
    echo %GREEN%The eSIM Enterprise Management Portal is ready for use%RESET%
)

echo.
echo Error log saved to: %ERROR_LOG%
echo.

:: Auto-fix prompt
if %TOTAL_ERRORS% gtr 0 (
    echo %BLUE%Would you like to attempt automatic fixes? (Y/N)%RESET%
    set /p AUTO_FIX=
    if /i "!AUTO_FIX!"=="Y" (
        echo.
        echo %BLUE%Running automatic fixes...%RESET%
        
        :: Install missing modules
        powershell -Command "Install-Module -Name Microsoft.Graph -Force -AllowClobber" >nul 2>&1
        
        :: Install dependencies
        if not exist "node_modules" (
            echo Installing Node.js dependencies...
            npm install
        )
        
        :: Create .env from example
        if not exist ".env" if exist ".env.example" (
            copy ".env.example" ".env"
        )
        
        echo %GREEN%Automatic fixes completed%RESET%
    )
)

echo.
echo %BLUE%System check completed at %date% %time%%RESET%
pause

:: Exit with appropriate code
if %CRITICAL_ERRORS% gtr 0 (
    exit /b 2
) else if %TOTAL_ERRORS% gtr 0 (
    exit /b 1
) else (
    exit /b 0
)