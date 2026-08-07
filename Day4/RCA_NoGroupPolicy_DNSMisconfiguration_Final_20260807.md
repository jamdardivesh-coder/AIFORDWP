# Root Cause Analysis - Group Policy Processing Failure (DNS via DHCP Misconfiguration)
## Incident Reference: INC-2024-0315-FIN-F3-GPO

| Field | Detail |
|-------|--------|
| Date of Incident | 2024-03-15 |
| Incident Window | 07:40 - 09:09 |
| Date Documented | 2026-08-07 |
| Affected Service | Active Directory Group Policy processing at startup/logon |
| Affected Scope | 3 of 4 Windows 11 endpoints in OU=Finance (Floor 3 subnet) |
| Primary Symptom | Group Policy processing failed; no reachable domain controller |
| Detection Source | Endpoint System and GroupPolicy logs + DHCP assignment evidence |
| Resolved Time | 09:09 AM |
| Resolution Status | Resolved, verified connectivity restored, GP processing successful, no further issues reported |

---

## 1. Executive Summary

Between 07:40 and 09:09, three Windows 11 endpoints in Finance experienced Group Policy processing failures during startup/logon. Event evidence shows clients could not discover/reach domain controllers because DNS resolution for the DC FQDN failed. DHCP assigned a decommissioned DNS server to affected endpoints, while an unaffected comparator endpoint had the correct DNS and processed policy successfully.

The DHCP scope was corrected to distribute the valid DNS server, affected endpoints refreshed network settings, and domain connectivity plus Group Policy processing recovered. Service restoration was verified and incident closure confirmed at 09:09 AM.

---

## 2. Incident Scope and Constraints

- Symptom in scope: Group Policy processing failed.
- Affected endpoints: 3 Windows 11 machines (Finance, Floor 3).
- Onset: approximately 07:40.
- Reported planned change at symptom onset: none.
- Comparator endpoint in same OU: unaffected due to correct DNS assignment.

---

## 3. Supporting Evidence

### 3.1 Affected Endpoint Evidence (DESKTOP-FB031)

| Timestamp | Event Source | Event ID | Level | Evidence Detail |
|-----------|--------------|----------|-------|-----------------|
| 07:40:02 | Service Control Manager | 7036 | Information | Network Location Awareness entered running state |
| 07:40:08 | Netlogon | 5719 | Error | Unable to set secure channel to domain FINBRIDGE; no DC available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response |
| 07:40:09 | GroupPolicy | 1058 | Error | Cannot access \\FINBRIDGE-DC01\\sysvol\\finbridge.local\\Policies\\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\\gpt.ini; error 0x3 |
| 07:40:10 | GroupPolicy | 1030 | Warning | Cannot query list of Group Policy objects; error 0x546 |
| 07:40:11 | GroupPolicy | 1058 | Error | Repeat SYSVOL/GPT access failure |
| 07:40:12 | GroupPolicy | 1129 | Error | GP failed due to no network connectivity to domain controller |
| 07:41:05 | DNS Client Events | 1014 | Warning | Name resolution timeout for FINBRIDGE-DC01.finbridge.local; configured DNS servers did not respond |
| 07:42:18 | DHCP Client | 50036 | Information | Lease assigned with DNS server 10.10.3.250 (old/decommissioned) |
| 07:44:01 | GroupPolicy | 1129 | Error | Repeat no DC connectivity during GP processing |

### 3.2 Comparator Evidence (Unchanged Service Path)

| Timestamp | Host | Event ID | Evidence Detail |
|-----------|------|----------|-----------------|
| 07:40:05 | DESKTOP-FB029 | DHCP 50036 | DNS assigned 10.10.0.10 (correct new DNS) |
| 07:40:11 | DESKTOP-FB029 | GroupPolicy 1500 | Group Policy processed successfully |

### 3.3 DHCP Scope Comparison Evidence

| Endpoint Group | DNS Assigned | Status |
|----------------|-------------|--------|
| FB055-FB057 | 172.16.5.5 (Floor 3 local DNS, decommissioned 2024-03-14) | Incorrect |
| FB058 | 10.10.0.10 (central DNS, manually set pre-migration) | Correct |

### 3.4 Evidence Interpretation

- Netlogon and DNS timeout events confirm domain controller discovery failure at name-resolution stage.
- GroupPolicy errors (1058/1030/1129) are downstream effects of DC reachability failure.
- DHCP evidence identifies direct configuration defect: stale/decommissioned DNS assignment.
- Comparator endpoint proves AD/GPO backend remained healthy when DNS path was correct.

---

## 4. Detailed Timeline

| Time | Event / Action | Outcome |
|------|----------------|---------|
| 07:40:02 | NLA service running (7036) | Network stack initialized |
| 07:40:08 | Netlogon 5719 on affected endpoint | DC secure channel setup failed; DNS no-response observed |
| 07:40:09 | GroupPolicy 1058 | SYSVOL policy file access failure |
| 07:40:10 | GroupPolicy 1030 | GPO list query failed |
| 07:40:11 | GroupPolicy 1058 repeated | Failure persisted |
| 07:40:12 | GroupPolicy 1129 | No DC connectivity for GP processing |
| 07:41:05 | DNS Client 1014 | DC FQDN resolution timeout confirmed |
| 07:42:18 | DHCP 50036 | Wrong DNS server assignment observed (10.10.3.250) |
| 07:44:01 | GroupPolicy 1129 repeated | Ongoing failure while stale DNS remained active |
| 08:xx | DHCP scope review and correction initiated | Old DNS entries identified/removed; correct DNS published |
| 08:xx | Endpoint remediation executed | Lease renew, DNS cache refresh, policy refresh performed |
| 09:09 | Post-fix validation complete | Connectivity restored, GP processing successful, no further issues reported |

Note: Exact minute stamps for remediation actions between 08:00 and 09:09 were not captured in the provided log extract; technical completion was validated by successful post-change behavior and closure confirmation at 09:09.

---

## 5. Root Cause Statement

Primary root cause:
DHCP scope configuration for the affected Floor 3 subnet continued to advertise decommissioned DNS server addresses after DNS migration.

Failure mechanism:
Clients receiving stale DNS could not resolve domain controller FQDN/SRV records, causing Netlogon secure channel failure and subsequent Group Policy processing failures (SYSVOL/GPO retrieval errors).

Contributing factors:
- Migration execution gap: dependent DHCP scope option update was missed.
- Validation gap: post-migration subnet-level endpoint sampling did not detect stale DNS publication before user impact.

---

## 6. 5-Why Analysis

Problem:
Three Windows 11 machines in Finance failed Group Policy processing at startup/logon.

Why 1:
Why did Group Policy processing fail?
Because clients could not reach/communicate with a domain controller during policy processing.
Evidence: GroupPolicy 1129 at 07:40:12 and 07:44:01; GroupPolicy 1058/1030 at 07:40:09-07:40:11.

Why 2:
Why could clients not reach a domain controller?
Because domain controller name resolution failed and secure channel setup could not complete.
Evidence: Netlogon 5719 at 07:40:08; DNS Client 1014 at 07:41:05.

Why 3:
Why did name resolution fail?
Because configured DNS server on affected endpoints was decommissioned and non-responsive.
Evidence: DHCP Client 50036 at 07:42:18 showed DNS 10.10.3.250 (old).

Why 4:
Why were endpoints still receiving decommissioned DNS?
Because the Floor 3 DHCP scope option values were not fully updated after DNS migration.
Evidence: DHCP comparison showed stale DNS assigned to impacted hosts while comparator had corrected DNS.

Why 5:
Why was scope update not caught before impact?
Because change controls lacked a mandatory dependency validation checkpoint linking DNS migrations to DHCP scope audits and endpoint canary verification.

Systemic cause:
Incomplete migration control design for cross-service dependency validation (DNS decommissioning vs DHCP scope publication).

---

## 7. Resolution Actions Applied

1. Corrected DHCP scope Option 006 for affected subnet(s) to approved DNS server(s) including 10.10.0.10.
2. Removed decommissioned DNS IPs from scope options/reservations/policies.
3. Applied endpoint recovery steps on affected devices:
   - DHCP lease renewal
   - DNS cache flush and DNS registration refresh
   - Group Policy refresh
4. Verified restored DC resolution/connectivity and successful Group Policy processing.
5. Confirmed user impact cleared and no active issue reported by 09:09 AM.

---

## 8. Preventive and Corrective Actions (CAPA)

### Immediate Corrective Actions (0-5 business days)

1. Audit all DHCP scopes for references to retired DNS infrastructure IPs.
2. Apply corrected DNS options across primary and failover DHCP servers.
3. Run a targeted verification script on a sample set of endpoints per subnet:
   - Current DNS assignment
   - DC FQDN and SRV resolution
   - SYSVOL reachability
   - GP processing status

### Short-Term Preventive Actions (1-4 weeks)

1. Add mandatory migration checklist control: DNS cutover cannot close until DHCP option audit is complete for all dependent subnets.
2. Introduce canary endpoint validation per subnet before decommission completion.
3. Implement alert rule for spikes in Event IDs 5719, 1014, and 1129 after infrastructure changes.
4. Update incident runbook to include immediate DHCP Option 006 verification during GP/DC connectivity incidents.

### Strategic Preventive Actions (1-3 months)

1. Implement configuration compliance monitoring to detect forbidden (retired) DNS IPs in DHCP options.
2. Establish dependency mapping between DNS lifecycle changes and DHCP management workflows in change tooling.
3. Introduce automated post-change synthetic probes from each site/subnet for AD dependency health.
4. Define rollback trigger thresholds (for example, sustained DC resolution failure rate) for migration waves.

---

## 9. Verification and Closure

Verification criteria met:
- Connectivity to domain services restored.
- Group Policy processing restored on previously affected endpoints.
- No new issues reported after remediation.
- Incident closed at 09:09 AM.

Final status:
Resolved and verified.

---

## 10. Lessons Learned

1. DNS migrations require explicit validation of all DHCP-dependent scope options before and after cutover.
2. Comparator endpoint evidence is high-value for quickly isolating configuration-drift root causes.
3. Event-chain correlation (5719 -> 1014 -> 1058/1030/1129) should be codified in triage playbooks for faster diagnosis.

---

Document prepared by DWP Engineering
Date prepared: 2026-08-07
