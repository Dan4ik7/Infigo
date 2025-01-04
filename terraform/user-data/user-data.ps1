<powershell>
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Start-Transcript -Path "C:\temp\userdata.log" -Append

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name AWS.Tools.Installer -Force

$bucket_name = "${bucket_name}"

Read-S3Object -BucketName $bucket_name -Key windows-exporter.ps1 -File C:\temp\windows-exporter.ps1
Read-S3Object -BucketName $bucket_name -Key storage_health.ps1 -File C:\temp\storage_health.ps1
Read-S3Object -BucketName $bucket_name -Key hyperv_health.ps1 -File C:\temp\hyperv_health.ps1

$MyInvocation.MyCommand.Path | Copy-Item -Destination "C:\temp\userdata.ps1" -Force
Write-Output "The current script has been saved to C:\temp\userdata.ps1."

### This is needed because WinGet will not be available until you have logged into Windows as a user for the first time
### So this will request the WinGet registration
### If any issues with the winget occurs, re-run the script at C:\temp\userdata.ps1
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
Start-Sleep -Seconds 10

$websiteName = "SampleIISWebsite"
$websitePort = 8080
$repositoryUrl = "https://github.com/AzureWorkshops/samples-simple-iis-website.git"
$repositoryPath = "$env:TEMP\$websiteName-repo"
$websitePath = "C:\inetpub\wwwroot\$websiteName"
$dumpToolPath = "C:\Tools\procdump.exe"
$dumpFilePath = "C:\temp\$websiteName-dump.dmp"

# Install IIS and Required Features
Write-Output "Installing IIS and necessary features..."
Install-WindowsFeature -Name Web-Server, Web-App-Dev, NET-Framework-Features, Web-Asp-Net45 -IncludeManagementTools
Write-Output "IIS and features installed successfully."

# Check for ASP.NET Core Hosting Bundle installation
Write-Output "Checking for ASP.NET Core Hosting Bundle..."
$hostingBundleCheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ASP.NET Core\Shared Framework" -ErrorAction SilentlyContinue

if (-not $hostingBundleCheck) {
    Write-Output "ASP.NET Core Hosting Bundle is not installed. Installing..."
    
    # Ensure winget accepts the agreements and uses the required source
    winget source reset --force
    winget source update
    winget settings --enable-experimental msstore
    winget source agree msstore
    
    # Install the hosting bundle
    winget install --id Microsoft.DotNet.SDK.9 --accept-package-agreements --accept-source-agreements
    Write-Output "ASP.NET Core Hosting Bundle installed successfully."
} else {
    Write-Output "ASP.NET Core Hosting Bundle is already installed."
}


# Checking for Git installation
Write-Output "Checking for Git installation..."
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Output "Git is not installed. Installing Git..."
    Start-Process -FilePath "winget" -ArgumentList "install --id Git.Git -e --source winget" -Wait -NoNewWindow
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
Write-Output "Git is available."

# Clone the repository
Write-Output "Cloning the repository from $repositoryUrl..."
if (Test-Path -Path $repositoryPath) {
    Remove-Item -Path $repositoryPath -Recurse -Force
}
git clone $repositoryUrl $repositoryPath
if (-not $?) {
    Write-Output "Unable to clone repository..."
    Write-Output "Retrying..."
    winget install -e --id Git.Git 
    git clone $repositoryUrl $repositoryPath
}
Write-Output "Repository cloned to $repositoryPath."

# Configure IIS Website
Write-Output "Configuring IIS website..."
if (Test-Path -Path $websitePath) {
    Remove-Item -Path $websitePath -Recurse -Force
}
New-Item -Path $websitePath -ItemType Directory
Copy-Item -Path "$repositoryPath\*" -Destination $websitePath -Recurse -Force

Import-Module WebAdministration
if (Get-Website | Where-Object { $_.Name -eq $websiteName }) {
    Remove-Website -Name $websiteName
}
New-Website -Name $websiteName -PhysicalPath $websitePath -Port $websitePort

# Remove any existing bindings on the same port
Get-WebBinding | Where-Object { $_.bindingInformation -like "*:$($websitePort):*" } | Remove-WebBinding


###If you want to add a binding to the Ec2 instance public IP -
###Consider uncommenting the below lines <EOF
# Write-Output "Adding IIS bindings..."
# $token = Invoke-RestMethod -Method PUT -Uri "http://169.254.169.254/latest/api/token" -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }
# $publicIP = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/public-ipv4" -Headers @{ "X-aws-ec2-metadata-token" = $token }

# Add a new binding for the public IP
# New-WebBinding -Name $websiteName -Protocol http -IPAddress $publicIP -Port $websitePort
###EOF###until here -

# Add a new binding for the localhost
New-WebBinding -Name $websiteName -Protocol http -IPAddress "127.0.0.1" -Port $websitePort

# Add a fallback binding for requests without a hostname
New-WebBinding -Name $websiteName -Protocol http -IPAddress "*" -Port $websitePort

Start-Website -Name $websiteName

# Set permissions
Write-Output "Setting permissions for $websitePath..."
icacls $websitePath /grant "IIS_IUSRS:(OI)(CI)F" /T

# Cleanup
if (Test-Path -Path $repositoryPath) {
    Remove-Item -Path $repositoryPath -Recurse -Force
}
Write-Output "Setup complete. Website is live at http://localhost:$websitePort"

# Add firewall rule to allow traffic on the public port (80)
Write-Output "Adding firewall rules to allow traffic on port $websitePort..."
New-NetFirewallRule -DisplayName "Allow HTTP on port $websitePort" -Direction Inbound -Protocol TCP -LocalPort $websitePort -Action Allow -Profile Any
Write-Output "Firewall rules added successfully."

# Generate IIS dump
Write-Output "Checking for ProcDump tool..."
if (!(Test-Path -Path $dumpToolPath)) {
    Write-Output "ProcDump not found. Downloading..."
    Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Procdump.zip" -OutFile "$env:TEMP\Procdump.zip"
    Expand-Archive -Path "$env:TEMP\Procdump.zip" -DestinationPath "C:\Tools" -Force
}
Write-Output "Generating dump file..."
Start-Process -FilePath $dumpToolPath -ArgumentList "-accepteula -ma w3wp.exe $dumpFilePath" -Wait
Write-Output "Dump file generated at $dumpFilePath"

# Generate IIS usage report
$logPath = "C:\inetpub\logs\LogFiles"
$jsonReportPath = "$env:TEMP\IISUsageReport.json"
$csvReportPath = "$env:TEMP\IISUsageReport.csv"
$htmlReportPath = "$env:TEMP\IISUsageReport.html"

Write-Output "Generating IIS usage report..."

# Check if IIS log directory exists
if (-Not (Test-Path -Path $logPath)) {
    Write-Output "No IIS logs found. Exiting."
    Write-Output "Generating some logs"
    Invoke-WebRequest http://localhost:$websitePort
    Invoke-WebRequest http://localhost:$websitePort/dude
}

$logFiles = Get-ChildItem -Path $logPath -Recurse -Include "*.log"
if (-Not $logFiles) {
    Write-Output "Generating some logs"
    Invoke-WebRequest http://localhost:$websitePort
    Invoke-WebRequest http://localhost:$websitePort/dude
}

# Initialize counters
$activeTimes = @{}
$errorSummary = @{}
$browserStats = @{}

foreach ($logFile in $logFiles) {
    Write-Output "Processing $($logFile.FullName)..."
    Get-Content $logFile.FullName | ForEach-Object {
        if ($_ -match "^(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\s.*\s(\d{3})\s.*\s(\S.*)$") 
            {
            $timestamp = $matches[1]
            $statusCode = $matches[2]
            $userAgent = $matches[3]

            # Extract hour from timestamp
            $hour = (Get-Date $timestamp).Hour
            if (-Not $activeTimes[$hour]) { $activeTimes[$hour] = 0 }
            $activeTimes[$hour]++

            # Track error codes
            if ($statusCode -match "^(4|5)\d{2}$") {
                if (-Not $errorSummary[$statusCode]) { $errorSummary[$statusCode] = 0 }
                $errorSummary[$statusCode]++
            }

            # Extract User-Agent data and track browser usage
            if ($_ -match "\s(?<userAgent>Mozilla/.*|.*)\s\d{3}\s\d\s\d\s\d+$") {
                $userAgent = $matches['userAgent']
    
                if ($userAgent) {
                    # Decode the User-Agent string
                    $decodedUserAgent = $userAgent -replace "\+", " "

                    # Detect browsers
                    if ($decodedUserAgent -match "(Edg/|OPR/|Chrome|Firefox|Safari|MSIE|Trident)") {
                        switch -regex ($decodedUserAgent) {
                            "Edg/"       { $browser = "Edge" }
                            "OPR/"       { $browser = "Opera" }
                            "Chrome"     { if ($decodedUserAgent -notmatch "OPR/|Edg/") { $browser = "Chrome" } }
                            "Firefox"    { $browser = "Firefox" }
                            "Safari"     { if ($decodedUserAgent -notmatch "Chrome|Edg/|OPR/") { $browser = "Safari" } }
                            "MSIE|Trident" { $browser = "Internet Explorer" }
                            default      { $browser = "Other" }
                        }
                    } else {
                        $browser = "Other"
                    }

                    # Increment browser count
                    if (-Not $browserStats[$browser]) { $browserStats[$browser] = 0 }
                    $browserStats[$browser]++
                } else {
                    Write-Host "No User-Agent data available in this entry."
                }
            }
        }
    }
}

# Convert data to JSON
$jsonReport = [pscustomobject]@{
    ActiveTimes = $activeTimes.GetEnumerator() | Sort-Object Key | ForEach-Object {
        [pscustomobject]@{ Hour = $_.Key; Requests = $_.Value }
    }
    ErrorSummary = $errorSummary.GetEnumerator() | Sort-Object Key | ForEach-Object {
        [pscustomobject]@{ Status = $_.Key; Occurrences = $_.Value }
    }
    BrowserStatistics = $browserStats.GetEnumerator() | Sort-Object Key | ForEach-Object {
        [pscustomobject]@{ Browser = $_.Key; Users = $_.Value }
    }
} | ConvertTo-Json -Depth 3
$jsonReport | Out-File -FilePath $jsonReportPath

# Convert data to CSV
$activeTimes.GetEnumerator() | Sort-Object Key | ForEach-Object {
    [pscustomobject]@{ Hour = $_.Key; Requests = $_.Value }
} | Export-Csv -Path $csvReportPath -Append -NoTypeInformation
$errorSummary.GetEnumerator() | Sort-Object Key | ForEach-Object {
    [pscustomobject]@{ Status = $_.Key; Occurrences = $_.Value }
} | Export-Csv -Path $csvReportPath -Append -NoTypeInformation
$browserStats.GetEnumerator() | Sort-Object Key | ForEach-Object {
    [pscustomobject]@{ Browser = $_.Key; Users = $_.Value }
} | Export-Csv -Path $csvReportPath -Append -NoTypeInformation

# Generate HTML report
$htmlReport = @()
$htmlReport += "<html><head><title>IIS Usage Report</title></head><body>"
$htmlReport += "<h1>IIS Usage Report</h1>"

# Most Active Times
$htmlReport += "<h2>Most Active Times</h2><ul>"
foreach ($entry in $activeTimes.GetEnumerator() | Sort-Object Key) {
    $htmlReport += "<li>Hour $($entry.Key): $($entry.Value) requests</li>"
}
$htmlReport += "</ul>"

# Error Summary
$htmlReport += "<h2>Error Summary</h2><ul>"
foreach ($entry in $errorSummary.GetEnumerator() | Sort-Object Key) {
    $htmlReport += "<li>Status $($entry.Key): $($entry.Value) occurrences</li>"
}
$htmlReport += "</ul>"

# Browser Statistics
$htmlReport += "<h2>Browser Statistics</h2><ul>"
foreach ($entry in $browserStats.GetEnumerator() | Sort-Object Key) {
    $htmlReport += "<li>$($entry.Key): $($entry.Value) usages</li>"
}
$htmlReport += "</ul>"

$htmlReport += "</body></html>"
$htmlReport -join "`n" | Out-File -FilePath $htmlReportPath

Write-Output "Reports generated:"
Write-Output "JSON: $jsonReportPath"
Write-Output "CSV: $csvReportPath"
Write-Output "HTML: $htmlReportPath"

Write-Output "Starting windows-exporter script..."
& "C:\temp\windows-exporter.ps1"

Stop-Transcript
</powershell>