# install-minikube.ps1
# PowerShell script to install and configure Minikube on Windows 10/11 Pro

Write-Host "=== Installing Minikube ===" -ForegroundColor Cyan

# Define target folder
$installPath = "C:\Program Files\minikube"

# Create folder if it doesn't exist
if (!(Test-Path -Path $installPath)) {
    New-Item -ItemType Directory -Force -Path $installPath | Out-Null
    Write-Host "Created folder: $installPath"
}

# Download latest Minikube binary
$minikubeUrl = "https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe"
$destination = "$installPath\minikube.exe"

Write-Host "Downloading Minikube from $minikubeUrl ..."
Invoke-WebRequest -Uri $minikubeUrl -OutFile $destination -UseBasicParsing

# Add to PATH
$existingPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($existingPath -notlike "*$installPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$existingPath;$installPath", [EnvironmentVariableTarget]::Machine)
    Write-Host "Added Minikube to PATH. Please restart PowerShell after installation." -ForegroundColor Yellow
}

# Verify installation
Write-Host "Verifying Minikube installation..."
Start-Sleep -Seconds 2
& "$installPath\minikube.exe" version

Write-Host "`n=== Minikube installation complete! ===" -ForegroundColor Green
Write-Host "After restarting PowerShell, run the following to start your cluster:" -ForegroundColor Cyan
Write-Host "`nminikube start --driver=docker`n" -ForegroundColor Yellow
