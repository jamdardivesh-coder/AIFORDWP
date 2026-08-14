# Runbook - Apply Security/Data-Governance Confirmed Remediation for Legal Floor 6 Copilot Access Issue

## Version Header
- Version: v1.0
- Date: 2026-08-14
- Status: Draft
- Audience: Security, Data-Governance, Microsoft 365 Engineering, Service Owner
- Source: Section 4 of RCA_LegalFloor6_CopilotAccess_SecurityDataGovernance_20260814.md

## 1. Scope
Use this runbook only after Security/Data-Governance has issued the official finding and the approved remediation action for the Legal Floor 6 Copilot access issue.

Current Section 4 source values:
- Confirmed cause detail text: [their finding - e.g., the specific permissions/access-path cause].
- Confirmed remediation action: [confirmed action].

Do not infer or substitute missing values. Replace the bracketed fields with the exact closure-record wording before execution.

## 2. Prerequisites

Complete every item before making changes.

- [ ] Active incident or change record exists and is assigned to the executing engineer.
- [ ] Official Security/Data-Governance closure record is available.
- [ ] Exact Section 4 confirmed cause text has been copied into the ticket.
- [ ] Exact remediation action text has been copied into the ticket.
- [ ] Affected user identity, matter identifier, source repository, and access path are documented.
- [ ] Current effective-permission evidence is captured.
- [ ] Current configuration snapshot is captured for the object being changed.
- [ ] Approval to execute the remediation is recorded.
- [ ] Rollback owner is identified.

### Required Access

- [ ] Administrative rights to the affected source platform identified in the finding.
- [ ] Rights to view and export current ACL, membership, sharing, inheritance, or connector settings.
- [ ] Rights to validate post-change access behavior using approved audit methods.

### Mandatory Evidence to Capture Before Change

- [ ] Screenshot or export of the current access-granting object.
- [ ] List of users and groups currently granting the reported access path.
- [ ] Timestamped copy of the Security/Data-Governance finding.
- [ ] Timestamped copy of the approved remediation action.
- [ ] Ticket note recording business approval and change-start time.

Pre-start gate:
- Start only when every prerequisite above is complete and the exact finding/action text is no longer a placeholder.

## 3. Procedure

1. Record the change-start timestamp in the incident or change record.
Expected result: The ticket shows who started the remediation and at what time.

2. Paste the exact Section 4 confirmed cause detail and exact remediation action into the work notes.
Expected result: The ticket contains the exact authorized wording that will drive the fix.

3. Identify the authoritative access object named by Security/Data-Governance.
Expected result: One specific object is named as the change target, such as the exact group, ACL entry, inherited permission, sharing link, connector scope, or provisioning rule.

4. Capture a pre-change export or screenshot of that authoritative access object.
Expected result: A rollback baseline is attached to the ticket before any modification is made.

5. Confirm the affected user currently receives access through the exact path described in the finding.
Expected result: The evidence shows the user-to-object-to-matter path that matches the confirmed cause.

6. Apply the exact approved remediation action to the authoritative access object.
Expected result: The access path identified in the finding is removed, corrected, disabled, or narrowed exactly as approved.

7. Save or publish the change in the source platform and capture the resulting confirmation message, change ID, or audit event.
Expected result: The platform records a successful configuration update with a traceable timestamp.

8. Re-evaluate effective permissions for the reported user against the reported matter or repository location.
Expected result: The previously confirmed unintended access path is no longer present.

9. Validate that intended users retain expected access to the same content scope.
Expected result: Authorized users still have access and no broader outage was introduced.

10. Validate Copilot or the affected discovery path using the approved post-remediation test method from Security/Data-Governance.
Expected result: The matter is no longer surfaced to the previously affected user through the same scenario.

11. Attach post-change evidence to the ticket, including permission results, validation output, and timestamps.
Expected result: The ticket contains before-and-after proof of remediation.

12. Record closure notes that restate the final cause, action taken, validation result, and any residual risk.
Expected result: The ticket is ready for Security/Data-Governance sign-off.

## 4. Verification

Treat the remediation as complete only when all checks below pass.

1. The exact access path named in the Security/Data-Governance finding no longer grants the affected user access.
Expected result: Effective permissions for the user no longer include the reported matter or source location.

2. The remediation change is visible in the authoritative platform audit trail.
Expected result: A timestamped audit event, change record, or object revision confirms the update.

3. Approved business owners confirm that authorized users still have the expected access.
Expected result: No collateral access loss is reported for intended users.

4. The approved post-remediation validation method confirms that the original Copilot access behavior no longer occurs.
Expected result: The prior reproduction path fails safely or returns only content the user is authorized to access.

5. Security/Data-Governance signs off on the evidence package.
Expected result: The investigation record can be closed without open evidence gaps for the remediation step.

## 5. Rollback

Use rollback if the remediation removes legitimate access, introduces broader access failure, or cannot be validated.

1. Stop further related changes and record rollback-start time in the ticket.
Expected result: Incident history clearly shows that remediation execution has paused.

2. Restore the exact pre-change configuration captured in the prerequisite evidence.
Expected result: The authoritative access object matches the saved pre-change baseline.

3. Re-run effective-permission checks for both the affected user and one known-authorized user.
Expected result: Access behavior returns to the pre-change state documented in the baseline.

4. Notify Security/Data-Governance and the service owner that rollback was required and provide the validation failure reason.
Expected result: Stakeholders are aware that the approved remediation did not safely complete.

5. Keep the incident open and require a revised approved remediation before another change attempt.
Expected result: No further access changes occur without a new authorized fix path.

## 6. Notes for Completion

- This runbook is intentionally evidence-bounded to the RCA and does not add an inferred platform-specific fix.
- When the exact Section 4 finding and confirmed action are populated, replace the placeholders in this document and increment the version.