# eSIM API Monitoring and Domain Tracking System
param([string]$OutputFormat = "json")

# API endpoints and domain configuration
$APIEndpoints = @{
    "Firebase" = @{
        URL = "https://thl-mcs-d-odccsm.firebaseio.com"
        Location = "USA-Missouri"
        Ports = @(443, 80)
        ExpectedResponse = 200
    }
    "GoogleSupport" = @{
        URL = "https://support.google.com"
        Location = "USA-California"
        Ports = @(443, 80)
        ExpectedResponse = 200
    }
    "SIMTransfer" = @{
        URL = "https://simtransfer.goog"
        Location = "Unknown"
        Ports = @(443)
        ExpectedResponse = 200
    }
    "GoogleMigrate" = @{
        URL = "https://migrate.google"
        Location = "USA-California"
        Ports = @(443)
        ExpectedResponse = 200
    }
    "HTTPStat" = @{
        URL = "https://httpstat.us"
        Location = "USA-Iowa"
        Ports = @(443, 80)
        ExpectedResponse = 200
    }
    "CarrierDemo" = @{
        URL = "https://carrier-qrcless-demo.appspot.com"
        Location = "Ireland-Dublin"
        Ports = @(443)
        ExpectedResponse = 200
    }
}

function Test-APIEndpoint {
    param(
        [string]$Name,
        [hashtable]$Config
    )
    
    $Result = @{
        Name = $Name
        URL = $Config.URL
        Location = $Config.Location
        Status = "UNKNOWN"
        ResponseTime = 0
        StatusCode = 0
        IPAddress = ""
        Ports = @()
        Timestamp = Get-Date
        Error = ""
    }
    
    try {
        # DNS resolution
        $Domain = ([System.Uri]$Config.URL).Host
        $IPAddress = [System.Net.Dns]::GetHostAddresses($Domain)[0].IPAddressToString
        $Result.IPAddress = $IPAddress
        
        # HTTP response test
        $Response = Measure-Command {
            $WebResponse = Invoke-WebRequest -Uri $Config.URL -TimeoutSec 10 -ErrorAction Stop
            $Result.StatusCode = $WebResponse.StatusCode
        }
        $Result.ResponseTime = [math]::Round($Response.TotalMilliseconds, 2)
        
        # Port connectivity test
        foreach ($Port in $Config.Ports) {
            $PortTest = Test-NetConnection -ComputerName $Domain -Port $Port -WarningAction SilentlyContinue
            $Result.Ports += @{
                Port = $Port
                Status = if ($PortTest.TcpTestSucceeded) { "OPEN" } else { "CLOSED" }
            }
        }
        
        $Result.Status = if ($Result.StatusCode -eq $Config.ExpectedResponse) { "ONLINE" } else { "DEGRADED" }
        
    } catch {
        $Result.Status = "OFFLINE"
        $Result.Error = $_.Exception.Message
    }
    
    return $Result
}

function Get-DomainHistory {
    param([string]$Domain)
    
    # Simulate domain history tracking
    return @{
        Domain = $Domain
        RegistrationDate = "2020-01-01"
        ExpirationDate = "2025-01-01"
        Registrar = "Google Domains"
        DNSRecords = @(
            @{ Type = "A"; Value = "142.250.191.14" },
            @{ Type = "AAAA"; Value = "2607:f8b0:4004:c1b::8e" },
            @{ Type = "MX"; Value = "smtp.google.com" }
        )
        LastUpdated = Get-Date
    }
}

function Start-ContinuousMonitoring {
    param([int]$IntervalSeconds = 300)
    
    Write-Host "Starting continuous API monitoring (interval: $IntervalSeconds seconds)" -ForegroundColor Cyan
    
    while ($true) {
        $MonitoringResults = @()
        
        foreach ($Endpoint in $APIEndpoints.Keys) {
            $Result = Test-APIEndpoint -Name $Endpoint -Config $APIEndpoints[$Endpoint]
            $MonitoringResults += $Result
            
            $Color = switch ($Result.Status) {
                "ONLINE" { "Green" }
                "DEGRADED" { "Yellow" }
                "OFFLINE" { "Red" }
                default { "Gray" }
            }
            
            Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $($Result.Name): $($Result.Status) ($($Result.ResponseTime)ms)" -ForegroundColor $Color
        }
        
        # Save results
        $LogEntry = @{
            Timestamp = Get-Date
            Results = $MonitoringResults
        }
        
        Add-Content -Path "api-monitoring-log.json" -Value (ConvertTo-Json $LogEntry -Depth 5)
        
        Start-Sleep -Seconds $IntervalSeconds
    }
}

function New-MonitoringReport {
    $Report = @{
        GeneratedAt = Get-Date
        Summary = @{
            TotalEndpoints = $APIEndpoints.Count
            OnlineCount = 0
            OfflineCount = 0
            DegradedCount = 0
        }
        EndpointDetails = @()
        DomainHistory = @()
    }
    
    foreach ($Endpoint in $APIEndpoints.Keys) {
        $Result = Test-APIEndpoint -Name $Endpoint -Config $APIEndpoints[$Endpoint]
        $Report.EndpointDetails += $Result
        
        switch ($Result.Status) {
            "ONLINE" { $Report.Summary.OnlineCount++ }
            "OFFLINE" { $Report.Summary.OfflineCount++ }
            "DEGRADED" { $Report.Summary.DegradedCount++ }
        }
        
        # Add domain history
        $Domain = ([System.Uri]$APIEndpoints[$Endpoint].URL).Host
        $Report.DomainHistory += Get-DomainHistory -Domain $Domain
    }
    
    if ($OutputFormat -eq "json") {
        $ReportJSON = ConvertTo-Json $Report -Depth 5
        Set-Content -Path "api-monitoring-report.json" -Value $ReportJSON
        Write-Host "Report saved: api-monitoring-report.json" -ForegroundColor Green
    } else {
        # HTML report
        $ReportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>eSIM API Monitoring Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .online { color: green; }
        .offline { color: red; }
        .degraded { color: orange; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>eSIM API Monitoring Report</h1>
    <p>Generated: $((Get-Date).ToString())</p>
    
    <h2>Summary</h2>
    <p>Online: $($Report.Summary.OnlineCount) | Offline: $($Report.Summary.OfflineCount) | Degraded: $($Report.Summary.DegradedCount)</p>
    
    <h2>Endpoint Status</h2>
    <table>
        <tr><th>Name</th><th>URL</th><th>Status</th><th>Response Time</th><th>Location</th></tr>
"@
        
        foreach ($Detail in $Report.EndpointDetails) {
            $StatusClass = $Detail.Status.ToLower()
            $ReportHTML += "<tr><td>$($Detail.Name)</td><td>$($Detail.URL)</td><td class='$StatusClass'>$($Detail.Status)</td><td>$($Detail.ResponseTime)ms</td><td>$($Detail.Location)</td></tr>"
        }
        
        $ReportHTML += @"
    </table>
</body>
</html>
"@
        
        Set-Content -Path "api-monitoring-report.html" -Value $ReportHTML
        Write-Host "Report saved: api-monitoring-report.html" -ForegroundColor Green
    }
}

# Execute based on parameters
if ($args[0] -eq "continuous") {
    Start-ContinuousMonitoring -IntervalSeconds 300
} elseif ($args[0] -eq "test") {
    foreach ($Endpoint in $APIEndpoints.Keys) {
        $Result = Test-APIEndpoint -Name $Endpoint -Config $APIEndpoints[$Endpoint]
        Write-Host "$($Result.Name): $($Result.Status) ($($Result.ResponseTime)ms)" -ForegroundColor $(if($Result.Status -eq "ONLINE"){"Green"}else{"Red"})
    }
} else {
    New-MonitoringReport
}