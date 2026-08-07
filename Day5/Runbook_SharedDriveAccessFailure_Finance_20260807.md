# Runbook - Restore Finance Shared Drive Access (Execution-Context Mapping Failure)
## Source RCA: SharedDriveAccessFailure_Finance_2026-08-07

| Field | Value |
|-------|-------|
| Title | Runbook - Restore Finance Shared Drive Access (Execution-Context Mapping Failure) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Divesh Jamdar |
| reviewed | self |
| status | draft |
| change | initial version from RCA |

## 1. Prerequisites

Complete every checklist item before change execution.

### Access Checklist

- [ ] Incident ticket is assigned to you and status is Active/In Progress.
- [ ] Intune RBAC role can edit PowerShell script assignments in Intune Admin Center. [ELEVATED]
- [ ] AD/GPO rights can edit and link the Finance drive-mapping GPO in Group Policy Management. [ELEVATED]
- [ ] Rights exist to run remote policy refresh on Finance endpoints. [ELEVATED]
- [ ] Rights exist to read endpoint Windows Event Logs and Intune Management Extension logs. [ELEVATED]
- [ ] Access to Finance file server path \\finbridge-fs01\Finance is available from a Finance user session.

### Tools Checklist

- [ ] Browser access to Microsoft Intune Admin Center: https://intune.microsoft.com
- [ ] Group Policy Management Console (gpmc.msc) on admin workstation or management server
- [ ] Event Viewer (eventvwr.msc) or SIEM query access
- [ ] PowerShell 5.1 console with administrative rights
- [ ] Command Prompt access on pilot endpoints for net use and gpupdate checks

### Mandatory End-User Intake Checklist

- [ ] Affected user count is documented.
- [ ] At least 3 affected usernames are documented for pilot verification.
- [ ] At least 3 affected endpoint names are documented (example format: DESKTOP-FBxxx).
- [ ] Exact first-failure time is documented.
- [ ] Business impact statement from Finance contact is documented.
- [ ] Confirmation is documented that users can sign in but cannot access mapped drive S:.
- [ ] Confirmation is documented whether users can access \\finbridge-fs01\Finance directly via UNC.

### Mandatory Configuration Identifiers

- [ ] Intune script name: Map-FinBridgeDrives.ps1
- [ ] Intune assignment group for Finance: <ENTRA_GROUP_NAME_OR_ID>
- [ ] Finance OU DN: <OU=Finance,...>
- [ ] Finance drive-mapping GPO name: <GPO_NAME>
- [ ] GPO path for drive mapping item: User Configuration > Preferences > Windows Settings > Drive Maps
- [ ] Target mapping value: S: -> \\finbridge-fs01\Finance
- [ ] Current rollback reference captured (screenshot/export of current Intune assignments and current GPO item settings)

Pre-start gate:
- Start procedure only after every checkbox above is complete.

---

## 2. Procedure

1. Add a change-start timestamp note in the incident ticket.
Expected result: Incident record shows exact start time for traceability.

2. Open Intune Admin Center at https://intune.microsoft.com. [ELEVATED]
Expected result: Intune portal landing page is visible.

3. Go to Devices > Scripts and remediations > Platform scripts > Windows.
Expected result: Windows platform scripts list is visible.

4. Select script Map-FinBridgeDrives.ps1.
Expected result: Script overview page opens.

5. Open the Assignments tab for Map-FinBridgeDrives.ps1.
Expected result: Current included and excluded groups are visible.

6. Capture a screenshot of Assignments tab and attach it to the incident ticket.
Expected result: Pre-change assignment evidence is preserved.

7. Click Edit assignment in the Assignments tab. [ELEVATED]
Expected result: Assignment edit pane opens.

8. Remove Finance assignment group <ENTRA_GROUP_NAME_OR_ID> from Included groups. [ELEVATED]
Expected result: Finance group is no longer listed in Included groups.

9. Click Review + save for the assignment change. [ELEVATED]
Expected result: Intune confirms assignment update success.

10. Open Group Policy Management by running gpmc.msc. [ELEVATED]
Expected result: Group Policy Management console opens.

11. Expand Forest > Domains > <domain> > <OU path containing Finance OU>.
Expected result: Finance OU appears in the left navigation tree.

12. Select the Finance OU.
Expected result: Linked GPOs for Finance OU are visible in the details pane.

13. Right-click GPO <GPO_NAME> and select Edit. [ELEVATED]
Expected result: Group Policy Management Editor opens.

14. Navigate to User Configuration > Preferences > Windows Settings > Drive Maps.
Expected result: Drive Maps pane is visible.

15. Open properties of the S: mapping item.
Expected result: Mapping properties dialog opens.

16. Set Action to Update for the S: mapping item.
Expected result: Action field shows Update.

17. Set Location to \\finbridge-fs01\Finance for the S: mapping item.
Expected result: Location field shows the Finance UNC path.

18. Set Label as to Finance for the S: mapping item.
Expected result: Label field shows Finance.

19. Enable Reconnect for the S: mapping item.
Expected result: Reconnect option is selected.

20. Click OK in mapping properties.
Expected result: Updated S: mapping is saved in Drive Maps list.

21. Close Group Policy Management Editor.
Expected result: Editor closes without save prompts.

22. Start Event Viewer on pilot endpoint 1 by running eventvwr.msc. [ELEVATED]
Expected result: Event Viewer opens on pilot endpoint 1.

23. Open Windows Logs > System on pilot endpoint 1.
Expected result: System log entries are visible.

24. Click Filter Current Log and set Event IDs to 7036,98.
Expected result: Filtered System log shows service state and NTFS mapping events.

25. Export filtered System log to C:\Incident\FinanceDriveMap\Pilot1-System-Before.evtx.
Expected result: Pre-change System log evidence file is saved.

26. Open Windows Logs > System on pilot endpoint 1.
Expected result: System log is visible for service and policy events.

27. Click Filter Current Log and set Event Sources to GroupPolicy and Event IDs to 1500.
Expected result: GroupPolicy Event ID 1500 entries are visible in System log.

28. Export filtered System log to C:\Incident\FinanceDriveMap\Pilot1-GroupPolicy1500-Before.evtx.
Expected result: Pre-change GroupPolicy evidence file is saved.

29. Open file C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log in CMTrace or Notepad.
Expected result: Intune script execution log file opens.

30. Search IntuneManagementExtension.log for Map-FinBridgeDrives.ps1 and record latest timestamp in the ticket.
Expected result: Last known SYSTEM-context script execution time is documented.

31. Run gpupdate /force on pilot endpoint 1 from elevated Command Prompt. [ELEVATED]
Expected result: Computer Policy and User Policy update complete successfully.

32. Sign out pilot user 1 on pilot endpoint 1.
Expected result: Session ends successfully.

33. Sign in pilot user 1 on pilot endpoint 1.
Expected result: User reaches desktop successfully.

34. Open File Explorer and select This PC on pilot endpoint 1.
Expected result: Drive list is displayed.

35. Open drive S: on pilot endpoint 1.
Expected result: Drive S: opens and displays Finance share contents.

36. Run net use in Command Prompt on pilot endpoint 1.
Expected result: Output shows S: mapped to \\finbridge-fs01\Finance.

37. Run gpupdate /force on pilot endpoint 2 from elevated Command Prompt. [ELEVATED]
Expected result: Computer Policy and User Policy update complete successfully on endpoint 2.

38. Sign out pilot user 2 on pilot endpoint 2.
Expected result: Session ends successfully on endpoint 2.

39. Sign in pilot user 2 on pilot endpoint 2.
Expected result: User reaches desktop successfully on endpoint 2.

40. Open drive S: on pilot endpoint 2.
Expected result: Drive S: opens and displays Finance share contents on endpoint 2.

41. Run net use in Command Prompt on pilot endpoint 2.
Expected result: Output shows S: mapped to \\finbridge-fs01\Finance on endpoint 2.

42. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log on pilot endpoint 2.
Expected result: Intune script execution log is open on endpoint 2.

43. Search IntuneManagementExtension.log for Map-FinBridgeDrives.ps1 on pilot endpoint 2.
Expected result: Latest script execution status is visible on endpoint 2.

44. Run gpupdate /force on pilot endpoint 3 from elevated Command Prompt. [ELEVATED]
Expected result: Computer Policy and User Policy update complete successfully on endpoint 3.

45. Sign out pilot user 3 on pilot endpoint 3.
Expected result: Session ends successfully on endpoint 3.

46. Sign in pilot user 3 on pilot endpoint 3.
Expected result: User reaches desktop successfully on endpoint 3.

47. Open drive S: on pilot endpoint 3.
Expected result: Drive S: opens and displays Finance share contents on endpoint 3.

48. Run net use in Command Prompt on pilot endpoint 3.
Expected result: Output shows S: mapped to \\finbridge-fs01\Finance on endpoint 3.

49. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log on pilot endpoint 3.
Expected result: Intune script execution log is open on endpoint 3.

50. Search IntuneManagementExtension.log for Map-FinBridgeDrives.ps1 on pilot endpoint 3.
Expected result: Latest script execution status is visible on endpoint 3.

51. Add pilot validation note with usernames, endpoint names, and timestamps to the incident ticket.
Expected result: Incident ticket has complete pilot proof.

52. Open Intune Admin Center > Devices > All devices.
Expected result: Device inventory list is visible.

53. Select remaining affected Finance devices.
Expected result: Target devices are highlighted.

54. Click Sync for selected devices. [ELEVATED]
Expected result: Intune sync action is queued for selected devices.

55. Send Service Desk instruction to perform one sign-out and one sign-in for affected users.
Expected result: Service Desk confirms user communication sent.

56. Record service-restored timestamp when majority users confirm S: access.
Expected result: Ticket contains formal restoration time.

---

## 3. Verification

Complete all checks in this order before closure.

1. Open Intune Admin Center at https://intune.microsoft.com. [ELEVATED]
Expected result: Intune portal landing page is visible.

2. Go to Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Device status.
Expected result: Device status list for script execution is visible.

3. Filter Device status to Finance pilot endpoints used in Procedure.
Expected result: Pilot endpoint execution rows are visible.

4. Confirm no new failed execution for Map-FinBridgeDrives.ps1 after change timestamp.
Expected result: No post-change failed runs are shown for pilot endpoints.

5. Open Event Viewer on pilot endpoint 1 by running eventvwr.msc. [ELEVATED]
Expected result: Event Viewer opens on pilot endpoint 1.

6. Go to Windows Logs > System on pilot endpoint 1.
Expected result: System log list is visible.

7. Click Filter Current Log and set Event IDs to 98 and Logged to Last 1 hour.
Expected result: Filter returns zero new NTFS drive assignment warning events.

8. Go to Windows Logs > System and set Event Source to GroupPolicy and Event ID to 1500.
Expected result: GroupPolicy processing success events are visible for recent user sign-in.

9. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log on pilot endpoint 1.
Expected result: Intune management log file opens.

10. Search IntuneManagementExtension.log for Map-FinBridgeDrives.ps1 entries after change timestamp.
Expected result: No new failure entries are present after change timestamp.

11. Open Event Viewer on pilot endpoint 2 by running eventvwr.msc. [ELEVATED]
Expected result: Event Viewer opens on pilot endpoint 2.

12. Go to Windows Logs > System on pilot endpoint 2.
Expected result: System log list is visible on pilot endpoint 2.

13. Click Filter Current Log on pilot endpoint 2 and set Event IDs to 98 and Logged to Last 1 hour.
Expected result: Filter returns zero new NTFS drive assignment warning events on pilot endpoint 2.

14. Set Event Source to GroupPolicy and Event ID to 1500 on pilot endpoint 2.
Expected result: GroupPolicy processing success events are visible on pilot endpoint 2.

15. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log on pilot endpoint 2.
Expected result: Intune management log file opens on pilot endpoint 2.

16. Search IntuneManagementExtension.log for Map-FinBridgeDrives.ps1 entries after change timestamp on pilot endpoint 2.
Expected result: No new failure entries are present after change timestamp on pilot endpoint 2.

17. Open Event Viewer on pilot endpoint 3 by running eventvwr.msc. [ELEVATED]
Expected result: Event Viewer opens on pilot endpoint 3.

18. Go to Windows Logs > System on pilot endpoint 3.
Expected result: System log list is visible on pilot endpoint 3.

19. Click Filter Current Log on pilot endpoint 3 and set Event IDs to 98 and Logged to Last 1 hour.
Expected result: Filter returns zero new NTFS drive assignment warning events on pilot endpoint 3.

20. Set Event Source to GroupPolicy and Event ID to 1500 on pilot endpoint 3.
Expected result: GroupPolicy processing success events are visible on pilot endpoint 3.

21. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log on pilot endpoint 3.
Expected result: Intune management log file opens on pilot endpoint 3.

22. Search IntuneManagementExtension.log for Map-FinBridgeDrives.ps1 entries after change timestamp on pilot endpoint 3.
Expected result: No new failure entries are present after change timestamp on pilot endpoint 3.

23. Open File Explorer on five affected user sessions and open drive S:.
Expected result: All five sessions can open S: and browse folders.

24. Run net use on those five sessions.
Expected result: Each session shows S: mapped to \\finbridge-fs01\Finance.

25. Query Service Desk queue for Finance shared-drive incident category for last 30 minutes.
Expected result: No new incidents with the same symptom are present.

26. Attach verification evidence files from C:\Incident\FinanceDriveMap\ to the incident ticket.
Expected result: Incident has log exports and proof artifacts attached.

27. Add closure note with final validation timestamp and impacted-user confirmation count.
Expected result: Incident has complete auditable closure evidence.

Closure gate:
- Close only if all verification steps above pass.

---

## 4. Rollback

Use this emergency rollback if impact increases after change. Execute steps 1 through 10 in under 3 minutes.

1. Add ticket note: "Emergency rollback started" with current timestamp.
Expected result: Rollback start time is recorded.

2. Open Intune Admin Center at https://intune.microsoft.com. [ELEVATED]
Expected result: Intune portal opens.

3. Go to Devices > Scripts and remediations > Platform scripts > Windows > Map-FinBridgeDrives.ps1 > Assignments.
Expected result: Assignment page is visible.

4. Click Edit assignment. [ELEVATED]
Expected result: Assignment edit pane opens.

5. Add Finance assignment group <ENTRA_GROUP_NAME_OR_ID> to Included groups. [ELEVATED]
Expected result: Finance group is present in Included groups.

6. Click Review + save. [ELEVATED]
Expected result: Intune confirms assignment saved.

7. Open Group Policy Management by running gpmc.msc. [ELEVATED]
Expected result: Group Policy Management opens.

8. Go to Forest > Domains > <domain> > <OU path containing Finance OU> > GPO <GPO_NAME> > Edit > User Configuration > Preferences > Windows Settings > Drive Maps.
Expected result: Drive Maps list opens for the target GPO.

9. Set the S: mapping item to Disabled and click OK. [ELEVATED]
Expected result: USER-context S: mapping is disabled.

10. Close Group Policy Management Editor.
Expected result: Rollback configuration is committed.

Immediate post-rollback check (do immediately after step 10):

11. On one pilot endpoint, run gpupdate /force in elevated Command Prompt. [ELEVATED]
Expected result: Policy refresh completes successfully.

12. Sign out and sign in one pilot Finance user.
Expected result: Pilot user returns to desktop.

13. Run net use on the pilot endpoint.
Expected result: Mapping behavior matches pre-change baseline.

14. Open C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log and confirm current-time assignment processing.
Expected result: Log shows rollback processing after step 6.

15. Open Event Viewer > Windows Logs > System and filter Event Source GroupPolicy with Event ID 1500 for Last 15 minutes.
Expected result: GroupPolicy processing success event is present.

16. If pilot check fails, escalate immediately to EUC Platform and IAM on-call and attach C:\Incident\FinanceDriveMap\ evidence files.
Expected result: Escalation receives full context without delay.

---

## 5. Notes

- This runbook is for USER-versus-SYSTEM execution-context mismatch in drive mapping after migration.
- Warning: running drive mapping in SYSTEM context for user-scoped shares can fail because user credentials are unavailable at execution time.
- Warning: overlapping assignments (Intune plus GPO) can create inconsistent mapping outcomes; keep one active mechanism per cohort.
- Edge case: if Workstation service startup is delayed at logon, mapping may still race; use readiness checks and bounded retries in future script versions.
- Edge case: VPN or network-init delay can mimic this incident; confirm UNC path reachability from user session before changing assignments.
- Related incidents: Day4 RCA and closure records for shared-drive access failure and policy/application timing issues.
