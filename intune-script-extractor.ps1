# Install Microsoft Graph module
Install-Module -Name Microsoft.Graph -Scope CurrentUser -Force

# Connect to Microsoft Graph with required permissions
Connect-MgGraph -Scopes "DeviceManagementScripts.Read.All"

# Create output directory
$outputPath = "C:\IntuneScripts"
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath -Force
}

# Get all Intune scripts
$intuneScripts = Get-MgDeviceManagementScript -All

# Process each script
foreach ($script in $intuneScripts) {
    if ($script.ScriptContent) {
        # Decode base64 content
        $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($script.ScriptContent))
        
        # Save to file
        $fileName = "$($script.DisplayName).ps1"
        $filePath = Join-Path $outputPath $fileName
        Set-Content -Path $filePath -Value $decodedContent
        
        Write-Host "Extracted: $fileName"
    }
}

Write-Host "All scripts extracted to: $outputPath"