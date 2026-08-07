# Incident Analysis and Ranked Hypotheses

## Scope Facts (as provided)
- Symptom: Group Policy processing failed
- Affected: 3 Windows 11 machines
- Since: approximately 07:40 this morning
- Reported change: Nil

## Ranked Likely Causes (most probable first)

### 1. DNS resolution failure for AD domain services (DC/SRV/SYSVOL paths)
Why this fits the scope facts:
- Group Policy requires reliable DNS to locate domain controllers and SYSVOL.
- Three machines failing around the same time suggests a shared dependency issue rather than isolated endpoint faults.
- "No change" is consistent with an external service degradation (DNS server issue, upstream path issue, stale/incorrect resolver response).

Single fastest check:
- From one affected machine, run `nslookup -type=SRV _ldap._tcp.dc._msdcs.<yourdomain>` and confirm valid domain controller SRV records are returned quickly.

### 2. Connectivity issue to domain controllers/SYSVOL (network path, routing, firewall, VLAN, NAC)
Why this fits the scope facts:
- Simultaneous onset at ~07:40 across multiple endpoints can indicate a shared network segment or policy path interruption.
- Group Policy failure often follows inability to reach `\\<domain>\\SYSVOL` or required DC ports.

Single fastest check:
- From one affected machine, test SYSVOL reachability directly with `dir \\<yourdomain>\\SYSVOL`.

### 3. Kerberos/authentication failure due to time skew or authentication service disruption
Why this fits the scope facts:
- Group Policy access to domain resources depends on successful computer/user authentication.
- If clock skew or KDC trust/auth issues began around 07:40, several clients can fail GPO processing together.

Single fastest check:
- On one affected machine, run `w32tm /query /status` and verify clock source and offset are within acceptable tolerance.

### 4. Broken machine secure channel/trust issue affecting the impacted clients
Why this fits the scope facts:
- A secure channel problem can cause policy retrieval failures and authentication errors.
- Less likely than DNS/network because three machines were impacted simultaneously, but still plausible if they share OU/build process/join lifecycle.

Single fastest check:
- On each affected machine, run `Test-ComputerSecureChannel` (PowerShell, elevated) and confirm it returns `True`.

### 5. AD/GPO backend issue (SYSVOL/DFSR replication lag or inconsistent DC state)
Why this fits the scope facts:
- If clients are referred to a problematic DC, Group Policy may fail despite endpoint health.
- "No endpoint change" and synchronized onset support a server-side possibility.

Single fastest check:
- From one affected client, run `gpresult /r` immediately after `gpupdate /force` and check whether the same DC is referenced with processing errors.

## Current Position
- This is a ranked hypothesis list only.
- No single root cause is confirmed yet.

## Evidence Request (please provide before narrowing to one cause)
Please share the following evidence set from at least one affected machine (preferably all three if possible):

1. Output of:
   - `ipconfig /all`
   - `nslookup -type=SRV _ldap._tcp.dc._msdcs.<yourdomain>`
   - `dir \\<yourdomain>\\SYSVOL`
   - `w32tm /query /status`
   - `gpupdate /force`
   - `gpresult /r`
2. Event logs around 07:30-08:00:
   - `Microsoft-Windows-GroupPolicy/Operational`
   - `System` (Netlogon, DNS Client, Time-Service entries)
3. Whether unaffected machines in the same site/VLAN can process Group Policy during the same window.

Once this evidence is available, we can confirm or eliminate each hypothesis and reduce to the most likely root cause.

## Evidence-Based Hypothesis Assessment (Event Window Review)

### Incident Evidence Provided
- System log source: DESKTOP-FB031
- Startup window reviewed: 2024-03-15 07:40-07:55
- Affected pattern: 3 of 4 machines in OU=Finance affected

Key events captured:
- 07:40:08 Netlogon Event 5719 (Error): no domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 GroupPolicy Event 1058 (Error): cannot access \\FINBRIDGE-DC01\\sysvol\\finbridge.local\\Policies\\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\\gpt.ini; error 0x3.
- 07:40:10 GroupPolicy Event 1030 (Warning): cannot query list of GPOs; error 0x546.
- 07:40:12 GroupPolicy Event 1129 (Error): no network connectivity to a domain controller.
- 07:41:05 DNS Client Event 1014 (Warning): name resolution for FINBRIDGE-DC01.finbridge.local timed out; configured DNS servers did not respond.
- 07:42:18 DHCP Client Event 50036 (Information): DNS assigned as 10.10.3.250 (old/decommissioned DNS).
- 07:44:01 GroupPolicy Event 1129 (Error): repeated no DC connectivity.

Comparison evidence:
- DESKTOP-FB029 (unaffected) at 07:40:05 DHCP Client Event 50036: DNS 10.10.0.10 (correct new DNS).
- DESKTOP-FB029 at 07:40:11 GroupPolicy Event 1500 (Information): policy processed successfully.

DHCP comparison evidence:
- FB055-057 DNS assigned: 172.16.5.5 (decommissioned).
- FB058 DNS assigned: 10.10.0.10 (correct; manually set before migration).

### Judgement Per Ranked Hypothesis

1) DNS resolution failure for AD domain services
- Judgement: Supports
- Determining evidence:
  - 07:41:05 DNS Client Event 1014
  - 07:40:08 Netlogon Event 5719
  - 07:42:18 DHCP Client Event 50036

2) Connectivity issue to domain controllers/SYSVOL
- Judgement: Supports
- Determining evidence:
  - 07:40:12 GroupPolicy Event 1129
  - 07:44:01 GroupPolicy Event 1129
  - 07:40:09 GroupPolicy Event 1058

3) Kerberos/authentication failure due to time skew/service disruption
- Judgement: Contradicts
- Determining evidence:
  - 07:41:05 DNS Client Event 1014 points to DNS failure first.
  - 07:40:11 GroupPolicy Event 1500 on unaffected FB029 indicates auth backend not broadly down.

4) Broken machine secure channel/trust issue
- Judgement: Contradicts
- Determining evidence:
  - 07:40:08 Netlogon Event 5719 attributes failure to no DC availability.
  - 07:42:18 DHCP Client Event 50036 shows incorrect DNS assignment on affected host.

5) AD/GPO backend issue (SYSVOL/DFSR/DC state)
- Judgement: Contradicts
- Determining evidence:
  - 07:40:11 GroupPolicy Event 1500 on FB029 confirms successful GPO processing during same window when DNS was correct.

## Surviving Hypothesis
- DHCP scope for the affected subnet still referenced decommissioned DNS server(s), causing DC name-resolution failure and downstream Group Policy processing failure.

## Detailed Resolution Steps

1. Immediate containment
   - Update DHCP scope Option 006 on the affected subnet to valid DNS servers only (for example: 10.10.0.10 and approved secondary).
   - Remove decommissioned DNS IPs from scope options, reservations, and any DHCP policies.
   - Temporarily reduce DHCP lease duration to accelerate client correction.

2. Correct affected endpoints quickly
   - Renew DHCP lease on each impacted machine.
   - Flush resolver cache and refresh DNS registration.
   - Restart Netlogon service (or reboot if operationally preferred).

3. Validate technical recovery per machine
   - Confirm active DNS server list reflects only approved DNS.
   - Verify domain controller FQDN and AD SRV records resolve.
   - Verify SYSVOL path accessibility.
   - Force Group Policy update and verify success events.
   - Confirm user login succeeds without Group Policy errors.

4. Validate infrastructure consistency
   - Check DHCP lease logs for the subnet to verify corrected DNS distribution.
   - Verify DHCP failover partner (if present) carries identical corrected options.
   - Confirm no unauthorized/rogue DHCP responder advertises legacy DNS.

5. Prevent recurrence
   - Introduce DNS migration gate: DHCP Option 006 audit before and after cutover.
   - Add automated control to flag scopes that reference retired infrastructure IPs.
   - Keep a decommission deny-list for IPs that must not reappear in DHCP options.
   - Add post-change synthetic checks from each critical subnet: DC SRV lookup, SYSVOL access, and GPO processing.

6. Closure criteria
   - All impacted devices obtain corrected DNS settings.
   - No recurring Event IDs 1014, 5719, 1058, 1030, or 1129 in the observation window.
   - Success events observed for Group Policy processing on previously affected machines.
   - Stability maintained for agreed monitoring period (for example, 24 hours).
