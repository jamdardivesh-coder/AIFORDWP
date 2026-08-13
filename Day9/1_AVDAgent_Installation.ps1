# AVD Agent Installation Script
# Purpose: Download and install AVD Agent + Bootloader on session host VM
# Requires: Registration token from host pool, executed on guest VM via az vm run-command
# Date: 2026-08-13

param(
    [Parameter(Mandatory=$true)]
    [string]$RegistrationToken,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkDir = "C:\AVD"
)

# Create working directory
New-Item -Path $WorkDir -ItemType Directory -Force | Out-Null
Write-Host "Working directory: $WorkDir"

# Define MSI URLs (Microsoft CDN for AVD components)
$agentUrl = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$bootUrl  = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$agentMsi = Join-Path $WorkDir 'AVD-Agent.msi'
$bootMsi  = Join-Path $WorkDir 'AVD-Bootloader.msi'
$agentLog = Join-Path $WorkDir 'agent-install.log'
$bootLog  = Join-Path $WorkDir 'boot-install.log'

Write-Host "Downloading AVD components..."
try {
    Invoke-WebRequest -Uri $bootUrl -OutFile $bootMsi -UseBasicParsing
    Write-Host "✓ Bootloader MSI downloaded"
}
catch {
    Write-Error "Failed to download Bootloader: $_"
    exit 1
}

try {
    Invoke-WebRequest -Uri $agentUrl -OutFile $agentMsi -UseBasicParsing
    Write-Host "✓ Agent MSI downloaded"
}
catch {
    Write-Error "Failed to download Agent: $_"
    exit 1
}

# Install Bootloader
Write-Host "Installing AVD Bootloader..."
$bootResult = & msiexec.exe /i $bootMsi /qn /norestart /l*v $bootLog
if ($bootResult -eq 0) {
    Write-Host "✓ Bootloader installation successful (exit code: $bootResult)"
}
else {
    Write-Error "Bootloader installation failed (exit code: $bootResult)"
    Get-Content $bootLog | Select-Object -Last 20 | Write-Host
    exit 1
}

# Install Agent with Registration Token
Write-Host "Installing AVD Agent with registration token..."
$agentResult = & msiexec.exe /i $agentMsi REGISTRATIONTOKEN=$RegistrationToken /qn /norestart /l*v $agentLog
if ($agentResult -eq 0) {
    Write-Host "✓ Agent installation successful (exit code: $agentResult)"
}
else {
    Write-Error "Agent installation failed (exit code: $agentResult)"
    Get-Content $agentLog | Select-Object -Last 20 | Write-Host
    exit 1
}

# Verify services
Write-Host "Verifying AVD services..."
Start-Sleep -Seconds 5
$rdAgent = Get-Service -Name "RDAgent" -ErrorAction SilentlyContinue
$rdBootLoader = Get-Service -Name "RDAgentBootLoader" -ErrorAction SilentlyContinue

if ($rdAgent) {
    Write-Host "✓ RDAgent service found (Status: $($rdAgent.Status))"
}
else {
    Write-Warning "RDAgent service not found yet (may appear after reboot)"
}

if ($rdBootLoader) {
    Write-Host "✓ RDAgentBootLoader service found (Status: $($rdBootLoader.Status))"
}
else {
    Write-Warning "RDAgentBootLoader service not found yet (may appear after reboot)"
}

Write-Host ""
Write-Host "Installation complete. VM restart is required to finalize registration."
Write-Host "The session host should appear as 'Available' in the host pool within 5 minutes after restart."

exit 0
