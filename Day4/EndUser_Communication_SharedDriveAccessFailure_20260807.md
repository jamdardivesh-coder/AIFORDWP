# End-User Communication Pack - Shared Drive Access Incident (Finance)
## Incident Date: 2026-08-07
## Resolved: 09:09

## Audience 1 - Non-Technical Executive
Access is restored and data is safe. From about 08:00, Finance users could not open shared drives because a drive setup change made the setup run at the wrong time and fail, with no retry. We removed the failing setup path and restored the correct sign-in-based method. Service was restored at 09:09, and login/access was verified with no further issues. No action is needed unless this reappears.

## Audience 2 - Affected End-User Team (10 People, Non-Technical)
Your access is restored and your data is safe. From about 08:00, Finance users could not open shared drives because a drive setup change made mapping run at the wrong sign-in moment, so it failed and did not retry. We removed that failing path and put back the correct sign-in-based setup, and the issue was resolved at 09:09. We then verified login and access with no further issues. If this happens again, contact the Service Desk immediately.

## Audience 3 - Engineer-to-Engineer Internal Note
Status: Resolved and verified at 09:09.

Root cause:
- Execution-context/timing failure after migration of drive mapping from GPO USER logon to Intune SYSTEM execution.
- Mapping attempted before required runtime conditions/credentials were available in that context.
- No retry configured, so single failure persisted for affected users.

Supporting evidence:
- Scope: Finance cohort, 45 users, DESKTOP-FB* in OU=Finance.
- 08:00:01 ScriptRunner Info: Executing Map-FinBridgeDrives.ps1.
- 08:00:02 ScriptRunner Info: Script context SYSTEM account.
- 08:00:03 ScriptRunner Warning: \\finbridge-fs01\Finance not accessible from SYSTEM context.
- 08:00:03 ScriptRunner Error: Exit code 1, "Network name cannot be found".
- 08:00:04 ScriptRunner Info: No retry configured.
- 08:00:05 SCM Event 7036: Workstation service entered running state.
- 08:00:06 GroupPolicy Event 1500: GP processed successfully.
- 08:00:07 Ntfs Event 98: S: drive letter not assigned.
- Prior change note (2024-03-14 23:30): USER->SYSTEM migration not updated for SYSTEM context handling.

Exact action taken:
1. Disabled/unassigned the failing SYSTEM-context Intune mapping path for Finance scope.
2. Restored corrected mapping approach in logged-on USER context.
3. Confirmed single active mapping path to prevent overlap/race.

Config detail:
- Affected script: Map-FinBridgeDrives.ps1.
- Failing path targeted via Intune PowerShell in SYSTEM context.
- Corrected path uses USER sign-in context for share mapping.
- Share path involved: \\finbridge-fs01\Finance.

Verification step:
- Resolution timestamp recorded at 09:09.
- Verified user login to host successful and no further shared-drive issue reported post-fix.

Preventive action needed:
1. Mandate USER/SYSTEM execution-context assessment in endpoint-script change control.
2. Require readiness checks (Workstation/UNC) and controlled retry behavior in mapping scripts.
3. Keep one authoritative mapping assignment per user cohort.
4. Add monitoring for repeated ScriptRunner mapping failures and Ntfs Event 98 spikes.
