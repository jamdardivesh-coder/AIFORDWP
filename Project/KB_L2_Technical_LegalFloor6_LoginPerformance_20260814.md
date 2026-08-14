# KB - L2 Technical Handling: Legal Floor 6 Login Failures or Very Slow Logon

## Version Header
- Version: v1.0
- Date: 2026-08-14
- Status: Draft
- Audience: L2 Engineers and Endpoint Support
- Source: Runbook_LegalFloor6_LoginPerformance_Remediation_20260814.md

## Purpose
Use this article when the Legal Floor 6 login/performance incident pattern recurs and the approved service-restoration path is to remove the Floor 6-targeted Document Manager deployment. This article is a technical restatement of the runbook and does not add new mechanism claims beyond the current RCA.

## Prerequisites

- Active incident or change record.
- SCCM deployment-management rights.
- Intune assignment-management rights if applicable.
- A documented Floor 6 target collection or assignment group.
- At least 2 affected pilot devices.
- Pre-change deployment evidence and rollback baseline.

## Procedure

1. Record change start and confirm the current event matches the known Floor 6 pattern.
Expected result: The ticket justifies reuse of the same remediation path.

2. Open SCCM deployments and identify the Document Manager assignment targeted to Legal-Win11 or Floor 6.
Expected result: The exact deployment object is identified.

3. Capture the current assignment state before editing it.
Expected result: Rollback evidence is preserved.

4. Retire, remove, or delete the Floor 6-targeted deployment assignment.
Expected result: The affected scope is no longer targeted by the problematic deployment.

5. Remove matching Intune targeting if it exists.
Expected result: No second management path remains to reapply the same assignment.

6. Save changes and confirm platform success state.
Expected result: SCCM and Intune record the assignment update successfully.

7. Verify deployment status shows no active assignment for the removed Floor 6 target.
Expected result: Platform status confirms the target scope is clear.

8. Force device check-in on pilot devices and validate user sign-in.
Expected result: Pilot users can sign in without the prior severe delay or failure.

9. Record broader service-restoration evidence from the floor contact or queue trend.
Expected result: Floor-wide stabilization is documented for closure.

## Verification

- Floor 6 deployment assignment is removed or retired.
- No active assignment remains for the affected target scope.
- Pilot devices show successful sign-in with materially improved timing.
- Broader Floor 6 reports indicate service restoration.
- Closure record contains exact restoration and verification text.

## Rollback

1. Stop wider change propagation and record rollback start time.
Expected result: Change history clearly shows rollback control.

2. Restore the SCCM assignment baseline.
Expected result: The original deployment targeting is reinstated.

3. Restore the Intune assignment baseline if changed.
Expected result: Assignment state matches pre-change evidence.

4. Revalidate one affected device and document baseline restoration.
Expected result: Post-rollback state is known and traceable.

5. Escalate to policy-conflict and network/auth diagnostic tracks.
Expected result: Investigation continues immediately on alternate ranked causes.

## Operational Note

Keep wording aligned to the RCA: deployment removal is the confirmed service-restoration path, but the exact failing logon component is still to confirm.