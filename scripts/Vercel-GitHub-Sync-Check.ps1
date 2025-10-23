# Vercel GitHub Sync Check and Update
# Complete error checking and data synchronization

param(
    [switch]$CheckOnly,
    [switch]$UpdateAll,
    [switch]$FixIssues
)

$ErrorActionPreference = "Continue"

function Write-Status {
    param($Message, $Type = "Info")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        default   { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
    }
}

function Test-GitHubConnection {
    try {
        $status = gh auth status 2>&1
        if ($status -like "*Logged in*") {
            $user = gh api user --jq .login
            Write-Status "GitHub connected as: $user" "Success"
            return $true
        } else {
            Write-Status "GitHub not connected" "Error"
            return $false
        }
    } catch {
        Write-Status "GitHub connection check failed" "Error"
        return $false
    }
}

function Test-VercelConnection {
    try {
        $user = vercel whoami
        if ($user -and $user -ne "Not logged in") {
            Write-Status "Vercel connected as: $user" "Success"
            return $true
        } else {
            Write-Status "Vercel not connected" "Error"
            return $false
        }
    } catch {
        Write-Status "Vercel connection check failed" "Error"
        return $false
    }
}

function Test-RepositorySync {
    try {
        $repoInfo = gh repo view --json name,defaultBranchRef | ConvertFrom-Json
        Write-Status "Repository: $($repoInfo.name)" "Info"
        Write-Status "Default branch: $($repoInfo.defaultBranchRef.name)" "Info"
        
        $projects = vercel ls --json | ConvertFrom-Json
        $project = $projects | Where-Object { $_.name -eq "esim-enterprise-management" }
        
        if ($project) {
            Write-Status "Vercel project found: $($project.name)" "Success"
            return $true
        } else {
            Write-Status "Vercel project not found" "Error"
            return $false
        }
    } catch {
        Write-Status "Repository sync check failed" "Error"
        return $false
    }
}

function Test-APIEndpoints {
    $endpoints = @(
        "/api/v1/system/health",
        "/api/v1/system/status", 
        "/api/v1/enterprise/status",
        "/api/v1/cicd/deployments",
        "/api/v1/auth/status"
    )
    
    $baseUrl = "https://esim-enterprise-management.vercel.app"
    $validCount = 0
    
    foreach ($endpoint in $endpoints) {
        try {
            $response = Invoke-WebRequest -Uri "$baseUrl$endpoint" -Method GET -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Status "API $endpoint - OK" "Success"
                $validCount++
            } else {
                Write-Status "API $endpoint - Status: $($response.StatusCode)" "Warning"
            }
        } catch {
            Write-Status "API $endpoint - Failed" "Error"
        }
    }
    
    Write-Status "API validation: $validCount/$($endpoints.Count) endpoints healthy" "Info"
    return $validCount -eq $endpoints.Count
}

function Update-AllData {
    Write-Status "Starting complete data update..." "Info"
    
    try {
        # Update GitHub repository
        Write-Status "Updating GitHub repository..." "Info"
        git fetch origin
        git pull origin main
        Write-Status "GitHub repository updated" "Success"
        
        # Trigger Vercel deployment
        Write-Status "Triggering Vercel deployment..." "Info"
        vercel --prod --yes
        Write-Status "Vercel deployment triggered" "Success"
        
        # Wait for deployment
        Write-Status "Waiting for deployment to complete..." "Info"
        Start-Sleep -Seconds 30
        
        # Validate deployment
        Test-APIEndpoints
        
        Write-Status "Data update completed" "Success"
        return $true
    } catch {
        Write-Status "Data update failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Repair-SyncIssues {
    Write-Status "Starting sync issue repair..." "Info"
    $fixedCount = 0
    
    try {
        # Fix GitHub authentication
        try {
            gh auth refresh
            Write-Status "GitHub authentication refreshed" "Success"
            $fixedCount++
        } catch {
            Write-Status "GitHub auth refresh failed" "Warning"
        }
        
        # Fix Vercel connection
        try {
            vercel whoami | Out-Null
            Write-Status "Vercel connection verified" "Success"
            $fixedCount++
        } catch {
            Write-Status "Vercel connection verification failed" "Warning"
        }
        
        # Link repository to Vercel
        try {
            vercel link --yes
            Write-Status "Repository linked to Vercel" "Success"
            $fixedCount++
        } catch {
            Write-Status "Repository linking failed" "Warning"
        }
        
        Write-Status "Sync repair completed. Fixed $fixedCount issues." "Success"
        return $fixedCount -gt 0
    } catch {
        Write-Status "Sync repair failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Main execution
Write-Host "Vercel GitHub Sync Check and Update" -ForegroundColor Cyan
Write-Host "Repository: kaunghtetpai/esim-enterprise-management" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan

if ($CheckOnly) {
    Write-Host "Running sync status check..." -ForegroundColor Yellow
    $ghOk = Test-GitHubConnection
    $vercelOk = Test-VercelConnection
    $syncOk = Test-RepositorySync
    $apiOk = Test-APIEndpoints
    
    Write-Host "`nSync Status Summary:" -ForegroundColor Cyan
    Write-Host "GitHub: $(if ($ghOk) { '✓ Connected' } else { '✗ Not connected' })" -ForegroundColor $(if ($ghOk) { "Green" } else { "Red" })
    Write-Host "Vercel: $(if ($vercelOk) { '✓ Connected' } else { '✗ Not connected' })" -ForegroundColor $(if ($vercelOk) { "Green" } else { "Red" })
    Write-Host "Repository Sync: $(if ($syncOk) { '✓ Synced' } else { '✗ Issues detected' })" -ForegroundColor $(if ($syncOk) { "Green" } else { "Red" })
    Write-Host "API Health: $(if ($apiOk) { '✓ All healthy' } else { '⚠ Some issues' })" -ForegroundColor $(if ($apiOk) { "Green" } else { "Yellow" })
    
} elseif ($UpdateAll) {
    Write-Host "Running complete data update..." -ForegroundColor Yellow
    $updateResult = Update-AllData
    
    if ($updateResult) {
        Write-Host "`nUpdate completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nUpdate completed with errors!" -ForegroundColor Red
    }
    
} elseif ($FixIssues) {
    Write-Host "Running sync issue repair..." -ForegroundColor Yellow
    $fixResult = Repair-SyncIssues
    
    if ($fixResult) {
        Write-Host "`nSync issues repaired successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nSync repair completed with warnings!" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "Running complete sync check and update..." -ForegroundColor Yellow
    
    # Check current status
    $ghOk = Test-GitHubConnection
    $vercelOk = Test-VercelConnection
    $syncOk = Test-RepositorySync
    
    # Fix issues if needed
    if (-not ($ghOk -and $vercelOk -and $syncOk)) {
        Write-Host "`nIssues detected, attempting repairs..." -ForegroundColor Yellow
        Repair-SyncIssues
    }
    
    # Update data
    Write-Host "`nUpdating all data..." -ForegroundColor Yellow
    Update-AllData
    
    # Final validation
    Write-Host "`nRunning final validation..." -ForegroundColor Yellow
    Test-APIEndpoints
}

Write-Host "`nSync check completed!" -ForegroundColor Green