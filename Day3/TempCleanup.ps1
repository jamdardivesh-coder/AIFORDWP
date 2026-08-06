<#
TempCleanup.ps1
PowerShell version target: 5.1
Purpose: Safe temp-file cleanup for Windows endpoints with dry-run, startup management,
		 detailed logging, summary reporting, rollback support, and idempotent behavior.

Modes:
- Cleanup mode (default): scans temp locations, optionally dry-runs, backs up then deletes files.
- Rollback mode: restores deleted files and re-enables startup items using a prior manifest.
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param(
	# Section: Mode and behavior options
	# This section controls whether the script runs cleanup behavior or rollback behavior.
	[Parameter(ParameterSetName = 'Cleanup')]
	[switch]$DryRun,

	[Parameter(ParameterSetName = 'Cleanup')]
	[ValidateRange(0, 3650)]
	[int]$MinAgeDays = 0,

	[Parameter(ParameterSetName = 'Cleanup')]
	[switch]$Disable,

	[Parameter(ParameterSetName = 'Cleanup')]
	[string]$ProgramName,

	[Parameter(ParameterSetName = 'Rollback')]
	[switch]$Rollback,

	[Parameter(ParameterSetName = 'Rollback')]
	[string]$RollbackManifest,

	# Section: Scope options
	# This section allows overriding which temp paths are targeted in cleanup mode.
	[Parameter(ParameterSetName = 'Cleanup')]
	[string[]]$TargetPaths = @(
		$env:TEMP,
		"$env:windir\Temp"
	),

	# Section: Output location options
	# This section controls where logs and rollback store data are written.
	[string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section: Validate parameter combinations
# This section enforces valid operator inputs for startup disable behavior.
if ($PSCmdlet.ParameterSetName -eq 'Cleanup') {
	if ($Disable -and [string]::IsNullOrWhiteSpace($ProgramName)) {
		throw 'When using -Disable, you must also provide -ProgramName "<startup program name>".'
	}

	if ((-not $Disable) -and (-not [string]::IsNullOrWhiteSpace($ProgramName))) {
		throw '-ProgramName can only be used together with -Disable.'
	}
}

# Section: Resolve output root
# This section safely derives a default output folder when one is not provided.
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

	$OutputRoot = Join-Path -Path $scriptBase -ChildPath 'TempCleanupArtifacts'
}

# Section: Utility functions
# This section contains helper functions for logging, lock checks, and safe path conversion.
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

function Convert-ToSafeRelativePath {
	param([Parameter(Mandatory = $true)][string]$FullPath)

	$drive = [System.IO.Path]::GetPathRoot($FullPath)
	$withoutDrive = $FullPath.Substring($drive.Length)
	$safeDrive = $drive.TrimEnd('\').Replace(':', '')
	$safeRelative = $withoutDrive.TrimStart('\')
	return (Join-Path -Path $safeDrive -ChildPath $safeRelative)
}

function Test-FileUnlocked {
	param([Parameter(Mandatory = $true)][string]$Path)

	try {
		$stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
		$stream.Close()
		return $true
	}
	catch {
		return $false
	}
}

function Get-StartupRegistryLocations {
	# Returns known startup registry locations for current and all users.
	return @(
		@{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'; Type = 'Run' },
		@{ Scope = 'CurrentUser'; Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; Type = 'RunOnce' },
		@{ Scope = 'AllUsers'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'; Type = 'Run' },
		@{ Scope = 'AllUsers'; Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'; Type = 'RunOnce' },
		@{ Scope = 'AllUsers'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Type = 'Run' },
		@{ Scope = 'AllUsers'; Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'; Type = 'RunOnce' }
	)
}

function Get-StartupInventory {
	# Collects startup entries from registry and startup folders.
	$items = New-Object System.Collections.Generic.List[object]

	foreach ($loc in (Get-StartupRegistryLocations)) {
		if (-not (Test-Path -LiteralPath $loc.Path)) {
			continue
		}

		try {
			$key = Get-Item -LiteralPath $loc.Path -ErrorAction Stop
			foreach ($valueName in $key.GetValueNames()) {
				$valueData = $key.GetValue($valueName)
				$items.Add([pscustomobject]@{
					Name = $valueName
					Command = [string]$valueData
					Location = $loc.Path
					EntryType = 'Registry'
					StartupScope = $loc.Scope
				}) | Out-Null
			}
		}
		catch {
			Write-Log -Level 'ERROR' -Message "Failed reading startup registry location '$($loc.Path)': $($_.Exception.Message)"
		}
	}

	$startupFolders = @(
		@{ Scope = 'CurrentUser'; Path = [Environment]::GetFolderPath('Startup') },
		@{ Scope = 'AllUsers'; Path = [Environment]::GetFolderPath('CommonStartup') }
	)

	foreach ($folder in $startupFolders) {
		if ([string]::IsNullOrWhiteSpace($folder.Path)) {
			continue
		}

		if (-not (Test-Path -LiteralPath $folder.Path)) {
			continue
		}

		try {
			Get-ChildItem -LiteralPath $folder.Path -File -Force -ErrorAction Stop | ForEach-Object {
				$items.Add([pscustomobject]@{
					Name = $_.BaseName
					Command = $_.FullName
					Location = $folder.Path
					EntryType = 'StartupFolder'
					StartupScope = $folder.Scope
				}) | Out-Null
			}
		}
		catch {
			Write-Log -Level 'ERROR' -Message "Failed reading startup folder '$($folder.Path)': $($_.Exception.Message)"
		}
	}

	return $items
}

function Disable-StartupEntries {
	param(
		[Parameter(Mandatory = $true)][string]$Name,
		[Parameter(Mandatory = $true)][bool]$IsDryRun,
		[Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$ManifestRows,
		[Parameter(Mandatory = $true)][hashtable]$Summary
	)

	# Matches by startup display name using wildcard support.
	$inventory = Get-StartupInventory
	$matches = @($inventory | Where-Object { $_.Name -like $Name })

	if ($matches.Count -eq 0) {
		Write-Log -Level 'WARN' -Message "No startup entries matched program name filter: $Name"
		return
	}

	foreach ($entry in $matches) {
		try {
			if ($IsDryRun) {
				$Summary.StartupDisableDryRunListed++
				Write-Log -Message "DRYRUN would disable startup entry: Name='$($entry.Name)'; Type='$($entry.EntryType)'; Location='$($entry.Location)'"
				continue
			}

			if ($entry.EntryType -eq 'Registry') {
				if (-not (Test-Path -LiteralPath $entry.Location)) {
					$Summary.StartupAlreadyDisabled++
					Write-Log -Level 'WARN' -Message "Startup key no longer present. Already disabled/skipped: $($entry.Location)"
					continue
				}

				$key = Get-Item -LiteralPath $entry.Location -ErrorAction Stop
				$existingNames = @($key.GetValueNames())

				if (-not ($existingNames -contains $entry.Name)) {
					$Summary.StartupAlreadyDisabled++
					Write-Log -Level 'WARN' -Message "Startup registry value already disabled or missing: Name='$($entry.Name)' in '$($entry.Location)'"
					continue
				}

				Remove-ItemProperty -LiteralPath $entry.Location -Name $entry.Name -ErrorAction Stop
				$Summary.StartupDisabled++
				Write-Log -Message "Disabled startup registry entry: Name='$($entry.Name)' at '$($entry.Location)'"

				$ManifestRows.Add([pscustomobject]@{
					ActionType = 'StartupRegistryDisable'
					OriginalPath = ''
					BackupPath = ''
					LastWriteTime = ''
					Length = ''
					StartupName = $entry.Name
					StartupCommand = $entry.Command
					StartupLocation = $entry.Location
					StartupEntryType = $entry.EntryType
					StartupScope = $entry.StartupScope
				}) | Out-Null
			}
			elseif ($entry.EntryType -eq 'StartupFolder') {
				if (-not (Test-Path -LiteralPath $entry.Command)) {
					$Summary.StartupAlreadyDisabled++
					Write-Log -Level 'WARN' -Message "Startup folder item already missing. Already disabled/skipped: $($entry.Command)"
					continue
				}

				$startupDisabledRoot = Join-Path -Path $script:RollbackStoreRoot -ChildPath 'StartupDisabled'
				$safeRelative = Convert-ToSafeRelativePath -FullPath $entry.Command
				$disabledPath = Join-Path -Path $startupDisabledRoot -ChildPath $safeRelative
				$disabledDir = Split-Path -Path $disabledPath -Parent

				if (-not (Test-Path -LiteralPath $disabledDir)) {
					New-Item -Path $disabledDir -ItemType Directory -Force | Out-Null
				}

				Copy-Item -LiteralPath $entry.Command -Destination $disabledPath -Force
				Remove-Item -LiteralPath $entry.Command -Force
				$Summary.StartupDisabled++
				Write-Log -Message "Disabled startup folder entry: Name='$($entry.Name)' moved from '$($entry.Command)' to '$disabledPath'"

				$ManifestRows.Add([pscustomobject]@{
					ActionType = 'StartupFolderDisable'
					OriginalPath = $entry.Command
					BackupPath = $disabledPath
					LastWriteTime = ''
					Length = ''
					StartupName = $entry.Name
					StartupCommand = $entry.Command
					StartupLocation = $entry.Location
					StartupEntryType = $entry.EntryType
					StartupScope = $entry.StartupScope
				}) | Out-Null
			}
		}
		catch {
			$Summary.ErrorCount++
			Write-Log -Level 'ERROR' -Message "Failed disabling startup entry '$($entry.Name)' at '$($entry.Location)': $($_.Exception.Message)"
		}
	}
}

# Section: Initialization
# This section creates timestamped log/manifest paths and folders used by the script.
$runId = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path -LiteralPath $OutputRoot)) {
	New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
}

$script:LogFile = Join-Path -Path $OutputRoot -ChildPath ("TempCleanup_{0}.log" -f $runId)
New-Item -Path $script:LogFile -ItemType File -Force | Out-Null

$script:RollbackStoreRoot = Join-Path -Path $OutputRoot -ChildPath ("RollbackStore_{0}" -f $runId)
$manifestPath = Join-Path -Path $OutputRoot -ChildPath ("Manifest_{0}.csv" -f $runId)

# Section: Summary counters
# This section tracks actions and outcomes for end-of-run reporting.
$summary = [ordered]@{
	TotalCandidates = 0
	EligibleByAge = 0
	DryRunListed = 0
	BackedUp = 0
	Deleted = 0
	LockedSkipped = 0
	MissingSkipped = 0
	StartupEntriesListed = 0
	StartupDisabled = 0
	StartupAlreadyDisabled = 0
	StartupDisableDryRunListed = 0
	ErrorCount = 0
	RollbackRestoredFiles = 0
	RollbackRestoredStartup = 0
	RollbackSkipped = 0
}

# Section: Rollback mode
# This section restores files and startup entries from a prior cleanup run using its manifest.
if ($PSCmdlet.ParameterSetName -eq 'Rollback') {
	if ([string]::IsNullOrWhiteSpace($RollbackManifest)) {
		Write-Log -Level 'ERROR' -Message 'Rollback mode requires -RollbackManifest <path-to-manifest.csv>.'
		Write-Host ''
		Write-Host 'Usage:'
		Write-Host '  powershell -NoProfile -ExecutionPolicy Bypass -File .\Day3\TempCleanup.ps1 -Rollback -RollbackManifest ".\Day3\TempCleanupArtifacts\Manifest_YYYYMMDD_HHMMSS.csv"'
		Write-Host ''
		Write-Host ("Log file: {0}" -f $script:LogFile)
		exit 2
	}

	try {
		Write-Log -Message "Starting rollback mode. Manifest: $RollbackManifest"

		if (-not (Test-Path -LiteralPath $RollbackManifest)) {
			throw "Rollback manifest not found: $RollbackManifest"
		}

		$entries = Import-Csv -Path $RollbackManifest
		foreach ($entry in $entries) {
			try {
				$actionType = if ([string]::IsNullOrWhiteSpace($entry.ActionType)) { 'FileDelete' } else { $entry.ActionType }

				if ($actionType -eq 'FileDelete') {
					$backupPath = $entry.BackupPath
					$originalPath = $entry.OriginalPath

					if ([string]::IsNullOrWhiteSpace($backupPath) -or [string]::IsNullOrWhiteSpace($originalPath)) {
						$summary.RollbackSkipped++
						Write-Log -Level 'WARN' -Message 'Manifest file restore row missing paths. Skipping malformed row.'
						continue
					}

					if (-not (Test-Path -LiteralPath $backupPath)) {
						$summary.RollbackSkipped++
						Write-Log -Level 'WARN' -Message "Backup file missing, cannot restore: $backupPath"
						continue
					}

					$destDir = Split-Path -Path $originalPath -Parent
					if (-not (Test-Path -LiteralPath $destDir)) {
						New-Item -Path $destDir -ItemType Directory -Force | Out-Null
					}

					Copy-Item -LiteralPath $backupPath -Destination $originalPath -Force
					$summary.RollbackRestoredFiles++
					Write-Log -Message "Restored file: $originalPath"
				}
				elseif ($actionType -eq 'StartupRegistryDisable') {
					if ([string]::IsNullOrWhiteSpace($entry.StartupLocation) -or [string]::IsNullOrWhiteSpace($entry.StartupName)) {
						$summary.RollbackSkipped++
						Write-Log -Level 'WARN' -Message 'Manifest startup registry row missing required data. Skipping malformed row.'
						continue
					}

					if (-not (Test-Path -LiteralPath $entry.StartupLocation)) {
						New-Item -Path $entry.StartupLocation -Force | Out-Null
					}

					$existing = Get-ItemProperty -LiteralPath $entry.StartupLocation -ErrorAction SilentlyContinue
					$hasName = $false
					if ($null -ne $existing) {
						$hasName = @($existing.PSObject.Properties.Name) -contains $entry.StartupName
					}

					if ($hasName) {
						Set-ItemProperty -LiteralPath $entry.StartupLocation -Name $entry.StartupName -Value $entry.StartupCommand -Force
					}
					else {
						New-ItemProperty -LiteralPath $entry.StartupLocation -Name $entry.StartupName -Value $entry.StartupCommand -PropertyType String -Force | Out-Null
					}

					$summary.RollbackRestoredStartup++
					Write-Log -Message "Restored startup registry entry: Name='$($entry.StartupName)' at '$($entry.StartupLocation)'"
				}
				elseif ($actionType -eq 'StartupFolderDisable') {
					if ([string]::IsNullOrWhiteSpace($entry.OriginalPath) -or [string]::IsNullOrWhiteSpace($entry.BackupPath)) {
						$summary.RollbackSkipped++
						Write-Log -Level 'WARN' -Message 'Manifest startup folder row missing required paths. Skipping malformed row.'
						continue
					}

					if (-not (Test-Path -LiteralPath $entry.BackupPath)) {
						$summary.RollbackSkipped++
						Write-Log -Level 'WARN' -Message "Startup backup missing, cannot restore: $($entry.BackupPath)"
						continue
					}

					$destDir = Split-Path -Path $entry.OriginalPath -Parent
					if (-not (Test-Path -LiteralPath $destDir)) {
						New-Item -Path $destDir -ItemType Directory -Force | Out-Null
					}

					Copy-Item -LiteralPath $entry.BackupPath -Destination $entry.OriginalPath -Force
					$summary.RollbackRestoredStartup++
					Write-Log -Message "Restored startup folder entry: $($entry.OriginalPath)"
				}
				else {
					$summary.RollbackSkipped++
					Write-Log -Level 'WARN' -Message "Unknown ActionType '$actionType' in manifest row. Skipping."
				}
			}
			catch {
				$summary.ErrorCount++
				Write-Log -Level 'ERROR' -Message "Rollback failed for row with ActionType '$($entry.ActionType)': $($_.Exception.Message)"
			}
		}

		Write-Log -Message "Rollback completed. RestoredFiles=$($summary.RollbackRestoredFiles), RestoredStartup=$($summary.RollbackRestoredStartup), Skipped=$($summary.RollbackSkipped), Errors=$($summary.ErrorCount)"
	}
	catch {
		$summary.ErrorCount++
		Write-Log -Level 'ERROR' -Message "Rollback mode failed: $($_.Exception.Message)"

		Write-Host ""
		Write-Host "=== Summary ==="
		Write-Host ("Rollback restored files   : {0}" -f $summary.RollbackRestoredFiles)
		Write-Host ("Rollback restored startup : {0}" -f $summary.RollbackRestoredStartup)
		Write-Host ("Rollback skipped          : {0}" -f $summary.RollbackSkipped)
		Write-Host ("Errors                    : {0}" -f $summary.ErrorCount)
		Write-Host ("Log file                  : {0}" -f $script:LogFile)
		exit 1
	}

	Write-Host ""
	Write-Host "=== Summary ==="
	Write-Host ("Rollback restored files   : {0}" -f $summary.RollbackRestoredFiles)
	Write-Host ("Rollback restored startup : {0}" -f $summary.RollbackRestoredStartup)
	Write-Host ("Rollback skipped          : {0}" -f $summary.RollbackSkipped)
	Write-Host ("Errors                    : {0}" -f $summary.ErrorCount)
	Write-Host ("Log file                  : {0}" -f $script:LogFile)
	exit 0
}

# Section: Cleanup mode startup inventory
# This section always lists startup items so operators can review startup state safely.
Write-Log -Message 'Enumerating startup programs.'
$startupItems = Get-StartupInventory
if (@($startupItems).Count -eq 0) {
	Write-Log -Level 'WARN' -Message 'No startup programs found in standard startup locations.'
}
else {
	foreach ($item in $startupItems) {
		$summary.StartupEntriesListed++
		Write-Log -Message "STARTUP: Name='$($item.Name)'; Type='$($item.EntryType)'; Scope='$($item.StartupScope)'; Location='$($item.Location)'; Command='$($item.Command)'"
	}
}

# Section: Cleanup mode discovery
# This section discovers candidate files and filters by age threshold.
try {
	Write-Log -Message "Starting cleanup mode. DryRun=$DryRun; MinAgeDays=$MinAgeDays; Disable=$Disable"
	Write-Log -Message ("Target paths: {0}" -f ($TargetPaths -join '; '))

	$cutoff = (Get-Date).AddDays(-$MinAgeDays)

	$allFiles = New-Object System.Collections.Generic.List[System.IO.FileInfo]
	foreach ($path in $TargetPaths) {
		if ([string]::IsNullOrWhiteSpace($path)) {
			continue
		}

		if (-not (Test-Path -LiteralPath $path)) {
			Write-Log -Level 'WARN' -Message "Target path not found, skipping: $path"
			continue
		}

		try {
			Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction Stop | ForEach-Object { [void]$allFiles.Add($_) }
		}
		catch {
			$summary.ErrorCount++
			Write-Log -Level 'ERROR' -Message "Failed enumerating target path '$path': $($_.Exception.Message)"
		}
	}

	$summary.TotalCandidates = $allFiles.Count
	$eligibleFiles = $allFiles | Where-Object { $_.LastWriteTime -lt $cutoff }
	$summary.EligibleByAge = @($eligibleFiles).Count

	Write-Log -Message "Candidates found: $($summary.TotalCandidates). Eligible by age: $($summary.EligibleByAge)."
}
catch {
	Write-Log -Level 'ERROR' -Message "Cleanup discovery failed: $($_.Exception.Message)"
	throw
}

$manifestRows = New-Object System.Collections.Generic.List[object]

# Section: Startup disable action
# This section disables requested startup entries with rollback metadata for restoration.
if ($Disable) {
	Disable-StartupEntries -Name $ProgramName -IsDryRun:$DryRun -ManifestRows $manifestRows -Summary $summary
}

# Section: Dry-run output
# This section prints which files would be deleted without changing any files.
if ($DryRun) {
	Write-Log -Message "Dry run selected. Listing files that would be deleted."
	foreach ($file in $eligibleFiles) {
		$summary.DryRunListed++
		Write-Log -Message ("DRYRUN would delete: {0}" -f $file.FullName)
	}

	Write-Host ""
	Write-Host "=== Summary ==="
	Write-Host ("Startup entries listed      : {0}" -f $summary.StartupEntriesListed)
	Write-Host ("Startup disable dry-run     : {0}" -f $summary.StartupDisableDryRunListed)
	Write-Host ("Total candidates            : {0}" -f $summary.TotalCandidates)
	Write-Host ("Eligible by age             : {0}" -f $summary.EligibleByAge)
	Write-Host ("Dry-run listed for deletion : {0}" -f $summary.DryRunListed)
	Write-Host ("Errors                      : {0}" -f $summary.ErrorCount)
	Write-Host ("Log file                    : {0}" -f $script:LogFile)
	exit 0
}

# Section: Prepare rollback store
# This section creates folders used to store backup copies for rollback.
if (-not (Test-Path -LiteralPath $script:RollbackStoreRoot)) {
	New-Item -Path $script:RollbackStoreRoot -ItemType Directory -Force | Out-Null
}

# Section: Per-file cleanup with error handling
# This section processes each eligible file with lock checks, backup, delete, and logging.
foreach ($file in $eligibleFiles) {
	try {
		if (-not (Test-Path -LiteralPath $file.FullName)) {
			$summary.MissingSkipped++
			Write-Log -Level 'WARN' -Message "File missing (already removed), skipping: $($file.FullName)"
			continue
		}

		if (-not (Test-FileUnlocked -Path $file.FullName)) {
			$summary.LockedSkipped++
			Write-Log -Level 'WARN' -Message "File locked, skipped: $($file.FullName)"
			continue
		}

		$relative = Convert-ToSafeRelativePath -FullPath $file.FullName
		$backupPath = Join-Path -Path $script:RollbackStoreRoot -ChildPath $relative
		$backupDir = Split-Path -Path $backupPath -Parent

		if (-not (Test-Path -LiteralPath $backupDir)) {
			New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
		}

		Copy-Item -LiteralPath $file.FullName -Destination $backupPath -Force
		$summary.BackedUp++
		Write-Log -Message "Backed up: $($file.FullName) -> $backupPath"

		Remove-Item -LiteralPath $file.FullName -Force
		$summary.Deleted++
		Write-Log -Message "Deleted: $($file.FullName)"

		$manifestRows.Add([pscustomobject]@{
			ActionType = 'FileDelete'
			OriginalPath = $file.FullName
			BackupPath = $backupPath
			LastWriteTime = $file.LastWriteTime
			Length = $file.Length
			StartupName = ''
			StartupCommand = ''
			StartupLocation = ''
			StartupEntryType = ''
			StartupScope = ''
		}) | Out-Null
	}
	catch {
		$summary.ErrorCount++
		Write-Log -Level 'ERROR' -Message "Failed processing '$($file.FullName)': $($_.Exception.Message)"
	}
}

# Section: Manifest write
# This section writes rollback metadata for this run after processing files/startup actions.
try {
	$manifestRows | Export-Csv -Path $manifestPath -NoTypeInformation -Force
	Write-Log -Message "Rollback manifest saved: $manifestPath"
}
catch {
	$summary.ErrorCount++
	Write-Log -Level 'ERROR' -Message "Failed writing rollback manifest: $($_.Exception.Message)"
}

# Section: Final summary
# This section reports aggregate results and artifact locations.
Write-Host ""
Write-Host "=== Summary ==="
Write-Host ("Startup entries listed  : {0}" -f $summary.StartupEntriesListed)
Write-Host ("Startup disabled        : {0}" -f $summary.StartupDisabled)
Write-Host ("Startup already skipped : {0}" -f $summary.StartupAlreadyDisabled)
Write-Host ("Total candidates        : {0}" -f $summary.TotalCandidates)
Write-Host ("Eligible by age         : {0}" -f $summary.EligibleByAge)
Write-Host ("Backed up               : {0}" -f $summary.BackedUp)
Write-Host ("Deleted                 : {0}" -f $summary.Deleted)
Write-Host ("Locked skipped          : {0}" -f $summary.LockedSkipped)
Write-Host ("Missing skipped         : {0}" -f $summary.MissingSkipped)
Write-Host ("Errors                  : {0}" -f $summary.ErrorCount)
Write-Host ("Log file                : {0}" -f $script:LogFile)
Write-Host ("Rollback store          : {0}" -f $script:RollbackStoreRoot)
Write-Host ("Manifest file           : {0}" -f $manifestPath)
