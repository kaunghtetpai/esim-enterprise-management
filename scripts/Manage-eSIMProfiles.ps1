# eSIM Profile Management with Microsoft Graph
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('List', 'Create', 'Deploy', 'Remove', 'Status')]
    [string]$Action,
    
    [string]$DeviceId,
    [string]$ProfileName,
    [string]$ICCID,
    [string]$Carrier,
    [string]$ActivationCode
)

function Get-ManagedDevices {
    try {
        $devices = Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'"
        return $devices | Select-Object Id, DeviceName, OperatingSystem, ComplianceState, LastSyncDateTime
    } catch {
        throw "Failed to get managed devices: $($_.Exception.Message)"
    }
}

function Get-eSIMProfiles {
    param([string]$DeviceId)
    
    try {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceId/deviceConfigurationStates"
        $response = Invoke-MgGraphRequest -Uri $uri -Method GET
        
        return $response.value | Where-Object { $_.settingName -like "*eUICC*" }
    } catch {
        throw "Failed to get eSIM profiles: $($_.Exception.Message)"
    }
}

function New-eSIMProfile {
    param(
        [string]$ProfileName,
        [string]$ICCID,
        [string]$Carrier,
        [string]$ActivationCode
    )
    
    try {
        $profileConfig = @{
            '@odata.type' = '#microsoft.graph.windows10EsimConfiguration'
            displayName = $ProfileName
            description = "eSIM profile for $Carrier"
            activationCode = $ActivationCode
            cellularData = @{
                apn = "$Carrier.com"
                username = ""
                password = ""
            }
        }
        
        $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations"
        $response = Invoke-MgGraphRequest -Uri $uri -Method POST -Body ($profileConfig | ConvertTo-Json -Depth 10)
        
        return $response
    } catch {
        throw "Failed to create eSIM profile: $($_.Exception.Message)"
    }
}

function Deploy-eSIMProfile {
    param(
        [string]$DeviceId,
        [string]$ProfileId
    )
    
    try {
        $assignment = @{
            assignments = @(
                @{
                    '@odata.type' = '#microsoft.graph.deviceConfigurationAssignment'
                    target = @{
                        '@odata.type' = '#microsoft.graph.deviceAndAppManagementAssignmentTarget'
                        deviceAndAppManagementAssignmentFilterId = $null
                        deviceAndAppManagementAssignmentFilterType = 'none'
                    }
                }
            )
        }
        
        $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$ProfileId/assign"
        Invoke-MgGraphRequest -Uri $uri -Method POST -Body ($assignment | ConvertTo-Json -Depth 10)
        
        Write-Host "eSIM profile deployed successfully to device $DeviceId" -ForegroundColor Green
    } catch {
        throw "Failed to deploy eSIM profile: $($_.Exception.Message)"
    }
}

function Remove-eSIMProfile {
    param(
        [string]$DeviceId,
        [string]$ICCID
    )
    
    try {
        $resetAction = @{
            '@odata.type' = '#microsoft.graph.deviceAction'
            actionName = 'resetToFactoryState'
            deviceIds = @($DeviceId)
            parameters = @{
                eUICCId = $ICCID
            }
        }
        
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceId/resetToFactoryState"
        Invoke-MgGraphRequest -Uri $uri -Method POST -Body ($resetAction | ConvertTo-Json -Depth 10)
        
        Write-Host "eSIM profile removed successfully from device $DeviceId" -ForegroundColor Green
    } catch {
        throw "Failed to remove eSIM profile: $($_.Exception.Message)"
    }
}

function Get-eSIMStatus {
    param(
        [string]$DeviceId,
        [string]$ICCID
    )
    
    try {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$DeviceId/deviceConfigurationStates"
        $response = Invoke-MgGraphRequest -Uri $uri -Method GET
        
        $esimStatus = $response.value | Where-Object { 
            $_.settingName -like "*eUICC*" -and $_.settingName -like "*$ICCID*" 
        }
        
        return $esimStatus | Select-Object settingName, state, errorDescription, lastReportedDateTime
    } catch {
        throw "Failed to get eSIM status: $($_.Exception.Message)"
    }
}

# Main execution
try {
    switch ($Action) {
        'List' {
            if ($DeviceId) {
                Get-eSIMProfiles -DeviceId $DeviceId | Format-Table
            } else {
                Get-ManagedDevices | Format-Table
            }
        }
        
        'Create' {
            if (-not $ProfileName -or -not $ICCID -or -not $Carrier) {
                throw "ProfileName, ICCID, and Carrier are required for Create action"
            }
            $result = New-eSIMProfile -ProfileName $ProfileName -ICCID $ICCID -Carrier $Carrier -ActivationCode $ActivationCode
            Write-Host "eSIM profile created with ID: $($result.id)" -ForegroundColor Green
        }
        
        'Deploy' {
            if (-not $DeviceId -or -not $ICCID) {
                throw "DeviceId and ICCID are required for Deploy action"
            }
            Deploy-eSIMProfile -DeviceId $DeviceId -ProfileId $ICCID
        }
        
        'Remove' {
            if (-not $DeviceId -or -not $ICCID) {
                throw "DeviceId and ICCID are required for Remove action"
            }
            Remove-eSIMProfile -DeviceId $DeviceId -ICCID $ICCID
        }
        
        'Status' {
            if (-not $DeviceId -or -not $ICCID) {
                throw "DeviceId and ICCID are required for Status action"
            }
            Get-eSIMStatus -DeviceId $DeviceId -ICCID $ICCID | Format-Table
        }
    }
} catch {
    Write-Error $_.Exception.Message
    exit 1
}