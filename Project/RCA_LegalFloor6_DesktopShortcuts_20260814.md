# Root Cause Analysis (RCA) - Legal Floor 6 Missing Desktop Shortcuts Incident

## Document Control
- Date: 2026-08-14
- Incident: Missing desktop shortcuts for Legal Floor 6 users
- Scope baseline (from triage artifacts): Floor 6 user-impact report within broader Monday incident context
- RCA status: Closed at service-restoration level; technical-mechanism confirmation partially pending

## 1) Executive Summary
A desktop usability incident was reported on Legal Floor 6: one or more users reported missing desktop shortcuts. Triage classified this as a medium-priority productivity issue and separated it from higher-priority login/confidentiality tracks. Hypothesis and remediation materials centered on potential Friday deployment side effects (post-install/script/policy/profile-redirection behavior).

Confirmed restoration statement provided:
- The suggested resolution for the missing desktop shortcuts issue on Legal Floor 6 was applied.
- The issue is resolved as of [confirmed time] (to confirm exact timestamp value).
- Verified [confirmed verification detail] (to confirm exact verification evidence text).

## 2) Confirmed Facts and Evidence Register
Only evidence confirmed in triage, hypothesis/evidence package, remediation notes, and your closure statement is treated as confirmed. Unknowns are marked to confirm.

| ID | Fact / Evidence Item | Status | Source |
|---|---|---|---|
| E1 | A user reported desktop shortcuts disappeared on Floor 6. | Confirmed | Project/TriageSummary_Issue3_DesktopShortcutsMissing_PostRollout_20260814.md |
| E2 | Incident urgency classified as Medium (P3), lower than login/confidentiality issues. | Confirmed | Project/TriageSummary_Issue3_DesktopShortcutsMissing_PostRollout_20260814.md |
| E3 | Friday rollout package behavior was identified as a key investigation path for shortcut changes. | Confirmed | Project/TriageSummary_Issue3_DesktopShortcutsMissing_PostRollout_20260814.md |
| E4 | Evidence package explicitly includes desktop path verification, shortcut inventory, and redirection indicators as required causal checks. | Confirmed | Project/RankedCauseAnalysis_DesktopShortcuts_LegalFloor6_20260814.md |
| E5 | Remediation plan defined actions to inspect/adjust deployment script behavior and restore shortcuts via GPO/script. | Confirmed (as remediation plan) | Project/Floor6_Remediation_DesktopShortcuts_TechnicalAction_FloorMessage_20260814.md |
| E6 | Suggested resolution was applied and issue resolved. | Confirmed | User closure statement (this request) |
| E7 | Exact restoration timestamp. | To confirm | User closure statement placeholder: [confirmed time] |
| E8 | Exact post-fix verification evidence text. | To confirm | User closure statement placeholder: [confirmed verification detail] |
| E9 | Definitive log-level proof of specific shortcut deletion/overwrite command in deployment script execution on affected devices. | To confirm | Remediation notes identify this as pending confirmation |
| E10 | Device-level before/after artifact set (shortcut lists, desktop timestamps, redirection state) linked to final closure record. | To confirm | Evidence package defines artifacts; closure linkage not included in reviewed text |

## 3) Incident Timeline (Fact-Based)
Timeline includes only evidence-supported sequence markers. Unknown timestamp values are retained as to confirm.

| Time | Event | Evidence Type | Confidence |
|---|---|---|---|
| Friday (deployment window; exact time to confirm) | Document-management rollout context existed and was investigated as potential trigger for endpoint symptoms including shortcuts. | Triage + evidence package context | High |
| Monday morning | Desktop shortcut issue reported on Floor 6. | Triage report | High |
| Monday triage window | Initial checks prioritized deletion vs hidden/redirected paths, rollout script behavior, profile/shell health, and cross-user pattern consistency. | Triage report | High |
| During response (timestamp to confirm) | Suggested remediation path selected and executed (deployment/script correction and shortcut restoration path). | Remediation plan + user closure statement | Medium for action class; exact execution record to confirm |
| [confirmed time] | Resolution confirmed after suggested remediation was applied. | Closure statement | High for restoration; timestamp value to confirm |
| [confirmed time] | Verification result recorded: [confirmed verification detail]. | Closure statement | High for restoration outcome; exact verification detail text to confirm |

## 4) Root Cause Statement
### 4.1 Service-Restoration Root Cause (Confirmed)
The incident was operationally linked to the deployment/remediation path for desktop shortcuts because the suggested corrective action was applied and restoration was confirmed.

### 4.2 Technical-Mechanism Root Cause (Partially Confirmed)
The leading mechanism documented in response materials is an unintended deployment-side shortcut modification effect (post-install/script/policy/profile path interaction). Definitive mechanism proof (specific command/task/process plus execution log evidence on affected endpoints) remains to confirm in currently reviewed artifacts.

## 5) 5-Why Analysis (Evidence-Constrained)
This 5-Why is intentionally limited to confirmed facts and explicitly labels pending evidence.

1. Why were desktop shortcuts missing for Legal Floor 6 users?
- Because endpoint desktop state changed for affected users, resulting in missing visible shortcuts.
- Evidence: user-reported symptom in triage.

2. Why did endpoint desktop state change?
- Most likely due to a rollout-related shortcut/path/profile side effect introduced around the Friday deployment context.
- Evidence: triage investigation priority and remediation focus; restoration after suggested remediation.
- To confirm: exact script/process/action that altered shortcut state.

3. Why could rollout activity affect desktop shortcuts?
- Because deployment scripts, policy/application behavior, or profile/redirection changes can create/delete/move shortcut artifacts.
- Evidence: investigation/remediation framework explicitly targets these mechanisms.
- To confirm: which exact mechanism occurred in this incident.

4. Why was user impact not prevented before broad visibility?
- Pre-change controls for desktop artifact integrity were not evidenced as complete in reviewed materials.
- To confirm: pre-deployment validation scope, post-install script peer review results, and canary acceptance criteria.

5. Why was detection initiated by user report?
- Available artifacts indicate issue discovery started from user/service-desk reporting.
- To confirm: whether proactive endpoint telemetry existed for shortcut/path drift and whether alerts were configured.

## 6) Corrective Actions Taken (Containment and Recovery)
| Action | Status | Evidence |
|---|---|---|
| Isolate incident as separate desktop-usability track from login/confidentiality tracks | Completed | Triage classification and routing |
| Execute suggested remediation path for deployment/shortcut restoration | Completed | User closure statement confirms application |
| Confirm restoration of desktop shortcut functionality | Completed | User closure statement confirms resolved |
| Record exact restoration time and concrete verification evidence in closure artifact | To confirm | Placeholder values currently provided |

## 7) Preventive Actions (CAPA)
Preventive actions below are recommended controls derived from confirmed investigation themes; implementation evidence is to confirm unless separately documented.

| Preventive Action | Owner | Due | Status |
|---|---|---|---|
| Require static review checklist for deployment scripts that touch user profile paths (Desktop/Start Menu/Documents) | EUC Packaging / Endpoint Engineering | To confirm | To confirm |
| Enforce canary rollout for any package with post-install actions affecting shell/profile artifacts | Change Management + Endpoint Engineering | To confirm | To confirm |
| Add automated post-deployment desktop integrity checks (expected shortcut baseline + path redirection validation) | Endpoint Operations | To confirm | To confirm |
| Add rollback trigger criteria for shortcut-impact incidents (threshold-based, time-boxed) in change records | Change Management | To confirm | To confirm |
| Improve endpoint observability for profile/redirection anomalies and sudden shortcut count drops | Endpoint Observability | To confirm | To confirm |
| Archive before/after evidence package per affected cohort in incident closure template | Incident Management | To confirm | To confirm |

## 8) Residual Risks and Open Items
- Exact restoration timestamp: to confirm.
- Exact verification evidence language and artifact links: to confirm.
- Definitive script/process-level causality proof (deletion/overwrite/move mechanism): to confirm.
- Device-level before/after artifact set attached to final closure package: to confirm.

## 9) Closure Criteria
This RCA becomes fully evidence-complete when all to confirm items are populated with traceable records: restoration timestamp, verification details, endpoint artifact comparisons, and mechanism-level execution evidence.

## Appendix A - Source Artifacts Reviewed
- Project/TriageSummary_Issue3_DesktopShortcutsMissing_PostRollout_20260814.md
- Project/RankedCauseAnalysis_DesktopShortcuts_LegalFloor6_20260814.md
- Project/Floor6_Remediation_DesktopShortcuts_TechnicalAction_FloorMessage_20260814.md
- User-provided closure statement in this request
