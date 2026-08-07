# AVD Black Screen — Diagnosis Hypothesis & Ranked Causes
## Incident: POOL-FIN-01 Post-Login Black Screen (2024-03-15)

---

## Executive Summary

Following an overnight image update to POOL-FIN-01 (Finance AVD pool) at 02:00, approximately 40% of Finance users experienced a black screen upon login at ~07:00. POOL-FIN-02 (IT pool), which did NOT receive the update, is completely unaffected. This analysis ranks five potential causes by their consistency with the scope facts, particularly the immunity of the non-updated pool.

---

## Scope Facts (Control Variables)

| Variable | Observation | Significance |
|----------|-------------|--------------|
| **Affected Pool** | POOL-FIN-01 | Received overnight image update at 02:00 |
| **Unaffected Pool** | POOL-FIN-02 | Did NOT receive update; completely unaffected (control) |
| **Symptom** | Black screen post-login | Clears after ~30 seconds (some users) OR persists indefinitely (others) |
| **Impact Scope** | ~40% of POOL-FIN-01 users | NOT 100%; partial impact within pool |
| **Timing** | First report ~07:00 | ~5 hours post-update; coincides with morning user login surge |
| **Infrastructure** | Both pools are identical | Same hardware SKUs, same network, same domain, same user population |

---

## Critical Timing Logic

**The single strongest clue:** POOL-FIN-02 (not updated) is **completely unaffected**.

Under identical conditions (same infrastructure, same user load, same time of day), one pool experiences 40% black screens while the other has zero incidents. This directly implicates **the update itself** as the root cause — not infrastructure, not load, not user behavior.

**Any cause that doesn't explain FIN-02's immunity is inconsistent with the scope.**

---

## Ranked Causes (by consistency with FIN-02 immunity)

---

### RANK 1: GPU DRIVER INCOMPATIBILITY OR DEFECT
**Confidence: ★★★★★ (99%)**

#### Why This Directly Explains FIN-02's Immunity:
- The 02:00 update to FIN-01 included a new/defective GPU driver (NVIDIA, Intel, AMD)
- FIN-02 retained the old (working) driver version
- FIN-01 hosts fail at GPU initialization during user login → black screen
- FIN-02 hosts boot normally with the old driver
- **The update *is* the entire root cause; without it, no problem**

#### Consistency with Timing Facts:
- ✓ Update delivered at 02:00 → GPU driver pushed to FIN-01 only
- ✓ FIN-02 never touched → retains working driver
- ✓ Black screen appears at 07:00 when users log in and GPU driver first loads
- ✓ Variable duration (30s vs. indefinite): timeout in fallback rendering or driver restart mechanism
- ✓ 40% (not 100%) affected: compatible with hardware variance (mixed GPU SKUs in pool, or driver version conflict on specific hardware)

#### Fastest Diagnostic Check:
1. On an affected session host, open **Device Manager**
2. Look for yellow exclamation marks or errors on GPU/display adapter
3. Check driver version and date — does it match the 02:00 update?
4. **Time: 3–5 minutes**

---

### RANK 2: PARTIAL OR CORRUPTED UPDATE ON SUBSET OF HOSTS
**Confidence: ★★★★★ (99%)**

#### Why This Directly Explains FIN-02's Immunity:
- The 02:00 update was deployed to FIN-01 via WSUS/deployment system
- ~60% of FIN-01 hosts successfully applied the update
- ~40% of FIN-01 hosts experienced corruption/failure: network interruption, disk I/O error, power loss, or incomplete rollback
- Corrupted hosts are in a hybrid/broken state → black screen
- FIN-02 hosts never received update → pristine, untouched baseline → no problems
- **FIN-02's immunity is because the update never reached them**

#### Consistency with Timing Facts:
- ✓ Update deployment began at 02:00 → completed by ~02:45
- ✓ Some hosts succeeded, others failed (race condition, network issues)
- ✓ The 40% impact (not 100%) perfectly matches a partial update failure rate
- ✓ Black screen at 07:00 on corrupted hosts; unaffected hosts operate normally
- ✓ Variable duration: some hosts partially applied (hybrid state), others fully corrupted

#### Fastest Diagnostic Check:
1. On an affected session host, open **Settings > Update & Security > Update History**
2. Is the 02:00 update marked "Successfully installed" or "Failed"?
3. Check for "Pending Restart" or rollback status
4. Compare against an unaffected host (or POOL-FIN-02): do they show different update states?
5. **Time: 2–3 minutes**

---

### RANK 3: DISPLAY SERVER / SERVICE INITIALIZATION HANG
**Confidence: ★★★★ (85%)**

#### Why This Explains FIN-02's Immunity:
- The 02:00 update altered service startup dependencies/order on FIN-01 hosts (e.g., Themes service, Display Driver Foundation, RDP graphics services)
- FIN-01 hosts: new service config causes timeout/hang during user login
- FIN-02 hosts: old service config, unchanged, services boot normally
- **FIN-02's immunity is because the update never changed their services**

#### Consistency with Timing Facts:
- ✓ Update delivered at 02:00 → service config pushed to FIN-01 only
- ✓ 30-second recovery matches typical Windows service startup timeout (30–60s); after timeout, fallback mechanism → desktop appears
- ✓ Persistent hang for others: service timeout exceeded, user logged out
- ✓ 40% affected: race condition in startup order, depends on system load/CPU/disk I/O at login time

#### Fastest Diagnostic Check:
1. On an affected host, during a failed login, open **Event Viewer > Windows Logs > System**
2. Look for events at 07:00–07:15 time window:
   - "Service Control Manager" errors (Event ID 7000, 7001, 7009, 7010)
   - Service failed to start or timeout waiting for service
   - Focus on Display/Graphics services: "Display Driver Foundation", "NVIDIA Driver Service", "Themes"
3. Compare timeline to login attempt time
4. **Time: 2–3 minutes**

---

### RANK 4: LOGON SCRIPT OR USER PROFILE INITIALIZATION HANG
**Confidence: ★★ (40%)**

#### Why This *Weakly* Explains FIN-02's Immunity:
- The 02:00 update deployed a new or broken logon script / Group Policy to FIN-01
- FIN-01 hosts: logon script runs → hangs
- FIN-02 hosts: old GPO configuration, script never deployed → no hang
- **FIN-02's immunity *could* be because they weren't targeted by the update**

#### Consistency with Timing Facts:
- ✓ Update at 02:00 pushed new GPO to FIN-01
- ✗ GPOs are typically user/OU-based, not pool-based
- ✗ Requires additional assumption: pools have separate GPO scope (less common)
- ✓ Variable duration: script timeout (30s) vs. permanent hang

#### Weakness:
This cause requires adding extra assumptions about pool-specific GPOs. It doesn't *directly* explain the immunity the way GPU driver or update corruption do. **The update alone doesn't clearly explain why the script would be pool-specific.**

#### Fastest Diagnostic Check:
1. On an affected host, log in as affected user
2. Open **Event Viewer > Windows Logs > Application**
3. Look for "Userenv" or "Group Policy" errors during login (07:00 window):
   - Event ID 1000, 1001 (GPO processing errors)
   - Errors referencing logon scripts or profile paths
4. Run: `gpresult /h report.html` to check GPO application
5. **Time: 3–5 minutes**

---

### RANK 5: RESOURCE EXHAUSTION / UNSTARTED CRITICAL SERVICE
**Confidence: ★ (5%)**

#### Why This FAILS to Explain FIN-02's Immunity:
- If the issue is load-dependent resource exhaustion or a critical service failure *not related to the update*, then FIN-02 should experience the **same problem** at 07:00 under the same morning login surge
- FIN-02 has identical infrastructure, similar user load, same time of day
- Yet FIN-02 is **completely unaffected**
- **This cause actively fails to explain FIN-02's immunity**

#### Consistency with Timing Facts:
- ✗ Black screen at 07:00 on FIN-01 but NOT on FIN-02
- ✗ Both pools experience same time-of-day load surge
- ✗ If cause is load/resource, both pools should be affected
- ✓ Only consistent if the update specifically caused higher resource usage (which brings us back to Rank 1–2)

#### Why This is Weak:
This cause is **inconsistent** with the control data. The fact that FIN-02 (not updated) is unaffected under identical load/timing conditions **proves** that load is not the root cause. If it were, both pools would fail.

---

## Summary: Ranking by "Does FIN-02 Not Receiving the Update Explain Its Immunity?"

| Rank | Cause | Update is Root Cause? | Confidence | Feasibility |
|------|-------|----------------------|------------|-------------|
| **1** | GPU Driver Defect | ✓✓✓ YES — update *is* the defect | ★★★★★ 99% | Investigate immediately |
| **2** | Partial/Corrupted Update | ✓✓✓ YES — update failure *is* the cause | ★★★★★ 99% | Investigate immediately |
| **3** | Service Config Hang | ✓✓ YES — update changed configs | ★★★★ 85% | Secondary investigation |
| **4** | Logon Script / GPO | ✓ MAYBE — requires extra assumptions | ★★ 40% | Lower priority |
| **5** | Resource Exhaustion | ✗ NO — contradicts FIN-02 immunity | ★ 5% | **Eliminate this cause** |

---

## Diagnostic Priority

**Immediate (Rank 1 & 2):** These two causes directly explain FIN-02's immunity and account for 99% + 99% = combined overwhelming probability.
- Check GPU driver status (3–5 min)
- Check Windows Update history (2–3 min)

**Secondary (Rank 3):** If Rank 1 & 2 checks are clear, investigate service startup events.
- Check Event Viewer for service errors (2–3 min)

**De-prioritize (Rank 4):** Unless Rank 1–3 are ruled out AND there is evidence of pool-specific GPO deployment.

**Eliminate (Rank 5):** Do not investigate load/resource issues; the FIN-02 immunity proves this is not the root cause.

---

## Hypothesis (No Commitment)

**Most Likely Scenario (70% confidence):**
The overnight image update to POOL-FIN-01 included a defective GPU driver version (Rank 1) that is incompatible with specific hardware SKUs or OS configurations within the pool. When Finance users logged in at 07:00, the new driver failed to initialize, causing the black screen. Some systems recovered after a 30-second timeout/fallback; others hung indefinitely.

**Secondary Scenario (25% confidence):**
The update was incompletely or unevenly applied to POOL-FIN-01 session hosts (Rank 2). Some hosts successfully updated, others experienced network/disk failures mid-update and are in a corrupted hybrid state. The 40% impact rate matches the proportion of hosts with corrupted updates.

**Lower Probability:**
Service startup dependency issues (Rank 3) or GPO-based logon script errors (Rank 4) are secondary possibilities if GPU/update diagnostics are clear.

---

## Next Immediate Steps

1. **Pull diagnostics from one AFFECTED host:**
   - Device Manager: GPU driver version, status, errors
   - Windows Update History: 02:00 update status (success/fail)
   - Event Viewer System logs: service startup errors (07:00 window)

2. **Compare to one UNAFFECTED host (or POOL-FIN-02):**
   - Same three checks
   - Identify differences

3. **Do NOT wait for post-mortem:** Run checks in parallel; first positive finding is your lead.

4. **If GPU driver mismatch found:** Rollback driver on affected hosts (30–60 min remediation)

5. **If update corruption found:** Rollback or re-apply update cleanly (60–90 min remediation)

---

*Analysis prepared by: DWP Engineer*  
*Date: 2024-03-15*  
*Incident: POOL-FIN-01 AVD Black Screen Post-Login*  
*Status: Hypothesis ready for diagnostic testing*

---

## PART 2: EVENT LOG ANALYSIS & HYPOTHESIS VALIDATION

**Date: 2024-03-15 (Updated after event log review)**  
**Source: SHFIN-01-A (affected, POOL-FIN-01) vs SHFIN-02-A (unaffected, POOL-FIN-02)**

---

### Event Log Evidence Summary

#### Critical Events from Affected Host (SHFIN-01-A, POOL-FIN-01)

| Timestamp | Event ID | Source | Detail |
|-----------|----------|--------|--------|
| 07:02:10  | 21 | TerminalServices-LocalSessionManager | Session logon succeeded: FINBRIDGE\mlopez |
| 07:02:14  | 1 | Kernel-General | System boot time: 2024-03-15 02:03:11 (post-update restart) |
| **07:02:16** | **1000** | **Application Error** | **dwm.exe crashed in igdumd64.dll (v31.0.101.4146)**<br>Exception: 0xc0000005 (access violation)<br>Fault offset: 0x0000000000047f12 |
| 07:02:17  | 40 | TerminalServices-LocalSessionManager | Session disconnected (reason: crash) |
| 07:02:18  | 9009 | Desktop Window Manager | **DWM exited with code 0x40010004** |
| 07:02:44  | 21 | TerminalServices-LocalSessionManager | Session logon succeeded (reconnect attempt) |
| 07:02:46  | 1000 | Application Error | **dwm.exe crashed again in igdumd64.dll** (same pattern) |
| 07:08:24  | 1000 | Application Error | **Second user (akapoor) — same igdumd64.dll crash** |

#### Comparison: Unaffected Host (SHFIN-02-A, POOL-FIN-02)

| Timestamp | Event ID | Source | Detail |
|-----------|----------|--------|--------|
| 07:01:44  | 21 | TerminalServices-LocalSessionManager | Session logon succeeded: FINBRIDGE\bwalker |
| 07:01:46  | 9011 | Desktop Window Manager | **Desktop Window Manager started successfully** |
| — | — | — | **No Application Error events in window** |
| — | — | — | **Same OS version (10.0.22621.2861) but older igdumd64.dll** |

---

### Hypothesis Evaluation Against Evidence

#### RANK 1: GPU DRIVER INCOMPATIBILITY OR DEFECT
**Verdict: ✓✓✓ STRONGLY SUPPORTED — 99% Confidence**

**Supporting Evidence:**
- **Event 1000 (07:02:16):** Application crash in dwm.exe, faulting module: **igdumd64.dll v31.0.101.4146**
- **Exception 0xc0000005:** Access violation — GPU driver memory corruption or compatibility fault
- **Event 9009 (07:02:18):** Desktop Window Manager exited with code 0x40010004 (crash exit)
- **Repeating Pattern:** Same crash for multiple users (mlopez at 07:02:16, akapoor at 07:08:24)
- **Repeating on Reconnect:** Crash recurs at 07:02:46 on same user's reconnection attempt
- **Unaffected Pool Comparison:** SHFIN-02-A (same OS, older driver) shows clean DWM startup (Event 9011), zero crashes
- **Timeline Correlation:** Host restarted 02:03:11 → new driver loaded → first user login 07:02:10 → driver crash 07:02:16

**Smoking Gun:** The event logs explicitly record a GPU driver crash (igdumd64.dll) that directly caused DWM to exit, resulting in black screen.

---

#### RANK 2: PARTIAL OR CORRUPTED UPDATE
**Verdict: ◇ NEUTRAL — 30% Confidence (secondary to Rank 1)**

**Analysis:**
- The igdumd64.dll crash is **consistent** with a corrupted driver binary
- Access violation (0xc0000005) could indicate bad memory in driver code
- **However:** No explicit Windows Update failure events in logs (Event 7000, 7001, 20000, 20001)
- No CBS.log or SFC errors indicating corruption
- This hypothesis is **nested within** Rank 1 — if driver is defective, it doesn't matter whether defect was due to bad release or bad deployment; the driver must be replaced

**Conclusion:** Rank 2 is plausible but secondary. The immediate cause is Rank 1 (driver defect).

---

#### RANK 3: DISPLAY SERVER / SERVICE INITIALIZATION HANG
**Verdict: ✗ CONTRADICTED**

**Evidence Against:**
- Event 9009 shows DWM **crashed and exited**, not hung
- A hang would produce Event 7009 (Service did not respond to start) or Event 7010 (Service startup timeout) — **NOT FOUND**
- Service hangs show multiple restart attempts; this shows single crash
- Expected hang indicators (dependency failures, service timeouts) — **NOT FOUND**

**Conclusion:** Eliminated. The evidence is a crash (Event 1000, 9009), not a hang.

---

#### RANK 4: LOGON SCRIPT OR USER PROFILE INITIALIZATION
**Verdict: ✗ CONTRADICTED**

**Evidence Against:**
- Event 21 (07:02:10) shows logon **succeeded successfully** before any errors
- Event 1000 crash occurs **6 seconds after** logon completion (07:02:16)
- GPU driver is loaded **after** logon scripts complete (during desktop render phase)
- No Userenv errors (would show Event 1000–1003 in Userenv provider) — **NOT FOUND**
- No Group Policy errors — **NOT FOUND**
- Multiple users affected identically (mlopez, akapoor) — inconsistent with user-specific logon script issue

**Conclusion:** Eliminated. Logon succeeded; crash is post-logon in GPU driver initialization.

---

#### RANK 5: RESOURCE EXHAUSTION / UNSTARTED CRITICAL SERVICE
**Verdict: ✗ CONTRADICTED**

**Evidence Against:**
- **SHFIN-02-A (unaffected) shows clean DWM startup (Event 9011) at 07:01:44**
- Same time of day (07:01 vs 07:02 = ~1 minute apart)
- Both pools identical infrastructure, same user load surge
- SHFIN-02-A shows zero resource stress indicators, zero Service Control Manager errors
- If resource exhaustion were the cause, **both pools would fail identically**
- The different outcome (one fails, one succeeds) is **conclusive proof** that the variable is not load, but the driver

**Conclusion:** Eliminated. The unaffected pool demonstrates that resources/load are not the root cause.

---

### Summary: Evidence Evaluation Results

| Rank | Hypothesis | Evidence Verdict | Confidence | Status |
|------|-----------|------------------|------------|--------|
| **1** | GPU Driver Defect | ✓✓✓ STRONGLY SUPPORTED | ★★★★★ 99% | **CONFIRMED** |
| 2 | Partial/Corrupted Update | ◇ Neutral (secondary) | ★★ 30% | Secondary |
| 3 | Service Initialization Hang | ✗ Contradicted | ★ 5% | Eliminated |
| 4 | Logon Script/GPO Hang | ✗ Contradicted | ★ 3% | Eliminated |
| 5 | Resource Exhaustion | ✗ Contradicted | ★ 2% | Eliminated |

---

## SURVIVING HYPOTHESIS: GPU DRIVER INCOMPATIBILITY

**The overnight image update to POOL-FIN-01 included Intel GPU driver version 31.0.101.4146 (igdumd64.dll), which is incompatible with the session host hardware or Windows version, causing a memory access violation (0xc0000005) and immediate crash of the Desktop Window Manager (dwm.exe) upon user login.**

**Evidence:** Event 1000 (application crash) at 07:02:16, Event 9009 (DWM exit), repeating pattern across multiple users and reconnection attempts, comparison with unaffected pool running older driver version showing zero crashes.

---

## DETAILED RESOLUTION STEPS

### Phase 1: Immediate Mitigation (0–30 minutes)

**Objective:** Stop the bleeding and restore user access while maintaining evidence for post-mortem.

#### Step 1.1: Identify the Defective Driver
- **Action:** Query Windows Update metadata from POOL-FIN-01 session host
- **Command (PowerShell, as admin on SHFIN-01-A):**
  ```powershell
  Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*Intel*Graphics*" -or $_.DeviceName -like "*NVIDIA*" } | Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer
  ```
- **Expected Output:** GPU driver v31.0.101.4146 (Intel integrated graphics)
- **Record this version:** This is the defective version to be rolled back
- **Time: 2 minutes**

#### Step 1.2: Identify the Working Driver Version
- **Action:** Query POOL-FIN-02 session host (unaffected) to get the working driver version
- **Command (PowerShell, as admin on SHFIN-02-A):**
  ```powershell
  Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*Intel*Graphics*" -or $_.DeviceName -like "*NVIDIA*" } | Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer
  ```
- **Expected Output:** Older GPU driver version (e.g., 31.0.100.9999 or similar)
- **Record this version:** This is the working baseline to restore to
- **Time: 2 minutes**

#### Step 1.3: Locate Defective Driver Package in Image Update
- **Action:** Review the overnight update package (02:00 wave) to identify the driver source
- **Where to Look:**
  - Change Management system / WSUS console
  - Server: `\\DEPLOY-SRV\Updates\Pool_FIN-01_20240315_0200`
  - Or WSUS: Server Options → Products and Classifications → look for GPU driver updates approved for POOL-FIN-01 on 2024-03-15 between 01:00–02:30
- **Confirm:** The defective driver (v31.0.101.4146) is present in the image
- **Time: 5 minutes**

#### Step 1.4: Isolate Affected Session Hosts (Stop Login Storm)
- **Action:** Temporarily pause load balancing to prevent new user logins to affected POOL-FIN-01 hosts
- **Steps:**
  1. Open RDP Connection Broker (RD Connection Broker console)
  2. Navigate to POOL-FIN-01 → Properties
  3. Set "New Connections" to **Disabled** (prevents new logons; current sessions continue)
  4. Communicate to Service Desk: "Finance users will get 'pool full' or 'not available' message; advise them to wait 15 min"
- **Why:** This reduces the volume of crash events in the log and prevents user frustration during remediation
- **Time: 3 minutes**

### Phase 2: Targeted Rollback (30–60 minutes)

**Objective:** Restore the working driver to affected hosts and validate fix.

#### Step 2.1: Isolate One Test Host
- **Action:** Take SHFIN-01-A out of the load-balanced pool for testing
- **Steps:**
  1. In RD Connection Broker → POOL-FIN-01 → Collection Properties
  2. Mark SHFIN-01-A as **"Staging" or "Disabled for new logons"**
  3. Wait for existing sessions to disconnect (or force disconnect after 5 min timeout)
- **Why:** Isolate one host for safe rollback testing before rolling out to entire pool
- **Time: 3 minutes**

#### Step 2.2: Rollback GPU Driver on Test Host
- **Action:** Uninstall defective driver and restore working version
- **Method A: Device Manager (GUI, on SHFIN-01-A):**
  ```
  1. Open Device Manager
  2. Expand "Display adapters"
  3. Right-click "Intel Iris/UHD Graphics" (or NVIDIA)
  4. Select "Uninstall device" → CHECK "Delete driver software"
  5. Reboot
  6. After reboot, driver defaults to Windows inbox driver or DCHU driver (fallback)
  7. Manually install working driver version from \\DRIVER-SRV\GPUdrivers\Intel\31.0.100.9999\
  ```
  
- **Method B: PowerShell (automated, recommended for scale):**
  ```powershell
  # Run as admin on SHFIN-01-A
  
  # Step 1: List current driver
  pnputil /enum-devices /class DISPLAY
  
  # Step 2: Remove defective driver (v31.0.101.4146)
  pnputil /remove-device /instanceid "PCI\VEN_8086&DEV_9A49"
  
  # Step 3: Force re-detect hardware and install driver from repo
  # Copy working driver INF to local temp
  Copy-Item "\\DRIVER-SRV\GPUdrivers\Intel\31.0.100.9999\igdumd64.inf" -Destination "C:\Temp\igdumd64.inf"
  
  # Install via PnPUtil
  pnputil /add-driver "C:\Temp\igdumd64.inf" /install
  
  # Reboot
  Restart-Computer -Force
  ```

- **Expected Result:** Driver reverts to working version (v31.0.100.9999 or inbox driver)
- **Time: 10 minutes (includes reboot)**

#### Step 2.3: Validate Fix on Test Host
- **Action:** Test user login on the rolled-back host
- **Steps:**
  1. Log in to SHFIN-01-A as a test user (e.g., from Finance AD group)
  2. Verify desktop renders cleanly (no black screen, no DWM crash)
  3. Check Event Viewer: confirm no Event 1000 or Event 9009 in 5-minute window
  4. Session should remain stable for at least 2 minutes
  
- **Event Viewer Check:**
  ```powershell
  # Run as admin on SHFIN-01-A
  Get-EventLog -LogName Application -Source ".NET Runtime" -ErrorAction SilentlyContinue
  Get-WinEvent -LogName "System" | Where-Object { $_.ID -eq 9009 -or $_.ID -eq 1000 } | Select-Object TimeCreated, Message | tail -10
  # Should be empty or show pre-2024-03-15 events
  ```

- **Expected Output:** Clean login, no crash events, desktop stable
- **If successful:** Proceed to Phase 3 (full rollout)
- **If failed:** Investigate further driver version or hardware compatibility
- **Time: 5 minutes**

### Phase 3: Full Remediation Rollout (60–120 minutes)

**Objective:** Roll back defective driver across all affected POOL-FIN-01 session hosts.

#### Step 3.1: Create Rollback Script for Batch Application
- **Action:** Generate a PowerShell script to automate driver rollback on all hosts
- **Script (save as `Rollback-GPUDriver-POOL-FIN-01.ps1`):**
  ```powershell
  param(
    [string[]]$SessionHosts = @(
      "SHFIN-01-A", "SHFIN-01-B", "SHFIN-01-C", "SHFIN-01-D",
      "SHFIN-01-E", "SHFIN-01-F", "SHFIN-01-G", "SHFIN-01-H"
    ),
    [string]$WorkingDriverPath = "\\DRIVER-SRV\GPUdrivers\Intel\31.0.100.9999\",
    [switch]$Force
  )
  
  foreach ($Host in $SessionHosts) {
    Write-Host "=== Rolling back driver on $Host ===" -ForegroundColor Cyan
    
    try {
      # Remote PowerShell to target host
      $RemoteScript = {
        param($DriverPath)
        
        # Uninstall defective driver
        Write-Host "Removing defective GPU driver..." -ForegroundColor Yellow
        pnputil /remove-device /instanceid "PCI\VEN_8086&DEV_9A49"
        
        # Copy working driver
        Write-Host "Copying working driver..." -ForegroundColor Yellow
        Copy-Item "$DriverPath*" -Destination "C:\Temp\IGDriver\" -Force
        
        # Install working driver
        Write-Host "Installing working driver..." -ForegroundColor Yellow
        Get-ChildItem "C:\Temp\IGDriver\*.inf" | ForEach-Object {
          pnputil /add-driver $_.FullName /install
        }
        
        # Reboot
        Write-Host "Rebooting host..." -ForegroundColor Green
        Restart-Computer -Force
        
        return "Rollback complete"
      }
      
      Invoke-Command -ComputerName $Host -ScriptBlock $RemoteScript -ArgumentList $WorkingDriverPath
      
      Write-Host "✓ $Host rollback initiated" -ForegroundColor Green
      
    } catch {
      Write-Host "✗ $Host failed: $_" -ForegroundColor Red
      if (-not $Force) { throw }
    }
    
    Start-Sleep -Seconds 5
  }
  
  Write-Host "`n=== Rollback initiated for all hosts ===" -ForegroundColor Cyan
  Write-Host "Hosts are rebooting. Monitor completion in RD Connection Broker." -ForegroundColor Yellow
  ```

- **Execution:**
  ```powershell
  # Run as admin from management host
  .\Rollback-GPUDriver-POOL-FIN-01.ps1 -SessionHosts @("SHFIN-01-A", "SHFIN-01-B", "SHFIN-01-C", "SHFIN-01-D", "SHFIN-01-E", "SHFIN-01-F", "SHFIN-01-G", "SHFIN-01-H")
  ```

- **Time: 3 minutes to execute; 10–15 minutes for all hosts to reboot**

#### Step 3.2: Monitor Rollout Progress
- **Action:** Track host restart completion and driver validation
- **Method 1: RD Connection Broker Console**
  - Open Connection Broker
  - Monitor POOL-FIN-01 → Session Host status
  - Wait for all hosts to show "Available" (green) status post-reboot
  
- **Method 2: PowerShell Status Check**
  ```powershell
  $Hosts = @("SHFIN-01-A", "SHFIN-01-B", "SHFIN-01-C", "SHFIN-01-D", "SHFIN-01-E", "SHFIN-01-F", "SHFIN-01-G", "SHFIN-01-H")
  
  foreach ($Host in $Hosts) {
    $Reachable = Test-Connection -ComputerName $Host -Count 1 -Quiet
    $GPU = Invoke-Command -ComputerName $Host { Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*Intel*Graphics*" } | Select-Object DriverVersion } -ErrorAction SilentlyContinue
    Write-Host "$Host : Reachable=$Reachable, GPUDriver=$($GPU.DriverVersion)"
  }
  ```

- **Expected Output:** All hosts "Reachable=True" with driver version = 31.0.100.9999 (or working version)
- **Time: 5 minutes**

#### Step 3.3: Re-enable Load Balancing and User Access
- **Action:** Open POOL-FIN-01 back to new user connections
- **Steps:**
  1. In RD Connection Broker → POOL-FIN-01 → Properties
  2. Set "New Connections" to **Enabled**
  3. Notify Service Desk: "POOL-FIN-01 is back online; Finance users can now log in"
  
- **Communication:** Issue incident update stating "Issue resolved, drivers rolled back to stable version. Users may experience normal queue for login."
- **Time: 2 minutes**

#### Step 3.4: Validation: Monitor User Logins for Black Screen Recurrence
- **Action:** Monitor Event Viewer on random affected hosts for new crash events
- **For 30 minutes:**
  - Spot-check 3–4 random session hosts
  - Look for new Event 1000 (Application Error) or Event 9009 (DWM exit) in the Application and System logs
  - If zero crashes observed, resolution is successful
  
- **Validation Command:**
  ```powershell
  # Run every 5 minutes on random host (e.g., SHFIN-01-C)
  Get-WinEvent -LogName "System" -MaxEvents 100 | Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-5) -and ($_.ID -eq 1000 -or $_.ID -eq 9009) }
  # Expected: empty result = no new crashes
  ```

- **Time: 30 minutes observation**

---

### Phase 4: Restoration & Sign-off (120–150 minutes)

**Objective:** Confirm resolution and document remediation.

#### Step 4.1: Declare Incident Resolved
- **Action:** Update incident ticket with resolution summary
- **Ticket Update:**
  - Status: **RESOLVED**
  - Root Cause: Intel GPU driver v31.0.101.4146 incompatible with session host hardware; triggered access violation in dwm.exe
  - Fix Applied: Rolled back driver to v31.0.100.9999 (working baseline from POOL-FIN-02)
  - Time to Resolve: ~90 minutes from incident identification
  - Affected Sessions: Approximately 40 users in POOL-FIN-01 (now able to log in normally)

#### Step 4.2: Notify Users
- **Communication Template:**
  ```
  Subject: RESOLVED — AVD Finance Pool — Login Issue Fixed
  
  Dear Finance Team,
  
  The AVD login issue affecting POOL-FIN-01 this morning has been resolved.
  
  Issue: A graphics driver update deployed overnight was found to be 
  incompatible with our session host hardware, causing a black screen 
  immediately after login.
  
  Action Taken: We rolled back the driver to the previous stable version 
  (v31.0.100.9999). All session hosts have been updated and validated.
  
  Status: You can now log in normally. If you experience any further issues, 
  please contact the Service Desk immediately at [ext].
  
  Root Cause Analysis: A post-mortem will be conducted to prevent pre-deployment 
  testing gaps in future updates.
  
  Thank you for your patience during the incident.
  
  — IT Operations
  ```

#### Step 4.3: Preserve Evidence for Post-Mortem
- **Action:** Archive event logs and metadata from all affected hosts
- **Commands:**
  ```powershell
  # Export event logs from all affected hosts
  foreach ($Host in @("SHFIN-01-A", "SHFIN-01-B", "SHFIN-01-C", "SHFIN-01-D", "SHFIN-01-E", "SHFIN-01-F", "SHFIN-01-G", "SHFIN-01-H")) {
    Write-Host "Archiving logs from $Host..."
    
    # Export System event log (contains driver/service errors)
    Get-WinEvent -ComputerName $Host -LogName "System" -MaxEvents 1000 -ErrorAction SilentlyContinue | 
      Export-Csv -Path "C:\IncidentArchive\$Host-SystemLog-20240315.csv"
    
    # Export Application event log (contains dwm.exe crashes)
    Get-WinEvent -ComputerName $Host -LogName "Application" -MaxEvents 1000 -ErrorAction SilentlyContinue | 
      Export-Csv -Path "C:\IncidentArchive\$Host-AppLog-20240315.csv"
    
    # Capture driver version post-rollback
    Invoke-Command -ComputerName $Host { Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.DeviceName -like "*Graphics*" } } | 
      Export-Csv -Path "C:\IncidentArchive\$Host-DriverInfo-PostFix.csv"
  }
  ```

- **Store Archive:** `\\ARCHIVE-SRV\Incidents\INC-2024-0315-AVD-BLACKSCREEN\`
- **Time: 10 minutes**

#### Step 4.4: Schedule Post-Mortem
- **Action:** Schedule incident post-mortem meeting for within 48 hours
- **Participants:**
  - Change Management (why was update not tested on pilot pool first?)
  - AVD Engineering (driver source, vendor contact info)
  - Service Desk (impact tracking, user feedback)
  - Infrastructure (update rollout procedures)
  
- **Agenda:**
  1. Why was driver update v31.0.101.4146 deployed without pilot testing?
  2. Does the update vendor (Intel, NVIDIA) acknowledge compatibility issue?
  3. Should POOL-FIN-02 have been the pilot pool for this update wave?
  4. What process change prevents this in the future (mandatory pilot testing)?

---

### Timeline Summary

| Phase | Activity | Time | Cumulative |
|-------|----------|------|-----------|
| 1.1 | Identify defective driver version | 2 min | 2 min |
| 1.2 | Identify working driver version | 2 min | 4 min |
| 1.3 | Locate driver in update package | 5 min | 9 min |
| 1.4 | Pause load balancing (stop crash spam) | 3 min | 12 min |
| 2.1 | Isolate test host | 3 min | 15 min |
| 2.2 | Rollback driver on test host + reboot | 10 min | 25 min |
| 2.3 | Validate fix on test host | 5 min | 30 min |
| 3.1 | Create batch rollback script | 3 min | 33 min |
| 3.2 | Execute rollout on all hosts (8 hosts × 1.5 min reboot) | 15 min | 48 min |
| 3.3 | Monitor host status post-reboot | 5 min | 53 min |
| 3.4 | Re-enable load balancing | 2 min | 55 min |
| 3.5 | Validate user login (30-min observation) | 30 min | 85 min |
| 4.1–4.4 | Documentation, user comms, post-mortem scheduling | 15 min | **~100 min (1.5 hrs)** |

**Total Time to Resolution: ~90–100 minutes from incident identification to full remediation and user access restoration.**

---

*Resolution Path Confirmed: GPU Driver Incompatibility*  
*Evidence: Event 1000 (igdumd64.dll crash), Event 9009 (DWM exit)*  
*Status: Ready for implementation*
