# Runbook — AVD Black Screen Post-Login (POOL-FIN-01)
## Source RCA: INC-2024-0315-AVD-BLACKSCREEN-FIN01

| Field | Value |
|-------|-------|
| Title | Runbook - AVD Black Screen Post-Login (POOL-FIN-01) |
| Version | 1.0 |
| Date | 07/08/2026 |
| Author | Sathishbabu |
| Reviewed | self |
| Status | draft |
| Change | initial version from RCA |

## 1) Prerequisites

Use this pre-flight checklist before any change activity.

### Access Checklist

- [ ] Azure Portal role can manage AVD session hosts in the subscription/resource group that contains POOL-FIN-01. [ELEVATED]
- [ ] Local Administrator rights are available on SHFIN-01-A through SHFIN-01-H. [ELEVATED]
- [ ] Permission exists to read Windows Event Logs on affected hosts and control host SHFIN-02-A. [ELEVATED]
- [ ] Permission exists to run PowerShell remoting commands against SHFIN-01-A through SHFIN-01-H. [ELEVATED]
- [ ] Permission exists to drain/un-drain session hosts in AVD host pool POOL-FIN-01. [ELEVATED]

### Tools Checklist

- [ ] Azure Portal access is working in a browser session.
- [ ] PowerShell 5.1 or later is available on the admin workstation.
- [ ] Event Viewer is available on the admin workstation.
- [ ] AVD management endpoint can reach all target hosts over management network paths.
- [ ] A writable evidence folder exists (example: C:\Incident\INC-2024-0315-AVD\).

### Mandatory End-User / Service-Desk Information Checklist

- [ ] Affected user names are collected.
- [ ] First failure time is captured.
- [ ] Exact symptom text is captured: black screen after successful login.
- [ ] Affected pool name is confirmed: POOL-FIN-01.
- [ ] Unaffected control pool is confirmed: POOL-FIN-02.
- [ ] Known affected hosts are listed (SHFIN-01-A through SHFIN-01-H if full-pool impact).
- [ ] Incident ticket ID is assigned and active.

### Mandatory Technical Baseline Checklist

- [ ] Defective driver signature is confirmed: igdumd64.dll version 31.0.101.4146 on affected host.
- [ ] Known-good baseline is confirmed: 31.0.100.9999 from SHFIN-02-A.
- [ ] Rollback driver package for 31.0.100.9999 is staged on admin share or local path.
- [ ] Change recorder is assigned for timestamps and command capture.

---

## 2) Procedure

### Phase A - Validate Signature on One Host (SHFIN-01-A)

1. Open Azure Portal and go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. [ELEVATED]
Expected result: Session host list for POOL-FIN-01 is visible.

2. Select SHFIN-01-A and set Allow new session to Off (drain mode). [ELEVATED]
Expected result: SHFIN-01-A shows drain mode and stops receiving new sessions.

3. In the same Session hosts page, select user sessions on SHFIN-01-A and sign out all sessions. [ELEVATED]
Expected result: SHFIN-01-A shows 0 active sessions.

4. Open Event Viewer on SHFIN-01-A and go to Windows Logs > Application. [ELEVATED]
Expected result: Application log is open on SHFIN-01-A.

5. In Application log, apply Filter Current Log with Event IDs 1000,9009 and time window starting 07:00. [ELEVATED]
Expected result: DWM crash evidence is visible if host matches RCA pattern.

6. Export the filtered Application log to C:\Incident\INC-2024-0315-AVD\SHFIN-01-A-Application-Before.evtx. [ELEVATED]
Expected result: Pre-change app log evidence is saved.

7. In Event Viewer, open Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational. [ELEVATED]
Expected result: TerminalServices operational log is open.

8. Apply Filter Current Log with Event IDs 21,40 in that Operational log. [ELEVATED]
Expected result: Successful logon and disconnect pattern is visible for impacted sessions.

9. Export the filtered TerminalServices log to C:\Incident\INC-2024-0315-AVD\SHFIN-01-A-TSLSM-Before.evtx. [ELEVATED]
Expected result: Pre-change session log evidence is saved.

10. Open an elevated PowerShell console connected to SHFIN-01-A. [ELEVATED]
Expected result: Remote admin shell is ready for driver commands.

11. Run Get-CimInstance Win32_PnPSignedDriver | Where-Object {$_.DeviceClass -eq 'DISPLAY'} | Select-Object DeviceName, DriverVersion, InfName. [ELEVATED]
Expected result: Current display driver details are listed, including DriverVersion and InfName.

12. Record the display driver InfName value in the ticket. [ELEVATED]
Expected result: Exact INF package identifier is captured for uninstall.

13. Run pnputil /delete-driver <InfNameFromStep11> /uninstall /force. [ELEVATED]
Expected result: Defective display driver package is removed.

14. Run pnputil /add-driver <PathToBaseline31.0.100.9999_INF> /install. [ELEVATED]
Expected result: Baseline display driver 31.0.100.9999 is installed.

15. Restart SHFIN-01-A. [ELEVATED]
Expected result: Host reboots and returns online.

16. In Azure Portal Session hosts view, refresh until SHFIN-01-A status is Available. [ELEVATED]
Expected result: Host is healthy post-reboot.

17. Re-run Get-CimInstance Win32_PnPSignedDriver | Where-Object {$_.DeviceClass -eq 'DISPLAY'} | Select-Object DeviceName, DriverVersion, InfName on SHFIN-01-A. [ELEVATED]
Expected result: DriverVersion shows 31.0.100.9999.

18. Perform one controlled test login to SHFIN-01-A with a finance test user.
Expected result: Desktop renders without black screen.

19. In Event Viewer Application log on SHFIN-01-A, filter Event IDs 1000,9009 for post-change window. [ELEVATED]
Expected result: No new DWM crash events are found after rollback.

20. In Event Viewer Application log on SHFIN-01-A, filter Event ID 9011 for post-change window. [ELEVATED]
Expected result: DWM start success event is present.

### Phase B - Roll Out to Remaining Hosts (SHFIN-01-B to SHFIN-01-H)

21. In Azure Portal Session hosts view, set Allow new session to Off for SHFIN-01-B through SHFIN-01-H. [ELEVATED]
Expected result: All seven hosts are in drain mode.

22. In Azure Portal, sign out all active user sessions on SHFIN-01-B through SHFIN-01-H. [ELEVATED]
Expected result: Each host shows 0 active sessions.

23. Run the uninstall command pnputil /delete-driver <InfNameFromEachHost> /uninstall /force on SHFIN-01-B through SHFIN-01-H. [ELEVATED]
Expected result: Defective driver package is removed from all seven hosts.

24. Run the install command pnputil /add-driver <PathToBaseline31.0.100.9999_INF> /install on SHFIN-01-B through SHFIN-01-H. [ELEVATED]
Expected result: Baseline driver is installed on all seven hosts.

25. Restart SHFIN-01-B through SHFIN-01-H one host at a time. [ELEVATED]
Expected result: Hosts return online sequentially with controlled impact.

26. Re-run Get-CimInstance Win32_PnPSignedDriver | Where-Object {$_.DeviceClass -eq 'DISPLAY'} | Select-Object DeviceName, DriverVersion, InfName on SHFIN-01-B through SHFIN-01-H. [ELEVATED]
Expected result: All seven hosts report DriverVersion 31.0.100.9999.

27. In Azure Portal, set Allow new session to On for SHFIN-01-A through SHFIN-01-H. [ELEVATED]
Expected result: Full pool capacity is restored.

28. Notify Service Desk to ask impacted users to reconnect to POOL-FIN-01.
Expected result: Reconnect message is sent to end users.

29. Monitor Event Viewer Application logs on a rotating sample of three hosts for 30 minutes at Windows Logs > Application with Event IDs 1000,9009,9011. [ELEVATED]
Expected result: No new 1000/9009 errors and normal 9011 starts are observed.

---

## 3) Verification

1. Open Azure Portal and go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. [ELEVATED]
Expected result: All eight hosts SHFIN-01-A to SHFIN-01-H are visible in one list.

2. Select each host in Session hosts and verify status is Available. [ELEVATED]
Expected result: No host is Unavailable, Unhealthy, or in draining unexpectedly.

3. Open elevated PowerShell and run this on each host: Get-CimInstance Win32_PnPSignedDriver | Where-Object {$_.DeviceClass -eq 'DISPLAY'} | Select-Object PSComputerName,DeviceName,DriverVersion,InfName. [ELEVATED]
Expected result: Every host reports DriverVersion 31.0.100.9999.

4. Open Event Viewer on SHFIN-01-A and navigate to Windows Logs > Application. [ELEVATED]
Expected result: Application log is open for crash verification.

5. In Windows Logs > Application, click Filter Current Log and set Event IDs to 1000,9009 and Logged to Last 30 minutes. [ELEVATED]
Expected result: No new Event 1000 (dwm.exe/igdumd64.dll) and no new Event 9009 are present.

6. In the same Application log, click Filter Current Log and set Event ID to 9011 and Logged to Last 30 minutes. [ELEVATED]
Expected result: Event 9011 entries exist, confirming DWM start success.

7. Repeat steps 4 through 6 on SHFIN-01-C and SHFIN-01-H as verification samples. [ELEVATED]
Expected result: Sampled hosts also show no new 1000/9009 and show 9011 entries.

8. In Event Viewer on SHFIN-01-A, navigate to Applications and Services Logs > Microsoft > Windows > TerminalServices-LocalSessionManager > Operational. [ELEVATED]
Expected result: Session activity log is open.

9. In the Operational log, click Filter Current Log and set Event IDs to 21,40 and Logged to Last 30 minutes. [ELEVATED]
Expected result: Logons (21) are present without repeated immediate disconnect pattern (40 after a few seconds).

10. Ask Service Desk to perform three live user login checks on POOL-FIN-01 and record usernames/time.
Expected result: All three users reach desktop without black screen.

11. Append verification evidence paths and timestamps to the incident ticket.
Expected result: Closure evidence is complete and auditable.

12. Close the incident only after a full 30-minute window shows no new Event 1000 or 9009 on sampled hosts. [ELEVATED]
Expected result: Resolution is confirmed stable before closure.

---

## 4) Rollback

Use these steps immediately if black screens increase, hosts fail to stabilize, or crash events continue after applying the procedure.

### 3-Minute Emergency Containment (No Guesswork)

1. Open Azure Portal and go to Azure Virtual Desktop > Host pools > POOL-FIN-01 > Session hosts. [ELEVATED]
Expected result: You can control host admission immediately.

2. Select the unstable host and set Allow new session to Off. [ELEVATED]
Expected result: New users stop landing on the failing host.

3. In the same host row, click Sessions and sign out all active users from that unstable host. [ELEVATED]
Expected result: Active user count on that host becomes 0.

4. In Azure Portal Session hosts list, confirm at least one other host is Available with Allow new session set to On. [ELEVATED]
Expected result: Users can still connect to healthy capacity.

5. Post in incident channel: "Host <name> isolated in drain mode; users redirected; rollback in progress."
Expected result: Team has immediate situational awareness.

### Immediate Host Recovery Actions

6. Open elevated PowerShell to the isolated host. [ELEVATED]
Expected result: Recovery commands can be executed.

7. Run Get-CimInstance Win32_PnPSignedDriver | Where-Object {$_.DeviceClass -eq 'DISPLAY'} | Select-Object DeviceName,DriverVersion,InfName. [ELEVATED]
Expected result: Current display driver and INF name are shown.

8. Run pnputil /delete-driver <InfNameFromStep7> /uninstall /force. [ELEVATED]
Expected result: Current problematic display package is removed.

9. Run pnputil /add-driver <PathToBaseline31.0.100.9999_INF> /install. [ELEVATED]
Expected result: Known-good driver package installs.

10. Restart the isolated host. [ELEVATED]
Expected result: Host reboots with baseline driver.

11. In Azure Portal > Host pools > POOL-FIN-01 > Session hosts, refresh until isolated host status is Available. [ELEVATED]
Expected result: Host is back online.

12. In Event Viewer on recovered host, go to Windows Logs > Application, filter Event IDs 1000,9009 for Last 15 minutes. [ELEVATED]
Expected result: No fresh DWM crash events appear.

13. In Event Viewer on recovered host, filter Event ID 9011 for Last 15 minutes. [ELEVATED]
Expected result: DWM start success event is present.

14. Set Allow new session to On only after steps 12 and 13 pass. [ELEVATED]
Expected result: Host safely rejoins pool.

15. If step 12 fails, keep Allow new session Off and escalate to Infrastructure Engineering with exported logs from Windows Logs > Application and TerminalServices-LocalSessionManager > Operational. [ELEVATED]
Expected result: Failed host stays isolated while escalation proceeds.

---

## 5) Notes

- This runbook applies to the verified RCA signature: Event 1000 for dwm.exe faulting in igdumd64.dll v31.0.101.4146, paired with Event 9009 and post-login black screen behavior.
- POOL-FIN-02 is the control pool baseline and should remain unchanged during emergency remediation.
- In the reference incident, first stable recovery was proven on SHFIN-01-A before broad rollout; keep that sequence to reduce blast radius.
- Warning: Re-enabling full load balancing before host-by-host version verification can reintroduce user impact.
- Related incident artifacts: RCA in Day4 for AVD black screen and the corresponding communication/closure records.
