# LargeFileFinder.ps1 (PowerShell 5.1)

Safe and idempotent large-file discovery script for Windows endpoints.

## File Location
- Day3/LargeFileFinder.ps1

## Purpose
- Recursively scans configured paths and lists files larger than a threshold.
- Default threshold is 100 MB.
- Uses per-file try/catch error handling so scan continues even if some files fail.
- Logs every action to a timestamped log file.
- Prints a summary report at the end.
- Optional CSV export for reporting.

## Safety and Idempotency
- The script is read-only: it does not modify, move, or delete files.
- Running it multiple times produces the same behavior for the same filesystem state.
- Any differences in output between runs are due only to real endpoint changes.

## Parameters
- `-ScanPaths <string[]>`
  - One or more root paths to scan recursively.
  - Default:
    - `C:\Users`
    - `C:\ProgramData`

- `-MinSizeMB <int>`
  - Minimum file size to report in MB.
  - Default: `100`

- `-OutputRoot <string>`
  - Folder for logs and optional CSV output.
  - Default: `Day3\LargeFileFinderArtifacts`

- `-ExportCsv`
  - Optional switch to export matching results to a timestamped CSV report.

## Logging
- Log files are timestamped and written as:
  - `LargeFileFinder_yyyyMMdd_HHmmss.log`
- Every action and error is logged with timestamp and severity.

## Summary Counters
- PathsRequested
- PathsScanned
- PathsMissing
- FileCandidatesEnumerated
- LargeFilesFound
- PerFileErrors
- PathEnumerationErrors
- CsvExported

## Examples
- Run with defaults (100 MB):
  - `powershell -ExecutionPolicy Bypass -File .\Day3\LargeFileFinder.ps1`

- Scan custom paths with default threshold:
  - `powershell -ExecutionPolicy Bypass -File .\Day3\LargeFileFinder.ps1 -ScanPaths "C:\Users\labuser\Downloads","C:\Temp"`

- Set threshold to 250 MB:
  - `powershell -ExecutionPolicy Bypass -File .\Day3\LargeFileFinder.ps1 -MinSizeMB 250`

- Export findings to CSV:
  - `powershell -ExecutionPolicy Bypass -File .\Day3\LargeFileFinder.ps1 -ExportCsv`

## Operational Notes
- Some directories may return access-denied errors on endpoints; these are logged and the scan continues.
- For broad scans (for example entire system drives), expect longer runtime.
