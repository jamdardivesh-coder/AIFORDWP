<#
.SYNOPSIS
Collects read-only endpoint evidence to validate or refute a deployment-related impact hypothesis.

.DESCRIPTION
This script gathers workstation evidence for incidents involving login failures, slow logons,
performance degradation, missing desktop shortcuts, and possible data-access anomalies after
a software deployment.

The script is read-only and does not modify system configuration. It is designed for Service Desk
and Incident Response use on Windows 10 and Windows 11 endpoints.

.PARAMETER OutputRoot
Parent folder where a timestamped evidence directory is created.

.PARAMETER DmsNamePattern
Regex pattern used to identify deployment-related application artifacts.

.PARAMETER DeploymentServicePatterns
Service name/display-name/path patterns associated with the deployment.

.PARAMETER LookbackDays
Number of days to look back for event logs and recently installed software.

.PARAMETER DeploymentWindowStart
Start timestamp for file-change correlation (for example, Friday deployment time).

.PARAMETER IncludeSecurityLog
Includes Security log collection. This may require elevated rights.

.PARAMETER DryRun
Shows what would be collected without creating files or transcript output.

.EXAMPLE
.\Collect-Floor6DeploymentEvidence.ps1 -OutputRoot C:\IR -DmsNamePattern "iManage|NetDocuments|DMS" -DryRun

.EXAMPLE
.\Collect-Floor6DeploymentEvidence.ps1 -OutputRoot C:\IR -LookbackDays 5 -IncludeSecurityLog

.NOTES
Safe operation:
- No uninstall operations
- No registry writes
- No service/process control actions
- Evidence collection only
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputRoot = "$PSScriptRoot",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DmsNamePattern = 'DMS|Document Management|iManage|NetDocuments|Worldox|OpenText',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$DeploymentServicePatterns = @('DMS', 'Document', 'iManage', 'NetDocuments', 'Worldox', 'OpenText'),

    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$LookbackDays = 7,

    [Parameter()]
    [datetime]$DeploymentWindowStart = (Get-Date).Date.AddDays(-3).AddHours(12),

    [Parameter()]
    [switch]$IncludeSecurityLog,

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Started = Get-Date
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:Errors = New-Object System.Collections.Generic.List[string]
$script:Artifacts = [ordered]@{}
$script:EvidenceRoot = $null
$script:TranscriptPath = $null

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Message"
}

function Add-WarningRecord {
    param([string]$Message)
    $script:Warnings.Add($Message)
    Write-Warning $Message
}

function Add-ErrorRecord {
    param([string]$Message)
    $script:Errors.Add($Message)
    Write-Error $Message
}

function Invoke-Safely {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Step,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,

        [Parameter()]
        $Default = $null
    )

    try {
        & $Action
    }
    catch {
        Add-WarningRecord "$Step failed: $($_.Exception.Message)"
        $Default
    }
}

function New-EvidenceFolder {
    if ($DryRun) {
        Write-Status "DryRun enabled. Evidence folder creation skipped."
        return $null
    }

    $folderName = "Evidence-Floor6-$env:COMPUTERNAME-$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
    $folderPath = Join-Path -Path $OutputRoot -ChildPath $folderName

    if (-not (Test-Path -LiteralPath $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    }

    return $folderPath
}

function Export-JsonArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $Data
    )

    if ($DryRun) {
        Write-Status "DryRun: would export JSON artifact $Name"
        return
    }

    $path = Join-Path -Path $script:EvidenceRoot -ChildPath ("{0}.json" -f $Name)
    $Data | ConvertTo-Json -Depth 8 | Out-File -LiteralPath $path -Encoding UTF8
    $script:Artifacts[$Name] = $path
}

function Export-CsvArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Data
    )

    if ($DryRun) {
        Write-Status "DryRun: would export CSV artifact $Name"
        return
    }

    $path = Join-Path -Path $script:EvidenceRoot -ChildPath ("{0}.csv" -f $Name)
    $Data | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8
    $script:Artifacts[$Name] = $path
}

function Get-InstalledPrograms {
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $programs = foreach ($path in $regPaths) {
        Invoke-Safely -Step "Reading $path" -Default @() -Action {
            Get-ItemProperty -Path $path -ErrorAction Stop |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_.DisplayName) } |
                Select-Object @{
                    Name = 'DisplayName'; Expression = { $_.DisplayName }
                }, @{
                    Name = 'DisplayVersion'; Expression = { $_.DisplayVersion }
                }, @{
                    Name = 'Publisher'; Expression = { $_.Publisher }
                }, @{
                    Name = 'InstallDateRaw'; Expression = { $_.InstallDate }
                }, @{
                    Name = 'InstallLocation'; Expression = { $_.InstallLocation }
                }, @{
                    Name = 'UninstallString'; Expression = { $_.UninstallString }
                }, @{
                    Name = 'RegistryPath'; Expression = { $path }
                }
        }
    }

    $programs | Sort-Object -Property DisplayName -Unique
}

function Convert-InstallDate {
    param([string]$InstallDateRaw)

    if ([string]::IsNullOrWhiteSpace($InstallDateRaw)) {
        return $null
    }

    try {
        if ($InstallDateRaw -match '^\d{8}$') {
            return [datetime]::ParseExact($InstallDateRaw, 'yyyyMMdd', $null)
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-StartupInventory {
    $startupCommands = Invoke-Safely -Step 'Collecting Win32_StartupCommand' -Default @() -Action {
        Get-CimInstance -ClassName Win32_StartupCommand -ErrorAction Stop |
            Select-Object Name, Command, Location, User
    }

    $startupFolders = @(
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    )

    $folderItems = foreach ($folder in $startupFolders) {
        if (Test-Path -LiteralPath $folder) {
            Invoke-Safely -Step "Listing startup folder $folder" -Default @() -Action {
                Get-ChildItem -LiteralPath $folder -File -ErrorAction Stop |
                    Select-Object @{
                        Name = 'Name'; Expression = { $_.Name }
                    }, @{
                        Name = 'Command'; Expression = { $_.FullName }
                    }, @{
                        Name = 'Location'; Expression = { $folder }
                    }, @{
                        Name = 'User'; Expression = { 'FolderItem' }
                    }
            }
        }
    }

    @($startupCommands + $folderItems)
}

function Get-ScheduledTaskInventory {
    if (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
        return Invoke-Safely -Step 'Collecting scheduled tasks' -Default @() -Action {
            Get-ScheduledTask -ErrorAction Stop |
                Select-Object TaskName, TaskPath, State, Author, Description,
                    @{
                        Name = 'UserId'; Expression = {
                            if ($_.Principal) { $_.Principal.UserId } else { $null }
                        }
                    }
        }
    }

    Add-WarningRecord 'Get-ScheduledTask not available on this endpoint.'
    @()
}

function Get-ProcessInventory {
    $result = @()
    $processes = Invoke-Safely -Step 'Collecting process list' -Default @() -Action {
        Get-Process -ErrorAction Stop
    }

    foreach ($p in $processes) {
        $startTime = $null
        $path = $null

        try {
            $startTime = $p.StartTime
        }
        catch {
        }

        try {
            $path = $p.Path
        }
        catch {
        }

        $result += [pscustomobject]@{
            Name = $p.Name
            Id = $p.Id
            CPU = $p.CPU
            WorkingSetMB = [math]::Round($p.WorkingSet64 / 1MB, 2)
            PrivateMemoryMB = [math]::Round($p.PrivateMemorySize64 / 1MB, 2)
            StartTime = $startTime
            Path = $path
        }
    }

    $result
}

function Get-UtilizationSnapshot {
    $cpuPercent = Invoke-Safely -Step 'Collecting CPU utilization' -Default $null -Action {
        (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples[0].CookedValue
    }

    $os = Invoke-Safely -Step 'Collecting memory utilization' -Default $null -Action {
        Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    }

    $disks = Invoke-Safely -Step 'Collecting disk utilization' -Default @() -Action {
        Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop |
            Select-Object DeviceID, VolumeName,
                @{
                    Name = 'SizeGB'; Expression = { [math]::Round($_.Size / 1GB, 2) }
                },
                @{
                    Name = 'FreeGB'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) }
                },
                @{
                    Name = 'UsedPercent'; Expression = {
                        if ($_.Size -gt 0) {
                            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
                        }
                        else {
                            $null
                        }
                    }
                }
    }

    [pscustomobject]@{
        CpuPercent = if ($cpuPercent -ne $null) { [math]::Round($cpuPercent, 2) } else { $null }
        MemoryTotalGB = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 2) } else { $null }
        MemoryFreeGB = if ($os) { [math]::Round($os.FreePhysicalMemory / 1MB, 2) } else { $null }
        MemoryUsedPercent = if ($os -and $os.TotalVisibleMemorySize -gt 0) {
            [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
        }
        else {
            $null
        }
        Disk = $disks
    }
}

function Get-ServicesByPattern {
    param(
        [string[]]$Patterns
    )

    $regex = ($Patterns | ForEach-Object { [regex]::Escape($_) }) -join '|'

    Invoke-Safely -Step 'Collecting deployment-related services' -Default @() -Action {
        Get-CimInstance -ClassName Win32_Service -ErrorAction Stop |
            Where-Object {
                $_.Name -match $regex -or $_.DisplayName -match $regex -or $_.PathName -match $regex
            } |
            Select-Object Name, DisplayName, State, StartMode, StartName, PathName
    }
}

function Get-AvailableLogs {
    Invoke-Safely -Step 'Enumerating event logs' -Default @() -Action {
        Get-WinEvent -ListLog * -ErrorAction Stop | Select-Object -ExpandProperty LogName
    }
}

function Read-EventLogs {
    param(
        [string[]]$LogNames,
        [datetime]$StartTime,
        [int[]]$Ids,
        [string]$ProviderPattern,
        [int]$MaxEvents = 600
    )

    $available = Get-AvailableLogs
    $results = @()

    foreach ($log in $LogNames) {
        if ($available -notcontains $log) {
            Add-WarningRecord "Event log not present: $log"
            continue
        }

        $events = Invoke-Safely -Step "Reading event log $log" -Default @() -Action {
            $fh = @{
                LogName = $log
                StartTime = $StartTime
            }

            if ($Ids -and $Ids.Count -gt 0) {
                $fh['Id'] = $Ids
            }

            Get-WinEvent -FilterHashtable $fh -MaxEvents $MaxEvents -ErrorAction Stop
        }

        if ($ProviderPattern) {
            $events = $events | Where-Object { $_.ProviderName -match $ProviderPattern }
        }

        $results += $events | Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, LogName, MachineName, Message
    }

    $results
}

function Get-UserProfileEvidence {
    $profiles = Invoke-Safely -Step 'Collecting Win32_UserProfile' -Default @() -Action {
        Get-CimInstance -ClassName Win32_UserProfile -ErrorAction Stop |
            Select-Object LocalPath, SID, Loaded, Special, LastUseTime
    }

    $profileList = Invoke-Safely -Step 'Collecting ProfileList registry entries' -Default @() -Action {
        Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ErrorAction Stop |
            ForEach-Object {
                $p = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop
                [pscustomobject]@{
                    SID = $_.PSChildName
                    ProfileImagePath = $p.ProfileImagePath
                    State = $p.State
                    RefCount = $p.RefCount
                }
            }
    }

    $tempProfileIndicators = @()

    $tempProfileIndicators += $profileList | Where-Object {
        $_.ProfileImagePath -match '\\.tmp$' -or ($_.State -band 0x00000100)
    } | ForEach-Object {
        [pscustomobject]@{
            Source = 'ProfileList'
            Detail = "Possible temporary profile: SID=$($_.SID) Path=$($_.ProfileImagePath) State=$($_.State)"
        }
    }

    $tempProfileIndicators += Read-EventLogs -LogNames @('Application', 'Microsoft-Windows-User Profile Service/Operational') -StartTime ((Get-Date).AddDays(-$LookbackDays)) -Ids @(1511, 1515, 1518, 1521) -ProviderPattern 'User Profile Service' -MaxEvents 300 |
        ForEach-Object {
            [pscustomobject]@{
                Source = 'EventLog'
                Detail = "[$($_.TimeCreated)] ID $($_.Id) $($_.Message)"
            }
        }

    [pscustomobject]@{
        CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        UserProfile = $env:USERPROFILE
        Profiles = $profiles
        ProfileRegistry = $profileList
        TemporaryProfileIndicators = $tempProfileIndicators
    }
}

function Get-DesktopEvidence {
    $desktopCurrent = [Environment]::GetFolderPath('Desktop')
    $desktopUser = Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop'
    $desktopPublic = Join-Path -Path $env:PUBLIC -ChildPath 'Desktop'

    $paths = @($desktopCurrent, $desktopUser, $desktopPublic) | Select-Object -Unique

    $pathStatus = foreach ($path in $paths) {
        [pscustomobject]@{
            Path = $path
            Exists = Test-Path -LiteralPath $path
            LastWriteTime = if (Test-Path -LiteralPath $path) { (Get-Item -LiteralPath $path).LastWriteTime } else { $null }
        }
    }

    $shell = $null
    $shortcuts = @()

    try {
        $shell = New-Object -ComObject WScript.Shell
    }
    catch {
        Add-WarningRecord "Unable to initialize WScript.Shell for shortcut target resolution: $($_.Exception.Message)"
    }

    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }

        $items = Invoke-Safely -Step "Reading shortcuts in $path" -Default @() -Action {
            Get-ChildItem -LiteralPath $path -File -ErrorAction Stop |
                Where-Object { $_.Extension -in '.lnk', '.url' }
        }

        foreach ($item in $items) {
            $target = $null
            if ($shell -and $item.Extension -ieq '.lnk') {
                $target = Invoke-Safely -Step "Resolving shortcut target $($item.FullName)" -Default $null -Action {
                    $shortcut = $shell.CreateShortcut($item.FullName)
                    $shortcut.TargetPath
                }
            }

            $shortcuts += [pscustomobject]@{
                Name = $item.Name
                FullName = $item.FullName
                Extension = $item.Extension
                LastWriteTime = $item.LastWriteTime
                Length = $item.Length
                TargetPath = $target
            }
        }
    }

    if ($shell) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
    }

    [pscustomobject]@{
        DesktopPaths = $pathStatus
        ShortcutInventory = $shortcuts
    }
}

function Get-NetworkEvidence {
    $netConfig = @()
    if (Get-Command -Name Get-NetIPConfiguration -ErrorAction SilentlyContinue) {
        $netConfig = Invoke-Safely -Step 'Collecting Get-NetIPConfiguration' -Default @() -Action {
            Get-NetIPConfiguration -ErrorAction Stop |
                Select-Object InterfaceAlias, InterfaceDescription,
                    IPv4Address, IPv4DefaultGateway, DNSServer,
                    NetProfile
        }
    }
    else {
        $netConfig = Invoke-Safely -Step 'Collecting Win32_NetworkAdapterConfiguration' -Default @() -Action {
            Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = True' -ErrorAction Stop |
                Select-Object Description,
                    @{ Name = 'IPAddress'; Expression = { $_.IPAddress -join ';' } },
                    @{ Name = 'DefaultIPGateway'; Expression = { $_.DefaultIPGateway -join ';' } },
                    @{ Name = 'DNSServerSearchOrder'; Expression = { $_.DNSServerSearchOrder -join ';' } }
        }
    }

    $dns = @()
    if (Get-Command -Name Get-DnsClientServerAddress -ErrorAction SilentlyContinue) {
        $dns = Invoke-Safely -Step 'Collecting DNS client server addresses' -Default @() -Action {
            Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
                Select-Object InterfaceAlias,
                    @{ Name = 'ServerAddresses'; Expression = { $_.ServerAddresses -join ';' } }
        }
    }

    $computerSystem = Invoke-Safely -Step 'Collecting domain membership details' -Default $null -Action {
        Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    }

    $secureChannel = Invoke-Safely -Step 'Testing computer secure channel' -Default $null -Action {
        Test-ComputerSecureChannel -ErrorAction Stop
    }

    $authEvents = Read-EventLogs -LogNames @('System', 'Application') -StartTime ((Get-Date).AddDays(-$LookbackDays)) -Ids @(5719, 40960, 40961, 1129, 1055, 1058, 1030) -ProviderPattern 'NETLOGON|LSA|GroupPolicy|Userenv|Kerberos' -MaxEvents 400

    [pscustomobject]@{
        NetworkConfiguration = $netConfig
        DnsConfiguration = $dns
        Domain = [pscustomobject]@{
            PartOfDomain = if ($computerSystem) { $computerSystem.PartOfDomain } else { $null }
            Domain = if ($computerSystem) { $computerSystem.Domain } else { $null }
            ComputerSecureChannelHealthy = $secureChannel
        }
        AuthenticationRelatedErrors = $authEvents
    }
}

function Get-FolderRedirectionEvidence {
    $userShellFolders = Invoke-Safely -Step 'Reading User Shell Folders' -Default $null -Action {
        Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
    }

    $desktopValue = $null
    if ($userShellFolders) {
        $desktopValue = $userShellFolders.Desktop
    }

    $folderRedirectionIndicators = [pscustomobject]@{
        DesktopValue = $desktopValue
        DesktopRedirectedToUNC = if ($desktopValue) { $desktopValue -match '^\\\\' } else { $false }
        DesktopRedirectedToOneDrive = if ($desktopValue) { $desktopValue -match 'OneDrive' } else { $false }
    }

    $oneDriveInfo = [pscustomobject]@{
        OneDriveEnv = $env:OneDrive
        OneDriveCommercialEnv = $env:OneDriveCommercial
        OneDriveConsumerEnv = $env:OneDriveConsumer
        OneDriveProcess = (Get-Process -Name OneDrive -ErrorAction SilentlyContinue |
            Select-Object Name, Id, StartTime, Path)
    }

    [pscustomobject]@{
        UserShellFolders = $userShellFolders
        FolderRedirectionIndicators = $folderRedirectionIndicators
        OneDriveIndicators = $oneDriveInfo
    }
}

function Get-DeploymentFileTimestampEvidence {
    param(
        [datetime]$WindowStart,
        [string]$NamePattern
    )

    $roots = @(
        $env:ProgramData,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        $env:LOCALAPPDATA,
        $env:APPDATA,
        (Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $regex = [regex]$NamePattern
    $matches = @()

    foreach ($root in $roots) {
        $items = Invoke-Safely -Step "Scanning changed files under $root" -Default @() -Action {
            Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.LastWriteTime -ge $WindowStart -and
                    ($_.Name -match $regex -or $_.DirectoryName -match $regex)
                } |
                Select-Object FullName, Length, LastWriteTime
        }

        if ($items.Count -gt 0) {
            $matches += $items
        }

        if ($matches.Count -ge 1000) {
            Add-WarningRecord 'File timestamp evidence truncated at 1000 records for performance safety.'
            break
        }
    }

    $matches | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1000
}

function Invoke-GpResultCapture {
    if ($DryRun) {
        Write-Status 'DryRun: would run gpresult and capture policy output.'
        return [pscustomobject]@{ TextPath = $null; HtmlPath = $null; ExitCode = $null }
    }

    $txtPath = Join-Path -Path $script:EvidenceRoot -ChildPath 'GpResult.txt'
    $htmlPath = Join-Path -Path $script:EvidenceRoot -ChildPath 'GpResult.html'

    $txtExit = Invoke-Safely -Step 'Running gpresult /z' -Default -1 -Action {
        & gpresult /z > $txtPath
        $LASTEXITCODE
    }

    $htmlExit = Invoke-Safely -Step 'Running gpresult /h' -Default -1 -Action {
        & gpresult /h $htmlPath /f | Out-Null
        $LASTEXITCODE
    }

    [pscustomobject]@{
        TextPath = $txtPath
        HtmlPath = $htmlPath
        ExitCode = "txt=$txtExit;html=$htmlExit"
    }
}

try {
    Write-Status 'Starting deployment-impact evidence collection.'
    Write-Status "DryRun: $DryRun"

    $script:EvidenceRoot = New-EvidenceFolder

    if (-not $DryRun) {
        $script:TranscriptPath = Join-Path -Path $script:EvidenceRoot -ChildPath 'Transcript.log'
        Start-Transcript -Path $script:TranscriptPath -Force | Out-Null
    }

    $identity = Invoke-Safely -Step 'Collecting system identity' -Default $null -Action {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

        [pscustomobject]@{
            ComputerName = $env:COMPUTERNAME
            LoggedOnUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            Domain = $cs.Domain
            PartOfDomain = $cs.PartOfDomain
            OSName = $os.Caption
            OSVersion = $os.Version
            OSBuild = $os.BuildNumber
            LastBootTime = $os.LastBootUpTime
            LocalTime = $os.LocalDateTime
            ScriptStartTime = $script:Started
        }
    }

    $installedPrograms = Get-InstalledPrograms
    $recentSoftware = $installedPrograms | Where-Object {
        $converted = Convert-InstallDate -InstallDateRaw $_.InstallDateRaw
        $converted -and $converted -ge (Get-Date).AddDays(-$LookbackDays)
    } | Select-Object *, @{
        Name = 'InstallDateParsed'; Expression = {
            Convert-InstallDate -InstallDateRaw $_.InstallDateRaw
        }
    }

    $deploymentApps = $installedPrograms | Where-Object {
        $_.DisplayName -match $DmsNamePattern -or $_.Publisher -match $DmsNamePattern
    }

    $startupApps = Get-StartupInventory
    $scheduledTasks = Get-ScheduledTaskInventory
    $processes = Get-ProcessInventory
    $utilization = Get-UtilizationSnapshot
    $deploymentServices = Get-ServicesByPattern -Patterns $DeploymentServicePatterns

    $eventStart = (Get-Date).AddDays(-$LookbackDays)
    $generalEvents = Read-EventLogs -LogNames @('Application', 'System') -StartTime $eventStart -Ids @() -ProviderPattern '' -MaxEvents 600
    $loginEvents = Read-EventLogs -LogNames @('System', 'Application') -StartTime $eventStart -Ids @(6005, 6006, 6008, 7000, 7001, 7011, 7031, 7034) -ProviderPattern 'Winlogon|User Profile Service|GroupPolicy|Service Control Manager|Microsoft-Windows-GroupPolicy' -MaxEvents 500

    $securityLogons = @()
    if ($IncludeSecurityLog) {
        $securityLogons = Read-EventLogs -LogNames @('Security') -StartTime $eventStart -Ids @(4624, 4625, 4648, 4672, 4768, 4769, 4771, 4776) -ProviderPattern '' -MaxEvents 800
    }

    $gpResult = Invoke-GpResultCapture
    $profileEvidence = Get-UserProfileEvidence
    $desktopEvidence = Get-DesktopEvidence
    $networkEvidence = Get-NetworkEvidence
    $redirectionEvidence = Get-FolderRedirectionEvidence
    $fileTimestampEvidence = Get-DeploymentFileTimestampEvidence -WindowStart $DeploymentWindowStart -NamePattern $DmsNamePattern

    $appErrors = $generalEvents | Where-Object {
        $_.LevelDisplayName -in @('Error', 'Critical') -and ($_.ProviderName -match $DmsNamePattern -or $_.Message -match $DmsNamePattern)
    }

    $summary = [pscustomobject]@{
        Investigation = 'Deployment-related endpoint impact (Floor 6)'
        ComputerName = $env:COMPUTERNAME
        CollectedAt = Get-Date
        DryRun = [bool]$DryRun
        LookbackDays = $LookbackDays
        DeploymentWindowStart = $DeploymentWindowStart
        DmsNamePattern = $DmsNamePattern
        Counts = [pscustomobject]@{
            InstalledPrograms = @($installedPrograms).Count
            RecentlyInstalled = @($recentSoftware).Count
            DeploymentMatchedApps = @($deploymentApps).Count
            StartupEntries = @($startupApps).Count
            ScheduledTasks = @($scheduledTasks).Count
            Processes = @($processes).Count
            DeploymentRelatedServices = @($deploymentServices).Count
            GeneralEvents = @($generalEvents).Count
            LoginRelatedEvents = @($loginEvents).Count
            SecurityAuthEvents = @($securityLogons).Count
            ShortcutCount = @($desktopEvidence.ShortcutInventory).Count
            AuthenticationErrors = @($networkEvidence.AuthenticationRelatedErrors).Count
            TempProfileIndicators = @($profileEvidence.TemporaryProfileIndicators).Count
            DeploymentTimestampMatches = @($fileTimestampEvidence).Count
            DmsAppErrors = @($appErrors).Count
        }
        Warnings = $script:Warnings
        Errors = $script:Errors
    }

    Export-JsonArtifact -Name 'SystemInfo' -Data $identity
    Export-CsvArtifact -Name 'InstalledSoftware' -Data $installedPrograms
    Export-CsvArtifact -Name 'RecentlyInstalledSoftware' -Data $recentSoftware
    Export-CsvArtifact -Name 'DeploymentMatchedSoftware' -Data $deploymentApps
    Export-CsvArtifact -Name 'StartupApplications' -Data $startupApps
    Export-CsvArtifact -Name 'ScheduledTasks' -Data $scheduledTasks
    Export-CsvArtifact -Name 'RunningProcesses' -Data $processes
    Export-JsonArtifact -Name 'UtilizationSnapshot' -Data $utilization
    Export-CsvArtifact -Name 'Services' -Data $deploymentServices
    Export-CsvArtifact -Name 'EventLogs' -Data $generalEvents
    Export-CsvArtifact -Name 'LoginEventLogs' -Data $loginEvents

    if ($IncludeSecurityLog) {
        Export-CsvArtifact -Name 'SecurityLogonEvents' -Data $securityLogons
    }

    Export-JsonArtifact -Name 'GpResultMetadata' -Data $gpResult
    Export-JsonArtifact -Name 'UserProfile' -Data $profileEvidence
    Export-CsvArtifact -Name 'DesktopShortcuts' -Data $desktopEvidence.ShortcutInventory
    Export-JsonArtifact -Name 'DesktopPathVerification' -Data $desktopEvidence.DesktopPaths
    Export-JsonArtifact -Name 'NetworkInfo' -Data $networkEvidence
    Export-JsonArtifact -Name 'FolderRedirection' -Data $redirectionEvidence
    Export-CsvArtifact -Name 'DeploymentFileTimestamps' -Data $fileTimestampEvidence
    Export-CsvArtifact -Name 'ApplicationSpecificErrors' -Data $appErrors
    Export-JsonArtifact -Name 'SummaryReport' -Data $summary

    if (-not $DryRun) {
        $artifactIndexPath = Join-Path -Path $script:EvidenceRoot -ChildPath 'ArtifactIndex.json'
        $script:Artifacts.GetEnumerator() |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject]@{ Name = $_.Name; Path = $_.Value }
            } | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $artifactIndexPath -Encoding UTF8
    }

    Write-Status 'Evidence collection complete.'

    if ($DryRun) {
        Write-Status 'DryRun completed. No files were written.'
    }
    else {
        Write-Status "Evidence folder: $script:EvidenceRoot"
    }
}
catch {
    Add-ErrorRecord "Unhandled failure: $($_.Exception.Message)"
    throw
}
finally {
    if (-not $DryRun -and $script:TranscriptPath) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            Write-Warning "Stop-Transcript failed: $($_.Exception.Message)"
        }
    }

    $ended = Get-Date
    Write-Status "Started: $script:Started"
    Write-Status "Ended:   $ended"
    Write-Status "Duration: $([math]::Round((New-TimeSpan -Start $script:Started -End $ended).TotalSeconds, 2)) seconds"
}
