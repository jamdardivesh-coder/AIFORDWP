# RCA - No Group Policy Processing (Floor 3 DNS Misconfiguration)

- Date of analysis: 2026-08-07
- Analyst role: DWP Incident Analyst
- Affected pattern: Domain-joined endpoints on Floor 3 subnet (example impacted host behavior aligned with FB055-FB057)
- Unaffected comparator: DESKTOP-FB029 / FB058 (same OU, successful processing)

## 1) What each Event ID records

### Event 7036 - Service Control Manager
Records a service state transition (for example, starting, stopping, running, paused). In this incident, it confirms **Network Location Awareness (NLA)** entered the **running** state at 07:40:02.

### Event 5719 - Netlogon (Error)
Records failure to establish a secure channel to the domain because no domain controller (DC) could be contacted. Commonly seen during startup/logon when DC discovery fails (often DNS-related). Here it explicitly states no DC was available and DNS query for `FINBRIDGE-DC01.finbridge.local` returned no response.

### Event 1058 - GroupPolicy (Error)
Records Group Policy processing failure when the client cannot read policy files from SYSVOL (for example `gpt.ini` under `\\<DC>\sysvol\...`). In this incident, access to the policy path failed with error `0x3` (path not found), which is consistent with inability to reach/resolve the DC hosting SYSVOL.

### Event 1030 - GroupPolicy (Warning)
Records failure to query the list of applicable Group Policy Objects (GPOs). This is often paired with 1058 and indicates the client could not retrieve policy metadata from AD/SYSVOL because domain services were unreachable.

### Event 1129 - GroupPolicy (Error)
Records that Group Policy processing failed due to lack of network connectivity to a domain controller. It is effectively the summary symptom event for DC-unreachable policy processing.

### Event 1014 - DNS Client Events (Warning)
Records DNS name-resolution timeout (query sent, no response from configured DNS servers). This is strong evidence of DNS-path failure, not just SMB/LDAP failure.

### Event 50036 - DHCP Client (Information)
Records lease assignment details, including IP lease source and DNS server(s) assigned via DHCP options. In this case it documents assignment of **old/decommissioned DNS server** `10.10.3.250` (and in comparison data `172.16.5.5` old local DNS for FB055-057).

### Event 1500 - GroupPolicy (Information)
Records successful completion of Group Policy processing. Used here as a control signal on unaffected device(s) with correct DNS (`10.10.0.10`).

## 2) Reconstructed sequence of events (plain English)

1. The endpoint boots/logs on and networking services begin; NLA reaches running state at 07:40:02.
2. Very shortly after, the machine tries to locate and authenticate to a domain controller, but Netlogon fails (07:40:08) because the DC hostname cannot be resolved/reached.
3. Group Policy then attempts to read policy data (`gpt.ini`) from SYSVOL and fails (07:40:09 and 07:40:11, Event 1058), and also cannot enumerate GPOs (07:40:10, Event 1030).
4. Group Policy posts a higher-level failure message indicating no DC connectivity (07:40:12, Event 1129).
5. DNS client timeout appears (07:41:05, Event 1014), confirming name-resolution failure path.
6. DHCP lease detail appears at 07:42:18 showing DNS server assigned as `10.10.3.250`, which was decommissioned during migration; this explains why DC FQDN lookups fail.
7. Group Policy retries and fails again (07:44:01, Event 1129), consistent with unresolved DNS misconfiguration.
8. Comparison host in same OU (DESKTOP-FB029 / FB058) received correct DNS (`10.10.0.10`) and processed Group Policy successfully (Event 1500), proving OU/GPO content itself is healthy.

## 3) Most likely cause of the "service crash" (with evidence)

### Technical conclusion
There is **no direct evidence of an actual Windows service crash** in the provided events (no crash/termination events such as 7031/7034 for Group Policy or GPSVC). The observed failure is best characterized as **Group Policy processing failure due to DNS/DHCP misconfiguration**, not a service binary crash.

### Most likely operational cause
The Floor 3 DHCP scope still advertises **decommissioned DNS server(s)** (`10.10.3.250` and comparison note `172.16.5.5`) instead of the current central DNS (`10.10.0.10`). Endpoints that consumed stale DNS cannot resolve domain controller FQDNs, so domain secure channel establishment and SYSVOL access fail.

### Evidence map
- Netlogon 5719: secure channel to domain cannot be established; no DC available; DC DNS query gets no response.
- DNS Client 1014: explicit timeout for `FINBRIDGE-DC01.finbridge.local`; configured DNS servers not responding.
- GroupPolicy 1058/1030/1129: cascading failures to access SYSVOL/query GPO list due to absent DC connectivity.
- DHCP 50036 on impacted host: DNS assigned = `10.10.3.250` (old/decommissioned).
- Comparator host DHCP 50036 + GP 1500: DNS assigned = `10.10.0.10` and GP succeeds; isolates fault to DNS assignment path, not policy object corruption.

## 4) 5-Why analysis

### Problem statement
Endpoints on Floor 3 intermittently report "no Group Policy" / GP processing failures after migration.

1. **Why did Group Policy fail?**  
   Because the client could not contact a domain controller and could not read SYSVOL (`gpt.ini`) (Events 5719, 1058, 1030, 1129).

2. **Why could the client not contact a domain controller?**  
   Because DNS resolution for `FINBRIDGE-DC01.finbridge.local` timed out (Event 1014) and Netlogon reported no DC available (Event 5719).

3. **Why did DNS resolution time out?**  
   Because the endpoint was configured (via DHCP) to use a decommissioned DNS server (`10.10.3.250`; comparison logs also cite stale `172.16.5.5`) (Event 50036 + migration note).

4. **Why was DHCP handing out decommissioned DNS server addresses?**  
   Because the Floor 3 DHCP scope options were not updated during/after the DNS migration wave to the new DNS `10.10.0.10`.

5. **Why were DHCP scope options not updated and validated?**  
   Because migration change controls lacked an enforced post-change validation checkpoint for dependent DHCP scopes and endpoint sampling across subnets.

### Root cause (5th why)
Process/control gap in migration execution: missing DHCP scope update and post-change validation, resulting in stale DNS advertisement to clients.

## 5) Impact and scope assessment

- Likely impacted: endpoints that renewed DHCP leases on affected Floor 3 scope(s) after migration and received old DNS entries.
- Likely unaffected: endpoints manually configured/pre-staged with correct DNS (`10.10.0.10`) such as FB058 / DESKTOP-FB029.
- User-facing impact: delayed or failed user policy application at startup/logon, potential login script/drive mapping/security baseline drift.

## 6) Corrective and preventive actions

### Immediate containment
- Update Floor 3 DHCP scope option 006 to `10.10.0.10` (and remove all decommissioned DNS entries).
- Force lease renewal on affected endpoints (`ipconfig /release` + `ipconfig /renew`) and clear resolver cache (`ipconfig /flushdns`).
- Trigger policy refresh (`gpupdate /force`) and verify Event 1500 success.

### Verification steps
- On sample impacted clients: confirm `ipconfig /all` shows only approved DNS.
- Validate `nslookup FINBRIDGE-DC01.finbridge.local` resolves quickly and consistently.
- Confirm absence of new Event 5719/1058/1030/1129 after remediation window.
- Confirm presence of GroupPolicy success events (e.g., 1500).

### Preventive controls
- Add migration runbook gate: DHCP scope review/update checklist for every affected subnet.
- Add post-change health check automation: compare DHCP DNS options vs CMDB authoritative DNS list.
- Add canary endpoint validation in each subnet before closure.
- Add rollback trigger threshold based on DC resolution failure rate.

## 7) Final determination

The incident is most consistently explained by **stale DHCP-provided DNS configuration after migration**, causing DC name-resolution failure and subsequent Group Policy processing errors. The data does **not** support a true service-process crash; it supports a dependency/connectivity failure chain rooted in DNS assignment.
