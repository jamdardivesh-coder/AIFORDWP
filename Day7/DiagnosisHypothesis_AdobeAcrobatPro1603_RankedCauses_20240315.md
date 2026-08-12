# Ranked Hypothesis List: Adobe Acrobat Pro v23.6 — Intune Install Failure (MSI 1603)

**Date:** 2024-03-15  
**Author:** DWP Endpoint Engineering  
**Status:** Hypothesis only — root cause not yet confirmed  
**Source log period:** 2024-03-15 10:01:00 – 11:02:31  

---

## Key Observations Extracted from Log (no assumptions)

| Observation | Detail |
|---|---|
| Exit code | 1603 — fatal error during installation |
| Failure speed | 41 seconds (10:01:03 → 10:01:44); retry 43 seconds (11:01:48 → 11:02:31) |
| Install context | SYSTEM |
| Install command | `msiexec /i AcrobatPro.msi /quiet` — no transform, no log flag, no explicit path |
| Detection rule | Checks `HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0` — product is **Acrobat Pro**, not Reader |
| Detection result | Not found |
| Retry behaviour | Identical 1603 after 60 minutes — no change in outcome |
| Scope clue (external) | Overnight image update applied to **one pool only** — failure confined to that pool |

**Critical timing signal:** 41-second failure window indicates the MSI aborted during initialisation, before any significant file copy activity. This is characteristic of a conflict check or prerequisite validation failure, not a mid-install error.

---

## Ranked Hypotheses (most probable first)

---

### 1. Existing Adobe product conflict introduced by the overnight image update

**Why this fits the scope facts:**
- The overnight image update to one pool is the only confirmed environmental change. If Adobe Acrobat Reader (or a prior Acrobat version) was baked into the new base image, the Acrobat Pro MSI would detect a conflicting product code or upgrade code and abort with 1603.
- The detection rule targets `Adobe\Acrobat Reader\23.0` — the rule was written for Reader, which is strong evidence Reader is (or was expected to be) present on these machines.
- The 41-second failure is consistent with MSI conflict detection during initialisation, not a mid-install problem.
- The failure is scoped to one pool only, matching exactly the pool that received the image update.
- Deterministic on retry — the conflict persists because the image-installed Reader is still present.

**Single fastest check:**
On an affected endpoint, run:
```
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -like "*Adobe*"} | Select-Object DisplayName, DisplayVersion, InstallDate
```
If any Adobe Reader or prior Acrobat version appears, this hypothesis is confirmed.

---

### 2. MSI packaging or install command defect in the .intunewin payload

**Why this fits the scope facts:**
- The install command `msiexec /i AcrobatPro.msi /quiet` has no explicit working directory, no transform file (`/t`), and no prerequisite chain. Adobe Acrobat Pro enterprise deployments often require a transform or setup bootstrap.
- If expected payload files (CABs, Setup.ini, support folders) are missing from the Intune content or the working path is wrong, MSI fails with 1603 immediately.
- This cause is not weighted as highest because the failure is scoped to one pool only — a packaging defect would affect all pools equally. The overnight image update makes an environmental change more likely.

**Single fastest check:**
Extract the `.intunewin` package source and verify all referenced files are present. Then re-run the install command manually as SYSTEM with verbose logging:
```
msiexec /i "AcrobatPro.msi" /qn /L*v C:\Windows\Temp\AcrobatPro_debug.log
```
Inspect the first `Return value 3` block in the log.

---

### 3. Pending reboot state left by the overnight image update blocking the MSI

**Why this fits the scope facts:**
- Image updates frequently trigger a pending reboot flag (via `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations` or Windows Update). If the pool sessions were not fully rebooted post-image-update, Windows Installer may refuse to proceed and return 1603.
- Scoped to one pool only — aligns with the image update timing.
- Retry 60 minutes later still returns 1603 — a pending reboot flag persists until the device is rebooted.

**Single fastest check:**
On an affected endpoint, check for a pending reboot:
```
(Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue).PendingFileRenameOperations
```
Also check: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired`  
If either key has a value, force reboot and re-trigger the Intune deployment.

---

### 4. SYSTEM context path or permission constraint introduced by the image update

**Why this fits the scope facts:**
- Install runs as SYSTEM. If the overnight image update altered ACLs on `C:\Program Files`, `C:\ProgramData`, or the Intune IME cache directory, the MSI may fail when attempting to create directories or write files.
- 1603 from a permission boundary looks identical in the log to a conflict failure — it cannot be distinguished from this log alone.
- Scoped to one pool — an ACL change in the image would affect all sessions on that pool consistently.
- Weighted below causes 1 and 3 because ACL changes are less common image update outputs than software additions or pending reboots.

**Single fastest check:**
Check SYSTEM write access to the target install directory:
```
icacls "C:\Program Files\Adobe"
```
Also review the IME working directory: `C:\Program Files (x86)\Microsoft Intune Management Extension\Content\Staging`  
Any `DENY` entries or missing SYSTEM permissions confirm this hypothesis.

---

### 5. Security software or policy change in the image blocking MSI execution

**Why this fits the scope facts:**
- The overnight image update may have introduced updated AV/EDR signatures, a new AppLocker/WDAC policy, or changed security baseline settings that prevent MSI custom actions from executing.
- Security tools operating in SYSTEM context can intercept MSI operations and cause 1603 without leaving obvious trace in the Intune log alone.
- Weighted lowest in this ranked list because security tool interference tends to generate additional event log entries and would typically affect more deployment types, not just this one package.

**Single fastest check:**
On an affected endpoint, check Windows Application event log and security/AV logs at 10:01:03–10:01:44 for any block, quarantine, or denial events:
```
Get-WinEvent -LogName Application -MaxEvents 200 | Where-Object {$_.TimeCreated -gt "2024-03-15 10:00:00" -and $_.TimeCreated -lt "2024-03-15 10:05:00"} | Select-Object TimeCreated, Id, Message
```

---

## Summary Ranking Table

| Rank | Cause | Key weighting reason |
|---|---|---|
| 1 | Existing Adobe product conflict from overnight image update | Detection rule targets Reader; 41-sec abort; scoped to updated pool only |
| 2 | MSI packaging / install command defect | Generic 1603 vector; no transform or path in command |
| 3 | Pending reboot from overnight image update | Image updates commonly set reboot flags; persists across retries |
| 4 | SYSTEM context ACL/path constraint from image update | Consistent with scoped failure; requires log evidence to confirm |
| 5 | Security software or policy change in image | Plausible but least specific to this failure pattern |

---

## Current Position

Root cause is **not yet confirmed**. This document represents a ranked hypothesis list only.  
Causes 1 and 3 are most directly tied to the overnight image update timing clue and should be eliminated or confirmed first before investigating causes 2, 4, and 5.

## Next Step

Run the fastest check for Hypothesis 1 (installed Adobe product inventory) on one affected endpoint.  
If Reader or a prior Acrobat version is present, proceed directly to remediation.  
If not, check for a pending reboot (Hypothesis 3) before proceeding further.
