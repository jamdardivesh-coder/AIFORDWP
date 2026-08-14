# Root Cause Analysis (RCA) - Legal Floor 6 Login/Performance Incident

## Document Control
- Date: 2026-08-14
- Incident: Legal Floor 6 widespread login failures / very slow logon
- Scope baseline (from triage): Legal Floor 6, Win11/Intune migrated cohort, Friday app deployment context
- RCA status: Closed at service-restoration level; technical-mechanism confirmation partially pending

## 1) Executive Summary
A floor-wide login/performance incident affected Legal Floor 6 users on Monday morning, with reports of failed logins and severe logon delay. During triage and hypothesis ranking, the leading suspected cause was a Friday Document Manager deployment side effect at logon/startup. The suggested remediation (retire/remove Floor 6-targeted deployment assignment) was applied, and service was reported restored.

Confirmed restoration statement provided:
- The suggested resolution for the Legal Floor 6 login/performance issue was applied.
- The issue is resolved as of [confirmed time] (to confirm exact timestamp value).
- Verified [confirmed verification detail] (to confirm exact verification evidence text).

## 2) Confirmed Facts and Evidence Register
Only facts confirmed in triage, hypothesis, remediation, and your closure input are listed as confirmed. Unverified technical specifics are marked to confirm.

| ID | Fact / Evidence Item | Status | Source |
|---|---|---|---|
| E1 | At least a dozen Floor 6 users reported inability to log in or very slow logon on Monday morning. | Confirmed | Project/TriageSummary_Issue2_Floor6_LoginFailuresAndSlowLogon_20260814.md |
| E2 | Incident was treated as high urgency with multi-user productivity impact. | Confirmed | Project/TriageSummary_Issue2_Floor6_LoginFailuresAndSlowLogon_20260814.md |
| E3 | A Friday afternoon document-management rollout was in scope as a likely contributing change. | Confirmed | Project/TriageSummary_Issue2_Floor6_LoginFailuresAndSlowLogon_20260814.md; Project/IncidentCommander_ExecutiveAnalysis_Floor6_MultiIncident_20260814.md |
| E4 | Ranked cause analysis placed app logon/startup hook failure as highest-likelihood cause, ahead of policy conflict and network/auth causes. | Confirmed (as ranked hypothesis) | Project/RankedCauseAnalysis_LegalFloor6Login_20260814.md |
| E5 | Remediation runbook specified retirement/removal of Floor 6-targeted Document Manager deployment assignment (SCCM/Intune path). | Confirmed | Project/Floor6_Remediation_TechnicalAction_FloorMessage_20260814.md |
| E6 | Suggested resolution was applied and issue resolved. | Confirmed | User closure statement (this request) |
| E7 | Exact restoration timestamp. | To confirm | User closure statement placeholder: [confirmed time] |
| E8 | Exact post-fix verification evidence text. | To confirm | User closure statement placeholder: [confirmed verification detail] |
| E9 | Event-log proof of specific failing executable/script during logon phase. | To confirm | Remediation notes explicitly list as pending confirmation |
| E10 | Definitive elimination evidence for alternate causes (policy conflict, network/auth path) via test artifacts. | To confirm | Ranked cause analysis defined checks; no attached outputs in reviewed artifacts |

## 3) Incident Timeline (Fact-Based)
Times are included only when present in source artifacts or your closure statement.

| Time | Event | Evidence Type | Confidence |
|---|---|---|---|
| Friday afternoon (exact time to confirm) | New document-management application rollout to Floor 6 occurred. | Change context documented in incident artifacts | High |
| Monday morning | Broad Floor 6 login impact reported; at least a dozen users affected by login failure/very slow logon. | Triage report | High |
| Monday morning triage window | Investigation focused on three causal tracks: app logon/startup hook, Win11/Intune policy conflict, floor-specific network/auth path. | Ranked cause analysis | High |
| During response (timestamp to confirm) | Suggested remediation path selected: remove/retire Floor 6 deployment assignment and stop pending installs. | Remediation runbook / action plan | Medium |
| [confirmed time] | Resolution confirmed after remediation applied. | Closure statement | High for restoration; timestamp value to confirm |
| [confirmed time] | Verification result recorded: [confirmed verification detail]. | Closure statement | High for restoration outcome; verification detail text to confirm |

## 4) Root Cause Statement
### 4.1 Service-Restoration Root Cause (Confirmed)
The incident was operationally linked to the Floor 6 document-management deployment path because the recommended deployment-removal remediation was applied and the service was confirmed restored.

### 4.2 Technical-Mechanism Root Cause (Partially Confirmed)
The most likely mechanism documented during analysis is a logon/startup process contention or failure introduced by the Friday deployment. Definitive mechanism proof (specific failing script/service/process and event IDs) remains to confirm in currently reviewed artifacts.

## 5) 5-Why Analysis (Evidence-Constrained)
This 5-Why is intentionally bounded to confirmed facts and clearly labeled unknowns.

1. Why did users on Legal Floor 6 experience login failures/slow logon?
- Because login/startup processing on affected Floor 6 endpoints became unstable or delayed during Monday morning usage.
- Evidence: multi-user floor-specific symptom reports in triage.

2. Why did login/startup processing become unstable or delayed?
- Most likely because a Friday floor-targeted document-management deployment introduced a startup/logon dependency conflict.
- Evidence: strongest-ranked hypothesis plus successful restoration after deployment-removal remediation.
- To confirm: exact failing component and failure mode in event logs.

3. Why could a deployment affect login/startup path this broadly?
- Because the deployment was scoped to the Floor 6 cohort and login/startup integrations can execute during authentication or shell initialization.
- Evidence: scope and hypothesis documentation.
- To confirm: whether all affected devices had identical package/config revision and startup hook enabled.

4. Why was this not prevented before user impact?
- Pre-deployment guardrails for login-path safety were insufficiently evidenced in reviewed artifacts.
- To confirm: documented canary/ring validation results, pre-prod login performance test results, and rollback rehearsal records.

5. Why did incident detection rely on user reports instead of preemptive telemetry?
- Current artifacts show incident detection beginning with user/service-desk reports.
- To confirm: whether proactive telemetry alerts existed but did not trigger, or were not configured for this failure pattern.

## 6) Corrective Actions Taken (Containment and Recovery)
| Action | Status | Evidence |
|---|---|---|
| Identify likely triggering deployment in Floor 6 collection context | Completed | Triage + ranked analysis + remediation runbook |
| Apply suggested remediation by removing/retiring Floor 6-targeted deployment assignment | Completed | User closure statement confirms application |
| Confirm service restoration for affected users | Completed | User closure statement confirms resolved |
| Capture exact restoration timestamp and verification details in final closure record | To confirm | Placeholder values provided in closure statement |

## 7) Preventive Actions (CAPA)
Actions are listed as preventive controls; implementation evidence is to confirm unless already documented elsewhere.

| Preventive Action | Owner | Due | Status |
|---|---|---|---|
| Enforce phased rollout gates (pilot/canary before floor-wide assignment) for login-path-impacting packages | Endpoint Engineering / App Deployment | To confirm | To confirm |
| Add explicit pre-release login performance and startup timing regression test for Win11/Intune cohort | Endpoint Engineering QA | To confirm | To confirm |
| Require change record to include rollback trigger criteria and rollback SLA | Change Management | To confirm | To confirm |
| Add monitoring/alerting for abnormal login duration and floor-scoped login failure spikes | Identity + Endpoint Observability | To confirm | To confirm |
| Add post-deployment 24-hour and next-business-day health checkpoints for cohort-targeted app changes | Endpoint Operations | To confirm | To confirm |
| Maintain evidence checklist (event logs, deployment IDs, affected device list, before/after metrics) for RCA closure quality | Incident Management | To confirm | To confirm |

## 8) Residual Risks and Open Items
- Exact restoration timestamp: to confirm.
- Exact verification statement and evidence artifact references: to confirm.
- Definitive failing component/event ID during logon path: to confirm.
- Formal proof of alternate-cause elimination (policy/network tracks): to confirm.

## 9) Closure Criteria
This RCA can be considered fully evidence-complete when all to confirm items are populated with traceable artifacts (timestamps, verification records, event IDs, and elimination evidence for alternate causes).

## Appendix A - Source Artifacts Reviewed
- Project/TriageSummary_Issue2_Floor6_LoginFailuresAndSlowLogon_20260814.md
- Project/RankedCauseAnalysis_LegalFloor6Login_20260814.md
- Project/Floor6_Remediation_TechnicalAction_FloorMessage_20260814.md
- Project/IncidentCommander_ExecutiveAnalysis_Floor6_MultiIncident_20260814.md
- User-provided closure statement in this request
