<#
StartupProgramManager.ps1
PowerShell version target: 5.1
Purpose: Safely list and optionally disable startup programs on Windows endpoints
         with dry-run support, per-item error handling, action logging, and summary output.
#>

[CmdletBinding()]
param(
    # Section: Behavior options
    # Controls whether the script only reports data or also disables startup entries.
    [switch]$DryRun,

    [switch]$Disable,

    [string]$ProgramName,

    # Section: Output options
    # Controls where timestamped log files are written.
    [string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section: Parameter validation
# Ensures the operator provides valid and safe parameter combinations.
if ($Disable -and [string]::IsNullOrWhiteSpace($ProgramName)) {
    throw 'When using -Disable you must provide -ProgramName "<startup program name or wildcard>".'
}

if ((-not $Disable) -and (-not [string]::IsNullOrWhiteSpace($ProgramName))) {
    throw '-ProgramName can only be used together with -Disable.'
}

# Section: Resolve output folder and log file
# Derives a safe default output folder when one is not provided.
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $scriptBase = $null

    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $scriptBase = $PSScriptRoot
    }
    elseif ($MyInvocation.MyCommand.Path) {
        $scriptBase = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    }
    else {
        $scriptBase = (Get-Location).Path
    }

    $OutputRoot = Join-Path -Path $scriptBase -ChildPath 'StartupProgramArtifacts'
}

if (-not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
}

$runStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogFile = Join-Path -Path $OutputRoot -ChildPath ("StartupProgramManager_{0}.log" -f $runStamp)
New-Item -Path $script:LogFile -ItemType File -Force | Out-Null

# Section: Summary counters
# Tracks each important outcome so operators get an end-of-run report.
$summary = [ordered]@{
    RegistryLocationsScanned      = 0
    StartupFoldersScanned         = 0
    StartupEntriesListed          = 0
    MatchedForDisable             = 0
    DisableAttempted              = 0
    DisableSucceeded              = 0
    DisableDryRunListed           = 0
    AlreadyDisabled               = 0
    Skipped                       = 0
    Errors                        = 0
}

# Section: Logging utility
# Writes every action to console and to the timestamped log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $line = "[$timestamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $script:LogFile -Value $line
}

# Section: Startup source definitions
# Defines registry and startup-folder locations that are safe to inspect.
function Get-StartupRegistryLocations {
    return @(
        @{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Type = 'Run' },
        @{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; Type = 'RunOnce' },
        @{ Scope = 'AllUsers'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'; Type = 'Run' },
        @{ Scope = 'AllUsers'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; Type = 'RunOnce' },
        @{ Scope = 'AllUsers'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Type = 'Run' },
        @{ Scope = 'AllUsers'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'; Type = 'RunOnce' }
    )
}

function Get-StartupFolderLocations {
    return @(
        @{ Scope = 'CurrentUser'; Path = [Environment]::GetFolderPath('Startup') },
        @{ Scope = 'AllUsers'; Path = [Environment]::GetFolderPath('CommonStartup') }
    )
}

# Section: Startup inventory collection
# Collects startup entries with per-location and per-file error handling.
function Get-StartupInventory {
    $items = New-Object System.Collections.Generic.List[object]
    $startupFileExtensions = @('.lnk', '.exe', '.bat', '.cmd', '.vbs', '.js', '.jse', '.vbe', '.wsf', '.wsh', '.ps1', '.url')

    foreach ($loc in (Get-StartupRegistryLocations)) {
        $summary.RegistryLocationsScanned++

        if (-not (Test-Path -LiteralPath $loc.Path)) {
            Write-Log -Level 'WARN' -Message ("Registry startup location missing: {0}" -f $loc.Path)
            continue
        }

        try {
            $key = Get-Item -LiteralPath $loc.Path -ErrorAction Stop
            foreach ($valueName in $key.GetValueNames()) {
                try {
                    $valueData = $key.GetValue($valueName)
                    $items.Add([pscustomobject]@{
                        Name         = $valueName
                        Command      = [string]$valueData
                        Location     = $loc.Path
                        EntryType    = 'Registry'
                        StartupScope = $loc.Scope
                        Enabled      = $true
                    }) | Out-Null
                }
                catch {
                    $summary.Errors++
                    Write-Log -Level 'ERROR' -Message ("Failed reading registry value '{0}' in '{1}': {2}" -f $valueName, $loc.Path, $_.Exception.Message)
                }
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed reading registry startup location '{0}': {1}" -f $loc.Path, $_.Exception.Message)
        }
    }

    foreach ($folder in (Get-StartupFolderLocations)) {
        $summary.StartupFoldersScanned++

        if ([string]::IsNullOrWhiteSpace($folder.Path)) {
            Write-Log -Level 'WARN' -Message ("Startup folder path for scope '{0}' is empty." -f $folder.Scope)
            continue
        }

        if (-not (Test-Path -LiteralPath $folder.Path)) {
            Write-Log -Level 'WARN' -Message ("Startup folder missing: {0}" -f $folder.Path)
            continue
        }

        try {
            Get-ChildItem -LiteralPath $folder.Path -File -Force -ErrorAction Stop | ForEach-Object {
                try {
                    if ($_.Name -like '*.disabled-by-dwp') {
                        return
                    }

                    if ($startupFileExtensions -notcontains $_.Extension.ToLowerInvariant()) {
                        return
                    }

                    $items.Add([pscustomobject]@{
                        Name         = $_.BaseName
                        Command      = $_.FullName
                        Location     = $folder.Path
                        EntryType    = 'StartupFolder'
                        StartupScope = $folder.Scope
                        Enabled      = $true
                    }) | Out-Null
                }
                catch {
                    $summary.Errors++
                    Write-Log -Level 'ERROR' -Message ("Failed processing startup file '{0}': {1}" -f $_.FullName, $_.Exception.Message)
                }
            }
        }
        catch {
            $summary.Errors++
            Write-Log -Level 'ERROR' -Message ("Failed reading startup folder '{0}': {1}" -f $folder.Path, $_.Exception.Message)
        }
    }

    return $items
}

# Section: Disable operation helpers
# Provides idempotent disable actions for registry and startup-folder entries.
function Disable-RegistryStartupEntry {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Entry,
        [Parameter(Mandatory = $true)][bool]$IsDryRun
    )

    $disabledPath = '{0}_DisabledByDWP' -f $Entry.Location

    try {
        if ($IsDryRun) {
            $summary.DisableDryRunListed++
            Write-Log -Message ("DRYRUN would disable registry startup entry: Name='{0}', Location='{1}'" -f $Entry.Name, $Entry.Location)
            return
        }

        $sourceExists = Test-Path -LiteralPath $Entry.Location
        if (-not $sourceExists) {
            $summary.AlreadyDisabled++
            Write-Log -Level 'WARN' -Message ("Source registry key missing for '{0}'. Treating as already disabled." -f $Entry.Name)
            return
        }

        if (-not (Test-Path -LiteralPath $disabledPath)) {
            New-Item -Path $disabledPath -Force | Out-Null
            Write-Log -Message ("Created disabled registry container: {0}" -f $disabledPath)
        }

        $sourceKey = Get-Item -LiteralPath $Entry.Location -ErrorAction Stop
        $valueNames = $sourceKey.GetValueNames()

        if ($valueNames -notcontains $Entry.Name) {
            $summary.AlreadyDisabled++
            Write-Log -Level 'WARN' -Message ("Startup value already absent, skipping: Name='{0}', Location='{1}'" -f $Entry.Name, $Entry.Location)
            return
        }

        $data = (Get-ItemProperty -LiteralPath $Entry.Location -Name $Entry.Name -ErrorAction Stop).$($Entry.Name)
        New-ItemProperty -Path $disabledPath -Name $Entry.Name -Value $data -PropertyType String -Force | Out-Null
        Remove-ItemProperty -LiteralPath $Entry.Location -Name $Entry.Name -ErrorAction Stop

        $summary.DisableSucceeded++
        Write-Log -Message ("Disabled registry startup entry: Name='{0}', MovedTo='{1}'" -f $Entry.Name, $disabledPath)
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed disabling registry startup entry '{0}': {1}" -f $Entry.Name, $_.Exception.Message)
    }
}

function Disable-StartupFolderEntry {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Entry,
        [Parameter(Mandatory = $true)][bool]$IsDryRun
    )

    try {
        $sourcePath = $Entry.Command
        $disabledPath = '{0}.disabled-by-dwp' -f $sourcePath

        if ($IsDryRun) {
            $summary.DisableDryRunListed++
            Write-Log -Message ("DRYRUN would disable startup folder entry: Name='{0}', File='{1}'" -f $Entry.Name, $sourcePath)
            return
        }

        if (-not (Test-Path -LiteralPath $sourcePath)) {
            if (Test-Path -LiteralPath $disabledPath) {
                $summary.AlreadyDisabled++
                Write-Log -Level 'WARN' -Message ("Startup file already disabled, skipping: {0}" -f $disabledPath)
                return
            }

            $summary.Skipped++
            Write-Log -Level 'WARN' -Message ("Startup file missing, skipping: {0}" -f $sourcePath)
            return
        }

        Move-Item -LiteralPath $sourcePath -Destination $disabledPath -Force -ErrorAction Stop
        $summary.DisableSucceeded++
        Write-Log -Message ("Disabled startup folder entry: Name='{0}', RenamedTo='{1}'" -f $Entry.Name, $disabledPath)
    }
    catch {
        $summary.Errors++
        Write-Log -Level 'ERROR' -Message ("Failed disabling startup folder entry '{0}': {1}" -f $Entry.Name, $_.Exception.Message)
    }
}

# Section: Startup listing output
# Displays startup items in a clear table for endpoint operators.
function Show-StartupInventory {
    param([Parameter(Mandatory = $true)][object[]]$Inventory)

    if ($Inventory.Count -eq 0) {
        Write-Log -Level 'WARN' -Message 'No enabled startup entries were discovered.'
        return
    }

    $summary.StartupEntriesListed = $Inventory.Count

    Write-Log -Message 'Listing enabled startup entries.'

    $Inventory |
        Sort-Object -Property Name, EntryType, StartupScope |
        Select-Object Name, EntryType, StartupScope, Location, Command |
        Format-Table -AutoSize |
        Out-String -Width 4096 |
        ForEach-Object { $_.TrimEnd() } |
        ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_)) {
                Write-Host $_
                Add-Content -Path $script:LogFile -Value $_
            }
        }
}

# Section: Disable orchestration
# Applies disable behavior to matching entries with wildcard program matching.
function Disable-StartupEntries {
    param(
        [Parameter(Mandatory = $true)][string]$NameFilter,
        [Parameter(Mandatory = $true)][bool]$IsDryRun,
        [Parameter(Mandatory = $true)][object[]]$Inventory
    )

    $matches = @($Inventory | Where-Object { $_.Name -like $NameFilter })
    $summary.MatchedForDisable = $matches.Count

    if ($matches.Count -eq 0) {
        Write-Log -Level 'WARN' -Message ("No startup entries matched filter: {0}" -f $NameFilter)
        return
    }

    foreach ($entry in $matches) {
        $summary.DisableAttempted++

        if ($entry.EntryType -eq 'Registry') {
            Disable-RegistryStartupEntry -Entry $entry -IsDryRun:$IsDryRun
        }
        elseif ($entry.EntryType -eq 'StartupFolder') {
            Disable-StartupFolderEntry -Entry $entry -IsDryRun:$IsDryRun
        }
        else {
            $summary.Skipped++
            Write-Log -Level 'WARN' -Message ("Unsupported entry type skipped: {0}" -f $entry.EntryType)
        }
    }
}

# Section: Script execution
# Executes startup listing and optional disable behavior.
Write-Log -Message 'Startup program manager started.'
Write-Log -Message ("Mode flags: DryRun={0}, Disable={1}" -f $DryRun, $Disable)
Write-Log -Message ("Log file: {0}" -f $script:LogFile)

$inventory = @(Get-StartupInventory)
Show-StartupInventory -Inventory $inventory

if ($Disable) {
    Write-Log -Message ("Disable operation requested for filter: {0}" -f $ProgramName)
    Disable-StartupEntries -NameFilter $ProgramName -IsDryRun:$DryRun -Inventory $inventory

    if (-not $DryRun) {
        Write-Log -Message 'Refreshing startup inventory after disable actions.'
        $postInventory = @(Get-StartupInventory)
        Show-StartupInventory -Inventory $postInventory
    }
}

# Section: End-of-run summary
# Prints a concise operational summary and persists it to the log.
Write-Log -Message 'Summary report:'
foreach ($key in $summary.Keys) {
    Write-Log -Message ("  {0}: {1}" -f $key, $summary[$key])
}

Write-Log -Message 'Startup program manager completed.'
