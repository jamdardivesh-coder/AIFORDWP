# Floor 6 Deployment Incident Evidence Collection Package
**Date:** 2026-08-14
**Audience:** Service Desk, Endpoint Engineering, Incident Response, M365 Administration
**Scope:** Windows 10/11 endpoint evidence collection only (read-only)

---

# 1. Investigation Objective

## Hypothesis Being Tested
Friday's document management system (DMS) deployment caused Monday's endpoint symptoms on Floor 6:
- Slow logins
- Login failures
- Poor workstation performance
- Missing desktop shortcuts
- Potential unauthorized Copilot data exposure claim

## Why This Evidence Matters
Endpoint evidence can establish if symptom onset aligns with deployment artifacts:
- Installation timestamps, service/task creation, and startup entries
- Authentication and profile event failures around first Monday logons
- Desktop path, shortcut inventory, and redirection/OneDrive state
- CPU/memory/disk pressure and process footprint linked to DMS components

## Findings That Would Support Deployment Causation
- DMS install/upgrade timestamps align with Friday window and first Monday logon
- New or modified startup entries/tasks/services tied to DMS
- Login/profile failures start immediately after deployment artifacts appear
- Desktop folder/shortcut changes align with deployment window
- DMS-specific errors and performance overhead are concentrated on affected endpoints

---

# 2. AI-Generated First Draft Script

This is a plausible AI first draft before senior review.

```powershell
<#
.SYNOPSIS
Collect endpoint incident evidence.

.PARAMETER OutputPath
Output directory.

.PARAMETER DryRun
Show actions only.
#>
param(
	[string]$OutputPath = "$PSScriptRoot\Evidence",
	[switch]$DryRun
)

$ErrorActionPreference = 'Continue'

if (-not $DryRun) {
	New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$sys = Get-ComputerInfo
$procs = Get-Process | Select-Object Name, Id, CPU, WS
$services = Get-Service
$apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
	Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

$events = Get-WinEvent -LogName Application -MaxEvents 200 |
	Select-Object TimeCreated, Id, ProviderName, Message

$desktop = "$env:USERPROFILE\Desktop"
$shortcuts = Get-ChildItem $desktop -Filter *.lnk -ErrorAction SilentlyContinue |
	Select-Object Name, FullName, LastWriteTime

$result = [pscustomobject]@{
	Computer = $env:COMPUTERNAME
	User = $env:USERNAME
	System = $sys
	ProcessCount = $procs.Count
	ServiceCount = $services.Count
	AppCount = $apps.Count
	ShortcutCount = $shortcuts.Count
}

if ($DryRun) {
	Write-Host "DryRun complete"
}
else {
	$result | ConvertTo-Json -Depth 4 | Out-File "$OutputPath\Summary.json"
	$apps | Export-Csv "$OutputPath\InstalledApps.csv" -NoTypeInformation
	$services | Export-Csv "$OutputPath\Services.csv" -NoTypeInformation
	$events | Export-Csv "$OutputPath\Events.csv" -NoTypeInformation
	$shortcuts | Export-Csv "$OutputPath\Shortcuts.csv" -NoTypeInformation
}
```

---

# 3. Human Review of AI Draft

## Weaknesses
- No timestamped evidence folder per run, making chain-of-custody and repeat runs harder.
- Minimal parameterization; no deployment window or DMS pattern targeting.
- No transcript logging.

## Missing Evidence
- No scheduled tasks, startup commands, group policy outputs, profile registry analysis, redirection/OneDrive indicators.
- No login-focused event IDs and no auth/domain health checks.
- No deployment-correlated file timestamp analysis.

## Reliability Problems
- Uses broad Get-ComputerInfo payload and shallow event sample without structured filtering.
- Uses ErrorActionPreference Continue, potentially hiding failed collection sections.

## Performance Concerns
- Not bounded where needed by lookback windows or targeted providers.
- No safeguards for access denied / unavailable logs.

## Security and Safety Concerns
- DryRun only skips writes but does not clearly show planned actions.
- No explicit read-only safety statements in operational output.

## Logging Shortcomings
- No centralized warning/error capture.
- No per-step failure reporting; no summary diagnostics.

---

# 4. Hand-Corrected Production Version

Production script created and ready to execute:
- Path: Project/Collect-Floor6DeploymentEvidence.ps1
- Design: read-only, DryRun support, transcript logging, robust error handling, JSON/CSV artifacts, timestamped output

## Execution Examples

```powershell
# Dry run (no files written)
.\Project\Collect-Floor6DeploymentEvidence.ps1 -OutputRoot C:\IR -DryRun

# Live evidence collection with default DMS matching
.\Project\Collect-Floor6DeploymentEvidence.ps1 -OutputRoot C:\IR

# Include Security log auth events (if rights permit)
.\Project\Collect-Floor6DeploymentEvidence.ps1 -OutputRoot C:\IR -IncludeSecurityLog

# Override DMS pattern and deployment window
.\Project\Collect-Floor6DeploymentEvidence.ps1 -OutputRoot C:\IR -DmsNamePattern "iManage|NetDocuments|DMS" -DeploymentWindowStart "2026-08-07 14:00"
```

## Production Script

```powershell
Get-Content .\Project\Collect-Floor6DeploymentEvidence.ps1
```

The full implementation is intentionally kept in the standalone script file so engineers can execute it directly during live response without copy/paste risk.

---

# 5. Side-by-Side Comparison

| AI Draft Section | Hand-Corrected Section | What Was Fixed | Why It Matters |
|---|---|---|---|
| Single output folder path | Timestamped per-run evidence directory | Added run-unique folder naming and artifact index | Preserves evidence integrity and prevents overwrites |
| Basic error handling | Invoke-Safely wrapper + warning/error aggregation | Per-step try/catch and resilient fallback defaults | Collection continues safely while preserving failure context |
| Generic Application log sample | Targeted event collection (Application/System/User Profile/optional Security) with lookback and IDs/providers | Added focused login/auth/profile/app error acquisition | Better causal signal for deployment vs non-deployment causes |
| Installed apps from one registry path | Multi-hive uninstall inventory (HKLM x64/x86 and HKCU) + recent install parsing | Expanded coverage and install date normalization | Reduces false negatives for per-user and 32-bit installs |
| Desktop shortcut list only | Desktop path verification + shortcut target resolution + redirection/OneDrive indicators | Added context around path drift and redirection behavior | Distinguishes deletion from path redirection/profile changes |
| No performance telemetry | CPU/memory/disk utilization snapshot + process inventory | Added endpoint pressure evidence | Correlates user complaints with objective resource state |
| No scheduled tasks/startup services correlation | Startup commands/folders, scheduled tasks, deployment-matched services | Added persistence and boot/logon trigger surface checks | Detects deployment hooks that impact login/performance |
| No domain/auth connectivity checks | DNS config, domain membership, secure channel test, auth-related system/app events | Added identity/network evidence stream | Separates endpoint deployment impact from AD/network issues |
| No GP evidence | gpresult text/html metadata and capture | Added policy-processing evidence | Identifies policy collisions or post-deployment policy side effects |
| No deployment-time file analysis | Timestamp correlation scan constrained by DMS pattern and deployment window | Added Friday-window artifact correlation | Strengthens or weakens deployment causality hypothesis |

---

# 6. Expected Output Example

Example folder created by live run:

```text
Evidence-Floor6-WS123-20260814_091530
├── ApplicationSpecificErrors.csv
├── ArtifactIndex.json
├── DeploymentFileTimestamps.csv
├── DeploymentMatchedSoftware.csv
├── DesktopPathVerification.json
├── DesktopShortcuts.csv
├── EventLogs.csv
├── FolderRedirection.json
├── GpResult.html
├── GpResult.txt
├── GpResultMetadata.json
├── InstalledSoftware.csv
├── LoginEventLogs.csv
├── NetworkInfo.json
├── RecentlyInstalledSoftware.csv
├── RunningProcesses.csv
├── ScheduledTasks.csv
├── Services.csv
├── StartupApplications.csv
├── SummaryReport.json
├── SystemInfo.json
├── Transcript.log
├── UserProfile.json
└── UtilizationSnapshot.json
```

If IncludeSecurityLog is used and rights are sufficient:
- SecurityLogonEvents.csv

---

# 7. Evidence Interpretation Guide

## SystemInfo.json
- Look for: OS build, last boot, current user, domain join, machine identity.
- Supports deployment causation: symptom onset immediately follows reboot/logon after deployment.
- Rules out deployment causation: unaffected timing or stale last boot unrelated to incident window.
- Escalate when: inconsistent identity/domain data across affected machines.

## InstalledSoftware.csv + RecentlyInstalledSoftware.csv + DeploymentMatchedSoftware.csv
- Look for: DMS install/upgrade records, publisher, install dates, path consistency.
- Supports deployment causation: DMS-related install dates align with Friday rollout and affected users.
- Rules out deployment causation: no DMS footprint change on affected endpoint.
- Escalate when: mismatched versions across floor, partial deployment, failed/unexpected package.

## StartupApplications.csv + ScheduledTasks.csv + Services.csv
- Look for: new entries referencing DMS or deployment scripts.
- Supports deployment causation: new startup/task/service aligns with issue onset.
- Rules out deployment causation: no deployment-linked startup/persistence changes.
- Escalate when: service crash loops, repeated task failure, or startup command errors.

## EventLogs.csv + LoginEventLogs.csv + SecurityLogonEvents.csv
- Look for: login failure spikes, profile errors, service control failures, app exceptions.
- Supports deployment causation: error onset begins after deployment and references DMS/provider.
- Rules out deployment causation: failures predate deployment or map to unrelated providers.
- Escalate when: widespread 4625/Kerberos/Netlogon failures or repeated profile temp-profile events.

## UserProfile.json
- Look for: temp profile indicators, profile state/refcount anomalies, load failures.
- Supports deployment causation: profile issues begin after rollout and coincide with DMS startup hooks.
- Rules out deployment causation: clean profile state with no correlated failures.
- Escalate when: persistent temporary profile or profile load corruption events.

## DesktopPathVerification.json + DesktopShortcuts.csv + FolderRedirection.json
- Look for: path drift, missing physical desktop path, OneDrive/folder redirection anomalies, sudden shortcut timestamp changes.
- Supports deployment causation: shortcut removal or desktop path changes during deployment window.
- Rules out deployment causation: shortcuts exist in redirected path or changes happened outside incident window.
- Escalate when: path redirection inconsistency between policy and local state.

## NetworkInfo.json
- Look for: DNS server correctness, secure channel status, auth-related system errors.
- Supports deployment causation: none directly unless DMS components break auth path locally.
- Rules out deployment causation: clear network/auth infrastructure break independent of app deployment.
- Escalate when: secure channel false, DNS misconfiguration, widespread auth failures.

## DeploymentFileTimestamps.csv
- Look for: DMS-related files changed during Friday window and first Monday login.
- Supports deployment causation: concentrated DMS file writes immediately before symptom onset.
- Rules out deployment causation: no matching file changes in window.
- Escalate when: unexpected binaries/scripts altered in user profile or startup locations.

## Transcript.log + SummaryReport.json
- Look for: collection completeness, warnings/errors, artifact counts.
- Supports deployment causation: high signal across DMS-linked artifacts with low collection error.
- Rules out deployment causation: sparse DMS evidence with stronger alternate signals.
- Escalate when: repeated denied access or missing key artifacts across many endpoints.

---

# 8. Final Incident Responder Assessment

## Is This Sufficient for First-Response Triage?
Yes. This script is suitable for first-response endpoint triage and evidence preservation on individual Floor 6 workstations. It is safe, read-only, and operationally practical for Service Desk execution.

## Additional Evidence Needed from Central Systems
- Intune deployment timeline, assignment scope, and policy revision history (Friday onward)
- DMS deployment package metadata, install logs, and post-install script actions
- Entra ID / AD sign-in telemetry for Floor 6 affected users
- Defender for Endpoint advanced hunting (process/file/network timeline)
- Copilot/M365 audit logs for the reported matter visibility anomaly

## Findings That Would Justify Rollback of Friday Deployment
- Consistent endpoint evidence that DMS artifacts correlate with login failures/performance degradation
- Reproducible startup/task/service or profile failures introduced by deployment
- Broad floor-level impact tightly bounded to deployment version and timestamp

## Findings That Shift Investigation Away from Deployment
- Domain secure channel/DNS/authentication failures present regardless of DMS state
- Group Policy or Intune baseline changes unrelated to DMS package
- Identity/audit evidence pointing to permissions, indexing, or data governance issues for Copilot access concern

## Operational Recommendation
Run this collector on:
1. At least 3 impacted Floor 6 devices (including the shortcut-affected paralegal)
2. 2 non-impacted Floor 6 control devices
3. One non-Floor-6 control device with same baseline

Then compare SummaryReport.json and deployment-correlated artifacts to confirm or refute deployment causation with confidence.
