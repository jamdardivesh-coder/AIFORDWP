# End-User Communication Pack — Logon Incident (cthompson)
## Incident Date: 2024-03-15
## Resolved: 09:09

## Audience 1 — Non-Technical Executive
Access is restored and data is safe. One user, cthompson, could not sign in between about 08:44 and 09:09. The account was automatically locked after repeated incorrect password attempts from DESKTOP-FB022, and additional incorrect attempts came from 10.10.8.112. Helpdesk-admin re-enabled the account at 09:08:14, and successful sign-in was confirmed at 09:09:01. Preventive steps are in progress to remove saved old credentials and improve early detection. No action is needed from you.

## Audience 2 — Affected End-User Team (10 People, Non-Technical)
Your access and data are safe, and the issue is resolved. One teammate account (cthompson) could not sign in from about 08:44 to 09:09 because repeated incorrect saved password attempts locked the account, including attempts from DESKTOP-FB022 and 10.10.8.112. Helpdesk-admin re-enabled the account at 09:08:14, and sign-in succeeded at 09:09:01. We are removing saved old credentials and improving early alerts. If you see the same issue, stop retrying and contact the Service Desk immediately.

## Audience 3 — Engineer-to-Engineer Internal Note
Status: Resolved, verified at 09:09.

Facts to carry forward:
- Scope remained single-user only: FINBRIDGE\cthompson.
- Incident window: approximately 08:44 to 09:09 on 2024-03-15.
- Primary root cause: AD account lockout after repeated bad credential submissions.
- Contributing cause: continued stale credential submissions from secondary source IP 10.10.8.112 after lockout.

Supporting evidence:
- 08:44:01 Event 4776 (Audit Failure), error 0xC000006A wrong password, source workstation DESKTOP-FB022.
- 08:44:03 / 08:44:28 / 08:44:55 Event 4625 (Audit Failure), logon type 2, bad username/password, source DESKTOP-FB022.
- 08:44:56 Event 4740 (Audit Failure), account locked out, caller DESKTOP-FB022.
- 08:45:10 Event 4625 (Audit Failure), logon type 7 unlock attempt, account locked out.
- 08:45:44 / 08:46:01 / 08:46:33 Event 4771 (Audit Failure), failure code 0x18 wrong password, source IP 10.10.8.112.
- 09:08:14 Event 4722 (Audit Success), account enabled by FINBRIDGE\helpdesk-admin.
- 09:09:01 Event 4624 (Audit Success), interactive logon type 2 successful from DESKTOP-FB022.

Exact action taken:
1. Investigated lockout sequence using Security logs (4776, 4625, 4740, 4771).
2. Identified secondary stale credential source behavior from 10.10.8.112.
3. Re-enabled/unlocked FINBRIDGE\cthompson (4722 at 09:08:14).
4. Validated successful interactive sign-in from DESKTOP-FB022 (4624 at 09:09:01).
5. Confirmed user reported no further issue.

Config/detail note:
- Evidence pattern confirms authentication-stage failure path (wrong password and lockout), not post-auth profile failure and not CA/MFA denial in provided logs.

Verification step used:
- Closure required successful 4624 interactive logon following 4722 account re-enable, plus user confirmation of normal access.

Preventive action needed:
1. Identify and remediate the credential-bearing asset/process behind 10.10.8.112.
2. Add runbook requirement to check for secondary 4771 source before closure.
3. Implement alert correlation on 4776/4625/4740/4771 sequence for earlier triage.
4. Perform stale-credential cleanup on endpoints after lockout incidents.
