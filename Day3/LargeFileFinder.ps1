<#
LargeFileFinder.ps1
PowerShell version target: 5.1
Purpose: Safely find large files on Windows endpoints with per-file error handling,
         timestamped logging, summary reporting, and idempotent read-only behavior.
#>

[CmdletBinding()]
param(
    # Section: Scan scope options
    # Defines one or more root paths that will be scanned recursively.
    [string[]]$ScanPaths = @(
        'C:\Users',
        'C:\ProgramData'
    ),

    # Section: File size threshold options
    # Sets the minimum file size in megabytes to report as a large file.
    [ValidateRange(1, 1048576)]
    [int]$MinSizeMB = 100,

    # Section: Output options
    # Controls where logs and optional report files are written.
    [string]$OutputRoot,

    # Section: Reporting options
    # When specified, exports discovered large files to a timestamped CSV file.
    [switch]$ExportCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section: Resolve output folder and log file
# Derives a safe default output folder when one is not supplied.
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

    $OutputRoot = Join-Path -Path $scriptBase -ChildPath 'LargeFileFinderArtifacts'
}

if (-not (Test-Path -LiteralPath $OutputRoot)) {
    New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
}

$runStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$script:LogFile = Join-Path -Path $OutputRoot -ChildPath ("LargeFileFinder_{0}.log" -f $runStamp)
New-Item -Path $script:LogFile -ItemType File -Force | Out-Null

$script:CsvFile = $null
if ($ExportCsv) {
    $script:CsvFile = Join-Path -Path $OutputRoot -ChildPath ("LargeFiles_{0}.csv" -f $runStamp)
}

# Section: Summary counters
# Tracks runtime outcomes for end-of-run reporting.
$summary = [ordered]@{
    PathsRequested                = 0
    PathsScanned                  = 0
    PathsMissing                  = 0
    FileCandidatesEnumerated      = 0
    LargeFilesFound               = 0
    PerFileErrors                 = 0
    PathEnumerationErrors         = 0
    CsvExported                   = 0
}

# Section: Logging utility
# Logs every action to console and to a timestamped log file.
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

# Section: Large file scanner
# Recursively scans each valid path and evaluates each file with per-file error handling.
function Find-LargeFiles {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][Int64]$MinBytes
    )

    $results = New-Object System.Collections.Generic.List[object]

    foreach ($path in $Paths) {
        $summary.PathsRequested++

        if ([string]::IsNullOrWhiteSpace($path)) {
            $summary.PathsMissing++
            Write-Log -Level 'WARN' -Message 'Skipped an empty scan path value.'
            continue
        }

        if (-not (Test-Path -LiteralPath $path)) {
            $summary.PathsMissing++
            Write-Log -Level 'WARN' -Message ("Scan path does not exist: {0}" -f $path)
            continue
        }

        $summary.PathsScanned++
        Write-Log -Message ("Scanning path: {0}" -f $path)

        try {
            $enumerationErrors = @()

            # Suppress direct access-denied error stream output; inaccessible paths are handled via ErrorVariable.
            Get-ChildItem -LiteralPath $path -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable +enumerationErrors 2>$null | ForEach-Object {
                try {
                    $summary.FileCandidatesEnumerated++
                    $sizeBytes = [Int64]$_.Length

                    if ($sizeBytes -ge $MinBytes) {
                        $sizeMB = [Math]::Round(($sizeBytes / 1MB), 2)
                        $record = [pscustomobject]@{
                            FullName      = $_.FullName
                            SizeBytes     = $sizeBytes
                            SizeMB        = $sizeMB
                            LastWriteTime = $_.LastWriteTime
                        }

                        $results.Add($record) | Out-Null
                        $summary.LargeFilesFound++
                        Write-Log -Message ("Large file found: {0} ({1} MB)" -f $_.FullName, $sizeMB)
                    }
                }
                catch {
                    $summary.PerFileErrors++
                    Write-Log -Level 'ERROR' -Message ("Failed processing file '{0}': {1}" -f $_.FullName, $_.Exception.Message)
                }
            }

            if ($enumerationErrors.Count -gt 0) {
                foreach ($errRecord in $enumerationErrors) {
                    $summary.PathEnumerationErrors++

                    $blockedPath = $path
                    if ($null -ne $errRecord.TargetObject -and -not [string]::IsNullOrWhiteSpace([string]$errRecord.TargetObject)) {
                        $blockedPath = [string]$errRecord.TargetObject
                    }

                    Write-Log -Level 'WARN' -Message ("Skipped inaccessible path '{0}': {1}" -f $blockedPath, $errRecord.Exception.Message)
                }
            }
        }
        catch {
            $summary.PathEnumerationErrors++
            Write-Log -Level 'ERROR' -Message ("Failed enumerating path '{0}': {1}" -f $path, $_.Exception.Message)
        }
    }

    return $results
}

# Section: Result output
# Displays matching files and optionally exports them to CSV.
function Show-AndExportResults {
    param(
        [Parameter(Mandatory = $true)][object[]]$Items,
        [Parameter(Mandatory = $true)][bool]$ShouldExportCsv
    )

    if ($Items.Count -eq 0) {
        Write-Log -Level 'WARN' -Message 'No large files matched the threshold.'
        return
    }

    Write-Log -Message 'Listing large files sorted by size (descending).'

    $Items |
        Sort-Object -Property SizeBytes -Descending |
        Select-Object FullName, SizeMB, LastWriteTime |
        Format-Table -AutoSize |
        Out-String -Width 4096 |
        ForEach-Object { $_.TrimEnd() } |
        ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_)) {
                Write-Host $_
                Add-Content -Path $script:LogFile -Value $_
            }
        }

    if ($ShouldExportCsv) {
        try {
            $Items |
                Sort-Object -Property SizeBytes -Descending |
                Export-Csv -Path $script:CsvFile -NoTypeInformation -Encoding UTF8

            $summary.CsvExported = 1
            Write-Log -Message ("CSV report written: {0}" -f $script:CsvFile)
        }
        catch {
            Write-Log -Level 'ERROR' -Message ("Failed exporting CSV report '{0}': {1}" -f $script:CsvFile, $_.Exception.Message)
        }
    }
}

# Section: Main execution
# Runs the scan in read-only mode to ensure endpoint-safe and idempotent behavior.
$minBytes = [Int64]$MinSizeMB * 1MB
Write-Log -Message 'Large file finder started.'
Write-Log -Message ("Configuration: MinSizeMB={0}; ScanPaths={1}; ExportCsv={2}" -f $MinSizeMB, ($ScanPaths -join '; '), $ExportCsv)
Write-Log -Message ("Log file: {0}" -f $script:LogFile)

$matches = @(Find-LargeFiles -Paths $ScanPaths -MinBytes $minBytes)
Show-AndExportResults -Items $matches -ShouldExportCsv:$ExportCsv

# Section: End summary
# Reports collected summary counters at the end of execution.
Write-Log -Message 'Summary report:'
foreach ($key in $summary.Keys) {
    Write-Log -Message ("  {0}: {1}" -f $key, $summary[$key])
}

Write-Log -Message 'Large file finder completed.'
