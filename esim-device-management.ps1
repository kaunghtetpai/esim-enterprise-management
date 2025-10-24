# eSIM Device Management - Intune Integration for iOS and Android
Connect-MgGraph -Scopes @(
    "DeviceManagementManagedDevices.ReadWrite.All",
    "DeviceManagementConfiguration.ReadWrite.All",
    "DeviceManagementApps.ReadWrite.All"
)

# Device platform configurations
$PlatformConfigs = @{
    "iOS" = @{
        ProfileType = "com.apple.cellular"
        ConfigMethod = "MobileConfig"
        CompliancePolicy = "iOS-eSIM-Compliance"
    }
    "Android" = @{
        ProfileType = "OEMConfig"
        ConfigMethod = "AppConfig"
        CompliancePolicy = "Android-eSIM-Compliance"
    }
}

function Get-eSIMDevices {
    param([string]$Platform = "All")
    
    $Filter = if ($Platform -ne "All") { "operatingSystem eq '$Platform'" } else { $null }
    $Devices = Get-MgDeviceManagementManagedDevice -Filter $Filter
    
    $eSIMDevices = @()
    foreach ($Device in $Devices) {
        if ($Device.DeviceName -like "*eSIM*" -or $Device.Model -like "*eSIM*") {
            $eSIMDevices += @{
                DeviceId = $Device.Id
                DeviceName = $Device.DeviceName
                Platform = $Device.OperatingSystem
                Model = $Device.Model
                ComplianceState = $Device.ComplianceState
                LastSyncDateTime = $Device.LastSyncDateTime
                EnrollmentType = $Device.DeviceEnrollmentType
                SerialNumber = $Device.SerialNumber
                IMEI = $Device.Imei
            }
        }
    }
    
    return $eSIMDevices
}

function New-eSIMCompliancePolicy {
    param(
        [string]$Platform,
        [string]$PolicyName
    )
    
    $ComplianceSettings = switch ($Platform) {
        "iOS" {
            @{
                "@odata.type" = "#microsoft.graph.iosCompliancePolicy"
                displayName = $PolicyName
                description = "eSIM compliance policy for iOS devices"
                passcodeRequired = $true
                passcodeMinimumLength = 6
                deviceThreatProtectionEnabled = $true
                deviceThreatProtectionRequiredSecurityLevel = "medium"
                osMinimumVersion = "15.0"
                osMaximumVersion = "17.0"
            }
        }
        "Android" {
            @{
                "@odata.type" = "#microsoft.graph.androidCompliancePolicy"
                displayName = $PolicyName
                description = "eSIM compliance policy for Android devices"
                passwordRequired = $true
                passwordMinimumLength = 6
                securityRequireVerifyApps = $true
                deviceThreatProtectionEnabled = $true
                deviceThreatProtectionRequiredSecurityLevel = "medium"
                osMinimumVersion = "10.0"
                osMaximumVersion = "14.0"
            }
        }
    }
    
    try {
        $Policy = New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $ComplianceSettings
        Write-Host "Compliance policy created: $($Policy.DisplayName)" -ForegroundColor Green
        return $Policy
    } catch {
        Write-Host "Failed to create compliance policy: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Deploy-eSIMConfiguration {
    param(
        [string]$DeviceId,
        [string]$Platform,
        [hashtable]$CarrierConfig
    )
    
    $ConfigProfile = switch ($Platform) {
        "iOS" {
            @{
                "@odata.type" = "#microsoft.graph.iosCustomConfiguration"
                displayName = "eSIM Configuration - $($CarrierConfig.Name)"
                description = "eSIM profile for $($CarrierConfig.Name) carrier"
                payloadFileName = "esim-config.mobileconfig"
                payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(@"
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
        <dict>
            <key>PayloadType</key>
            <string>com.apple.cellular</string>
            <key>PayloadIdentifier</key>
            <string>com.esim.carrier.$($CarrierConfig.Code)</string>
            <key>SMDP_Address</key>
            <string>$($CarrierConfig.SMDP)</string>
            <key>MCC</key>
            <string>$($CarrierConfig.MCC)</string>
            <key>MNC</key>
            <string>$($CarrierConfig.MNC)</string>
        </dict>
    </array>
</dict>
</plist>
"@))
            }
        }
        "Android" {
            @{
                "@odata.type" = "#microsoft.graph.androidManagedAppConfiguration"
                displayName = "eSIM OEMConfig - $($CarrierConfig.Name)"
                description = "eSIM OEMConfig for $($CarrierConfig.Name) carrier"
                encodedSettingXml = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(@"
<wap-provisioningdoc>
    <characteristic type="com.android.omadm.service.ESIM">
        <parm name="SMDP_ADDRESS" value="$($CarrierConfig.SMDP)"/>
        <parm name="MCC" value="$($CarrierConfig.MCC)"/>
        <parm name="MNC" value="$($CarrierConfig.MNC)"/>
        <parm name="CARRIER_NAME" value="$($CarrierConfig.Name)"/>
    </characteristic>
</wap-provisioningdoc>
"@))
            }
        }
    }
    
    try {
        $Configuration = New-MgDeviceManagementDeviceConfiguration -BodyParameter $ConfigProfile
        
        # Assign to device
        $Assignment = @{
            target = @{
                "@odata.type" = "#microsoft.graph.deviceAndAppManagementAssignmentTarget"
                deviceAndAppManagementAssignmentFilterId = $null
                deviceAndAppManagementAssignmentFilterType = "none"
            }
        }
        
        New-MgDeviceManagementDeviceConfigurationAssignment -DeviceConfigurationId $Configuration.Id -BodyParameter $Assignment
        
        Write-Host "eSIM configuration deployed to device: $DeviceId" -ForegroundColor Green
        return $Configuration
    } catch {
        Write-Host "Failed to deploy configuration: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Monitor-DeviceCompliance {
    $Devices = Get-eSIMDevices
    $ComplianceReport = @{
        TotalDevices = $Devices.Count
        CompliantDevices = 0
        NonCompliantDevices = 0
        UnknownDevices = 0
        DeviceDetails = @()
    }
    
    foreach ($Device in $Devices) {
        switch ($Device.ComplianceState) {
            "compliant" { $ComplianceReport.CompliantDevices++ }
            "noncompliant" { $ComplianceReport.NonCompliantDevices++ }
            default { $ComplianceReport.UnknownDevices++ }
        }
        
        $ComplianceReport.DeviceDetails += @{
            DeviceName = $Device.DeviceName
            Platform = $Device.Platform
            ComplianceState = $Device.ComplianceState
            LastSync = $Device.LastSyncDateTime
            IMEI = $Device.IMEI
        }
    }
    
    Write-Host "=== Device Compliance Report ===" -ForegroundColor Cyan
    Write-Host "Total Devices: $($ComplianceReport.TotalDevices)" -ForegroundColor White
    Write-Host "Compliant: $($ComplianceReport.CompliantDevices)" -ForegroundColor Green
    Write-Host "Non-Compliant: $($ComplianceReport.NonCompliantDevices)" -ForegroundColor Red
    Write-Host "Unknown: $($ComplianceReport.UnknownDevices)" -ForegroundColor Yellow
    
    return $ComplianceReport
}

function Start-eSIMProfileDeployment {
    param([string]$CarrierCode = "MPT")
    
    $CarrierConfigs = @{
        "MPT" = @{ Name = "MPT"; Code = "MPT"; MCC = "414"; MNC = "01"; SMDP = "mpt-smdp.com.mm" }
        "ATOM" = @{ Name = "ATOM"; Code = "ATOM"; MCC = "414"; MNC = "06"; SMDP = "atom-smdp.com.mm" }
        "OOREDOO" = @{ Name = "OOREDOO"; Code = "OOREDOO"; MCC = "414"; MNC = "05"; SMDP = "ooredoo-smdp.com.mm" }
        "MYTEL" = @{ Name = "MYTEL"; Code = "MYTEL"; MCC = "414"; MNC = "09"; SMDP = "mytel-smdp.com.mm" }
    }
    
    $CarrierConfig = $CarrierConfigs[$CarrierCode]
    if (!$CarrierConfig) {
        Write-Host "Invalid carrier code: $CarrierCode" -ForegroundColor Red
        return
    }
    
    Write-Host "Deploying eSIM profiles for $($CarrierConfig.Name)..." -ForegroundColor Cyan
    
    # Get all eSIM devices
    $Devices = Get-eSIMDevices
    
    foreach ($Device in $Devices) {
        Write-Host "Deploying to $($Device.DeviceName) ($($Device.Platform))..." -ForegroundColor Yellow
        
        # Deploy configuration
        $Result = Deploy-eSIMConfiguration -DeviceId $Device.DeviceId -Platform $Device.Platform -CarrierConfig $CarrierConfig
        
        if ($Result) {
            Write-Host "  Success: Configuration deployed" -ForegroundColor Green
        } else {
            Write-Host "  Failed: Configuration deployment failed" -ForegroundColor Red
        }
    }
    
    Write-Host "eSIM profile deployment completed" -ForegroundColor Cyan
}

# Main execution
Write-Host "=== eSIM Device Management System ===" -ForegroundColor Cyan

# Create compliance policies
Write-Host "`n1. Creating compliance policies..." -ForegroundColor Yellow
New-eSIMCompliancePolicy -Platform "iOS" -PolicyName "iOS-eSIM-Compliance"
New-eSIMCompliancePolicy -Platform "Android" -PolicyName "Android-eSIM-Compliance"

# Monitor device compliance
Write-Host "`n2. Monitoring device compliance..." -ForegroundColor Yellow
$ComplianceReport = Monitor-DeviceCompliance

# Deploy eSIM profiles (example for MPT)
Write-Host "`n3. Deploying eSIM profiles..." -ForegroundColor Yellow
Start-eSIMProfileDeployment -CarrierCode "MPT"

Write-Host "`neSIM Device Management completed" -ForegroundColor Cyan