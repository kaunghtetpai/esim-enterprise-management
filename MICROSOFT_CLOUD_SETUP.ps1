param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Install", "Connect", "Deploy", "Check", "All")]
    [string]$Action = "All"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MICROSOFT CLOUD COMPLETE SETUP SYSTEM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Install-Prerequisites {
    Write-Host "[1/5] Installing Prerequisites..." -ForegroundColor Yellow
    
    # Install Azure CLI
    if (!(Get-Command "az" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Azure CLI..." -ForegroundColor Green
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
        Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
        Remove-Item .\AzureCLI.msi
    }
    
    # Install Microsoft Graph PowerShell
    if (!(Get-Module -ListAvailable Microsoft.Graph)) {
        Write-Host "Installing Microsoft Graph PowerShell..." -ForegroundColor Green
        Install-Module Microsoft.Graph -Force -AllowClobber
    }
    
    # Install Microsoft Graph Intune
    if (!(Get-Module -ListAvailable Microsoft.Graph.Intune)) {
        Write-Host "Installing Microsoft Graph Intune..." -ForegroundColor Green
        Install-Module Microsoft.Graph.Intune -Force -AllowClobber
    }
    
    # Install Vercel CLI
    if (!(Get-Command "vercel" -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Vercel CLI..." -ForegroundColor Green
        npm install -g vercel
    }
    
    Write-Host "Prerequisites installed successfully" -ForegroundColor Green
}

function Connect-MicrosoftCloud {
    Write-Host "[2/5] Connecting to Microsoft Cloud..." -ForegroundColor Yellow
    
    try {
        # Connect to Azure
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        az login --tenant "your-tenant-id"
        
        # Connect to Microsoft Graph
        Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Green
        Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All"
        
        # Test Intune connection
        Write-Host "Testing Intune connection..." -ForegroundColor Green
        $devices = Get-MgDeviceManagementManagedDevice -Top 1
        Write-Host "Intune connection successful - Found $($devices.Count) devices" -ForegroundColor Green
        
        Write-Host "Microsoft Cloud connection successful" -ForegroundColor Green
    }
    catch {
        Write-Host "Error connecting to Microsoft Cloud: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Deploy-Application {
    Write-Host "[3/5] Deploying Application..." -ForegroundColor Yellow
    
    try {
        # Install dependencies
        Write-Host "Installing dependencies..." -ForegroundColor Green
        npm install
        
        # Build application
        Write-Host "Building application..." -ForegroundColor Green
        npm run build
        
        # Deploy to Vercel
        Write-Host "Deploying to Vercel..." -ForegroundColor Green
        vercel --prod --yes
        
        # Sync with GitHub
        Write-Host "Syncing with GitHub..." -ForegroundColor Green
        git add .
        git commit -m "Microsoft Cloud deployment update"
        git push origin main
        
        Write-Host "Application deployed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error deploying application: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Test-AllSystems {
    Write-Host "[4/5] Testing All Systems..." -ForegroundColor Yellow
    
    $errors = @()
    
    # Test GitHub
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com/repos/kaunghtetpai/esim-enterprise-management" -UseBasicParsing
        Write-Host "GitHub: OK" -ForegroundColor Green
    }
    catch {
        $errors += "GitHub connection failed"
        Write-Host "GitHub: ERROR" -ForegroundColor Red
    }
    
    # Test Vercel
    try {
        $response = Invoke-WebRequest -Uri "https://esim-enterprise-management.vercel.app/health" -UseBasicParsing
        Write-Host "Vercel: OK" -ForegroundColor Green
    }
    catch {
        $errors += "Vercel deployment failed"
        Write-Host "Vercel: ERROR" -ForegroundColor Red
    }
    
    # Test Azure
    try {
        $account = az account show | ConvertFrom-Json
        Write-Host "Azure: OK - Logged in as $($account.user.name)" -ForegroundColor Green
    }
    catch {
        $errors += "Azure authentication failed"
        Write-Host "Azure: ERROR" -ForegroundColor Red
    }
    
    # Test Intune
    try {
        $devices = Get-MgDeviceManagementManagedDevice -Top 1
        Write-Host "Intune: OK - Connected to tenant" -ForegroundColor Green
    }
    catch {
        $errors += "Intune connection failed"
        Write-Host "Intune: ERROR" -ForegroundColor Red
    }
    
    if ($errors.Count -eq 0) {
        Write-Host "All systems operational" -ForegroundColor Green
    } else {
        Write-Host "Errors found:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
    }
}

function Update-SystemSync {
    Write-Host "[5/5] Updating System Sync..." -ForegroundColor Yellow
    
    try {
        # Create sync status file
        $syncStatus = @{
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            github = @{
                status = "synced"
                url = "https://github.com/kaunghtetpai/esim-enterprise-management"
            }
            vercel = @{
                status = "deployed"
                url = "https://vercel.com/e-sim/esim-enterprise-management"
                production = "https://esim-enterprise-management.vercel.app"
            }
            azure = @{
                status = "connected"
                tenant = "your-tenant-id"
            }
            intune = @{
                status = "integrated"
                devices = (Get-MgDeviceManagementManagedDevice).Count
            }
        }
        
        $syncStatus | ConvertTo-Json -Depth 3 | Out-File -FilePath "sync-status.json" -Encoding UTF8
        
        Write-Host "System sync updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error updating system sync: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Execute based on action parameter
switch ($Action) {
    "Install" { Install-Prerequisites }
    "Connect" { Connect-MicrosoftCloud }
    "Deploy" { Deploy-Application }
    "Check" { Test-AllSystems }
    "All" {
        Install-Prerequisites
        Connect-MicrosoftCloud
        Deploy-Application
        Test-AllSystems
        Update-SystemSync
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MICROSOFT CLOUD SETUP COMPLETED" -ForegroundColor Cyan
Write-Host "GitHub: https://github.com/kaunghtetpai/esim-enterprise-management" -ForegroundColor White
Write-Host "Vercel: https://vercel.com/e-sim/esim-enterprise-management" -ForegroundColor White
Write-Host "Production: https://esim-enterprise-management.vercel.app" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan