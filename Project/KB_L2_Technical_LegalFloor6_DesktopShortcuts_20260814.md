# KB - L2 Technical Handling: Legal Floor 6 Missing Desktop Shortcuts

## Version Header
- Version: v1.0
- Date: 2026-08-14
- Status: Draft
- Audience: L2 Engineers and Endpoint Support
- Source: Runbook_LegalFloor6_DesktopShortcuts_Remediation_20260814.md

## Purpose
Use this article for the recurring Floor 6 shortcut-loss pattern tied to the deployment/remediation path documented in the RCA. This is a technical restatement of the source runbook and does not claim a more specific mechanism than the current evidence supports.

## Prerequisites

- Active incident or change record.
- SCCM deployment-edit rights.
- Optional GPO edit rights if Group Policy restoration is used.
- One affected and one unaffected comparison device.
- Pre-change deployment evidence and rollback baseline.
- Documented list of missing shortcuts and first-failure time.

## Procedure

1. Record change start and prove the shortcuts are actually missing rather than hidden or redirected.
Expected result: The ticket contains a verified endpoint symptom with desktop-path evidence.

2. Open SCCM and review the deployment type for the Document Manager rollout package associated with the incident window.
Expected result: The suspected post-install or install-behavior logic is visible for review.

3. Capture the current deployment configuration before editing it.
Expected result: Rollback evidence is preserved.

4. Remove, disable, or correct any logic that modifies desktop shortcuts in a way that can recreate the incident.
Expected result: The new application revision no longer includes the shortcut-affecting behavior.

5. Redeploy the corrected revision to the affected Legal Floor 6 target collection.
Expected result: Target devices are queued for corrected deployment behavior.

6. Restore the missing shortcuts using the approved recovery path.
Expected result: GPO or script-based restoration is configured for the documented shortcut set.

7. Force execution on pilot affected devices and validate shortcut presence and launch behavior.
Expected result: Pilot devices show restored and working shortcuts.

8. Validate an unaffected comparison device and monitor rollout telemetry.
Expected result: No collateral regression is introduced and deployment status shows success.

9. Attach before-and-after evidence and record exact restoration and verification text for closure.
Expected result: The incident record is evidence-complete for operational closure.

## Verification

- Corrected deployment revision no longer contains the shortcut-affecting logic.
- Missing shortcuts are restored on pilot affected devices.
- Restored shortcuts launch the intended applications.
- Unaffected devices do not regress.
- SCCM, GPO, or script telemetry confirms successful application.

## Rollback

1. Stop wider rollout and record rollback start time.
Expected result: The incident record shows controlled rollback handling.

2. Revert SCCM deployment configuration to the captured baseline.
Expected result: Application behavior returns to the pre-change revision.

3. Withdraw the new GPO shortcut items or remediation script if they are incorrect.
Expected result: Newly introduced restoration logic is removed.

4. Revalidate one affected and one unaffected device.
Expected result: No new shortcut regression remains after rollback.

5. Escalate for a revised engineering fix path.
Expected result: Further action is paused until a safer approved remediation exists.

## Operational Note

The current RCA confirms service restoration through the deployment/remediation path, but mechanism-level proof is still partial. Keep ticket wording aligned with that evidence boundary.