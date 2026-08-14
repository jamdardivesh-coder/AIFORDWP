# KB - L2 Technical Handling: Legal Floor 6 Copilot Access Remediation

## Version Header
- Version: v1.0
- Date: 2026-08-14
- Status: Draft
- Audience: L2 Engineers and Incident Handlers
- Source: Runbook_LegalFloor6_CopilotAccess_Remediation_20260814.md

## Purpose
Use this article when a user reports that Copilot surfaced matter content they do not believe they should be able to access. This article is a technical restatement of the source runbook and does not add new root-cause assumptions.

## Prerequisites

- Active incident or change record.
- Official Security/Data-Governance finding.
- Exact confirmed remediation action.
- Documented user, matter, repository, and access path.
- Pre-change evidence and rollback baseline.
- Administrative rights on the affected source platform.

## Procedure

1. Record the change-start timestamp and copy the exact confirmed cause and remediation wording into the ticket.
Expected result: The ticket contains the authorized reason and action for the change.

2. Identify the exact authoritative object named by Security/Data-Governance and capture its current state.
Expected result: You have one rollback-ready baseline for the real access-granting object.

3. Prove the affected user currently reaches the reported matter through that exact path.
Expected result: Evidence shows the current user-to-object-to-content access chain.

4. Apply the approved remediation action to that object only.
Expected result: The unintended access path is removed, corrected, or narrowed without changing unrelated scope.

5. Save the change and capture the platform confirmation or audit event.
Expected result: The authoritative system records a successful change with timestamp.

6. Re-run effective-permission validation for the affected user.
Expected result: The user no longer has the unintended access path.

7. Validate authorized-user access and the original Copilot reproduction scenario.
Expected result: Intended access remains intact and the prior Copilot result no longer reproduces.

8. Attach before-and-after evidence and request Security/Data-Governance sign-off.
Expected result: The evidence package is complete for closure.

## Verification

- Effective permissions no longer grant the affected user the reported matter.
- Audit trail confirms the change.
- Authorized users still retain expected access.
- The approved post-remediation Copilot validation passes.
- Security/Data-Governance signs off.

## Rollback

1. Stop further changes and record rollback start time.
Expected result: Incident history reflects controlled rollback.

2. Restore the exact pre-change configuration baseline.
Expected result: The authoritative object returns to its previous state.

3. Re-test the affected user and one authorized user.
Expected result: Access returns to the documented pre-change behavior.

4. Notify Security/Data-Governance and keep the incident open pending a revised approved action.
Expected result: Ownership returns to the investigation team with clear rollback evidence.

## Operational Note

Do not invent a platform-specific fix from symptoms alone. If the exact Section 4 finding and remediation text are still placeholders, stop and obtain the official closure wording before execution.