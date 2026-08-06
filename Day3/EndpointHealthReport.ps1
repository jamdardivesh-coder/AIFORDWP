<#
EndpointHealthReport.ps1
PowerShell version target: 5.1
Purpose: Read-only endpoint health report for DWP engineers.

VERIFY BEFORE RUNNING:
1) Run context: Some data sources (System event log, certain registry paths) may need elevated rights.
2) Network policy: Internet speed test uses an HTTPS download from speed.cloudflare.com and may be blocked by proxy/firewall.
3) Security tooling: Access to Microsoft Defender service status can be restricted by policy on hardened hosts.
4) Locale/output differences: Session parsing uses quser output and can vary slightly by OS language.

READ-ONLY GUARANTEE:
- This script only reads system information and writes report output to the console.
- It does not create, modify, or delete files, registry keys, services, or settings.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 0: Report metadata
# This section prints basic context for when and where the report was generated.
$reportTime = Get-Date
$computerName = $env:COMPUTERNAME
Write-Host "`n=== Endpoint Health Report ==="
Write-Host "Generated: $reportTime"
Write-Host "Computer : $computerName"

# Section 1: System uptime
# This section reads the OS last boot time and calculates uptime duration.
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $lastBoot = $os.LastBootUpTime
    $uptime = (Get-Date) - $lastBoot
    Write-Host "`n[1] System Uptime"
    Write-Host ("Last boot time : {0}" -f $lastBoot)
    Write-Host ("Uptime         : {0} days, {1} hours, {2} minutes" -f [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes)
}
catch {
    Write-Warning "[1] Failed to read uptime: $($_.Exception.Message)"
}

# Section 2: Free disk space
# This section reads all local fixed disks and reports free/total space in GB.
try {
    Write-Host "`n[2] Free Disk Space"
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,
            @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
            @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
            @{Name='FreePercent';Expression={
                if ($_.Size -gt 0) {
                    [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                }
                else {
                    0
                }
            }}
    $disks | Format-Table -AutoSize
}
catch {
    Write-Warning "[2] Failed to read disk space: $($_.Exception.Message)"
}

# Section 3: Pending reboot status (registry checks)
# This section checks common registry indicators used by Windows and update components.
try {
    Write-Host "`n[3] Pending Reboot (Registry)"

    $rebootIndicators = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
        'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    )

    $pendingFlags = [System.Collections.Generic.List[string]]::new()

    if (Test-Path $rebootIndicators[0]) {
        [void]$pendingFlags.Add('Component Based Servicing: RebootPending key exists')
    }

    if (Test-Path $rebootIndicators[1]) {
        [void]$pendingFlags.Add('Windows Update: RebootRequired key exists')
    }

    $sessionMgr = Get-ItemProperty -Path $rebootIndicators[2] -ErrorAction SilentlyContinue
    if ($null -ne $sessionMgr -and $sessionMgr.PSObject.Properties.Name -contains 'PendingFileRenameOperations') {
        if ($sessionMgr.PendingFileRenameOperations) {
            [void]$pendingFlags.Add('Session Manager: PendingFileRenameOperations is populated')
        }
    }

    if ($pendingFlags.Count -gt 0) {
        Write-Host 'Pending reboot: YES'
        $pendingFlags | ForEach-Object { Write-Host (" - {0}" -f $_) }
    }
    else {
        Write-Host 'Pending reboot: NO'
    }
}
catch {
    Write-Warning "[3] Failed to evaluate reboot pending state: $($_.Exception.Message)"
}

# Section 4: Top 5 processes by memory (Working Set)
# This section lists processes using the most physical memory right now.
try {
    Write-Host "`n[4] Top 5 Processes by Memory (Working Set)"
    Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First 5 Name, Id,
            @{Name='WorkingSetMB';Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} |
        Format-Table -AutoSize
}
catch {
    Write-Warning "[4] Failed to read top memory processes: $($_.Exception.Message)"
}

# Section 5: Top 5 processes by CPU
# This section lists processes with the highest cumulative CPU time since process start.
try {
    Write-Host "`n[5] Top 5 Processes by CPU"
    # Use Win32_Process times to avoid endpoint-specific issues with Get-Process CPU property access.
    Get-CimInstance -ClassName Win32_Process |
        Select-Object Name,
            @{Name='Id';Expression={$_.ProcessId}},
            @{Name='CPUSeconds';Expression={
                $kernel = [double]$_.KernelModeTime
                $user = [double]$_.UserModeTime
                [math]::Round(($kernel + $user) / 10000000, 2)
            }} |
        Sort-Object -Property CPUSeconds -Descending |
        Select-Object -First 5 Name, Id, CPUSeconds |
        Format-Table -AutoSize
}
catch {
    Write-Warning "[5] Failed to read top CPU processes: $($_.Exception.Message)"
}

# Section 6: Last 5 system log errors
# This section reads the newest 5 Error-level events from the Windows System log.
try {
    Write-Host "`n[6] Last 5 System Log Errors"
    Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
        Select-Object TimeCreated, Id, ProviderName, Message |
        Format-Table -Wrap -AutoSize
}
catch {
    Write-Warning "[6] Failed to read System log errors: $($_.Exception.Message)"
}

# Section 7: Internet speed (download test)
# This section performs a read-only in-memory download and estimates Mbps.
# No file is written to disk; bytes are downloaded into memory only.
try {
    Write-Host "`n[7] Internet Speed (Estimated Download)"

    $speedTestUrl = 'https://speed.cloudflare.com/__down?bytes=10000000'
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add('Cache-Control', 'no-cache')

    $start = Get-Date
    $bytes = $webClient.DownloadData($speedTestUrl)
    $end = Get-Date

    $durationSeconds = [math]::Max((New-TimeSpan -Start $start -End $end).TotalSeconds, 0.001)
    $bitsPerSecond = ($bytes.Length * 8) / $durationSeconds
    $mbps = [math]::Round($bitsPerSecond / 1MB, 2)

    Write-Host ("Downloaded bytes : {0}" -f $bytes.Length)
    Write-Host ("Duration (sec)   : {0}" -f [math]::Round($durationSeconds, 3))
    Write-Host ("Estimated speed  : {0} Mbps" -f $mbps)
}
catch {
    Write-Warning "[7] Failed to estimate internet speed: $($_.Exception.Message)"
}
finally {
    if ($null -ne $webClient) {
        $webClient.Dispose()
    }
}

# Section 8: Microsoft Defender service state
# This section checks whether the Defender service is currently running.
try {
    Write-Host "`n[8] Microsoft Defender Service"
    $defenderService = Get-Service -Name 'WinDefend' -ErrorAction Stop
    if ($defenderService.Status -eq 'Running') {
        Write-Host 'Microsoft Defender service is RUNNING.'
    }
    else {
        Write-Host ("Microsoft Defender service is NOT running. Current status: {0}" -f $defenderService.Status)
    }
}
catch {
    Write-Warning "[8] Failed to read Defender service status: $($_.Exception.Message)"
}

# Section 9: Number of users logged in
# This section counts interactive user sessions using quser command output.
try {
    Write-Host "`n[9] Logged-In Users Count"
    $quserOutput = quser 2>$null
    if ($LASTEXITCODE -eq 0 -and $quserOutput) {
        $sessionLines = $quserOutput | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
        $userCount = @($sessionLines).Count
        Write-Host ("Interactive logged-in sessions: {0}" -f $userCount)
    }
    else {
        Write-Host 'Unable to query user sessions via quser on this host.'
    }
}
catch {
    Write-Warning "[9] Failed to count logged-in users: $($_.Exception.Message)"
}

# Section 10: Last Windows update date/time
# This section reports the most recent installed hotfix date as the last update marker.
try {
    Write-Host "`n[10] Last Windows Update"
    $latestHotfix = Get-HotFix |
        Where-Object { $_.InstalledOn -ne $null } |
        Sort-Object -Property InstalledOn -Descending |
        Select-Object -First 1

    if ($null -ne $latestHotfix) {
        Write-Host ("Last update installed on: {0}" -f $latestHotfix.InstalledOn)
        Write-Host ("HotFix ID               : {0}" -f $latestHotfix.HotFixID)
        Write-Host ("Description             : {0}" -f $latestHotfix.Description)
    }
    else {
        Write-Host 'No installed hotfix records were returned.'
    }
}
catch {
    Write-Warning "[10] Failed to read last Windows update info: $($_.Exception.Message)"
}

Write-Host "`n=== End of Report ===`n"