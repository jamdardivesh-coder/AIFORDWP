# Runbook - Restore Legal Floor 6 Login Performance by Removing the Floor-Targeted Document Manager Deployment

## Version Header
- Version: v1.0
- Date: 2026-08-14
- Status: Draft
- Audience: Endpoint Engineering, SCCM/Intune Administrators, Incident Response, Service Desk Escalation
- Source: Section 4 of RCA_LegalFloor6_LoginPerformance_20260814.md

## 1. Scope
Use this runbook when Legal Floor 6 experiences the same widespread login-failure or severe logon-delay pattern and the remediation path from the RCA is being repeated.

Section 4 position to preserve:
- Service restoration was operationally linked to the Floor 6 document-management deployment path.
- The technical mechanism remains only partially confirmed.
- The most likely mechanism is logon/startup contention or failure introduced by the Friday deployment.

This runbook executes the confirmed service-restoration path. Do not claim a specific failing executable, service, or event ID unless the evidence package confirms it.

## 2. Prerequisites

Complete every item before making changes.

### Access Checklist

- [ ] Incident or change ticket is assigned and in progress.
- [ ] SCCM Administrator or delegated deployment-management rights are available. [ELEVATED]
- [ ] Intune Administrator or delegated assignment-management rights are available if Intune targeting exists. [ELEVATED]
- [ ] Rights exist to view deployment status and affected collection membership. [ELEVATED]
- [ ] Rights exist to validate pilot devices after the rollback action. [ELEVATED]

### Tools Checklist

- [ ] SCCM Admin Console
- [ ] Intune Admin Center if Intune assignment exists
- [ ] PowerShell 5.1 or Command Prompt with administrative rights for pilot validation
- [ ] Access to at least 2 affected pilot devices and 1 confirmed user for validation

### Mandatory Intake and Evidence Checklist

- [ ] Affected user count is documented.
- [ ] At least 2 affected device names are documented for pilot verification.
- [ ] Exact first-failure time is documented.
- [ ] The Floor 6 target collection or assignment group name is documented.
- [ ] Pre-change screenshot or export of the active SCCM deployment assignment is attached to the ticket.
- [ ] Pre-change screenshot or export of the Intune assignment is attached if applicable.
- [ ] Rollback baseline for the current deployment assignment is captured.
- [ ] Business approval to remove or retire the deployment assignment is recorded.

Pre-start gate:
- Start only after the issue matches the documented Floor 6 pattern and the target deployment assignment has been positively identified.

## 3. Procedure

1. Record the change-start timestamp in the incident or change ticket.
Expected result: The ticket shows exact remediation start time and owner.

2. Confirm the incident matches the known pattern: Floor 6 users report failed logins or very slow logon after the document-management rollout window.
Expected result: The ticket clearly ties the current event to the same service-restoration path.

3. Open SCCM Admin Console and go to Software Library > Application Management > Deployments.
Expected result: The SCCM deployments view is visible.

4. Locate the Document Manager deployment targeted to the Legal-Win11 or Floor 6 collection.
Expected result: The exact deployment object to be changed is identified.

5. Capture a screenshot or export of the current deployment assignment and attach it to the ticket.
Expected result: Pre-change deployment evidence is preserved for audit and rollback.

6. Retire, remove, or delete the Floor 6-targeted deployment assignment according to your SCCM change-control standard.
Expected result: The affected Floor 6 collection is no longer targeted by the problematic deployment.

7. If the same app is also targeted through Intune, open Intune Admin Center and remove the Floor 6 or Legal-Win11 assignment.
Expected result: No parallel Intune assignment remains to reapply the same deployment pressure.

8. Save the SCCM and, if applicable, Intune assignment changes and capture confirmation of successful update.
Expected result: The management platforms record the change with timestamped success state.

9. Check SCCM deployment status to confirm there are no active assignments left for the affected Floor 6 target.
Expected result: Deployment status shows 0 active assignments for the removed target scope.

10. If an approved prior stable version exists and business approval requires it, deploy the known-good previous version to the same scope.
Expected result: A controlled fallback version is available instead of the removed problematic revision.

11. Force policy refresh or device check-in on 2 affected pilot devices.
Expected result: Pilot devices receive the updated assignment state promptly.

12. Have the pilot users sign out and sign back in, or reboot and sign in, using the approved validation method.
Expected result: The login attempt completes without the prior failure or severe delay.

13. Record logon timing and user outcome for each pilot validation device.
Expected result: The ticket contains concrete post-change restoration evidence.

14. Confirm with the Floor 6 contact or service desk queue that broader user login behavior is stabilizing.
Expected result: Real-world user reports show the floor-wide issue is clearing.

15. Attach post-change screenshots, deployment-status evidence, and pilot validation notes to the ticket.
Expected result: The incident record contains before-and-after evidence for closure.

16. Record final closure notes, including the confirmed restoration time and exact verification wording when available.
Expected result: The ticket is ready for incident closure and RCA completion.

## 4. Verification

Treat the remediation as complete only when all checks below pass.

1. The Floor 6-targeted Document Manager deployment assignment has been removed or retired.
Expected result: SCCM and, if applicable, Intune no longer target the affected Floor 6 scope.

2. Deployment status confirms no active assignment remains for the removed Floor 6 target.
Expected result: Platform status shows 0 active assignments or equivalent retired state.

3. Pilot affected devices can complete login without the prior severe delay or failure.
Expected result: User sign-in succeeds within normal or materially improved timing.

4. Broader Floor 6 user reports indicate service restoration.
Expected result: New login-failure or severe-delay reports drop to normal levels.

5. Post-change evidence is attached and the closure record contains the exact restoration and verification statements.
Expected result: The ticket is evidence-complete for the service-restoration path.

## 5. Rollback

Use rollback if removing the deployment does not improve logon behavior, introduces new issues, or removes an application that must remain available without an approved fallback.

1. Record rollback-start time and stop wider change propagation.
Expected result: The ticket clearly shows the remediation was halted.

2. Restore the SCCM deployment assignment from the captured pre-change baseline if required by change control.
Expected result: The original assignment state is reinstated exactly as documented.

3. Restore the Intune assignment as captured in the baseline if it was changed.
Expected result: Any removed Intune targeting is returned to the previous state.

4. Revalidate one affected device and document that the environment matches the pre-change baseline.
Expected result: Post-rollback state is known and recorded.

5. Escalate immediately to the alternate-cause tracks for policy conflict and network or authentication investigation.
Expected result: The incident continues under the next ranked diagnostic path without delay.

## 6. Notes for Completion

- This runbook preserves the RCA boundary: service restoration is confirmed through deployment removal, but mechanism-level proof remains partial.
- When the exact restoration timestamp and verification text are confirmed, update this runbook and increment the version.