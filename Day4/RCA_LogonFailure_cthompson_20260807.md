# Root Cause Analysis — User Logon Failure (Account Lockout)
## Incident Reference: INC-2024-0315-CTHOMPSON-LOGON

| Field | Detail |
|-------|--------|
| Date of Incident | 2024-03-15 |
| Incident Window | 08:44 - 09:09 |
| Affected User | FINBRIDGE\cthompson |
| Affected Host | DESKTOP-FB022 |
| Severity | Medium (single-user service impact) |
| Reported Symptom | User unable to log in |
| Resolved Time | 09:09 |
| Resolution Owner | FINBRIDGE\helpdesk-admin |
| Status | Closed - Resolved and Verified |

---

## 1. Executive Summary

User FINBRIDGE\cthompson was unable to log in due to account lockout triggered by repeated wrong-password submissions. Security logs show a clear sequence: bad credential attempts from DESKTOP-FB022, automatic lockout, then continued Kerberos pre-authentication failures from a second source IP (10.10.8.112), indicating stale credentials persisted in at least one additional source.

The account was administratively restored (Event 4722 at 09:08:14), followed by successful interactive logon from DESKTOP-FB022 (Event 4624 at 09:09:01). User access was verified as restored and stable, with no further issue reported.

---

## 2. Scope and Constraints Used in Analysis

- Symptom: cthompson unable to log in
- Scope: single user only (no wider user impact identified)
- Start time: approximately 08:40
- Known planned change: none

---

## 3. Supporting Evidence (Security Event Logs)

### 3.1 Incident and Failure Evidence

| Timestamp | Event ID | Result | Key Detail |
|-----------|----------|--------|------------|
| 08:44:01 | 4776 | Audit Failure | Domain credential validation failed, Error 0xC000006A (wrong password), source workstation DESKTOP-FB022 |
| 08:44:03 | 4625 | Audit Failure | Interactive logon failed (type 2), reason bad username/password, source DESKTOP-FB022 |
| 08:44:28 | 4625 | Audit Failure | Interactive logon failed (type 2), reason bad username/password, source DESKTOP-FB022 |
| 08:44:55 | 4625 | Audit Failure | Interactive logon failed (type 2), reason bad username/password, source DESKTOP-FB022 |
| 08:44:56 | 4740 | Audit Failure | Account FINBRIDGE\cthompson locked out; caller computer DESKTOP-FB022 |
| 08:45:10 | 4625 | Audit Failure | Unlock attempt failed (type 7), reason account locked out, source DESKTOP-FB022 |
| 08:45:44 | 4771 | Audit Failure | Kerberos pre-auth failed, code 0x18 (wrong password), source IP 10.10.8.112 |
| 08:46:01 | 4771 | Audit Failure | Kerberos pre-auth failed, code 0x18 (wrong password), source IP 10.10.8.112 |
| 08:46:33 | 4771 | Audit Failure | Kerberos pre-auth failed, code 0x18 (wrong password), source IP 10.10.8.112 |

### 3.2 Recovery and Verification Evidence

| Timestamp | Event ID | Result | Key Detail |
|-----------|----------|--------|------------|
| 09:08:14 | 4722 | Audit Success | Account FINBRIDGE\cthompson enabled by FINBRIDGE\helpdesk-admin |
| 09:09:01 | 4624 | Audit Success | Successful interactive logon (type 2) for FINBRIDGE\cthompson from DESKTOP-FB022 |

### 3.3 Evidence Interpretation

- The causal sequence is explicit: wrong password attempts -> lockout -> continued bad credential attempts.
- Event 4771 failures from 10.10.8.112 after lockout indicate another source continued submitting stale/incorrect credentials.
- Successful 4624 at 09:09 confirms identity/authentication path recovery.

---

## 4. Incident Timeline (End-to-End)

| Time | Event | Interpretation |
|------|-------|----------------|
| ~08:40 | User reports inability to log in | Incident symptom begins |
| 08:44:01 | 4776 wrong password from DESKTOP-FB022 | Initial authentication failure confirmed |
| 08:44:03 -> 08:44:55 | Multiple 4625 interactive failures | Repeated bad credential attempts continue |
| 08:44:56 | 4740 account lockout | Domain lockout threshold reached |
| 08:45:10 | 4625 unlock failure (type 7) | User cannot proceed due to lockout state |
| 08:45:44 -> 08:46:33 | 4771 wrong password from 10.10.8.112 | Secondary stale credential source persists |
| 09:08:14 | 4722 account enabled by helpdesk-admin | Administrative recovery action applied |
| 09:09:01 | 4624 successful interactive logon | User access restored |
| 09:09 | User verified login and no further issues | Incident resolved and confirmed |

---

## 5. Root Cause Statement

Primary root cause:
Repeated wrong-password submissions for FINBRIDGE\cthompson triggered an automated domain account lockout.

Contributing cause:
A secondary source (IP 10.10.8.112) continued to submit incorrect credentials after the lockout event, increasing lockout persistence risk.

Non-causes ruled out by evidence:
- Account restriction as initial failure cause (disabled/expired/logon-hours/workstation) was not indicated before lockout.
- Conditional Access/MFA failure was not evidenced in provided logs.
- User profile load failure post-authentication was not evidenced; failures occurred at authentication stage.

---

## 6. 5-Why Analysis

Problem:
FINBRIDGE\cthompson could not log in during business hours.

Why 1:
Why could the user not log in?
Because the account entered a locked-out state.
Evidence: Event 4740 at 08:44:56.

Why 2:
Why did the account become locked?
Because repeated authentication attempts used wrong credentials.
Evidence: Event 4776 (0xC000006A) at 08:44:01 and Event 4625 failures at 08:44:03, 08:44:28, 08:44:55.

Why 3:
Why were wrong credentials repeatedly used?
Because at least one local interactive session and one additional source submitted incorrect/stale credentials.
Evidence: DESKTOP-FB022 failures and separate Event 4771 failures from 10.10.8.112 at 08:45:44, 08:46:01, 08:46:33.

Why 4:
Why did the issue persist after initial lockout?
Because credential sources were not immediately cleaned, allowing continued bad pre-auth attempts.
Evidence: Continued 4771 wrong-password events after lockout timestamp.

Why 5:
Why is recurrence possible?
Because credential hygiene and early lockout-source identification controls are not consistently automated.
Evidence: Manual investigation and administrative re-enable were required before successful login resumed.

Systemic improvement point:
Implement earlier detection and faster stale-credential source isolation to prevent prolonged single-user lockout incidents.

---

## 7. Resolution Actions Applied

1. Lockout condition investigated via Security Event IDs 4776, 4625, 4740, 4771.
2. Stale credential behavior from secondary source identified (10.10.8.112).
3. Account re-enabled/unlocked by FINBRIDGE\helpdesk-admin (Event 4722 at 09:08:14).
4. User re-authenticated successfully from DESKTOP-FB022 (Event 4624 at 09:09:01).
5. User confirmed normal login and no post-resolution issue.

---

## 8. Preventive Actions

### Immediate (0-5 business days)

1. Identify and remediate credential source mapped to 10.10.8.112 (stored credentials, service account usage, scheduled task, or client cache).
2. Run a targeted stale-credential cleanup checklist on user endpoints after lockout incidents.
3. Add service-desk runbook step to verify secondary source IP on Event 4771 before account unlock closure.

### Short-Term (1-4 weeks)

1. Implement alert correlation for 4776/4625/4740/4771 sequence per user to accelerate triage.
2. Standardize post-unlock validation window (for example 30 minutes) to confirm no recurring bad attempts.
3. Expand analyst playbook to include rapid IP-to-asset attribution via DHCP/IPAM/EDR.

### Strategic (1-3 months)

1. Improve credential lifecycle hygiene: reduce use of user credentials in scheduled tasks/services.
2. Increase user awareness for password updates across all enrolled devices and apps.
3. Review lockout policy tuning and user self-service recovery capability in line with security policy.

---

## 9. Verification and Closure

Closure evidence:
- Event 4722 at 09:08:14 confirms account re-enabled by authorized admin.
- Event 4624 at 09:09:01 confirms successful interactive logon.
- User verification at 09:09 confirms restored access with no active issue.

Final status:
Resolved at 09:09 with successful user login verification and no immediate recurrence observed.

---

Document prepared by DWP Engineering
Date prepared: 2026-08-07
