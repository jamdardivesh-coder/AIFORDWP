# KB — L2/L3 Diagnosis and Recovery: Autopilot Enrolment Failure, Legacy MDM Conflict (DESKTOP-FB099)
Version: v1.0
Date: 11/08/2026
Status: Draft

## Background
The affected workflow is Windows Autopilot device provisioning used to deploy DWP-managed Windows 11 endpoints. During Autopilot, the device connects to Microsoft enrolment endpoints, registers against the tenant, and receives MDM management through Intune. Policy profiles and compliance evaluation only begin after enrolment completes successfully.

Why this matters:
- If enrolment fails, no policy or compliance evaluation runs. The device is unmanaged and cannot be used for corporate work.
- The error 0x80180014 is a hard block. Retrying Autopilot without removing the conflicting enrolment will produce the same failure every time.
- This pattern affects any device previously managed through a legacy or manual MDM path that is reused without first de-enrolling.

## Symptom
What the engineer observes:
- In Intune admin center > Devices > All devices, the device appears with an existing managed device record from a legacy enrolment path.
- Autopilot enrolment for the same hardware fails and the device does not progress to a new managed device object.
- PolicyManager shows ProfilesApplied = 0 of N. ComplianceEngine reports "Could not evaluate / Enrolment not complete".
- No policy profiles land on the device after the failed Autopilot run.

What users report:
- "My new setup got stuck and never finished."
- Device sits at OOBE or fails silently without completing the expected Autopilot provisioning experience.
- Device is not available for normal use after the rebuild attempt.

## Root Cause
Specific technical cause:
- The device carries an existing active or residual MDM enrolment record from a previous manual or legacy enrolment path.
- When Autopilot attempts to perform MDM enrolment, the service detects the conflicting management relationship and terminates the flow.
- Error code 0x80180014 is the definitive indicator of this condition. The product-supplied message is "The device is already enrolled in MDM."

Evidence that confirms root cause:
- MDM diagnostic export shows EnrollmentState = Failed, ErrorCode = 0x80180014.
- DeviceInfo shows MDMEnrolled = Yes (previous enrolment) and EnrolmentSource identifying a legacy manual path.
- Intune managed device record for the same hardware exists with a pre-Autopilot check-in date.
- dsregcmd /status output on the device shows an existing MDM enrolment entry under the WorkplaceJoin or MDM sections.
- Licensing and network connectivity are healthy and do not explain the failure.

## Detection
Use this command-first workflow to confirm or reject the signature before any remediation.

### 3-minute quick confirm (command first)
1. Open elevated PowerShell on an admin workstation with Microsoft Graph PowerShell module installed and appropriate Intune read permissions.

Expected result: you can run managed device and Autopilot queries against the tenant.

2. Run this command to check whether the device has an existing Intune managed device record.
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$deviceName = 'DESKTOP-FB099'

Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$deviceName'" |
    Select-Object DeviceName, Id, EnrolledDateTime, ManagementAgent, OperatingSystem, UserId
```
Expected result: one or more managed device records appear for the target device name. If the EnrolledDateTime is older than the current Autopilot attempt, a legacy record is present.

3. Run this command to check the Autopilot device registration.
```powershell
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.Read.All"

Get-MgDeviceManagementWindowsAutopilotDeviceIdentity |
    Where-Object { $_.ManagedDeviceId -ne $null -or $_.SerialNumber -eq '<DeviceSerialNumber>' } |
    Select-Object Id, SerialNumber, Model, GroupTag, DeploymentProfileAssignmentStatus
```
Expected result: one valid Autopilot device registration exists for the target hardware. Note the Id before any cleanup.

4. Run this command on the affected device to confirm the local MDM enrolment state.
Run from an elevated PowerShell or command prompt directly on DESKTOP-FB099, or through a remote session if available.
```powershell
dsregcmd /status
```
Required confirmation fields:
- AzureAdJoined : YES
- MDMUrl : should show an Intune enrolment URL if MDM enrolment is active
- WorkplaceJoined : may also show YES if a legacy work account connection exists alongside the AAD join

Expected result: MDMUrl or a WorkplaceJoin entry is present, confirming the device believes it is already enrolled.

5. Run this command to enumerate existing MDM enrolment registry entries on the device.
Run from elevated PowerShell directly on or remoted to DESKTOP-FB099.
```powershell
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Enrollments' |
    ForEach-Object {
        $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        [pscustomobject]@{
            EnrollmentID   = $_.PSChildName
            ProviderID     = $props.ProviderID
            EnrollmentType = $props.EnrollmentType
            UPN            = $props.UPN
        }
    }
```
Expected result: one or more enrolment entries exist under HKLM:\SOFTWARE\Microsoft\Enrollments, confirming a residual MDM enrolment record is present on the device.

### Decision gate
Confirm this incident signature only when all conditions are true:
- Intune managed device record exists for the hardware with a pre-Autopilot check-in date.
- dsregcmd /status shows MDMUrl or WorkplaceJoined entries on the device.
- Registry confirms enrolment entries under HKLM:\SOFTWARE\Microsoft\Enrollments.
- ErrorCode in the diagnostic export or Autopilot event log is 0x80180014.
- Licensing and all required network endpoints are confirmed healthy.

## Resolution
Goal: remove the stale managed device record from Intune, remove the legacy management connection from the device, reset to OOBE, and complete a clean Autopilot run. Target completion in one engineer session.

### Required variables
Set these first in PowerShell so all commands are copy/paste ready.
```powershell
$DeviceName       = 'DESKTOP-FB099'
$DeviceSerial     = '<DeviceSerialNumber>'
$StaleDeviceId    = '<ManagedDeviceId from detection step 2>'
$AutopilotId      = '<AutopilotDeviceIdentityId from detection step 3>'
$ResourceGroup    = '<AzureResourceGroup if applicable>'
```

### Phase A: Record identifiers and confirm Autopilot registration before any deletion
1. Record the stale managed device ID and the Autopilot device registration ID before proceeding.
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementServiceConfig.Read.All"

# Stale managed device
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" |
    Select-Object DeviceName, Id, EnrolledDateTime, ManagementAgent

# Autopilot registration
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity |
    Where-Object { $_.SerialNumber -eq $DeviceSerial } |
    Select-Object Id, SerialNumber, DeploymentProfileAssignmentStatus
```
Expected result: both records are visible. The managed device record has an older EnrolledDateTime. The Autopilot record has an assigned deployment profile.

Intune admin center exact path:
- Devices > All devices > search by device name > open record > note Managed device ID
- Devices > Windows > Windows enrollment > Devices > Windows Autopilot devices > search by serial number > note record

2. Do not proceed if the Autopilot registration is missing. Investigate why the hardware hash is absent before continuing.

### Phase B: Delete the stale Intune managed device record
1. Delete the stale managed device object.
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $StaleDeviceId
```
Intune admin center exact path:
- Devices > All devices > open stale device record > Delete > confirm

Expected result: the stale managed device record is removed. It no longer appears in Devices > All devices.

2. Verify deletion is complete before proceeding.
```powershell
$check = Get-MgDeviceManagementManagedDevice -Filter "id eq '$StaleDeviceId'" -ErrorAction SilentlyContinue
if ($check) { Write-Warning "Record still present - wait and recheck." } else { Write-Output "Deletion confirmed." }
```
Expected result: no record returned for the stale device ID.

3. Confirm the Autopilot registration is still intact.
```powershell
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $AutopilotId |
    Select-Object Id, SerialNumber, DeploymentProfileAssignmentStatus
```
Expected result: Autopilot record is present and deployment profile is still assigned.

### Phase C: Remove the legacy management connection from the device
Requires device access: physical or remote interactive session.

1. Sign in to DESKTOP-FB099 with a local administrator account.
2. Open Settings > Accounts > Access work or school.
3. Identify the work or school connection associated with the old manual MDM enrolment. If the EnrolledDateTime from Phase A helps identify it, use that account UPN to match.
4. Select the legacy connection and choose Disconnect.
5. If multiple connections exist, remove only the obsolete one. Verify against the UPN recorded in the detection step.
6. Restart the device after the disconnect completes.

Optional: confirm removal of registry enrolment entries after restart.
```powershell
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Enrollments' |
    ForEach-Object {
        $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        [pscustomobject]@{
            EnrollmentID   = $_.PSChildName
            ProviderID     = $props.ProviderID
            EnrollmentType = $props.EnrollmentType
        }
    }
```
Expected result: no residual MDM enrolment entries remain from the legacy manual enrolment.

### Phase D: Reset device to Autopilot-ready OOBE state
Requires device access: physical or remote with reprovisioning control.

1. Initiate a full device reset.
Windows Settings path:
- Settings > System > Recovery > Reset this PC > Remove everything > Local reinstall

Or if wiping remotely from Intune:
- Intune admin center > Devices > All devices > [device if still visible] > Wipe

Expected result: device returns to OOBE (out-of-box experience) after reset completes.

2. Connect the device to a network with the following endpoints reachable:
- login.microsoftonline.com
- enrollment.manage.microsoft.com
- enterpriseregistration.windows.net

### Phase E: Run Autopilot and monitor enrolment
Requires device access: physical.

1. Complete the OOBE sign-in with the intended user account.
2. Allow Autopilot to proceed through the enrollment status page.
3. In Intune admin center, monitor for a new managed device object.

Intune admin center exact path:
- Devices > All devices > search for DESKTOP-FB099 or the user's UPN

Expected result: a new managed device record appears with a current check-in time and enrolment source reflecting the Autopilot path.

4. Confirm policy profiles begin landing on the new device object.
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

$newDevice = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" |
    Sort-Object EnrolledDateTime -Descending |
    Select-Object -First 1

Write-Output "New device ID: $($newDevice.Id)"
Write-Output "Enrolled: $($newDevice.EnrolledDateTime)"
Write-Output "Compliance state: $($newDevice.ComplianceState)"
```
Expected result: new managed device object has a current EnrolledDateTime and ComplianceState is not unknown.

## Verification
Close only if every check below passes.

1. Stale managed device record is gone.
```powershell
$stale = Get-MgDeviceManagementManagedDevice -Filter "id eq '$StaleDeviceId'" -ErrorAction SilentlyContinue
if ($stale) { Write-Warning "Stale record still present." } else { Write-Output "PASS: stale record removed." }
```
Expected result: no record returned.

2. Autopilot registration is intact and profile-assigned.
```powershell
Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $AutopilotId |
    Select-Object SerialNumber, DeploymentProfileAssignmentStatus
```
Expected result: DeploymentProfileAssignmentStatus is assigned.

3. New managed device object exists with current check-in.
```powershell
Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" |
    Select-Object DeviceName, Id, EnrolledDateTime, ManagementAgent, ComplianceState |
    Sort-Object EnrolledDateTime -Descending
```
Expected result: one record with an EnrolledDateTime matching the reprovisioning date and ManagementAgent reflecting MDM/Intune.

4. Policy profiles are applying.

Intune admin center exact path:
- Devices > All devices > [new device record] > Device configuration
- Confirm profile assignment state is not 0 applied.

Expected result: one or more configuration profiles show as applied or pending on the new device record.

5. Compliance evaluation is running.

Intune admin center exact path:
- Devices > All devices > [new device record] > Device compliance

Expected result: compliance state is Compliant, Not compliant, or In grace period. "Could not evaluate" and "Enrolment not complete" must no longer be present.

6. Device-side enrolment state is clean.
Run on DESKTOP-FB099:
```powershell
dsregcmd /status
```
Expected result: AzureAdJoined = YES, MDMUrl points to the current Intune enrolment URL, and no legacy WorkplaceJoin entry from the old manual connection remains.

7. Registry confirms clean enrolment state.
Run on DESKTOP-FB099:
```powershell
Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Enrollments' |
    ForEach-Object {
        $props = Get-ItemProperty -Path $_.PSPath -ErrorAction SilentlyContinue
        [pscustomobject]@{
            EnrollmentID   = $_.PSChildName
            ProviderID     = $props.ProviderID
            EnrollmentType = $props.EnrollmentType
        }
    }
```
Expected result: only the current Autopilot-sourced enrolment entry is present. No legacy manual enrolment entries remain.

## Rollback
Use this when the cleanup causes an unexpected state: the valid Autopilot registration is missing, the device cannot reach OOBE, or the device re-presents the same error after reset.

### Emergency containment
1. If the Autopilot device registration was accidentally deleted, stop the Autopilot attempt immediately and do not proceed with OOBE sign-in until the registration is restored.

2. Re-register the device hardware hash if the Autopilot record was lost.

Intune admin center exact path:
- Devices > Windows > Windows enrollment > Devices > Windows Autopilot devices > Import
- Import a new CSV with the device hardware hash, serial number, and intended group tag.

PowerShell (requires hardware hash from device):
```powershell
# Run on the device to extract hardware hash
$hash = (Get-WmiObject -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'").DeviceHardwareData
$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber

[pscustomobject]@{
    'Device Serial Number' = $serial
    'Windows Product ID'   = ''
    'Hardware Hash'        = $hash
} | Export-Csv -Path "C:\Temp\$serial-AutopilotHash.csv" -NoTypeInformation -Encoding UTF8
```
Expected result: a valid CSV is produced that can be imported to restore the Autopilot registration.

3. If the device reset fails or cannot reach OOBE, isolate the device and do not attempt further self-service recovery. Escalate to senior engineering with full device history.

4. If the delete operation removed the wrong managed device record (a different device), immediately notify the affected device owner and raise an incident. Use the Intune recycle bin if available in your tenant, or restore the device by having it check in again.

### Rollback decision gate
- If Autopilot still returns 0x80180014 after the cleanup sequence, re-run the detection step to confirm no second legacy managed device record exists for the same hardware under a different device name or user.
- If a second stale record is found, repeat Phase B for that record before retrying Autopilot.
- If no stale record is found and 0x80180014 still occurs, escalate to Microsoft Support with the MDM diagnostic export and the managed device history.

## Preventive
Implement these specific process and tooling controls to prevent recurrence across other legacy-enrolled devices.

1. Pre-Autopilot managed device record check.
- Owner: Endpoint engineering; Timing: before each device rebuild or reassignment; Mode: manual check today (automate with a pre-build script).
- Pass signal: no managed device record found in Intune for the target serial number or device name with an EnrolledDateTime older than the current build date.
- Fail action: do not start the Autopilot sequence; delete the stale managed device record and confirm deletion before proceeding.
```powershell
# Run as part of the rebuild preflight checklist
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"
$serial = '<TargetSerial>'
$existing = Get-MgDeviceManagementManagedDevice -Filter "serialNumber eq '$serial'"
if ($existing) {
    Write-Warning "PREFLIGHT FAIL: Existing managed device record found. Delete before Autopilot."
    $existing | Select-Object DeviceName, Id, EnrolledDateTime, ManagementAgent
} else {
    Write-Output "PREFLIGHT PASS: No conflicting managed device record."
}
```

2. Device-side enrolment cleanup verification before reset.
- Owner: Field engineering or deskside support; Timing: before device wipe; Mode: manual check during rebuild.
- Pass signal: dsregcmd /status shows no legacy MDMUrl or WorkplaceJoin entries, or all legacy connections are confirmed disconnected in Settings > Accounts > Access work or school.
- Fail action: disconnect all legacy work or school connections and restart before initiating the device reset.

3. Legacy device flag in asset or rebuild workflow.
- Owner: Service management; Timing: at ticket creation; Mode: manual tagging in ITSM.
- Pass signal: rebuild ticket contains a field confirming legacy enrolment check completed.
- Fail action: reject ticket from moving to "In progress" without that confirmation present.

4. Automated detection of devices with legacy MDM enrolment at risk of Autopilot conflict.
- Owner: Endpoint engineering; Timing: proactive, run periodically; Mode: scheduled Graph PowerShell query.
- Pass signal: no managed device records found with ManagementAgent = legacyPc or EnrolmentSource matching manual path that also appear in the Autopilot device list.
- Fail action: flag matched devices for preflight cleanup before the next rebuild cycle.
```powershell
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All","DeviceManagementServiceConfig.Read.All"

$autopilotSerials = (Get-MgDeviceManagementWindowsAutopilotDeviceIdentity).SerialNumber

Get-MgDeviceManagementManagedDevice -Filter "operatingSystem eq 'Windows'" |
    Where-Object { $_.SerialNumber -in $autopilotSerials -and $_.ManagementAgent -ne 'mdm' } |
    Select-Object DeviceName, SerialNumber, Id, EnrolledDateTime, ManagementAgent |
    Sort-Object EnrolledDateTime
```

5. Rebuild runbook cleanup gate.
- Owner: Endpoint operations; Timing: before Autopilot; Mode: mandatory checklist item.
- Pass signal: checklist item "Intune managed device record deleted and confirmed absent" is checked and evidenced before device reset begins.
- Fail action: rebuild cannot proceed to reset stage until the checklist item is evidenced.

6. Post-Autopilot enrolment verification gate.
- Owner: Endpoint engineering; Timing: after Autopilot run; Mode: automated check in monitoring.
- Pass signal: new managed device object exists with current check-in, ComplianceState is not unknown, and policy profiles are applying.
- Fail action: do not return device to user until enrolment is confirmed clean.

7. Knowledge update control.
- Owner: Service desk lead; Timing: after resolution; Mode: manual governance task.
- Pass signal: L1 guide, KB, Known Error, and rebuild runbook updated within 2 business days.
- Fail action: mark PIR incomplete until document updates are published.

## Related
- RCA: Day6/RCA_AutopilotEnrollmentFailure_LegacyMDMConflict_20260811.md
- Detailed RCA: Day6/RCA_AutopilotEnrollmentFailure_LegacyMDMConflict_DetailedAnalysis_20260811.md
- Known Error: Day6/KnownError_AutopilotEnrollmentFailure_LegacyMDMConflict_20260811.md
- Closure note: Day6/ClosureNote_AutopilotEnrollmentFailure_LegacyMDMConflict_20260811.md
- End-user communication: Day6/EndUser_Communication_AutopilotEnrollmentFailure_LegacyMDMConflict_20260811.md
- L1 companion guide: Day6/L1Guide_AutopilotEnrollmentFailure_LegacyMDMConflict_20260811.md
