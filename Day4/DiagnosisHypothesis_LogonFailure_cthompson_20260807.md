# Logon Incident Analysis & Hypothesis
## Incident: User cthompson unable to log in
## Date: 2026-08-07

## Scope Facts Used
- Symptom: user cthompson not able to login
- Who: cthompson only (single-user impact)
- Since: approximately 08:40 this morning
- Change: nil (no known intentional change)

## Ranked Likely Causes (Most Probable First)

### 1. Account lockout caused by stale credentials repeatedly submitted
Why this fits scope facts:
- Single-user impact strongly points to a user-specific identity state rather than platform-wide outage.
- Sudden onset at a specific time (~08:40) is consistent with lockout threshold being hit by repeated bad attempts.
- "No change" supports an unplanned trigger such as cached credentials in mobile mail, mapped drive, old service/task, or secondary device.

Fastest single check:
- In AD/Azure sign-in logs, confirm whether lockout or repeated bad-password events started around 08:40 for cthompson.

### 2. Password state mismatch (recent password change/expiry not propagated to all clients)
Why this fits scope facts:
- Affects only one user, which aligns with per-account password state issues.
- Time-bound failure can start when one endpoint/app keeps using an old password while user uses a new one elsewhere.
- "No change" in environment can still coexist with user-side credential drift.

Fastest single check:
- Check the account password metadata and sign-in failure reason (expired password, invalid credentials, or stale token) in identity logs.

### 3. Account restriction applied to cthompson (disabled, expired account, logon-hours/workstation restriction)
Why this fits scope facts:
- Restriction-based failures are naturally single-user scoped.
- Sudden start time fits a policy boundary (for example, logon hours beginning/ending) or an account state toggle.
- No broad change needed for this to happen.

Fastest single check:
- Open the account properties and verify enabled/disabled state, account expiry, logon hours, and allowed workstations.

### 4. Conditional Access/MFA challenge failure specific to this user session
Why this fits scope facts:
- Can affect one user only if CA/MFA state, authenticator registration, or risk posture is unique to that identity/session.
- Often appears as "cannot log in" from user perspective even when primary password is correct.
- No infrastructure change required.

Fastest single check:
- Review the most recent sign-in event decision details for cthompson (CA result, MFA required/satisfied/failed, device compliance condition).

### 5. User profile initialization failure on target host/session (post-auth perceived as login failure)
Why this fits scope facts:
- Single-user failures can result from profile corruption or profile path/load problems while other users authenticate normally.
- Sudden onset without planned change is possible if profile files became locked/corrupted.
- Fits only if authentication succeeded but session did not complete.

Fastest single check:
- Check host event logs for cthompson around 08:40 for profile service errors (for example, User Profile Service events) confirming auth success but profile load failure.

## Working Hypothesis (No Final Commitment)
Based on current scope facts alone, identity-state issues specific to cthompson are more likely than platform or tenant-wide faults. The top hypothesis is account lockout from repeated stale credential attempts, but this is not confirmed yet and must be validated by the first log check.

## Initial Validation Order
1. Identity sign-in and lockout/bad-password events around 08:40.
2. Password/account state metadata.
3. CA/MFA decision trace.
4. Host-side profile load events (only if auth appears successful).

## Event Evidence Assessment (Incident Window 2024-03-15 08:44-09:12)

### Source
- Security Event Log: DESKTOP-FB022

### Key Observed Events
- 08:44:01 - Event 4776 (Audit Failure): credential validation failed, error 0xC000006A (wrong password), account FINBRIDGE\cthompson, source workstation DESKTOP-FB022.
- 08:44:03 - Event 4625 (Audit Failure): bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:28 - Event 4625 (Audit Failure): bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:55 - Event 4625 (Audit Failure): bad password, logon type 2 (interactive), source DESKTOP-FB022.
- 08:44:56 - Event 4740 (Audit Failure): account FINBRIDGE\cthompson locked out, caller computer DESKTOP-FB022.
- 08:45:10 - Event 4625 (Audit Failure): failure reason account locked out, logon type 7 (unlock attempt), source DESKTOP-FB022.
- 08:45:44 - Event 4771 (Audit Failure): Kerberos pre-auth failed, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:01 - Event 4771 (Audit Failure): Kerberos pre-auth failed, failure code 0x18 (wrong password), source IP 10.10.8.112.
- 08:46:33 - Event 4771 (Audit Failure): Kerberos pre-auth failed, failure code 0x18 (wrong password), source IP 10.10.8.112.

### Hypothesis-by-Hypothesis Judgement

1. Account lockout caused by stale credentials repeatedly submitted
- Judgement: Supports.
- Determining evidence: Event 4776 at 08:44:01 (wrong password), Event 4625 at 08:44:03/08:44:28/08:44:55 (bad password), Event 4740 at 08:44:56 (account locked out), continued wrong-password attempts via Event 4771 at 08:45:44/08:46:01/08:46:33 from 10.10.8.112.

2. Password state mismatch (recent password change/expiry not propagated to all clients)
- Judgement: Supports.
- Determining evidence: Wrong-password events from DESKTOP-FB022 (Event 4776 at 08:44:01) and a second source IP 10.10.8.112 (Event 4771 at 08:45:44/08:46:01/08:46:33), consistent with multiple clients/processes using different credential state.

3. Account restriction applied to cthompson (disabled, expired account, logon-hours/workstation restriction)
- Judgement: Contradicts.
- Determining evidence: Initial failures are explicitly wrong-password (Event 4776 at 08:44:01, Event 4625 at 08:44:03/08:44:28/08:44:55). "Account locked out" appears later at 08:45:10 (Event 4625) after lockout occurred at 08:44:56 (Event 4740), indicating consequence rather than initial restriction cause.

4. Conditional Access/MFA challenge failure specific to this user session
- Judgement: Contradicts.
- Determining evidence: Failures are AD/Kerberos wrong-credential events (Event 4776 and Event 4771 with wrong-password codes) rather than CA/MFA policy decision failures.

5. User profile initialization failure on target host/session (post-auth perceived as login failure)
- Judgement: Contradicts.
- Determining evidence: Provided events show authentication failure path (Event 4776/4625/4771) and lockout (Event 4740), with no evidence of successful authentication preceding profile load failure in this window.

## Surviving Hypothesis After Evidence Elimination

Account lockout caused by repeated bad credentials from stale credential source(s).

Rationale:
- The observed sequence is coherent and causal: wrong-password attempts -> lockout -> continued wrong-password submissions from another source.
- Events indicate at least one additional source (10.10.8.112) continued to present incorrect credentials after lockout, reinforcing stale-credential replay behavior.

## Detailed Resolution Steps

### 1. Contain ongoing bad credential attempts
1. Identify asset behind source IP 10.10.8.112 using DHCP/IPAM/EDR records.
2. Temporarily isolate that asset from network authentication paths or stop the responsible process/service.
3. Keep account protected from immediate relock while stale credential sources are cleaned.

### 2. Restore user access in controlled order
1. Unlock account FINBRIDGE\cthompson in AD.
2. Reset password to a temporary strong value.
3. Enforce change at next successful sign-in.
4. Validate sign-in from known endpoint DESKTOP-FB022 only.

### 3. Remove stale credentials on DESKTOP-FB022
1. Sign out all sessions and reboot once.
2. Clear saved entries in Credential Manager (domain creds, RDP creds, mapped drives, Office/legacy entries).
3. Re-add required connections using current password.
4. Refresh authentication context and retest sign-in.

### 4. Remove stale credentials on secondary source (10.10.8.112)
1. Clear stored credentials and app caches on that device.
2. Check Scheduled Tasks running under cthompson and update stored credentials.
3. Check services configured with cthompson logon; update password or migrate to managed service account.
4. Check mobile/VPN/mail clients for cached old password and update.

### 5. Validate incident resolution
1. Monitor for at least 30-60 minutes after remediation.
2. Success criteria:
	- No new Event 4740 for cthompson.
	- No new Event 4776 with 0xC000006A.
	- No new Event 4771 with 0x18 from known sources.
	- Successful sign-ins from expected devices.

### 6. Prevent recurrence
1. Add alerting on repeated 4776/4771 patterns before lockout threshold is reached.
2. Document all known credential-bearing endpoints/processes for cthompson.
3. Use service accounts/managed identities for automated tasks instead of user credentials where possible.
