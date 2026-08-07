# Diagnosis Hypothesis - Shared Drive Access Failure (2026-08-07)

## Scope Facts (as provided)
- Symptom: users cannot access shared drives
- Impacted users: 45
- Since: ~08:00 this morning
- Recorded change: Nil

## Ranked Most Likely Causes (Most Probable First)

### 1) File server or DFS namespace outage/degradation
Why this fits scope facts:
- A shared-drive-only symptom strongly points to the storage path itself (file server role, SMB service, or DFS namespace target).
- Large blast radius (45 users) and same start window (~08:00) is consistent with a central dependency failure.
- "No change" does not rule out unplanned service failure (service crash, resource exhaustion, host/network issue).

Fastest single check:
- From one affected endpoint, run: `Test-Path \\fileserver\sharename` (or DFS path in use). If multiple known shares fail at the same time, this rapidly supports central file service/DFS failure.

### 2) Authentication path issue to domain services (DC/Kerberos/NTLM)
Why this fits scope facts:
- Accessing SMB shares usually requires domain authentication/authorization at connection time.
- Simultaneous impact across many users is consistent with a shared identity backend issue.
- Onset at a specific time can align with DC service interruption, trust/auth channel issues, or auth stack instability.

Fastest single check:
- On one affected machine, run `nltest /dsgetdc:<domainFQDN>`. Failure or major delay quickly indicates domain controller discovery/auth path problems.

### 3) Internal DNS resolution failure for file/DFS targets
Why this fits scope facts:
- Shared drives are commonly accessed by hostnames/DFS namespaces that rely on DNS.
- Multi-user impact beginning around the same time is consistent with resolver, forwarder, or zone issue.
- No declared change can still coexist with DNS service outage or stale/failed records.

Fastest single check:
- On an affected endpoint, run `Resolve-DnsName <fileserver-or-dfs-namespace-host>`. Name resolution failure or incorrect target immediately supports DNS as a primary suspect.

### 4) Network path disruption between user subnets and file services
Why this fits scope facts:
- A routing/ACL/firewall issue can block SMB (TCP 445) for many users at once while other functions may still work.
- The abrupt start (~08:00) matches a boundary/network incident profile.
- "No change" from service desk perspective does not exclude upstream network events.

Fastest single check:
- From one affected endpoint, run `Test-NetConnection <fileserver-hostname> -Port 445`. A failure quickly separates connectivity blocking from app-level/auth causes.

### 5) Permissions or token-group evaluation failure (AD group membership/authorization path)
Why this fits scope facts:
- "Cannot access shared drives" can be authorization-denied, not only unavailable path.
- If many users depend on a common AD group for drive access, a directory/authorization evaluation issue can produce broad impact.
- Same-time onset could align with directory replication/authz evaluation problems despite no announced change.

Fastest single check:
- Using one affected user account, attempt direct access to a known share and capture exact error (`Access is denied` vs `Network path not found`). This one observation rapidly distinguishes authorization failure from service/connectivity failure.

## Note
- This is a ranked hypothesis list only, based strictly on scope facts.
- No single root cause is asserted yet.

## Event Evidence Assessment (Incident Window)

### Evidence Provided
- Source: Intune Management Extension Log + System Log
- Affected set: Finance users on DESKTOP-FB* devices (OU=Finance)
- [08:00:01] ScriptRunner Info: Executing `Map-FinBridgeDrives.ps1`
- [08:00:02] ScriptRunner Info: Script context `SYSTEM account`
- [08:00:03] ScriptRunner Warning: Network path `\\finbridge-fs01\Finance` not accessible from SYSTEM context at execution time
- [08:00:03] ScriptRunner Error: Script failed, Exit code 1, Error `Network name cannot be found`
- [08:00:04] ScriptRunner Info: No retry configured
- [08:00:05] Service Control Manager Event 7036: Workstation service entered running state
- [08:00:06] GroupPolicy Event 1500: Group Policy settings processed successfully
- [08:00:07] Ntfs Event 98 Warning: Could not map drive letter S:
- Prior change note (2024-03-14 23:30): Mapping migrated from GPO logon script (USER) to Intune PowerShell script (SYSTEM) without SYSTEM-context handling updates

### Hypothesis-by-Hypothesis Judgement

#### 1) File server or DFS namespace outage/degradation
Judgement: Contradicts
Determining evidence:
- [08:00:02] SYSTEM execution context established before failure
- [08:00:03] Failure occurs at script execution time in SYSTEM context
- [08:00:05] Workstation service reaches running state after the failure point

#### 2) Authentication path issue to domain services (DC/Kerberos/NTLM)
Judgement: Contradicts
Determining evidence:
- [08:00:06] GroupPolicy Event 1500 confirms policy processing succeeded in the same window

#### 3) Internal DNS resolution failure for file/DFS targets
Judgement: Neutral
Determining evidence:
- [08:00:03] Error text `Network name cannot be found` is compatible with name resolution issues
- No DNS-specific event ID is present in the provided logs

#### 4) Network path disruption between user subnets and file services
Judgement: Neutral
Determining evidence:
- [08:00:03] UNC path inaccessible at execution time can align with connectivity issues
- No explicit network transport failure event ID is provided in the supplied evidence

#### 5) Permissions/token-group or execution-context authorization failure
Judgement: Supports
Determining evidence:
- [08:00:02] Script ran under SYSTEM
- [08:00:03] UNC not accessible from SYSTEM context; script fails with exit code 1
- [08:00:07] Ntfs Event 98 indicates drive mapping failure state after script failure
- Prior change note documents USER-to-SYSTEM migration gap as a known risk condition

## Surviving Hypothesis After Elimination
- Execution-context failure caused by migration from USER logon mapping to Intune SYSTEM execution, where UNC drive mapping prerequisites and credentials are not available at execution time.

## Detailed Resolution Steps

1. Contain impact immediately
- Disable or unassign the current Intune deployment of `Map-FinBridgeDrives.ps1` for Finance-targeted devices/users.
- If operationally permitted, temporarily restore the prior USER-context mapping method to recover shared drive access quickly.

2. Correct execution context
- Re-deploy drive mapping logic in USER context (logged-on credentials), not SYSTEM context.
- Keep targeting aligned to Finance scope (DESKTOP-FB* / OU=Finance policy scope as applicable).

3. Add readiness and resiliency to the script
- Wait for `LanmanWorkstation` service readiness (bounded timeout, for example 60 seconds).
- Validate UNC availability before mapping attempt (`Test-Path \\finbridge-fs01\Finance`).
- Add one controlled retry when initial check fails.
- Emit distinct exit codes for: success, service-not-ready timeout, UNC unavailable, mapping failure.

4. Remove conflicting deployment paths
- Ensure only one active drive-mapping mechanism remains assigned for Finance users.
- Confirm the legacy/broken SYSTEM-context assignment is fully removed to avoid race or duplicate execution.

5. Pilot validation before full rollout
- Validate on a small Finance pilot subset first.
- Confirm S: mapping success and access to `\\finbridge-fs01\Finance` after sign-in.
- Confirm no repeat of 08:00:03 SYSTEM-context failure signature in logs.

6. Controlled rollout and monitoring
- Expand to all affected Finance users after pilot pass.
- Monitor failure rate, mapping success rate, and ticket volume for at least one business day.

7. Prevent recurrence
- Update change standard to require explicit context validation when migrating scripts between USER and SYSTEM execution models.
- Add mandatory pre-production test cases for first-login timing and delayed network/service readiness.

## Addendum - Event Detail Update (2026-08-07)

### Updated Event Timeline (Finance Devices)
- 08:00:01 ScriptRunner Info: `Map-FinBridgeDrives.ps1` started.
- 08:00:02 ScriptRunner Info: Execution context is SYSTEM.
- 08:00:03 ScriptRunner Warning: `\\finbridge-fs01\Finance` not accessible from SYSTEM context.
- 08:00:03 ScriptRunner Error: Exit code 1, `Network name cannot be found`.
- 08:00:04 ScriptRunner Info: No retry configured.
- 08:00:05 Service Control Manager Event 7036: Workstation service entered running state.
- 08:00:06 GroupPolicy Event 1500: Group Policy processed successfully.
- 08:00:07 Ntfs Event 98 Warning: S: mapping not assigned.

### Surviving Hypothesis (Post-Elimination)
- Drive mapping failed due to USER-to-SYSTEM execution-context migration, where the mapping action was attempted before required runtime conditions were available to that context.

### Resolution Actions (Detailed)
1. Immediate containment
- Unassign or disable the current SYSTEM-context Intune deployment of `Map-FinBridgeDrives.ps1` for Finance targets.
- If needed for rapid recovery, temporarily re-enable the prior USER-context mapping mechanism.

2. Correct deployment model
- Deploy mapping in logged-on USER context.
- Keep assignment scoping to Finance users/devices only.

3. Script hardening
- Add bounded wait for Workstation service readiness.
- Add UNC pre-check for `\\finbridge-fs01\Finance`.
- Add one controlled retry with short delay.
- Return explicit status codes for success and each failure mode.

4. Conflict removal
- Ensure only one active mapping method is assigned.
- Remove any duplicate or legacy assignment paths that can race at sign-in.

5. Validation and rollout
- Pilot on a small DESKTOP-FB subset.
- Validate drive letter assignment and file share access after sign-in.
- Roll out broadly after pilot pass, then monitor incidents for one business day.

6. Recurrence prevention
- Add change-control checklist item: context impact assessment required for USER/SYSTEM migration.
- Add pre-production test case: first logon with delayed network/service readiness.
