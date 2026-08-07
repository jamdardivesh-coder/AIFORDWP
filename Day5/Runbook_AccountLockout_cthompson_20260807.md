# Runbook — Restore Access for Single-User Domain Lockout (cthompson Pattern)
## Based on RCA: INC-2024-0315-CTHOMPSON-LOGON

## 1. Prerequisites

1. Confirm the incident matches this pattern: single user cannot log in, evidence window shows bad-password events followed by lockout.
2. Obtain the affected account name in DOMAIN\username format (example: FINBRIDGE\cthompson).
3. Obtain the user endpoint hostname where the failure is reported (example: DESKTOP-FB022).
4. Obtain the incident time window to filter Security logs (example: 08:40-09:10).
5. Use an admin workstation with access to AD account management tools and Security Event logs.
6. Ensure you have permission to read Security logs on relevant systems. [ELEVATED]
7. Ensure you have permission to enable/unlock AD user accounts. [ELEVATED]
8. Ensure you can query IP-to-asset mapping in DHCP/IPAM/EDR for secondary source identification.

Required systems and tools:
- Active Directory user administration toolset (for account enable/unlock).
- Event Viewer or SIEM with access to Security events.
- DHCP/IPAM/EDR lookup for source IP attribution.
- Service Desk ticketing record for time-stamped actions.

---

## 2. Procedure

1. Open the incident ticket.
Expected result: Ticket is active and ready for timestamped updates.

2. Record the exact affected user account in the ticket.
Expected result: Account is documented as DOMAIN\username with no ambiguity.

3. Record the reported endpoint hostname in the ticket.
Expected result: Hostname is documented for source correlation.

4. Open Security event search for the incident time window.
Expected result: You can query events for the specified interval.

5. Filter Security logs for Event ID 4776 for the affected account.
Expected result: You find credential validation failure entries with wrong-password code (0xC000006A) if pattern matches.

6. Filter Security logs for Event ID 4625 for the affected account.
Expected result: You find failed logon attempts, including logon type 2 (interactive) from the reported endpoint.

7. Filter Security logs for Event ID 4740 for the affected account.
Expected result: You find account lockout event and caller computer details.

8. Filter Security logs for Event ID 4771 for the affected account.
Expected result: You identify any Kerberos pre-auth failures with code 0x18 and any secondary source IP.

9. Record every matched event timestamp, event ID, and source in the ticket.
Expected result: The ticket contains a complete causal sequence for audit.

10. Query DHCP/IPAM/EDR for the secondary source IP if 4771 shows a non-user endpoint source.
Expected result: You identify the asset or process associated with the secondary IP.

11. Notify the incident channel of identified secondary credential source.
Expected result: Stakeholders know lockout recurrence risk exists until source cleanup is completed.

12. Enable or unlock the affected AD account. [ELEVATED]
Expected result: Account state changes from locked/disabled to enabled.

13. Instruct the user to perform one interactive sign-in from the reported endpoint only.
Expected result: A single controlled login attempt is made from the known host.

14. Check Security logs for Event ID 4624 for the affected account immediately after the user sign-in.
Expected result: You see successful logon, type 2 (interactive), from the reported endpoint.

15. Ask the user to confirm desktop access is normal.
Expected result: User confirms they are logged in and working.

16. Start stale-credential cleanup on the identified secondary source asset.
Expected result: Credential replay source is removed or disabled.

17. Add a runbook flag in the ticket that secondary source validation was completed.
Expected result: Closure evidence includes source-check completion.

18. Document final resolution timestamps in the ticket.
Expected result: Ticket includes unlock time and successful logon time.

---

## 3. Verification

Complete all checks below before closure:

1. Confirm Event 4722 exists for the affected account with admin actor and timestamp. [ELEVATED]
Expected result: Administrative re-enable/unlock action is auditable.

2. Confirm Event 4624 exists for the affected account with logon type 2 from the user endpoint.
Expected result: Interactive login path is restored.

3. Confirm the user explicitly reports they can work normally.
Expected result: Service restoration is validated by the affected user.

4. Recheck for new Event 4771 wrong-password failures for the account for a 30-minute observation window. [ELEVATED]
Expected result: No recurring stale-credential submissions are observed.

5. Recheck for new Event 4740 lockout for the account during the same window. [ELEVATED]
Expected result: No relockout occurs.

Closure gate:
- Close only if steps 1 through 5 all pass.

---

## 4. Rollback

Use this section immediately if the account relocks or user access fails after unlock.

1. Reopen the incident ticket status to Active.
Expected result: Work is resumed under formal incident control.

2. Temporarily block or isolate the identified secondary source asset from authentication traffic using endpoint/network controls. [ELEVATED]
Expected result: Wrong-password replay from that asset stops.

3. Disable scheduled task or service on that asset if it runs with the affected user credentials. [ELEVATED]
Expected result: Automated credential retries are halted.

4. Unlock or re-enable the affected account again in AD. [ELEVATED]
Expected result: Account returns to enabled state.

5. Trigger one new interactive login attempt from the user endpoint only.
Expected result: Controlled test isolates whether replay source is now contained.

6. If login still fails, escalate to IAM on-call with attached event timeline (4776, 4625, 4740, 4771, 4722, 4624).
Expected result: IAM receives complete evidence to continue without re-triage.

7. Keep the account in managed state and do not close incident until verification section passes.
Expected result: No premature closure while recurrence risk remains.

---

## 5. Notes

- This runbook is for the verified pattern where authentication fails before profile load; it is not for post-login profile corruption scenarios.
- In the reference incident, key indicators were Event 4776 (0xC000006A), Event 4625 (type 2), Event 4740 lockout, and Event 4771 (0x18) from secondary IP 10.10.8.112.
- Recovery evidence in the reference incident was Event 4722 at 09:08:14 and Event 4624 at 09:09:01 from DESKTOP-FB022.
- Warning: unlocking without neutralizing the secondary source can cause immediate relockout.
- Related incidents: see Day4 RCA records for lockout cases with repeated wrong-password submissions and secondary source replay behavior.
