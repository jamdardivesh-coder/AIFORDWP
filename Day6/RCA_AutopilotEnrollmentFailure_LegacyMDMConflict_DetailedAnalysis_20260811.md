# Detailed Incident Analysis — Windows Autopilot Enrolment Failure
## Document Reference: RCA-AUTOPILOT-20240315-DA
## Analyst: DWP Analyst | Analysis Date: 2026-08-11
## Incident Date: 2024-03-15

---

| Field | Detail |
|---|---|
| **Device** | DESKTOP-FB099 |
| **User** | FINBRIDGE\rthomas |
| **OS Build** | 22621.2861 |
| **Enrollment Type** | Autopilot |
| **Enrollment State** | Failed |
| **Primary Error Code** | 0x80180014 |
| **Error Description** | The device is already enrolled in MDM. |
| **Azure AD Joined** | Yes |
| **Existing MDM Enrolment** | Yes |
| **Legacy Enrolment Date** | 2023-11-04 |
| **Profiles Attempted** | 4 |
| **Profiles Applied** | 0 |
| **Policy Last Error** | 0x80070005 (Access denied) |
| **Licensing** | M365 present, Intune P1 present, Autopilot license indicated present in scope facts |
| **Network State** | Required endpoints reachable, no proxy |
| **Status at Analysis** | Root cause identified; remediation defined |

---

## Section 1 — Supporting Evidence From The Diagnostic Export

### EnrollmentStatus

| Field | Value | Diagnostic Meaning |
|---|---|---|
| EnrollmentType | Autopilot | Confirms the failed workflow is Windows Autopilot enrolment, not a standard manual device add |
| EnrollmentState | Failed | Confirms the process did not complete |
| ErrorCode | 0x80180014 | Primary blocking error reported by the export |
| ErrorDescription | The device is already enrolled in MDM. | The export explicitly states the blocking condition. This is the strongest evidence in the case |
| Timestamp | 2024-03-15 09:18:44 | Establishes when the enrolment failure state was recorded |

**Diagnostic value:** This section directly identifies the failing stage and gives the product-supplied failure description. No inference is needed to conclude that an existing enrolment blocked the new Autopilot attempt.

---

### PolicyManager

| Field | Value | Diagnostic Meaning |
|---|---|---|
| ProfilesAttempted | 4 | Four policy payloads were in scope for application |
| ProfilesApplied | 0 | No policy payloads were successfully applied |
| LastError | 0x80070005 (Access denied) | The export provides the meaning as Access denied; this occurred after enrolment did not complete |
| FailedProfile | FinBridge-Win11-Security-Baseline | Identifies one concrete profile that could not apply |
| Timestamp | 2024-03-15 09:19:01 | Shows policy processing attempted shortly after the failed enrolment event |

**Diagnostic value:** Policy application failure is present, but the data sequence shows it is downstream. Because enrolment did not complete, policy could not establish a valid management context and therefore remained at 0 of 4 applied.

---

### ComplianceEngine

| Field | Value | Diagnostic Meaning |
|---|---|---|
| EvaluationResult | Could not evaluate | Compliance did not reach a usable evaluation state |
| Reason | Enrolment not complete | Explicitly ties compliance failure to the incomplete enrolment state |
| Timestamp | 2024-03-15 09:19:45 | Confirms compliance evaluation failed after the enrolment breakdown |

**Diagnostic value:** This section eliminates compliance policy as the primary cause. The engine states clearly that it could not evaluate because enrolment had not completed.

---

### DeviceInfo

| Field | Value | Diagnostic Meaning |
|---|---|---|
| AzureADJoined | Yes | Identity join to Microsoft Entra ID was already present |
| MDMEnrolled | Yes (previous enrolment) | Confirms an existing management relationship already existed |
| EnrolmentSource | Legacy (manual MDM enrolment, 2023-11-04) | Confirms the older management path and its date |
| AutopilotProfile | FinBridge-Autopilot-Standard | Confirms the device was targeted for an Autopilot deployment profile |
| TPMVersion | 2.0 | Hardware attestation prerequisite appears present |
| TPMStatus | Ready | TPM is not indicating a readiness blocker |
| SecureBoot | Enabled | Basic Windows 11 readiness posture is in place |

**Diagnostic value:** This is the key corroborating section. It proves the device already had a previous MDM enrolment and shows the enrolment was not a fresh first-time management attempt.

---

### NetworkCheck

| Field | Value | Diagnostic Meaning |
|---|---|---|
| login.microsoftonline.com | OK | Identity endpoint reachable |
| enrollment.manage.microsoft.com | OK | Intune enrolment endpoint reachable |
| enterpriseregistration.windows.net | OK | Device registration endpoint reachable |
| ProxyDetected | No | No proxy interference detected |

**Diagnostic value:** This rules out the common network-path blockers that would otherwise prevent Autopilot or enrolment traffic from reaching Microsoft endpoints.

---

### Licensing

| Field | Value | Diagnostic Meaning |
|---|---|---|
| M365LicenseFound | Yes | Microsoft 365 licensing was detected |
| IntuneP1License | Yes | Intune licensing prerequisite was present |

**Diagnostic value:** Licensing was not the blocker in the collected evidence. The earlier scope facts also stated Autopilot licensing was present.

---

## Section 2 — Timeline Reconstruction

### Chronological Timeline

| Time | Event | Evidence | Interpretation |
|---|---|---|---|
| 2023-11-04 | Legacy manual MDM enrolment occurs | DeviceInfo > EnrolmentSource | This creates the pre-existing management relationship later found in the export |
| 2024-03-15 09:18:44 | Autopilot enrolment records failure | EnrollmentStatus | The Autopilot process fails and reports that the device is already enrolled in MDM |
| 2024-03-15 09:19:01 | Policy application attempt fails | PolicyManager | Four profiles were attempted but none applied, consistent with invalid or incomplete enrolment state |
| 2024-03-15 09:19:45 | Compliance engine cannot evaluate | ComplianceEngine | Compliance evaluation is blocked because enrolment did not complete |
| 2024-03-15 09:22 | Export captured | Header fields | The diagnostic package is collected after the failure sequence is already visible |

### Plain English Sequence Of Events
A device that had already been manually enrolled into MDM on 2023-11-04 was later put through an Autopilot enrolment flow. When Autopilot attempted to establish device management, the service detected that the endpoint already had an MDM enrolment relationship. The enrolment stage then failed at 09:18:44 with 0x80180014 and the export-supplied message that the device is already enrolled in MDM. Policy processing continued only far enough to show that 4 profiles were in scope, but none could be applied. Compliance evaluation then failed because enrolment had not completed. Licensing and network checks were healthy throughout, so they do not explain the failure.

---

## Section 3 — Root Cause Analysis

### Primary Finding
A stale pre-existing legacy manual MDM enrolment conflicted with the new Windows Autopilot enrolment attempt. Autopilot could not complete because the device was already associated with an earlier MDM enrolment state.

### Why This Is The Most Defensible Conclusion

| # | Evidence | Analysis |
|---|---|---|
| 1 | EnrollmentStatus shows `ErrorDescription: The device is already enrolled in MDM.` | This is a direct product-reported cause, not an inferred theory |
| 2 | DeviceInfo shows `MDMEnrolled: Yes (previous enrolment)` | Confirms the blocking condition actually exists on the device |
| 3 | DeviceInfo shows `EnrolmentSource: Legacy (manual MDM enrolment, 2023-11-04)` | Identifies the historical source of the conflicting enrolment |
| 4 | AzureADJoined is `Yes` | Excludes missing identity join as the primary cause |
| 5 | Network endpoints are all reachable and no proxy is detected | Excludes endpoint reachability as the primary cause |
| 6 | M365 and Intune P1 licensing are present | Excludes missing licensing from the collected evidence |
| 7 | ComplianceEngine states `Reason: Enrolment not complete` | Shows compliance failure is downstream of the enrolment issue |
| 8 | PolicyManager shows `ProfilesApplied: 0 of 4` | Consistent with failed enrolment preventing policy application |

### Alternative Causes Considered And Ranked Lower

| Alternative Cause | Probability | Why Ranked Lower |
|---|---|---|
| Missing or incorrect licensing | Very low | Licensing is explicitly shown as present in the export and scope facts |
| Network or proxy issue | Very low | All required listed endpoints are reachable and no proxy is detected |
| Azure AD join failure | Very low | AzureADJoined is explicitly Yes |
| Policy profile misconfiguration | Low as a primary cause | Policy failure is present, but ComplianceEngine states enrolment not complete; policy appears downstream |
| TPM or Secure Boot readiness issue | Very low | TPM is Ready and Secure Boot is enabled |

---

## Section 4 — 5 Why Analysis

### Problem Statement
> Windows Autopilot enrolment failed for DESKTOP-FB099 and no assigned policy profiles applied.

### Why 1: Why did Autopilot enrolment fail?
**Answer:** Because the enrolment workflow detected that the device was already enrolled in MDM and terminated the Autopilot enrolment attempt.

**Evidence:**
- EnrollmentState = Failed
- ErrorCode = 0x80180014
- ErrorDescription = The device is already enrolled in MDM.

### Why 2: Why was the device already enrolled in MDM?
**Answer:** Because the device had a previous manual legacy MDM enrolment that still existed as an active or residual management relationship.

**Evidence:**
- MDMEnrolled = Yes (previous enrolment)
- EnrolmentSource = Legacy (manual MDM enrolment, 2023-11-04)

### Why 3: Why was the old legacy enrolment still present when the device was put through Autopilot?
**Answer:** Because the previous manual management record and/or device-side work or school connection had not been removed before reusing the device for an Autopilot-driven build or reprovision.

**Evidence:**
- The export shows both the old enrolment state and the new Autopilot attempt coexisting in the same failure set
- There is no evidence in the export that a clean de-registration or removal was performed before the new enrolment sequence

### Why 4: Why was pre-existing management not removed before the Autopilot attempt?
**Answer:** Because the rebuild or reprovisioning process did not enforce a preflight check for historical MDM enrolment records in Intune and on the endpoint before Autopilot was started.

**Evidence:**
- The incident only occurs because a legacy enrolment survived into a new Autopilot attempt
- The dataset shows healthy licensing, network, and join state, which indicates process hygiene around device cleanup is the more credible systemic gap

### Why 5: Why did the process not enforce a preflight cleanup check?
**Answer:** Because there was no mandatory operational control to identify and remove stale legacy MDM enrolments from reused devices before Autopilot redeployment.

**Systemic gap identified:**
- No mandatory pre-Autopilot cleanup step in the rebuild workflow
- No visible flag for previously manually enrolled devices that need de-enrolment before reuse
- No check to reconcile Intune managed device objects against the intended Autopilot record before redeployment

### Root Cause Statement
> The Autopilot failure was caused by a stale legacy manual MDM enrolment that remained associated with the device from 2023-11-04. The device was sent through a new Autopilot flow without first removing the prior management relationship, and the operational process did not contain a mandatory preflight control to catch and clean up that stale enrolment before redeployment.

---

## Section 5 — Remediation Actions

### Immediate Remediation

| Action | Detail | Access Requirement |
|---|---|---|
| Confirm stale managed device object | In Intune admin center, locate the existing managed device record and confirm it maps to the legacy manual enrolment | Admin center only |
| Preserve valid Autopilot registration | In Devices > Windows > Windows enrollment > Devices > Windows Autopilot devices, confirm the intended Autopilot device registration remains in place | Admin center only |
| Delete stale managed device object | Remove the obsolete Intune managed device record associated with the previous manual enrolment | Admin center only |
| Remove device-side work or school connection | Open Settings > Accounts > Access work or school and disconnect the old management relationship | Device access required |
| Restart and reset device | Restart, then wipe or reset to an Autopilot-ready OOBE state | Device access required |
| Rerun Autopilot | Start OOBE, connect to network, sign in with intended user, and allow Autopilot to complete | Device access required |

### Correct Order Of Operations
1. Confirm the correct Autopilot registration exists.
2. Delete the stale Intune managed device record.
3. Remove the old work or school connection from the endpoint.
4. Restart the device.
5. Reset or wipe the device to OOBE.
6. Rerun Autopilot.
7. Monitor for creation of a fresh managed device object and policy receipt.

---

## Section 6 — Verification Of Successful Recovery

### Success Criteria

| Check | Expected Result |
|---|---|
| New Intune managed device object | A fresh device object appears with current check-in time |
| Enrolment path | The device shows the intended current MDM enrolment, not the old legacy manual state |
| Autopilot status | The Autopilot record remains valid and associated with the expected profile |
| Policy application | Applied profile count increases beyond 0 and targeted policies begin landing |
| Compliance evaluation | Compliance can evaluate after enrolment completes |
| Device-side account state | Access work or school shows only the intended current management connection |

### Fastest Confirmation Test
- Confirm the old managed device object is gone from Intune.
- Confirm a new managed device object appears after OOBE sign-in.
- Confirm the new device checks in and begins receiving policy.
- Confirm the old legacy work or school connection is no longer present on the endpoint.

---

## Section 7 — Preventive Actions

### Process Prevention

| Preventive Action | Detail | Owner Type |
|---|---|---|
| Add mandatory preflight check | Before any device is reprovisioned with Autopilot, verify there is no stale manual/legacy managed device object in Intune | Endpoint engineering |
| Add device cleanup step | Require removal of obsolete Access work or school connections before a reused endpoint is wiped for Autopilot | Field engineering / deskside support |
| Preserve only valid Autopilot record | Validate the Windows Autopilot device record exists and remove only duplicate or stale objects, not the valid Autopilot registration | Endpoint engineering |
| Flag reused legacy devices | Mark previously manually enrolled devices in asset or rebuild workflow records so they always undergo cleanup before redeployment | Service management |
| Add rebuild checklist gate | Autopilot rebuild cannot proceed until Intune object cleanup and endpoint connection cleanup are both evidenced | Endpoint operations |

### Control Objective
Prevent devices with historical manual enrolment states from being sent into Windows Autopilot without first clearing the previous management relationship.

---

## Section 8 — Analyst Conclusion
This was a cleanly evidenced Autopilot enrolment conflict, not a network, licensing, Azure AD join, or generic policy-processing issue. The data shows a previously manually enrolled device was reused without removing its old MDM relationship. Autopilot then failed exactly where expected: at the enrolment stage, before policy and compliance could complete. The corrective action is to remove the stale managed device state in Intune and on the device, then rerun the endpoint through a clean Autopilot build. The preventive action is to make stale-enrolment detection and cleanup a mandatory preflight step for all reused devices.