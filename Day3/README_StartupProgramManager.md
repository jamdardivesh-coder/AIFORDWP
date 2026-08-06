# StartupProgramManager.ps1 (PowerShell 5.1)

Safe startup-program listing and disable script for Windows endpoints.

## File Location
- Day3/StartupProgramManager.ps1

## Purpose
- Lists enabled startup programs from common registry and Startup folder locations.
- Supports dry-run mode to preview disable actions without making system changes.
- Can disable startup entries by program name filter.
- Logs every action to a timestamped log file.
- Prints a summary at the end of each run.
- Uses idempotent behavior so repeated runs are safe.

## Script Options
- `-DryRun`
  - Runs in report/preview mode.
  - Always lists startup entries.
  - If used with `-Disable`, it shows what would be disabled but does not change the endpoint.

- `-Disable`
  - Enables disable mode.
  - Must be used with `-ProgramName`.

- `-ProgramName <string>`
  - Name or wildcard pattern to match startup entries for disable.
  - Example: `"OneDrive*"`

- `-OutputRoot <string>`
  - Optional output folder for logs.
  - Default: `Day3\StartupProgramArtifacts`

## What "Disable" Means
- Registry startup entries:
  - Moved from their active key (for example, `...\Run`) into a companion key ending with `_DisabledByDWP`.
  - This is safer than deleting and helps preserve value data.

- Startup folder entries:
  - Startup file is renamed by appending `.disabled-by-dwp`.

## Startup Folder File Types
- The script only treats likely startup-program files as startup entries.
- Included extensions: `.lnk`, `.exe`, `.bat`, `.cmd`, `.vbs`, `.js`, `.jse`, `.vbe`, `.wsf`, `.wsh`, `.ps1`, `.url`.
- Non-program files such as `desktop.ini` are ignored.

## Idempotent Behavior
- If a startup entry is already disabled, the script logs it and skips it.
- Missing entries are skipped and logged.
- Running with `-DryRun` repeatedly makes no system changes.

## Error Handling
- Uses try/catch around each startup source and each startup item operation.
- Errors are logged and counted; processing continues for remaining items.

## Logging
- Log files are created with date/time in the file name:
  - `StartupProgramManager_yyyyMMdd_HHmmss.log`
- Each log line includes a timestamp and severity level.

## Usage Examples
- List startup programs (safe inventory only):
  - `powershell -ExecutionPolicy Bypass -File .\Day3\StartupProgramManager.ps1`

- Dry run with listing and disable preview:
  - `powershell -ExecutionPolicy Bypass -File .\Day3\StartupProgramManager.ps1 -DryRun -Disable -ProgramName "OneDrive*"`

- Disable a specific startup entry name:
  - `powershell -ExecutionPolicy Bypass -File .\Day3\StartupProgramManager.ps1 -Disable -ProgramName "Microsoft Teams"`

- Disable using wildcard:
  - `powershell -ExecutionPolicy Bypass -File .\Day3\StartupProgramManager.ps1 -Disable -ProgramName "Adobe*"`

## Operational Notes
- Administrative rights may be required for all-users registry startup keys.
- Review log output after each run, especially when operating on production endpoints.
