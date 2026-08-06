# Root Cause Analysis — Account Lockout
## Incident Reference: INC-2026-0806-JSMITH

| Field              | Detail                                      |
|--------------------|---------------------------------------------|
| **Date**           | 2026-08-06                                  |
| **Time Window**    | 08:02 – 08:23 (UTC)                         |
| **Affected User**  | jsmith (FINBRIDGE domain)                   |
| **Affected Host**  | DESKTOP-FB001                               |
| **Severity**       | Medium — single user, resolved within 22 min |
| **Analyst**        | DWP Security Operations                     |
| **Status**         | Closed                                      |

---

## 1. Incident Summary

User account `jsmith` was locked out of workstation `DESKTOP-FB001` at 08:06:01 after two consecutive failed interactive logon attempts. The account remained locked for approximately 16 minutes until unlocked by `FINBRIDGE\helpdesk-admin` at 08:22:10. The user successfully authenticated at 08:23:44.

---

## 2. Event Log Evidence

| Timestamp  | Event ID | Type          | Detail                                                               |
|------------|----------|---------------|----------------------------------------------------------------------|
| 08:02:14   | 4625     | Audit Failure | Failed logon — jsmith @ DESKTOP-FB001. Reason: Unknown user or bad password. Logon type: 2 (Interactive) |
| 08:04:22   | 4625     | Audit Failure | Failed logon — jsmith @ DESKTOP-FB001. Reason: Unknown user or bad password. Logon type: 2 (Interactive) |
| 08:06:01   | 4740     | Audit Failure | Account locked out — jsmith. Caller: DESKTOP-FB001                  |
| 08:07:45   | 4625     | Audit Failure | Failed unlock attempt — jsmith. Reason: Account locked out. Logon type: 7 (Unlock) |
| 08:22:10   | 4722     | Audit Success | Account enabled — jsmith. Action by: FINBRIDGE\helpdesk-admin       |
| 08:23:44   | 4624     | Audit Success | Successful logon — jsmith. Logon type: 2 (Interactive)              |

---

## 3. Event ID Reference

| Event ID | Description |
|----------|-------------|
| **4625** | Windows Security records this whenever an account logon attempt fails. The event captures the target account, failure reason, source workstation, and logon type (2 = interactive console; 7 = screen-lock unlock attempt). |
| **4740** | Raised when an account is locked out after exceeding the domain bad-password threshold. Records the locked account and the machine from which the final bad attempt originated. |
| **4722** | Raised when a user account is enabled or unlocked. Captures both the target account and the administrative account responsible for the action. |
| **4624** | Records a successful logon, including account name, logon type, and source. Confirms the user regained access after the administrative unlock. |

---

## 4. Sequence of Events (Narrative)

1. At **08:02:14**, `jsmith` sat down at `DESKTOP-FB001` and attempted an interactive Windows logon. The credentials supplied were rejected — either the password was incorrect or the username was mistyped.
2. At **08:04:22**, a second interactive logon attempt was made with the same or a different set of incorrect credentials.
3. At **08:06:01**, the domain lockout policy threshold was reached (evidenced by exactly 2 prior 4625 events, indicating a lockout threshold of 2 bad attempts). The Active Directory account was automatically locked by the domain controller.
4. At **08:07:45**, `jsmith` attempted to unlock the workstation screen (Logon type 7), unaware or having forgotten the account was now domain-locked. This attempt failed immediately with reason "Account locked out".
5. Between **08:08 and 08:22**, `jsmith` contacted the helpdesk (via phone, Teams, or ticket — not captured in log). The 16-minute gap represents the support resolution time.
6. At **08:22:10**, `FINBRIDGE\helpdesk-admin` unlocked the account via Active Directory (Event 4722).
7. At **08:23:44**, `jsmith` successfully logged in interactively at `DESKTOP-FB001`.

---

## 5. Root Cause Analysis — 5 Whys

### Problem Statement
> User `jsmith` was locked out of their domain account, causing a 22-minute productivity loss and requiring helpdesk intervention.

---

### Why 1 — Why was the account locked out?

**Because the domain account lockout policy triggered after two failed logon attempts.**

The Active Directory Group Policy is configured with a low lockout threshold (2 bad attempts before lockout). Event 4740 at 08:06:01 confirms this was an automated domain response to repeated bad-password events, not a manual administrative action.

---

### Why 2 — Why did two failed logon attempts occur?

**Because `jsmith` entered an incorrect password on both attempts at the interactive logon screen.**

Both 4625 events originate from `DESKTOP-FB001` with Logon type 2 (physical console) and the failure reason "Unknown username or bad password". There is no network source IP or remote logon type, ruling out automated processes, cached service credentials, or a remote attacker. The pattern is consistent with a user who did not know or could not recall the current password.

---

### Why 3 — Why did `jsmith` not know the correct password?

**Most likely because the account password had recently been changed and the new password was not retained, or Caps Lock was engaged.**

Common causes at this stage include:
- A mandatory password reset performed the previous day or week (the 16-minute resolution window and a single helpdesk admin action suggest this is routine, not exceptional).
- Keyboard input error (Caps Lock, language layout).
- A shared workstation where another user had previously changed cached state.

No 4723 (password change attempt) or 4724 (admin password reset) events appear in the provided log window, but this window starts at 08:02 — a reset the previous day would not appear here.

---

### Why 4 — Why was the lockout threshold set to only 2 attempts?

**Because the current Group Policy lockout threshold is configured at 2 bad attempts, which is more restrictive than the commonly recommended baseline of 5–10 attempts.**

A threshold of 2 provides little tolerance for a genuine user making a typo and results in frequent legitimate lockouts, increasing helpdesk load. Microsoft's Security Baseline recommends a minimum threshold of 10 invalid attempts to balance security with usability.

---

### Why 5 — Why has the lockout policy not been reviewed against user experience impact?

**Because there is no documented review cycle for the account lockout Group Policy configuration, and its impact on helpdesk ticket volume has not been measured or reported.**

Without periodic policy review and a feedback loop from helpdesk ticket data, the lockout threshold remains at a historically set value that may have been appropriate for a different threat model or user population.

---

## 6. Most Likely Root Cause

**The user `jsmith` entered an incorrect password at the Windows logon screen on two consecutive attempts, triggering an automated domain account lockout enforced by a restrictive Group Policy threshold of 2 bad attempts.**

There is no evidence of malicious activity: all events originate from a single workstation (`DESKTOP-FB001`), use interactive logon types (2 and 7), occur within a 4-minute window typical of a user sitting at a desk, and were resolved with a standard helpdesk unlock — consistent with a forgotten or mistyped password.

---

## 7. Contributing Factors

| Factor | Detail |
|--------|--------|
| Low lockout threshold | Threshold of 2 provides no tolerance for legitimate user error |
| No self-service unlock | User had no mechanism to unlock their own account, requiring helpdesk involvement |
| No lockout observation period | It is not known whether a 30-minute observation window was configured; if not, repeated lockouts will accumulate |
| Possible recent password change | No 4723/4724 events in scope, but cannot be ruled out without wider log review |

---

## 8. Recommendations

| Priority | Recommendation | Owner |
|----------|----------------|-------|
| High | Review and increase the domain account lockout threshold to 10 attempts per Microsoft Security Baseline guidance | IAM / Active Directory Team |
| High | Implement a self-service password reset (SSPR) solution (e.g., Azure AD SSPR or on-prem equivalent) to reduce helpdesk dependency | IAM / Service Desk Manager |
| Medium | Set a lockout observation window (reset counter after N minutes) to reduce false lockouts from isolated typos | Active Directory Team |
| Medium | Pull monthly helpdesk ticket data for account lockout events and report to IT management to quantify policy impact | Service Desk Manager |
| Low | Provide `jsmith` with guidance on password management best practices | Line Manager / IT Training |

---

## 9. Lessons Learned

- A lockout threshold of 2 is excessively restrictive for a standard user workstation and causes unnecessary service disruption.
- Interactive logon failures (Logon type 2/7) from a single workstation with no network source are reliably distinguishable from brute-force or credential-stuffing attacks, which typically show Logon type 3 (network) from multiple sources.
- The 16-minute helpdesk resolution time is reasonable but avoidable; SSPR would reduce this to under 2 minutes for the user.

---

## 10. Closure

| Field      | Detail |
|------------|--------|
| Resolved by | FINBRIDGE\helpdesk-admin |
| Resolution | Account unlocked via Active Directory at 08:22:10 |
| Recurrence risk | Medium — will repeat unless lockout threshold is raised or SSPR is deployed |
| Follow-up actions | IAM team to review GPO lockout threshold (target: within 5 business days) |

---

*Document prepared by DWP Security Operations — 2026-08-06*
