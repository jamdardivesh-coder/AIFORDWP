# KB - L2/L3 Diagnosis and Recovery: Finance Shared Drive S: Not Mapping

## Version Header
- Version: v 1.0
- Date: 07/08/2026
- Status : Draft
- Audience: DWP L2/L3 Engineers
- Source: Runbook - Restore Finance Shared Drive Access (Execution-Context Mapping Failure)

## Background: what the system does and why it matter
The Finance shared drive mapping provides Finance users a persistent S: drive to the UNC path \\finbridge-fs01\Finance.

In this environment, drive mapping can be delivered by:
- Intune Platform Script: Map-FinBridgeDrives.ps1
- Group Policy Preferences (User Configuration > Preferences > Windows Settings > Drive Maps)

Why this matters:
- Finance business workflows depend on S: for daily file access.
- If mapping executes in the wrong security context (SYSTEM instead of USER), user credentials are not available to mount user-scoped shares.
- If both Intune script assignment and GPO mapping overlap for the same user cohort, mapping state can become inconsistent across endpoints.

## Symptom: what the engineer observers and what the user report
Engineer observes:
- Users can sign in successfully but S: is missing or inaccessible.
- Manual UNC path access may work (\\finbridge-fs01\Finance), while mapped drive fails.
- Intermittent behavior across devices (some endpoints map correctly, others fail).

User reports:
- "I can log in, but my Finance S: drive is gone or won’t open."
- "It worked before migration/change, now it fails after sign-in."

Command-level symptom check:
- Run net use in affected user session.
- Expected failure signature: S: missing, wrong target, or disconnected state.

## Root Cause: the specific technical cause with the evidence that confirms it
Specific technical cause:
- Execution-context mismatch plus overlapping assignment mechanisms.
- Map-FinBridgeDrives.ps1 executes from Intune in SYSTEM context while Finance S: mapping requires USER context.
- Concurrent targeting by Intune script and GPO Drive Maps creates race/override conditions.

Evidence that confirms this cause:
- IntuneManagementExtension.log shows recent execution entries for Map-FinBridgeDrives.ps1 around failure period.
- Windows System log shows related warning pattern around drive assignment timing (Event ID 98) and service state transitions (Event ID 7036).
- GroupPolicy processing events (Event ID 1500) present around sign-in but mapping outcome still inconsistent.
- Assignment review shows Finance group included in Intune script while Finance GPO Drive Maps also active.

## Detection: exactly how to confirm this is the issue before acting
Goal: confirm this incident signature in under 3 minutes before making changes.

### 3-minute fast confirm (required evidence)
1. Open the exact log location on an affected host (example: POOL-FIN-01):
- Event Viewer > Windows Logs > Application
Expected result: Application log is open (not System, not generic event logs).

2. Filter the Application log for exact Event IDs:
- Event ID 1000
- Event ID 9009
Expected result: Both Event 1000 and Event 9009 are visible in the incident time window.

3. Open Event 1000 details and confirm the faulting module field contains:
- igdumd64.dll
Expected result: Event 1000 explicitly names igdumd64.dll as the faulting module.

4. Compare against healthy control host POOL-FIN-02:
- Same log location: Event Viewer > Windows Logs > Application
- Check for Event ID 9011 in same time window
Expected result: POOL-FIN-02 shows Event 9011 as unaffected baseline while affected host shows Event 1000/9009 pattern.

5. Confirm shared-drive symptom from user session on affected host:
- Run net use
- Validate S: mapping status and remote path
Expected result: S: is missing/disconnected/incorrect on affected host during event window.

### PowerShell quick extraction (preferred over manual clicking)
Run on affected host (or remote into it) to extract exact events and fields fast:

```powershell
# Set incident window (adjust as needed)
$Start = (Get-Date).AddHours(-4)

# Affected host: exact Application log events
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=$Start} |
  Select-Object TimeCreated, Id, ProviderName, MachineName, LevelDisplayName, Message |
  Sort-Object TimeCreated -Descending |
  Format-Table -AutoSize

# Event 1000 faulting module check (must contain igdumd64.dll)
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$Start} |
  Where-Object { $_.Message -match 'igdumd64\.dll' } |
  Select-Object TimeCreated, Id, MachineName, Message |
  Sort-Object TimeCreated -Descending
```

Healthy baseline command on control host POOL-FIN-02:

```powershell
$Start = (Get-Date).AddHours(-4)
Get-WinEvent -ComputerName 'POOL-FIN-02' -FilterHashtable @{LogName='Application'; Id=9011; StartTime=$Start} |
  Select-Object TimeCreated, Id, ProviderName, MachineName, Message |
  Sort-Object TimeCreated -Descending |
  Format-Table -AutoSize
```

### Azure CLI quick extraction (when working from Azure admin shell)
Use Run Command to pull Application log evidence without opening Event Viewer:

```bash
# Affected host (replace RG and VM)
az vm run-command invoke \
  --resource-group <RG_NAME> \
  --name <AFFECTED_VM_NAME> \
  --command-id RunPowerShellScript \
  --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000,9009; StartTime=(Get-Date).AddHours(-4)} | Select TimeCreated,Id,ProviderName,MachineName,Message | Sort TimeCreated -Descending"

# Healthy control baseline on POOL-FIN-02
az vm run-command invoke \
  --resource-group <RG_NAME> \
  --name POOL-FIN-02 \
  --command-id RunPowerShellScript \
  --scripts "Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9011; StartTime=(Get-Date).AddHours(-4)} | Select TimeCreated,Id,ProviderName,MachineName,Message | Sort TimeCreated -Descending"
```

### Decision gate before action
Treat this as confirmed only when all are true:
1. Application log on affected host contains Event 1000 and Event 9009 in incident window.
2. Event 1000 faulting module explicitly contains igdumd64.dll.
3. Unaffected control POOL-FIN-02 shows Event 9011 baseline pattern.
4. User symptom aligns (S: mapping failure in net use output).

## Resolution: step-by-step fix with expected result after each step - include specific portal/console paths
Objective: remove Intune SYSTEM-context mapping pressure for Finance cohort and enforce USER-context mapping via GPO, using host-pool-scoped execution so fix completes in 5-10 minutes.

1. Add change-start timestamp in incident ticket.
Path: ITSM > Incident > Activity/Work Notes.
Expected result: Auditable start time is recorded.

2. Identify affected session hosts in Azure first (exact host pool path and options).
Path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 (host pool name) > Session hosts.
Options to use: Search/filter for POOL-FIN-01, POOL-FIN-03, and other reported hosts.
Expected result: You have exact host names to target for rapid command execution.

3. Capture host image baseline for rollback safety.
Path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-01 > Virtual machine > Settings > Configuration > Image.
Expected result: Current image publisher/offer/sku/version is recorded before change.

4. Remove Finance from Intune script targeting.
Path: https://intune.microsoft.com > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments > Edit assignment.
Option to set: Included groups -> remove <ENTRA_GROUP_NAME_OR_ID> -> Review + save.
Expected result: Finance cohort is no longer targeted by SYSTEM-context mapping script.

5. Enforce user-context mapping in GPO.
Path: gpmc.msc > Forest > Domains > <domain> > <Finance OU path> > <GPO_NAME> > Edit > User Configuration > Preferences > Windows Settings > Drive Maps > S: Properties.
Options to set:
- Action = Update
- Location = \\finbridge-fs01\Finance
- Label as = Finance
- Reconnect = Enabled
Expected result: User-context drive map definition is correct and saved.

6. Force policy refresh and mapping check on pilot session hosts using Azure CLI (faster than RDP/manual clicks).
Command:

```bash
az vm run-command invoke --resource-group <RG_NAME> --name POOL-FIN-01 --command-id RunPowerShellScript --scripts "gpupdate /force; cmd /c net use; powershell -NoProfile -Command \"Test-Path '\\\\finbridge-fs01\\Finance'\""
az vm run-command invoke --resource-group <RG_NAME> --name POOL-FIN-03 --command-id RunPowerShellScript --scripts "gpupdate /force; cmd /c net use; powershell -NoProfile -Command \"Test-Path '\\\\finbridge-fs01\\Finance'\""
```

Expected result: Policy refresh succeeds and host-level checks show UNC reachability and updated mapping state.

7. Optional PowerShell automation for bulk pilot execution.
Command:

```powershell
$hosts = 'POOL-FIN-01','POOL-FIN-03','POOL-FIN-04'
foreach ($h in $hosts) {
  az vm run-command invoke --resource-group <RG_NAME> --name $h --command-id RunPowerShellScript --scripts "gpupdate /force; cmd /c net use" | Out-Null
}
```

Expected result: All pilot hosts receive policy refresh without interactive login to each VM.

8. Trigger Intune sync for remaining affected devices.
Path: https://intune.microsoft.com > Devices > All devices > select affected devices > Sync.
Expected result: Device check-in is queued for broad propagation.

9. Request one sign-out/sign-in cycle for impacted users.
Path: ITSM > Incident > Service Desk task/communication update.
Expected result: User-context mapping applies at next logon and access is restored.

## Verification: how to confirm the fix worked
Complete verification before closure.

1. Verify host pool and host image are unchanged (required portal path).
Path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > <affected host> > Virtual machine > Settings > Configuration > Image.
Option to verify: Image publisher/offer/sku/version matches pre-change capture.
Expected result: No unintended host-image drift during incident fix.

2. Verify Intune assignment state and script status.
Path: https://intune.microsoft.com > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments and Device status.
Options to verify:
- Finance group not present in Included groups.
- No new post-change failures for pilot devices.
Expected result: SYSTEM-context script no longer drives mapping for Finance cohort.

3. Verify Application log event pattern on affected hosts using command (fast path).
Command:

```powershell
$Start=(Get-Date).AddHours(-1)
Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000,9009;StartTime=$Start} |
  Select-Object TimeCreated,Id,MachineName,Message |
  Sort-Object TimeCreated -Descending
```

Expected result: No new burst of Event 1000/9009 after remediation timestamp.

4. Verify healthy baseline remains intact on control host.
Path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02.
Command:

```powershell
$Start=(Get-Date).AddHours(-1)
Get-WinEvent -ComputerName 'POOL-FIN-02' -FilterHashtable @{LogName='Application';Id=9011;StartTime=$Start} |
  Select-Object TimeCreated,Id,MachineName,Message |
  Sort-Object TimeCreated -Descending
```

Expected result: POOL-FIN-02 continues to show unaffected baseline behavior.

5. Verify mapping outcome directly from hosts via Azure CLI.
Command:

```bash
az vm run-command invoke --resource-group <RG_NAME> --name POOL-FIN-01 --command-id RunPowerShellScript --scripts "cmd /c net use; powershell -NoProfile -Command \"Test-Path '\\\\finbridge-fs01\\Finance'\""
```

Expected result: net use shows S: -> \\finbridge-fs01\Finance and UNC test returns True.

6. Validate with user sample and queue health.
Path: 5 affected user sessions and ITSM queue view.
Options to verify:
- User can open S: and browse folders.
- No new Finance shared-drive incidents in last 30 minutes.
Expected result: Service restoration is confirmed and stable.

## Rollback: what to do if the fix makes thing worse- be specific
Use when impact increases post-change. Execute quickly.

1. Add ticket note: Emergency rollback started + timestamp.
Path: ITSM > Incident > Activity/Work Notes.
Expected result: Rollback start is auditable.

2. Re-enable original Intune targeting.
Path: https://intune.microsoft.com > Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments > Edit assignment.
Option to set: add back <ENTRA_GROUP_NAME_OR_ID> to Included groups -> Review + save.
Expected result: Pre-change script targeting is restored.

3. Disable GPO drive map item.
Path: gpmc.msc > Forest > Domains > <domain> > <Finance OU path> > <GPO_NAME> > Edit > User Configuration > Preferences > Windows Settings > Drive Maps > S: Properties.
Option to set: item state Disabled.
Expected result: USER-context mapping override is removed.

4. If host configuration drift occurred, confirm and restore host image reference (required host setting path).
Path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > <affected host> > Virtual machine > Settings > Configuration > Image.
Option to set: restore image to recorded pre-change publisher/offer/sku/version.
Expected result: Host image baseline is returned to known good state.

5. Push rollback refresh rapidly via Azure CLI.
Command:

```bash
az vm run-command invoke --resource-group <RG_NAME> --name POOL-FIN-01 --command-id RunPowerShellScript --scripts "gpupdate /force; cmd /c net use"
az vm run-command invoke --resource-group <RG_NAME> --name POOL-FIN-03 --command-id RunPowerShellScript --scripts "gpupdate /force; cmd /c net use"
```

Expected result: Rollback policy state is applied without waiting for manual checks.

6. Verify rollback state from commands.
Command:

```powershell
$Start=(Get-Date).AddMinutes(-30)
Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000,9009;StartTime=$Start} |
  Select-Object TimeCreated,Id,MachineName,Message |
  Sort-Object TimeCreated -Descending
```

Expected result: Event pattern matches pre-change baseline behavior and not a worsening trend.

7. Final rollback confirmation.
Path: Azure portal > Azure Virtual Desktop > Host pools > FIN01 > Session hosts > POOL-FIN-02 (control) and affected hosts.
Options to verify:
- Control host baseline Event 9011 still present.
- Affected hosts no longer degrade further after rollback time.
Expected result: Environment is stabilized.

8. If still unstable, escalate immediately with evidence bundle.
Path: C:\Incident\FinanceDriveMap\ and ITSM escalation update to EUC Platform and IAM on-call.
Expected result: On-call teams receive full context and timeline.

## Preventive: the specific change to process or tooling that stop this recurring
Implement all controls below.

1. Single-owner mapping policy by cohort:
- Owner/Timing/Type: Change manager + DWP engineer; before deployment; manual.
- Pass/Fail signal: In change record, active mechanism count for Finance cohort equals 1 (Intune assignment enabled + GPO drive map enabled = 1); fail if 0 or 2.
- If fail: block CAB approval and return change for correction; automation approach: pre-check script compares Intune assignment export and GPO item state. [REQUIRES: pre-change validation script]

2. Pre-deployment overlap validator:
- Owner/Timing/Type: DWP engineer; before deployment; manual now.
- Pass/Fail signal: Evidence pack contains 2 artifacts (Intune Assignments screenshot + GPO Drive Maps status screenshot) with timestamp within 24h of release; fail if either artifact missing/stale.
- If fail: do not start rollout and reopen change tasks; automation approach: pipeline gate validates both evidence files are attached. [REQUIRES: ITSM attachment gate]

3. Context-safe script engineering standard:
- Owner/Timing/Type: Release engineer + DWP engineer; before deployment; automated + manual review.
- Pass/Fail signal: PR check confirms script metadata includes execution context USER and static lint finds no SYSTEM-context mapping task for user share paths; fail on any violation.
- If fail: PR is rejected and cannot merge until context is corrected.

4. Controlled migration playbook:
- Owner/Timing/Type: DWP engineer; during deployment; manual.
- Pass/Fail signal: Checklist shows 3 pilot hosts + control host POOL-FIN-02 validated, with net use confirming S: -> \\finbridge-fs01\Finance on pilots and baseline Event 9011 on control; fail if any host missing/fails.
- If fail: halt rollout expansion and execute rollback trigger criteria.

5. Monitoring and alerting rule:
- Owner/Timing/Type: Image owner + DWP engineer; during deployment; automated.
- Pass/Fail signal: Alert fires when Event ID 1000 (faulting module igdumd64.dll) OR Event ID 9009 occurs on >=5 FIN hosts in 15 minutes, or when Event ID 98 rises >=5 hosts in 15 minutes with concurrent IME Map-FinBridgeDrives.ps1 activity.
- If fail: auto-page on-call and pause rollout batch immediately. [REQUIRES: SIEM rule + rollout pause hook]

6. Service Desk intake hardening:
- Owner/Timing/Type: Service desk lead; before deployment and steady state intake; manual with form enforcement.
- Pass/Fail signal: 100% of routed Finance-drive incidents contain 4 mandatory fields (first-failure time, UNC test result, net use output, endpoint); fail if completion rate <100% in weekly audit.
- If fail: ticket auto-returns to L1 queue for data completion; automation approach: required ITSM fields with route block. [REQUIRES: ITSM form rule]

7. Pre-deployment smoke test gate (missing layer):
- Owner/Timing/Type: Release engineer; before deployment; automated preferred.
- Pass/Fail signal: In test pool, 3/3 test users show S: mapping success (net use shows S: -> \\finbridge-fs01\Finance) and Application log has zero new Event IDs 1000/9009 in 30 minutes; fail on any miss.
- If fail: release is blocked and defect ticket is opened.

8. In-flight monitoring during rollout window (missing layer):
- Owner/Timing/Type: DWP engineer; during deployment; automated.
- Pass/Fail signal: Every 5 minutes, dashboard shows Event 1000/9009 count <=2 hosts per 15 minutes and helpdesk new-ticket count <=2 per 30 minutes for Finance drive issue; fail when threshold exceeded.
- If fail: stop next rollout batch and invoke rollback decision within 10 minutes. [REQUIRES: rollout dashboard]

9. Post-deployment validation gate (missing layer):
- Owner/Timing/Type: Change manager + DWP engineer; after deployment; manual.
- Pass/Fail signal: At +30 minutes, 5/5 sampled Finance sessions open S:, net use is correct, and no new critical alert from control 5; fail if any check fails.
- If fail: change remains open, initiate rollback or hotfix path, and notify stakeholders.

10. Rollback trigger criteria (missing layer):
- Owner/Timing/Type: Change manager; during and after deployment; automated signal with manual authorization.
- Pass/Fail signal: Trigger rollback if Event 1000/9009 appears on >=5 hosts in 15 minutes, or if Finance drive incidents >=3 in 30 minutes, or pilot success rate <90%.
- If fail: execute rollback procedure immediately and freeze further changes for the host pool.

11. Knowledge update control (missing layer):
- Owner/Timing/Type: DWP engineer + service desk lead; after deployment; manual.
- Pass/Fail signal: Within 2 business days, runbook, KB, and L1 checklist are updated with new signals/commands and version increment recorded; fail if update SLA missed.
- If fail: create problem-management action item and review in weekly ops governance.

## Related: other incidents or KB article this connects to
- Related RCA:
  - Day4 RCA_SharedDriveAccessFailure_Finance_20260807
  - Day4 ClosureNote_SharedDriveAccessFailure_20260807

- Related known error:
  - Day4 KnownError_SharedDriveAccessFailure_20260807

- Related runbook:
  - Day5 Runbook_SharedDriveAccessFailure_Finance_20260807

- Pattern-related incident family:
  - Day4 RCA_NoGroupPolicy_DNSMisconfiguration_20260807
  - Day4 DiagnosisHypothesis_SharedDriveAccessFailure_20260807

## Quick Triage Summary (for on-call handoff)
- Problem signature: user can sign in, S: fails, UNC may still work.
- Key evidence: Event IDs 98, 7036, 1500 + IME log execution trace for Map-FinBridgeDrives.ps1.
- Confirming condition: same cohort targeted by both Intune script and GPO mapping.
- Preferred fix: remove Finance from Intune script assignment, enforce GPO user-context mapping, then validate on pilot and control cohorts.
