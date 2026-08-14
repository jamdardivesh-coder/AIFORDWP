# Runbook - Restore Legal Floor 6 Desktop Shortcuts After Deployment-Side Shortcut Modification

## Version Header
- Version: v1.0
- Date: 2026-08-14
- Status: Draft
- Audience: Endpoint Engineering, EUC Packaging, Service Desk Escalation, Change Owner
- Source: Section 4 of RCA_LegalFloor6_DesktopShortcuts_20260814.md

## 1. Scope
Use this runbook when the Legal Floor 6 shortcut-loss pattern recurs and evidence indicates the same deployment/remediation path described in the RCA.

Section 4 position to preserve:
- Service-restoration root cause is confirmed at the operational level.
- Technical mechanism remains only partially confirmed.
- Leading mechanism is an unintended deployment-side shortcut modification effect involving post-install script, policy, or profile-path interaction.

This runbook restores service and prevents recurrence for the same pattern. Do not state a more specific mechanism unless log evidence confirms it.

## 2. Prerequisites

Complete every item before making changes.

### Access Checklist

- [ ] Incident or change ticket is assigned and in progress.
- [ ] SCCM Administrator or delegated application-deployment rights are available. [ELEVATED]
- [ ] Group Policy edit rights are available for the Legal Floor 6 targeting scope if GPO restoration is used. [ELEVATED]
- [ ] Rights exist to run remote policy refresh or remediation on pilot endpoints. [ELEVATED]
- [ ] Rights exist to review client deployment configuration and post-install command settings. [ELEVATED]

### Tools Checklist

- [ ] SCCM Admin Console
- [ ] Group Policy Management Console (gpmc.msc) if GPO restoration is used
- [ ] PowerShell 5.1 with administrative rights
- [ ] Access to one affected and one unaffected comparison endpoint

### Mandatory Intake and Evidence Checklist

- [ ] At least 2 affected device names are documented.
- [ ] At least 1 unaffected comparison device is documented.
- [ ] The exact shortcuts reported missing are documented.
- [ ] The first reported failure time is documented.
- [ ] Desktop path verification is captured for at least one affected device.
- [ ] Pre-change screenshot or export of the SCCM deployment type or post-install command is attached to the ticket.
- [ ] Pre-change shortcut inventory from one affected device is attached to the ticket.
- [ ] Rollback baseline is captured for any SCCM deployment change and any GPO change.

Pre-start gate:
- Start only after the evidence above supports a deployment-side shortcut impact and a rollback baseline exists.

## 3. Procedure

1. Record the change-start timestamp in the incident or change ticket.
Expected result: The ticket shows exact remediation start time and owner.

2. Confirm on one affected device that the shortcuts are actually missing rather than hidden or redirected.
Expected result: Desktop path and shortcut inventory prove the issue is real and not only a visibility or redirection symptom.

3. Open SCCM Admin Console and go to Software Library > Application Management > Applications.
Expected result: The applications list is visible.

4. Select the deployed Document Manager application version associated with the Friday rollout.
Expected result: The application properties for the suspected package are open.

5. Open the deployment type configuration and review the post-install command or install-behavior script.
Expected result: The exact shortcut-affecting logic can be inspected and captured for evidence.

6. Capture a screenshot or export of the current deployment type configuration and attach it to the ticket.
Expected result: Pre-change deployment evidence is preserved for rollback and RCA completion.

7. Remove, disable, or correct any desktop-modifying post-install logic that can delete, move, rename, or overwrite user desktop shortcuts.
Expected result: The deployment no longer contains the shortcut-affecting behavior.

8. Save the updated deployment type so SCCM creates a new application revision.
Expected result: A new revision exists and can be audited separately from the original package.

9. Redeploy the corrected application revision to the Legal-Win11 or Legal Floor 6 target collection using the approved change path.
Expected result: Affected devices are targeted to receive the corrected deployment behavior.

10. Choose the shortcut restoration method based on the documented shortcut pattern.
Expected result: One restoration path is selected and recorded in the ticket.

11. If the missing shortcuts are standard corporate shortcuts, open Group Policy Management and go to User Configuration > Preferences > Windows Settings > Shortcuts in the target GPO.
Expected result: The shortcuts configuration pane is open for the Legal Floor 6 targeting scope.

12. Create or update shortcut items for the missing standard applications with Action set to Update and Location set to %USERPROFILE%\Desktop.
Expected result: The target GPO contains the standard shortcuts needed for restoration.

13. If the shortcut set is user-specific or GPO is not the approved recovery path, deploy the approved PowerShell remediation script to recreate the documented missing shortcuts.
Expected result: A script-based restoration job is queued for affected devices.

14. Force policy refresh or remediation execution on 2 pilot affected devices.
Expected result: The corrected deployment logic and shortcut restoration path are applied on pilot devices.

15. Sign in to each pilot device with an affected user or approved test method and verify the reported shortcuts are present on the desktop.
Expected result: Missing shortcuts are restored on both pilot devices.

16. Open the restored shortcuts and confirm they launch the intended applications.
Expected result: Shortcuts are not only present but functional.

17. Confirm on one unaffected comparison device that the remediation did not remove or duplicate valid shortcuts.
Expected result: No collateral shortcut impact is introduced to unaffected users.

18. Monitor SCCM deployment status and, if used, Group Policy or script execution results until the affected target scope shows successful application.
Expected result: Deployment telemetry shows the corrected change has reached the intended devices.

19. Attach post-change screenshots, pilot verification notes, and deployment results to the ticket.
Expected result: The ticket contains before-and-after evidence for closure.

20. Record final closure notes, including the restoration time and the exact verification evidence text when confirmed.
Expected result: The ticket is ready for final incident closure and RCA evidence completion.

## 4. Verification

Treat the remediation as complete only when all checks below pass.

1. The corrected deployment no longer contains shortcut-modifying logic that can reproduce the issue.
Expected result: SCCM revision review confirms the problematic logic has been removed, disabled, or corrected.

2. The documented missing shortcuts are restored on pilot affected devices.
Expected result: Visual check and shortcut inventory show the shortcuts are present.

3. Restored shortcuts open the expected applications successfully.
Expected result: Pilot users or test validation confirm functional launch behavior.

4. Unaffected devices do not show regression such as duplicate shortcuts or new loss of shortcuts.
Expected result: Comparison validation shows no collateral change.

5. Deployment or policy execution status shows successful rollout to the intended scope.
Expected result: SCCM, GPO, or script telemetry confirms successful application.

## 5. Rollback

Use rollback if the corrected deployment causes new failures, shortcut restoration is incorrect, or pilot verification fails.

1. Stop wider rollout and record rollback-start time in the ticket.
Expected result: Incident history clearly shows when remediation execution was halted.

2. Revert the SCCM application or deployment type to the pre-change revision captured in the rollback baseline.
Expected result: The deployment configuration matches the pre-change state.

3. Remove or disable the newly added GPO shortcut items or remediation script if they created incorrect results.
Expected result: Restoration logic introduced during this change is withdrawn.

4. Re-run validation on one affected and one unaffected device.
Expected result: Environment state matches the pre-change baseline and no new regression remains.

5. Keep the incident open and escalate to Endpoint Engineering for a revised approved recovery path.
Expected result: No additional deployment changes proceed without a corrected plan.

## 6. Notes for Completion

- This runbook intentionally preserves the RCA distinction between confirmed service restoration and only partially confirmed technical mechanism.
- When exact restoration timestamp and verification text are confirmed, update this runbook and increment the version.