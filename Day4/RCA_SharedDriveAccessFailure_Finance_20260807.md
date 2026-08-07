# RCA - Shared Drive Access Failure (Finance) - 2026-08-07

## 1. Incident Summary
- Incident: Finance users unable to access shared drives.
- Affected population: 45 users (DESKTOP-FB* devices, OU=Finance).
- Symptom start: Approximately 08:00.
- Service restored: 09:09.
- Validation after fix: Verified user logon to host successful and no further issues reported.

## 2. Business Impact
- Finance users could not access required shared-drive resources during the incident window.
- Operational disruption occurred for file-dependent work until restoration at 09:09.

## 3. Scope and Constraints
- Initial scope facts:
  - Symptom: users cannot access shared drives.
  - Who: 45 users.
  - Since: ~08:00.
  - Reported change at intake: nil.
- Investigation then incorporated endpoint/system evidence and prior migration change records.

## 4. Root Cause Statement
Root cause was an execution-context mismatch introduced by prior drive-mapping migration:
- Drive mapping moved from GPO logon script (USER context) to Intune PowerShell script (SYSTEM context).
- Script was not updated for SYSTEM-context behavior and timing constraints.
- Mapping attempted before required runtime conditions and user-context credentials were available, causing UNC mapping failure and no drive assignment.

## 5. Supporting Evidence

### 5.1 Primary Log Evidence (Incident Window)
- 08:00:01 ScriptRunner Info: Executing Map-FinBridgeDrives.ps1.
- 08:00:02 ScriptRunner Info: Script context SYSTEM account.
- 08:00:03 ScriptRunner Warning: Network path \\finbridge-fs01\Finance not accessible from SYSTEM context at execution time.
- 08:00:03 ScriptRunner Error: Script Map-FinBridgeDrives.ps1 failed, exit code 1, error "Network name cannot be found".
- 08:00:04 ScriptRunner Info: No retry configured.
- 08:00:05 Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06 GroupPolicy Event 1500: Group Policy settings processed successfully.
- 08:00:07 Ntfs Event 98 Warning: Could not map drive letter S (drive letter not assigned).

### 5.2 Change Record Evidence
- Prior migration note (2024-03-14 23:30):
  - Drive mapping migrated from GPO logon script (USER) to Intune script (SYSTEM).
  - Script not updated to handle SYSTEM context.
  - UNC mapping dependency/timing and credential behavior not accounted for.

### 5.3 Evidence-to-Cause Mapping
- SYSTEM context at 08:00:02 plus immediate UNC failure at 08:00:03 indicates context/timing dependency failure.
- Workstation service only confirmed running at 08:00:05, after failure already occurred.
- GroupPolicy success at 08:00:06 reduces likelihood of broad domain policy processing failure.
- Ntfs Event 98 at 08:00:07 confirms mapping artifact (S:) was not created.

## 6. Detailed Timeline
- 08:00:01 - Mapping script execution starts (Map-FinBridgeDrives.ps1).
- 08:00:02 - Script confirmed running as SYSTEM.
- 08:00:03 - UNC path inaccessible in SYSTEM context; script fails (exit code 1, network name cannot be found).
- 08:00:04 - No retry occurs (not configured).
- 08:00:05 - Workstation service enters running state.
- 08:00:06 - Group Policy processing succeeds (Event 1500).
- 08:00:07 - NTFS warning indicates S: drive letter not assigned.
- 09:09 - Resolution applied; issue confirmed resolved.
- Post-09:09 - User logon and host access verified; no issues reported.

## 7. 5-Why Analysis
1. Why could Finance users not access shared drives?
- Because required drive mapping did not complete successfully, so the expected mapped drive was unavailable.

2. Why did drive mapping fail?
- Because Map-FinBridgeDrives.ps1 failed with "Network name cannot be found" when attempting UNC access.

3. Why was UNC access failing at that moment?
- Because the script was running in SYSTEM context during a timing window where required conditions for mapping were not yet available.

4. Why was the script running in SYSTEM context for this workflow?
- Because drive mapping had been migrated from a USER logon script model to Intune SYSTEM-context execution.

5. Why did migration introduce failure risk?
- Because migration implementation did not include context-specific design updates (USER vs SYSTEM behavior), readiness checks, retry logic, and controlled validation before broad use.

## 8. Resolution Implemented
- Removed/disabled the failing SYSTEM-context mapping path for Finance scope.
- Applied corrected mapping approach aligned to logged-on USER context.
- Confirmed restoration by 09:09 and validated successful user login and access behavior.

## 9. Corrective Actions
1. Deployment model correction
- Keep drive mapping execution in USER context for user-scoped network drives.

2. Script resiliency improvements
- Add bounded Workstation readiness wait.
- Add UNC pre-check before map attempt.
- Add controlled retry behavior.
- Add explicit exit codes and timestamped operational logging.

3. Assignment hygiene
- Ensure only one active mapping mechanism per user cohort.
- Remove conflicting legacy/intune assignments that can overlap at logon.

4. Validation controls
- Enforce pilot deployment on representative Finance endpoints before full rollout.
- Add first-logon and delayed-network test scenarios.

## 10. Preventive Actions
1. Change governance
- Mandatory execution-context impact assessment for any migration between USER and SYSTEM script models.
- Mandatory rollback plan and success criteria for endpoint login/mapping changes.

2. Technical guardrails
- Standardized drive-mapping script template with readiness checks, retries, and structured logging.
- Peer review checklist must include context, service dependencies, and startup timing risks.

3. Monitoring and alerting
- Add detection for repeated ScriptRunner mapping failures and Event 98 spikes on Finance endpoints.
- Trigger proactive operations alert if mapping failure rate crosses defined threshold.

4. Knowledge management
- Publish this RCA and update runbook guidance for drive-mapping deployment patterns.
- Add known-error entry for USER-to-SYSTEM mapping migration failure mode.

## 11. Incident Closure Evidence
- Resolution timestamp: 09:09 on 2026-08-07.
- Functional validation: user successfully logged in to host and no post-fix shared-drive issues reported.
- Status: Resolved and closed pending completion of preventive action tracking.
