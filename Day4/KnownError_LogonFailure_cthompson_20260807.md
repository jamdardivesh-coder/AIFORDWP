Symptom     : User FINBRIDGE\cthompson is unable to log in on DESKTOP-FB022. The incident presented as repeated sign-in failure followed by account lockout state.

Cause       : Verified root cause is automated domain account lockout triggered by repeated wrong-password submissions for FINBRIDGE\cthompson. A contributing factor was continued incorrect credential submission from secondary source IP 10.10.8.112 after lockout.

Scope       : This incident affected one user only: FINBRIDGE\cthompson. The affected endpoint in evidence was DESKTOP-FB022 during the incident window 08:44-09:09 on 2024-03-15.

Workaround  : Restore service by re-enabling/unlocking the account through authorized admin action, then validate interactive sign-in from DESKTOP-FB022. In this case, account re-enable occurred at 09:08:14 and successful sign-in was confirmed at 09:09:01.

Permanent fix: Identify and remediate the credential-bearing source behind IP 10.10.8.112 that continued sending stale credentials. Apply the RCA preventive controls: runbook check for secondary 4771 source before closure, stale-credential cleanup after lockout incidents, and alert correlation for 4776/4625/4740/4771.

How to spot it: Look for the sequence 4776 with error 0xC000006A (wrong password), multiple 4625 bad username/password interactive failures (type 2), and 4740 account lockout. Confirm persistence risk with repeated 4771 Kerberos pre-auth failures using code 0x18 (wrong password), especially from a secondary source such as 10.10.8.112, then verify recovery with 4722 followed by successful 4624 interactive logon.
