# KB — L2/L3 Diagnosis and Recovery: AVD Black Screen Post-Login (POOL-FIN-01)
Version: v 1.0  
Date: 07/08/2026  
Status: Draft

## Background
The affected service is Azure Virtual Desktop (AVD) host pool POOL-FIN-01 used by Finance users for daily business applications and shared-drive workflows. After Azure AD authentication, users are expected to receive a rendered Windows desktop session from one of the session hosts (SHFIN-01-A through SHFIN-01-H).

Why this matters:
- If desktop rendering fails after successful sign-in, users cannot access finance systems even though identity/authentication succeeded.
- The incident creates high business impact because users appear "logged in" but are blocked from productive work.
- Repeated reconnect attempts increase noise and hide root-cause timelines in logs.

## Symptom
What the engineer observes:
- In Azure Portal, user sessions are created on POOL-FIN-01 hosts, but affected users report unusable black screens.
- Terminal session activity appears normal at sign-in level, but desktop composition is unstable.
- Affected hosts are typically in POOL-FIN-01; control pool POOL-FIN-02 remains stable.

What users report:
- "I can sign in, but after login I only get a black screen."
- No immediate credential error.
- Frequent disconnect/reconnect pattern after logon.

## Root Cause
Specific technical cause:
- Intel display driver stack on POOL-FIN-01 hosts is at defective signature level:
  - Faulting module: igdumd64.dll
  - Defective version observed on affected hosts: 31.0.101.4146
- This causes Desktop Window Manager instability (dwm.exe), resulting in post-login black screen sessions.

Evidence that confirms root cause:
- Windows Application log shows Event ID 1000 for dwm.exe faulting in igdumd64.dll.
- Associated Event IDs 9009 (failure pattern) and absence/instability of expected steady-state rendering.
- Post-fix, Event ID 9011 appears as DWM start success signal.
- Driver comparison check:
  - POOL-FIN-01 affected hosts report defective display driver version.
  - Control baseline from POOL-FIN-02 (example: SHFIN-02-A) reports known-good 31.0.100.9999.

## Detection
Use this command-first workflow to confirm or reject the signature in under 3 minutes before any remediation.

### 3-minute quick confirm (command first)
1. Open elevated PowerShell on an admin workstation with remoting access to one affected host in POOL-FIN-01 (example SHFIN-01-A) and one unaffected control host in POOL-FIN-02 (example SHFIN-02-A).
Expected result: You can run remote event and driver queries against both hosts.

2. Run this command to pull required Application log events from both hosts.
Log location queried by command: Event Viewer > Windows Logs > Application (Application log).
```powershell
$affectedHost = 'SHFIN-01-A'
$controlHost  = 'SHFIN-02-A'
$since = (Get-Date).AddHours(-4)

Invoke-Command -ComputerName $affectedHost,$controlHost -ScriptBlock {
    param($sinceTime)
    Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000,9009,9011; StartTime=$sinceTime } |
        Select-Object @{Name='Host';Expression={$env:COMPUTERNAME}}, TimeCreated, Id, ProviderName, Message |
        Sort-Object TimeCreated -Descending
} -ArgumentList $since
```
Expected result: Event IDs 1000 and 9009 appear on affected host; Event 9011 is present on unaffected control host.

3. Run this command to confirm the exact Event 1000 fault signature.
Log location queried by command: Event Viewer > Windows Logs > Application (Application log).
```powershell
Invoke-Command -ComputerName $affectedHost -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=(Get-Date).AddHours(-4) } |
        Where-Object { $_.Message -match 'dwm\.exe' -and $_.Message -match 'igdumd64\.dll' } |
        Select-Object -First 5 TimeCreated, Id, ProviderName, Message
}
```
Required confirmation fields in Event 1000 message:
- Faulting application name: dwm.exe
- Faulting module name: igdumd64.dll
Expected result: At least one Event 1000 entry contains both dwm.exe and igdumd64.dll.

4. Run this command to confirm session symptom correlation.
Log location queried by command: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
```powershell
Invoke-Command -ComputerName $affectedHost -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=(Get-Date).AddHours(-4) } |
        Select-Object -First 20 TimeCreated, Id, ProviderName, Message |
        Sort-Object TimeCreated -Descending
}
```
Required event IDs and interpretation:
- Event 21: successful logon/session creation
- Event 40: disconnect soon after logon
Expected result: Event 21/40 pattern aligns with user black-screen reports.

5. Run this command to compare display driver versions between affected and control pools.
```powershell
Invoke-Command -ComputerName $affectedHost,$controlHost -ScriptBlock {
    Get-CimInstance Win32_PnPSignedDriver |
        Where-Object { $_.DeviceClass -eq 'DISPLAY' } |
        Select-Object @{Name='Host';Expression={$env:COMPUTERNAME}}, DeviceName, DriverVersion, InfName
}
```
Expected result:
- POOL-FIN-01 affected host shows defective signature level (31.0.101.4146).
- POOL-FIN-02 control host shows known-good baseline (31.0.100.9999).

### Optional host selection command (Azure)
Use this if you need a quick host list before running the remote commands.

Azure CLI:
```bash
az desktopvirtualization hostpool show --resource-group <ResourceGroup> --name POOL-FIN-01
az desktopvirtualization session-host list --resource-group <ResourceGroup> --host-pool-name POOL-FIN-01 --query "[].name"
az desktopvirtualization session-host list --resource-group <ResourceGroup> --host-pool-name POOL-FIN-02 --query "[].name"
```

PowerShell (Az.DesktopVirtualization):
```powershell
Get-AzWvdSessionHost -ResourceGroupName <ResourceGroup> -HostPoolName 'POOL-FIN-01' | Select-Object Name,Status,AllowNewSession
Get-AzWvdSessionHost -ResourceGroupName <ResourceGroup> -HostPoolName 'POOL-FIN-02' | Select-Object Name,Status,AllowNewSession
```

Decision gate:
- Confirm this incident signature only when all conditions are true:
  - Application log contains Event 1000 and Event 9009 on affected POOL-FIN-01 host.
  - Event 1000 explicitly shows igdumd64.dll (with dwm.exe fault context).
  - Control POOL-FIN-02 host shows Event 9011 as healthy baseline signal.
  - Driver comparison shows affected host at defective version and control host at known-good baseline.

## Resolution
Goal: complete repair in 5 to 10 minutes using command-first execution, with portal path equivalents for each action.

### Required variables
Set these first in PowerShell so all commands are copy/paste ready.
```powershell
$ResourceGroup = '<ResourceGroup>'
$HostPool = 'POOL-FIN-01'
$ControlPool = 'POOL-FIN-02'
$CanaryHost = 'SHFIN-01-A'
$TargetHosts = @('SHFIN-01-B','SHFIN-01-C','SHFIN-01-D','SHFIN-01-E','SHFIN-01-F','SHFIN-01-G','SHFIN-01-H')
$BaselineInfPath = '<PathToBaseline31.0.100.9999_INF>'
```

### Phase A: Canary fix on SHFIN-01-A
1. Drain canary host.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Allow new session = Off > Save

Azure CLI:
```bash
az desktopvirtualization session-host update --resource-group <ResourceGroup> --host-pool-name POOL-FIN-01 --name SHFIN-01-A --allow-new-session false
```

Az PowerShell:
```powershell
Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $CanaryHost -AllowNewSession:$false
```
Expected result: SHFIN-01-A is in drain mode and stops receiving new logons.

2. Sign out all active sessions on canary host.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > User sessions > select all > Sign out

Azure CLI:
```bash
az desktopvirtualization user-session list --resource-group <ResourceGroup> --host-pool-name POOL-FIN-01 --session-host-name SHFIN-01-A
```

Az PowerShell:
```powershell
Get-AzWvdUserSession -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -SessionHostName $CanaryHost |
ForEach-Object {
  Remove-AzWvdUserSession -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -SessionHostName $CanaryHost -Id $_.Name -Force
}
```
Expected result: Active sessions for SHFIN-01-A are zero.

3. Roll back display driver on canary host.
Console path:
- Elevated PowerShell remoting to SHFIN-01-A
```powershell
Invoke-Command -ComputerName $CanaryHost -ScriptBlock {
  param($infPath)
  $display = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'DISPLAY' } | Select-Object -First 1
  pnputil /delete-driver $display.InfName /uninstall /force
  pnputil /add-driver $infPath /install
} -ArgumentList $BaselineInfPath
```
Expected result: defective display driver package removed and baseline package installed.

4. Restart canary host and wait for availability.
Azure Portal exact path and option:
- Azure Portal > Virtual machines > SHFIN-01-A > Overview > Restart
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > SHFIN-01-A > Status

Azure CLI:
```bash
az vm restart --resource-group <ResourceGroup> --name SHFIN-01-A
```

Az PowerShell:
```powershell
Restart-AzVM -ResourceGroupName $ResourceGroup -Name $CanaryHost -NoWait
```
Expected result: host returns as Available in POOL-FIN-01 session hosts list.

5. Validate canary driver and re-enable admissions only after pass.
```powershell
Invoke-Command -ComputerName $CanaryHost -ScriptBlock {
  Get-CimInstance Win32_PnPSignedDriver |
    Where-Object { $_.DeviceClass -eq 'DISPLAY' } |
    Select-Object DeviceName, DriverVersion, InfName
}
```
Expected result: DriverVersion shows 31.0.100.9999 and test login renders desktop.

### Phase B: Bulk rollout to SHFIN-01-B through SHFIN-01-H
1. Drain all remaining hosts.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > each host SHFIN-01-B..H > Allow new session = Off > Save

Az PowerShell:
```powershell
foreach ($h in $TargetHosts) {
  Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $h -AllowNewSession:$false
}
```
Expected result: all target hosts show Allow new session = Off.

2. Sign out sessions on all target hosts.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > host > User sessions > Sign out

Az PowerShell:
```powershell
foreach ($h in $TargetHosts) {
  Get-AzWvdUserSession -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -SessionHostName $h |
  ForEach-Object {
    Remove-AzWvdUserSession -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -SessionHostName $h -Id $_.Name -Force
  }
}
```
Expected result: active sessions are zero on each target host.

3. Apply driver rollback and restart one host at a time.
```powershell
foreach ($h in $TargetHosts) {
  Invoke-Command -ComputerName $h -ScriptBlock {
    param($infPath)
    $display = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'DISPLAY' } | Select-Object -First 1
    pnputil /delete-driver $display.InfName /uninstall /force
    pnputil /add-driver $infPath /install
    Restart-Computer -Force
  } -ArgumentList $BaselineInfPath
}
```
Expected result: each host reboots with baseline driver package.

4. Re-enable host admissions after version confirmation.
Az PowerShell:
```powershell
foreach ($h in @($CanaryHost) + $TargetHosts) {
  Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $h -AllowNewSession:$true
}
```
Expected result: full pool capacity restored with baseline driver.

## Verification
Close only if every check below passes.

1. Host state and admission check.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
- Verify columns: Status = Available, Allow new session = On for SHFIN-01-A..H

Az PowerShell:
```powershell
Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool |
Select-Object Name, Status, AllowNewSession
```
Expected result: all hosts Available and AllowNewSession True.

2. Driver baseline on all repaired hosts.
```powershell
Invoke-Command -ComputerName (@($CanaryHost) + $TargetHosts) -ScriptBlock {
  Get-CimInstance Win32_PnPSignedDriver |
    Where-Object { $_.DeviceClass -eq 'DISPLAY' } |
    Select-Object @{Name='Host';Expression={$env:COMPUTERNAME}}, DriverVersion, InfName
}
```
Expected result: DriverVersion = 31.0.100.9999 on every POOL-FIN-01 host.

3. Crash/no-crash event check.
Exact log path queried: Event Viewer > Windows Logs > Application.
```powershell
Invoke-Command -ComputerName (@($CanaryHost) + $TargetHosts) -ScriptBlock {
  $start = (Get-Date).AddMinutes(-30)
  [pscustomobject]@{
    Host = $env:COMPUTERNAME
    Event1000 = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$start} -ErrorAction SilentlyContinue).Count
    Event9009 = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9009; StartTime=$start} -ErrorAction SilentlyContinue).Count
    Event9011 = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9011; StartTime=$start} -ErrorAction SilentlyContinue).Count
  }
}
```
Expected result: Event1000 = 0, Event9009 = 0, and Event9011 > 0 on sampled repaired hosts.

4. Control comparison check (unaffected baseline).
Exact log path queried: Event Viewer > Windows Logs > Application on POOL-FIN-02 control host.
```powershell
Invoke-Command -ComputerName 'SHFIN-02-A' -ScriptBlock {
  Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=9011; StartTime=(Get-Date).AddMinutes(-30) } |
    Select-Object -First 5 TimeCreated, Id, ProviderName, Message
}
```
Expected result: Event 9011 present on POOL-FIN-02 control host, confirming healthy baseline behavior.

5. Session quality check.
Exact log path queried: Event Viewer > Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational.
```powershell
Invoke-Command -ComputerName (@($CanaryHost) + $TargetHosts) -ScriptBlock {
  Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; Id=21,40; StartTime=(Get-Date).AddMinutes(-30) } |
    Select-Object -First 30 TimeCreated, Id, Message |
    Sort-Object TimeCreated -Descending
}
```
Expected result: normal Event 21 activity without repeated immediate Event 40 disconnect pattern.

6. User experience confirmation.
Action: complete three real user logins through POOL-FIN-01 and record timestamp and host.
Expected result: all users reach desktop without black screen.

## Rollback
Use this when the fix worsens user impact, black screens increase, or hosts remain unstable.

### Emergency containment (target <= 3 minutes)
1. Isolate unstable host immediately.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <UnstableHost> > Allow new session = Off > Save

Azure CLI:
```bash
az desktopvirtualization session-host update --resource-group <ResourceGroup> --host-pool-name POOL-FIN-01 --name <UnstableHost> --allow-new-session false
```

Az PowerShell:
```powershell
$UnstableHost = '<UnstableHost>'
Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $UnstableHost -AllowNewSession:$false
```
Expected result: no new users are assigned to unstable host.

2. Force sign-out on unstable host.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <UnstableHost> > User sessions > Sign out

Az PowerShell:
```powershell
Get-AzWvdUserSession -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -SessionHostName $UnstableHost |
ForEach-Object {
    Remove-AzWvdUserSession -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -SessionHostName $UnstableHost -Id $_.Name -Force
}
```
Expected result: active sessions become zero on unstable host.

3. Confirm service continuity on remaining hosts.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts
- Verify at least one other host has Status = Available and Allow new session = On
Expected result: users are redirected to healthy capacity.

### Host rollback actions
4. Re-apply known-good driver on isolated host.
```powershell
Invoke-Command -ComputerName $UnstableHost -ScriptBlock {
    param($infPath)
    $display = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceClass -eq 'DISPLAY' } | Select-Object -First 1
    pnputil /delete-driver $display.InfName /uninstall /force
    pnputil /add-driver $infPath /install
    Restart-Computer -Force
} -ArgumentList $BaselineInfPath
```
Expected result: host restarts with baseline 31.0.100.9999 package.

5. Verify rollback health before re-admission.
Exact log path queried: Event Viewer > Windows Logs > Application.
```powershell
Invoke-Command -ComputerName $UnstableHost -ScriptBlock {
    $start = (Get-Date).AddMinutes(-15)
    [pscustomobject]@{
        Host = $env:COMPUTERNAME
        Event1000 = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=$start} -ErrorAction SilentlyContinue).Count
        Event9009 = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9009; StartTime=$start} -ErrorAction SilentlyContinue).Count
        Event9011 = (Get-WinEvent -FilterHashtable @{LogName='Application'; Id=9011; StartTime=$start} -ErrorAction SilentlyContinue).Count
    }
}
```
Expected result: Event1000 = 0, Event9009 = 0, Event9011 > 0.

6. Re-enable unstable host only after pass.
Azure Portal exact path and option:
- Azure Portal > Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts > <UnstableHost> > Allow new session = On > Save

Az PowerShell:
```powershell
Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $UnstableHost -AllowNewSession:$true
```
Expected result: host safely rejoins active rotation.

7. If rollback still fails, keep host isolated and use image-level recovery path.
Azure Portal exact path and option:
- Azure Portal > Virtual machines > <UnstableHost> > Settings > Disks (confirm OS disk)
- Azure Portal > Virtual machines > <UnstableHost> > Overview > Redeploy + reapply
- If your standard requires rebuild from known-good image: Azure Portal > Virtual machines > Create from standardized baseline image used by POOL-FIN-02 control lineage
Expected result: failed host stays drained while infra engineering performs image-level recovery.

## Preventive
Implement these specific process/tooling controls to prevent recurrence:

1. Driver ring governance for AVD pools.
- Owner: Change manager; Timing: during deployment; Mode: manual gate (automate with pipeline approval rule) [REQUIRES: release gate workflow].
- Pass signal: Pilot (1 host) and Canary (1 host) each run 24h with Event 1000 count = 0, Event 9009 count = 0, and Event 9011 count > 0 every 30 min sample.
- Fail action: block Broad ring, keep modified hosts Allow new session = Off, and assign incident to DWP engineer + release engineer.

2. Golden image and package allowlist enforcement.
- Owner: Image owner; Timing: before deployment; Mode: automated CI/CD policy [REQUIRES: image pipeline policy check].
- Pass signal: build artifact contains only approved display driver version and matching hash/provenance from allowlist; noncompliant count = 0.
- Fail action: fail image publish, open defect to image owner, and prevent host-pool rollout ticket from moving to Approved.

3. Automated drift detection across pools.
- Owner: DWP engineer; Timing: after deployment (hourly); Mode: automated scheduled inventory [REQUIRES: scheduled job + central evidence share].
- Pass signal: POOL-FIN-01 and POOL-FIN-02 DISPLAY DriverVersion delta count = 0 against baseline 31.0.100.9999.
- Fail action: create incident, auto-notify service desk lead, and drain any host that reports non-baseline version.

4. Event-based early warning.
- Owner: DWP engineer; Timing: during deployment and first 24h after deployment; Mode: automated alerts [REQUIRES: Log Analytics workspace + alert rules].
- Pass signal: per host in 10-minute window, Event 1000 (dwm.exe + igdumd64.dll) < 2 and Event 9009 < 2.
- Fail action: page on-call DWP engineer, pause rollout, and set Allow new session = Off on the latest changed host.

5. Change ticket quality gates.
- Owner: Change manager; Timing: before deployment; Mode: manual checklist (automate with required ITSM fields) [REQUIRES: ITSM field validation rule].
- Pass signal: ticket contains target pool, POOL-FIN-02 comparison plan, pre/post evidence paths, rollback package path, and tested commands; missing field count = 0.
- Fail action: reject CAB approval and return ticket to release engineer for correction.

6. Standardized evidence collection toolkit.
- Owner: DWP engineer; Timing: during and after deployment; Mode: automated script execution [REQUIRES: signed script repository + execution rights].
- Pass signal: per host evidence bundle exists with Application(1000/9009/9011), TSLSM(21/40), and DISPLAY DriverVersion+InfName outputs.
- Fail action: block change closure and escalate to service desk lead until evidence is complete.

7. Pre-deployment smoke test gate.
- Owner: Release engineer; Timing: before deployment; Mode: manual run today (automate via pre-prod smoke pipeline) [REQUIRES: test account + pre-prod host].
- Pass signal: test login completes to desktop within 60 seconds, Event 1000/9009 count = 0, and Event 9011 present on smoke host over 15 minutes.
- Fail action: cancel release window and return package to image owner.

8. In-flight monitoring window.
- Owner: DWP engineer; Timing: during deployment; Mode: automated dashboard and alert [REQUIRES: rollout workbook/query pack].
- Pass signal: rolling 5-minute ratio Event 40/Event 21 stays < 0.10 and no host breaches Event 1000 >= 2.
- Fail action: stop next host wave, isolate last changed host, and invoke rollback section.

9. Post-deployment validation gate.
- Owner: Change manager; Timing: after deployment; Mode: manual sign-off (automate with verification script summary attachment).
- Pass signal: all POOL-FIN-01 hosts Status=Available, AllowNewSession=True, DriverVersion=31.0.100.9999, plus 30-minute Event 1000/9009 count = 0.
- Fail action: keep change in Implemented-not-Closed state and require DWP engineer remediation before closure.

10. Rollback trigger threshold.
- Owner: Service desk lead; Timing: during and after deployment; Mode: manual trigger today (can be automated alert-to-action) [REQUIRES: incident automation runbook].
- Pass signal: no trigger met; trigger = same host has >= 3 Event 1000 in 10 minutes or >= 2 user black-screen reports in 15 minutes.
- Fail action: immediate host drain, force sign-out, and baseline driver rollback on trigger host.

11. Knowledge update control.
- Owner: Service desk lead; Timing: after deployment; Mode: manual governance task [REQUIRES: PIR checklist process].
- Pass signal: runbook, KB, and change checklist updated within 2 business days with new query/thresholds and linked incident/change IDs.
- Fail action: mark PIR incomplete and block "lessons learned closed" status until document updates are published.

## Related
- Source runbook: Runbook — AVD Black Screen Post-Login (POOL-FIN-01).
- RCA final: Day4/RCA_AVDBlackScreen_Final_20240315.md
- Known error record: Day4/KnownError_AVDBlackScreen_20240315.md
- Diagnosis hypothesis: Day4/AVD_BlackScreen_DiagnosisHypothesis_20240315.md
- Closure note: Day4/ClosureNote_AVDBlackScreen_20240315.md
- End-user communication: Day4/EndUser_Communication_AVDBlackScreen_20240315.md
- L1 companion KB: Day5/KB_L1_SelfService_LoginBlackScreen_20260807.md
