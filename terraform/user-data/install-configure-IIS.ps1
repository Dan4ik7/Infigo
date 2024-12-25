<powershell>
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Start-Transcript -Path "C:\temp\userdata.log" -Append

$websiteName = "SampleIISWebsite"
$websitePort = 8080
$repositoryUrl = "https://github.com/AzureWorkshops/samples-simple-iis-website.git"
$repositoryPath = "$env:TEMP\$websiteName-repo"
$websitePath = "C:\inetpub\wwwroot\$websiteName"

# Install IIS and Required Features
Write-Output "Installing IIS and necessary features..."
Install-WindowsFeature -Name Web-Server, Web-App-Dev, NET-Framework-Features, Web-Asp-Net45 -IncludeManagementTools
Write-Output "IIS and features installed successfully."

# Check for ASP.NET Core Hosting Bundle installation
Write-Output "Checking for ASP.NET Core Hosting Bundle..."
$hostingBundleCheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ASP.NET Core\Shared Framework" -ErrorAction SilentlyContinue
if (-not $hostingBundleCheck) {
    Write-Output "ASP.NET Core Hosting Bundle is not installed. Installing..."
    
    # Run the dotnet-install.ps1 script from the same directory as this script
    $dotnetInstallScript = Join-Path -Path $PSScriptRoot -ChildPath "dotnet-install.ps1"
    & $dotnetInstallScript
    
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

Stop-Transcript
</powershell>