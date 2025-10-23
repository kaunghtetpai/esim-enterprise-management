# Complete System Error Check and Update
# 100% system validation with create, update, delete operations

param(
    [switch]$CheckAll,
    [switch]$UpdateAll,
    [switch]$FixAll,
    [switch]$CreateBackup,
    [switch]$DeleteOld,
    [switch]$ClearErrors
)

function Invoke-SystemAPI {
    param($Endpoint, $Method = "GET", $Body = $null)
    
    try {
        $uri = "https://esim-enterprise-management.vercel.app/api/v1$Endpoint"
        $params = @{
            Uri = $uri
            Method = $Method
            ContentType = "application/json"
        }
        
        if ($Body) {
            $params.Body = $Body | ConvertTo-Json
        }
        
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Host "API call failed: $Endpoint" -ForegroundColor Red
        return $null
    }
}

function Test-AllSystems {
    Write-Host "Checking all systems..." -ForegroundColor Yellow
    
    # Check sync status
    $syncStatus = Invoke-SystemAPI "/sync/status"
    if ($syncStatus -and $syncStatus.success) {
        Write-Host "✓ Sync Status: OK" -ForegroundColor Green
    } else {
        Write-Host "✗ Sync Status: Failed" -ForegroundColor Red
    }
    
    # Validate APIs
    $apiValidation = Invoke-SystemAPI "/sync/validate-apis"
    if ($apiValidation -and $apiValidation.success) {
        Write-Host "✓ API Validation: $($apiValidation.data.valid.Count) valid, $($apiValidation.data.invalid.Count) invalid" -ForegroundColor Green
    } else {
        Write-Host "✗ API Validation: Failed" -ForegroundColor Red
    }
    
    # Check complete system
    $systemCheck = Invoke-SystemAPI "/sync/check-all"
    if ($systemCheck -and $systemCheck.success) {
        Write-Host "✓ Complete System: All OK" -ForegroundColor Green
    } else {
        Write-Host "✗ Complete System: Issues detected" -ForegroundColor Red
        if ($systemCheck.data.errors) {
            $systemCheck.data.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
        }
    }
}

function Update-AllSystems {
    Write-Host "Updating all systems..." -ForegroundColor Yellow
    
    # Update all data
    $updateResult = Invoke-SystemAPI "/sync/update-all" "POST"
    if ($updateResult -and $updateResult.success) {
        Write-Host "✓ System Update: $($updateResult.data.updated.Count) updated" -ForegroundColor Green
        $updateResult.data.updated | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    } else {
        Write-Host "✗ System Update: Failed" -ForegroundColor Red
    }
    
    # Update complete systems
    $systemUpdate = Invoke-SystemAPI "/sync/update-systems" "POST"
    if ($systemUpdate -and $systemUpdate.success) {
        Write-Host "✓ Complete Update: Success" -ForegroundColor Green
    } else {
        Write-Host "✗ Complete Update: Failed" -ForegroundColor Red
    }
}

function Repair-AllIssues {
    Write-Host "Fixing all issues..." -ForegroundColor Yellow
    
    $fixResult = Invoke-SystemAPI "/sync/fix-issues" "POST"
    if ($fixResult -and $fixResult.success) {
        Write-Host "✓ Issue Fix: $($fixResult.data.fixed.Count) fixed, $($fixResult.data.failed.Count) failed" -ForegroundColor Green
        $fixResult.data.fixed | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    } else {
        Write-Host "✗ Issue Fix: Failed" -ForegroundColor Red
    }
}

function New-SystemBackup {
    Write-Host "Creating system backup..." -ForegroundColor Yellow
    
    $backupResult = Invoke-SystemAPI "/sync/create-backup" "POST"
    if ($backupResult -and $backupResult.success) {
        Write-Host "✓ Backup Created: $($backupResult.data.backupId)" -ForegroundColor Green
    } else {
        Write-Host "✗ Backup Creation: Failed" -ForegroundColor Red
    }
}

function Remove-OldData {
    Write-Host "Deleting old data (30+ days)..." -ForegroundColor Yellow
    
    $deleteResult = Invoke-SystemAPI "/sync/delete-old/30" "DELETE"
    if ($deleteResult -and $deleteResult.success) {
        Write-Host "✓ Old Data Deleted: $($deleteResult.data.deleted) records" -ForegroundColor Green
    } else {
        Write-Host "✗ Data Deletion: Failed" -ForegroundColor Red
    }
}

function Clear-SystemErrors {
    Write-Host "Clearing resolved errors..." -ForegroundColor Yellow
    
    $clearResult = Invoke-SystemAPI "/sync/clear-errors" "DELETE"
    if ($clearResult -and $clearResult.success) {
        Write-Host "✓ Errors Cleared: $($clearResult.data.cleared) resolved errors" -ForegroundColor Green
    } else {
        Write-Host "✗ Error Clearing: Failed" -ForegroundColor Red
    }
}

# Main execution
Write-Host "Complete System Error Check and Update" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

if ($CheckAll) {
    Test-AllSystems
} elseif ($UpdateAll) {
    Update-AllSystems
} elseif ($FixAll) {
    Repair-AllIssues
} elseif ($CreateBackup) {
    New-SystemBackup
} elseif ($DeleteOld) {
    Remove-OldData
} elseif ($ClearErrors) {
    Clear-SystemErrors
} else {
    # Run complete check and update
    Write-Host "Running complete system operations..." -ForegroundColor Yellow
    
    Test-AllSystems
    Write-Host ""
    Update-AllSystems
    Write-Host ""
    Repair-AllIssues
    Write-Host ""
    New-SystemBackup
    Write-Host ""
    Clear-SystemErrors
}

Write-Host "`nComplete system check finished!" -ForegroundColor Green