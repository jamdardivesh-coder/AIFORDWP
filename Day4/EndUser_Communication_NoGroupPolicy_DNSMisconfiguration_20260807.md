# End-User Communication Pack - Group Policy Processing Incident (Floor 3)
## Incident Date: 2024-03-15
## Resolved: 09:09

## Audience 1 — Non-technical Executive
Access is restored and data is safe. On 2024-03-15 from 07:40 to 09:09, 3 of 4 Finance Floor 3 Windows 11 devices could not apply sign-in settings because old name-server addresses (10.10.3.250 and 172.16.5.5) were sent instead of 10.10.0.10; a pre-set device on 10.10.0.10 worked. We corrected settings distribution, removed old addresses, refreshed affected devices, and confirmed normal processing with no further issues. No action is required.

## Audience 2 — Affected End-user Team (10 people, non-technical)
Your access and data are safe, and this issue is fixed. On 2024-03-15 from about 07:40 to 09:09, 3 of 4 Finance Floor 3 Windows 11 devices could not load sign-in settings because they were given old name-server addresses (10.10.3.250 and 172.16.5.5) instead of 10.10.0.10, while one pre-set device on 10.10.0.10 worked normally. We corrected the settings source, removed old addresses, refreshed affected devices, and verified normal processing with no further issues. If this happens again, contact the Service Desk.

## Audience 3 — Engineer-to-engineer Internal Note
Status: Resolved and verified at 09:09.

Facts (keep consistent):
- Incident window: 2024-03-15, 07:40 to 09:09.
- Scope: 3 of 4 Windows 11 endpoints in OU=Finance (Floor 3) affected.
- Symptom: Group Policy processing failed at startup/logon due to DC reachability failure.
- Comparator: DESKTOP-FB029/FB058 unaffected with DNS 10.10.0.10 and GP success.

Root cause:
- DHCP scope for Floor 3 continued to advertise decommissioned DNS server values (10.10.3.250 and 172.16.5.5) instead of current DNS 10.10.0.10.
- This caused DC FQDN resolution timeouts and secure channel failure, cascading to GP 1058/1030/1129 failures.

Supporting evidence:
- 07:40:08 Netlogon 5719: no DC available; DNS query for FINBRIDGE-DC01.finbridge.local no response.
- 07:40:09/07:40:11 GroupPolicy 1058: cannot access \\FINBRIDGE-DC01\\sysvol\\...\\gpt.ini (0x3).
- 07:40:10 GroupPolicy 1030: cannot query GPO list (0x546).
- 07:40:12 and 07:44:01 GroupPolicy 1129: no network connectivity to DC.
- 07:41:05 DNS Client 1014: resolution timeout for FINBRIDGE-DC01.finbridge.local.
- 07:42:18 DHCP Client 50036 on affected host: DNS assigned 10.10.3.250 (old).
- Comparator: 07:40:05 DHCP 50036 DNS 10.10.0.10; 07:40:11 GroupPolicy 1500 success.

Exact action taken:
1. Updated DHCP scope Option 006 on affected subnet(s) to valid DNS, including 10.10.0.10.
2. Removed decommissioned DNS entries (10.10.3.250 and 172.16.5.5) from scope options/reservations/policies.
3. On affected endpoints: renewed DHCP leases, refreshed DNS client state, and forced GP refresh.
4. Re-tested DC resolution and SYSVOL/GP path.

Verification step and result:
- Verified restored domain connectivity and successful Group Policy processing on previously affected hosts.
- Incident confirmed resolved at 09:09; no further issues reported.

Preventive action needed:
1. Mandatory DNS migration checkpoint: DHCP Option 006 audit before/after cutover.
2. Canary validation per subnet: DNS assignment, DC SRV/FQDN resolution, SYSVOL access, GP processing.
3. Monitoring for post-change spikes in Event IDs 5719, 1014, 1058, 1030, and 1129.
4. Compliance control to block retired DNS IPs from reappearing in DHCP scope configuration.
