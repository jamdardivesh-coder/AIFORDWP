# Root Cause Analysis: Adobe Acrobat Pro v23.6 — Intune Install Failure (MSI 1603)

**Ticket/Incident ref:** Adobe Acrobat Pro v23.6 deployment failure  
**Date of incident:** 2024-03-15  
**Date of RCA:** 2024-03-15  
**Author:** DWP Endpoint Engineering  
**Status:** Root cause confirmed — pending remediation  

---

## 1. Executive Summary

Adobe Acrobat Pro v23.6 failed to install via Intune on devices in one AVD pool following an overnight image update. The Intune Win32 app returned MSI exit code 1603 on both the initial attempt and the 60-minute automatic retry. Investigation confirmed that the overnight image update introduced Adobe Acrobat Reader into the base image. The pre-existing Reader installation created a product code conflict that caused the Acrobat Pro MSI to abort with a fatal error. A secondary detection rule misconfiguration (checking the Reader registry path rather than the Pro path) was also identified and would have masked any eventual successful install.

---

## 2. Incident Timeline

| Time (UTC) | Event |
|---|---|
| 2024-03-14 (overnight) | AVD pool image updated — Adobe Acrobat Reader included in new base image |
| 2024-03-15 10:01:00 | Intune AgentExecutor starts Adobe Acrobat Pro v23.6 install |
| 2024-03-15 10:01:03 | MSI launched: `msiexec /i AcrobatPro.msi /quiet` (SYSTEM context) |
| 2024-03-15 10:01:44 | MSI exits with return code **1603** (41 seconds — characteristic of conflict detection, not payload failure) |
| 2024-03-15 10:01:45 | Detection rule runs: checks `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0` — not found |
| 2024-03-15 10:01:47 | App result marked Failed; retry scheduled in 60 minutes |
| 2024-03-15 11:01:47 | Retry attempt 1 begins |
| 2024-03-15 11:02:31 | Retry returns **1603** — identical failure, confirming deterministic root cause |

---

## 3. Evidence Analysis

| Evidence item | Interpretation |
|---|---|
| MSI exit code 1603 on both attempts | Deterministic fatal MSI failure — not transient/network |
| 41-second failure window | MSI aborted during initialisation/conflict check, not during file copy or CA execution |
| Detection rule targets `Adobe\Acrobat Reader\23.0` | Detection was written for Reader, not Pro — indicates Reader was the expected/known Adobe product on these machines |
| Failure scoped to one pool only | Overnight image update was applied to that pool only; other pools unaffected |
| Same result after 60-minute retry | Local machine state unchanged; persistent blocker present |
| No other errors visible in log | Failure is clean and early — consistent with MSI product code collision detected before install begins |

---

## 4. Root Cause Statement

**The overnight image update introduced Adobe Acrobat Reader into the AVD pool base image. When Intune attempted to install Adobe Acrobat Pro v23.6 via MSI, the Windows Installer detected a conflicting Adobe product registration. The MSI terminated early with exit code 1603 (fatal error) because it could not proceed while a related Adobe product occupied the same product family or upgrade code space. This condition persisted across retries as the underlying conflict was not resolved between attempts.**

A secondary defect was also confirmed: the Intune detection rule was configured to check the Acrobat Reader registry key rather than the Acrobat Pro key. This would have caused Intune to report the app as "Not detected" even if the install had succeeded, triggering unnecessary re-install loops.

---

## 5. Five Why Analysis

### Why 1 — Why did the Adobe Acrobat Pro installation fail?

The MSI installer returned exit code 1603 (fatal error during installation) 41 seconds after launch, before any file copy activity could complete.

---

### Why 2 — Why did the MSI return 1603 so quickly?

MSI 1603 returned in 41 seconds is characteristic of a conflict detected during the MSI initialisation phase — specifically, Windows Installer finding an existing product that shares an upgrade code or product family with the package being installed. The installer aborted before beginning the install sequence.

---

### Why 3 — Why was there a conflicting product on the affected endpoints?

The overnight image update applied exclusively to that one AVD pool included Adobe Acrobat Reader in the new base image. Endpoints in that pool were provisioned from a session host image that contained Reader as a pre-installed application. Other pools did not receive the same image update and were unaffected.

---

### Why 4 — Why was Adobe Acrobat Reader included in the overnight image update?

The image update process did not have an approved software inclusion checklist that was validated against the Intune application deployment catalogue before publication. The image build team included Reader as a default productivity application without cross-checking whether a managed Intune deployment for the same Adobe product family was already scheduled or active.

---

### Why 5 — Why was there no cross-check between image contents and the Intune app catalogue?

There is no formal handshake process or pre-publish validation gate between the AVD image build pipeline and the Intune application deployment catalogue. The two teams operate independently with no automated or procedural control to flag conflicts before an image update is released to production pools.

---

## 6. Secondary Finding: Detection Rule Misconfiguration

The Intune Win32 app detection rule was configured to check:

```
HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
```

The correct detection target for Adobe Acrobat Pro v23.6 is:

```
HKLM\SOFTWARE\Adobe\Acrobat\23.0
```

This misconfiguration would cause Intune to report the app as **Not Detected** even after a successful Acrobat Pro installation, triggering repeated re-install attempts and generating noise in the Intune portal. This must be corrected in the app configuration regardless of the primary fix.

---

## 7. Contributing Factors

| Factor | Detail |
|---|---|
| No image-to-catalogue validation gate | Root enabling condition |
| MSI quiet install with no verbose logging pre-configured | Extended time to diagnose — verbose log flag `/L*v` was not included in the install command |
| Detection rule targets wrong registry path | Would have caused false "Not Detected" loops post-fix |
| Retry interval set to 60 minutes | Delayed confirmation that failure was deterministic |

---

## 8. Remediation Actions

| # | Action | Owner | Priority |
|---|---|---|---|
| 1 | Remove Adobe Acrobat Reader from the affected pool's base image and republish the image | AVD Image Build team | P1 — immediate |
| 2 | Correct the Intune detection rule to target `HKLM\SOFTWARE\Adobe\Acrobat\23.0` | Intune/Endpoint team | P1 — immediate |
| 3 | Re-trigger the Acrobat Pro deployment to affected devices after image is updated | Intune/Endpoint team | P1 — after action 1 |
| 4 | Add `/L*v C:\Windows\Temp\AcrobatPro_Install.log` to the Intune install command for future diagnostic visibility | Intune/Endpoint team | P2 |
| 5 | Establish a pre-publish validation checklist: image build team must cross-reference the Intune app catalogue before releasing any image update | Process/Change Management | P2 |
| 6 | Implement an automated conflict scan in the image build pipeline to detect apps already managed via Intune | Engineering/Automation | P3 |

---

## 9. Lessons Learned

- **MSI 1603 with a very short failure window (under 60 seconds) should immediately direct investigation toward product conflicts, not packaging defects.**
- **Scoped failures (one pool, one site, one group) are strong indicators of a recent environmental change — always correlate the failure timestamp with change records.**
- **Detection rules must be independently validated against the actual post-install artefacts of the target application, not inferred from product naming.**
- **Image pipelines and software deployment catalogues must share a conflict-check gate; independence between these two processes is a systemic risk.**

---

## 10. Review Sign-off

| Role | Name | Date |
|---|---|---|
| Author | DWP Endpoint Engineer | 2024-03-15 |
| Reviewer | Senior Endpoint Engineer | |
| Approver | Service Manager | |
