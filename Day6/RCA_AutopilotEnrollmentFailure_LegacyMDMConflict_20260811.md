# RCA: Autopilot Enrolment Failure Due to Existing Legacy MDM Enrolment

## Version Header
- Version: v1.0
- Date: 11/08/2026
- Status: Final
- Audience: DWP Endpoint Engineering (L2/L3)
- Scope: Confirmed-root-cause analysis and remediation for Windows Autopilot enrolment blocked by a pre-existing legacy MDM enrolment

## Incident Summary
- Device: DESKTOP-FB099
- User: FINBRIDGE\rthomas
- Incident date in export: 2024-03-15 09:22
- Enrollment type: Autopilot
- Enrollment state: Failed
- Primary error: 0x80180014
- Error description in export: The device is already enrolled in MDM.
- Azure AD joined: Yes
- Existing MDM enrolment: Yes
- Existing enrolment source: Legacy manual MDM enrolment dated 2023-11-04
- Profiles attempted: 4
- Profiles applied: 0
- Policy last error: 0x80070005 (Access denied)
- Licensing: Present
- Network: Healthy, required endpoints reachable, no proxy

## Scope Facts Confirmed From The Export
- Autopilot enrolment did not complete.
- The export explicitly states that the blocking condition is an existing MDM enrolment.
- The device was already Azure AD joined at the time of the failure.
- A previous manual MDM enrolment existed before the Autopilot attempt.
- No policy profiles applied because enrolment did not complete.
- Licensing and basic network reachability were not the blocking factors in this case.

## Confirmed Root Cause
The root cause is a stale pre-existing MDM enrolment record from a legacy manual enrolment completed on 2023-11-04. Autopilot attempted to perform MDM enrolment against a device that already had an active or residual MDM management relationship. That conflicting enrolment state blocked the Autopilot enrolment flow and prevented policy application from starting successfully.

## Why This Root Cause Is Confirmed
- The diagnostic export already provides the failure description for 0x80180014 as The device is already enrolled in MDM.
- DeviceInfo shows MDMEnrolled = Yes and identifies the source as a previous legacy manual MDM enrolment.
- AzureADJoined = Yes shows the device was not failing because it could not register to the identity platform.
- Licensing is present and endpoint reachability is healthy, removing the two most common prerequisite blockers from scope.
- PolicyManager shows 0 of 4 profiles applied, which is consistent with downstream policy failure after the enrolment stage did not complete.

## Correct Remediation Goal
Remove the stale legacy MDM relationship while preserving the correct Windows Autopilot registration, then rerun the device through a clean Autopilot enrolment.

## Exact Remediation Steps

### Phase 1: Confirm and record identifiers before cleanup
1. [Admin center only] In Intune admin center, go to Devices > All devices.
2. [Admin center only] Search for the device by device name, serial number, or user.
3. [Admin center only] Open the device record and record these identifiers before deleting anything:
   - Device name
   - Serial number
   - Managed device ID
   - Azure AD device ID if shown
   - Primary user
   - Last check-in time
4. [Admin center only] Go to Devices > Windows > Windows enrollment > Devices > Windows Autopilot devices.
5. [Admin center only] Locate the Autopilot registration for the same hardware and confirm the Autopilot record exists and has the expected deployment profile assigned.
6. [Admin center only] If there are duplicate Autopilot records for the same hardware, stop and clean up the duplicate according to tenant process before continuing. If there is only one valid Autopilot record, keep it.

### Phase 2: Remove the stale Intune-managed device record
1. [Admin center only] In Intune admin center, return to Devices > All devices.
2. [Admin center only] Open the stale managed device record that corresponds to the legacy manual enrolment.
3. [Admin center only] Use Delete to remove the stale managed device object from Intune.
4. [Admin center only] Wait for the deletion to complete and confirm the stale managed device record no longer appears in Devices > All devices.
5. [Admin center only] Do not remove the valid Windows Autopilot device registration unless you have confirmed it is itself stale or duplicated.

### Phase 3: Remove the old management connection from the device
1. [Device access required: physical or remote interactive session] Sign in to the device with an account that can remove work or school connections.
2. [Device access required: physical or remote interactive session] Open Settings > Accounts > Access work or school.
3. [Device access required: physical or remote interactive session] Identify the existing work or school connection associated with the previous manual MDM enrolment.
4. [Device access required: physical or remote interactive session] Select that connection and choose Disconnect.
5. [Device access required: physical or remote interactive session] If multiple historical work or school connections exist, remove only the obsolete connection tied to the legacy manual enrolment and verify with the user record and enrolment date.
6. [Device access required: physical or remote interactive session] Restart the device after the disconnect completes.

### Phase 4: Reprepare the device for Autopilot
1. [Admin center only] Confirm the stale Intune managed device record is deleted and the intended Autopilot device record still exists.
2. [Device access required: physical or remote with reprovisioning control] Reset or wipe the device so that it returns to the Autopilot-ready out-of-box experience.
3. [Device access required: physical] If the device is being rebuilt locally, start the device through OOBE and connect it to a network with Microsoft enrolment endpoints reachable.
4. [Device access required: physical] Sign in during Autopilot with the intended user account.

### Phase 5: Allow Autopilot to complete and apply policy
1. [Admin center only] In Intune admin center, monitor the new device object under Devices > All devices.
2. [Admin center only] Confirm a fresh managed device record is created during the new Autopilot run.
3. [Admin center only] Confirm the Autopilot profile is assigned and the device receives policy.
4. [Admin center only] Check that the device progresses beyond enrolment and that profile/application counts are increasing normally.

## Correct Order Of Operations
1. Confirm the device identifiers and verify that a valid Windows Autopilot registration exists.
2. Delete the stale Intune managed device record for the old manual MDM enrolment.
3. Remove the old work or school management connection from the device itself.
4. Restart the device.
5. Reset or wipe the device back to an Autopilot-ready state.
6. Run the device through Autopilot again.
7. Verify that a new Intune managed device object is created and policy begins applying.

## Verification Check After Remediation
Autopilot should be considered successfully remediated only when all of the following are true:
- [Admin center only] In Intune admin center > Devices > All devices, a new managed device record appears for the rebuilt device with a current check-in time.
- [Admin center only] The device shows as enrolled through the expected MDM path and is no longer tied to the old legacy manual enrolment.
- [Admin center only] The Windows Autopilot device record remains present and assigned to the expected Autopilot deployment profile.
- [Admin center only] The device progresses from enrolment into policy receipt, and profile/application status no longer shows 0 applied.
- [Device access required: physical or remote interactive session] On the device, Settings > Accounts > Access work or school shows only the intended current management relationship after enrolment.
- [Admin center only] The device can complete its first sync and receive the targeted baseline/profile set without repeating the same enrolment failure.

## Fastest Practical Success Test
Use this as the minimum confirmation sequence after rerunning Autopilot:
1. [Admin center only] Confirm the old managed device object is gone.
2. [Admin center only] Confirm a new managed device object is created after OOBE sign-in.
3. [Admin center only] Confirm the new object checks in successfully and shows assigned policy activity.
4. [Device access required: physical or remote interactive session] Confirm the device no longer shows the old legacy work or school enrolment connection.

## Preventive Action For Other Legacy-Enrolled Devices
Implement a pre-Autopilot cleanup control for reused devices.

Recommended preventive action:
- [Admin center only] Before assigning or reassigning a device to Autopilot, check Devices > All devices for an existing managed device record tied to the same hardware or user.
- [Admin center only] If the device was previously enrolled by a manual or legacy method, delete the stale managed device object before reprovisioning.
- [Admin center only] Keep the Windows Autopilot registration but remove duplicate or obsolete managed device records.
- [Process change] Add a mandatory preflight step to the rebuild runbook: Verify no legacy MDM enrolment exists in Intune and no obsolete work or school connection remains on the endpoint before Autopilot is started.
- [Process change] Flag legacy-manually-enrolled devices in asset or rebuild workflow records so service desk and field engineers know they require enrolment cleanup before reuse.

## Analyst Conclusion
This incident is not a licensing, connectivity, or generic policy-processing problem. The blocking condition is the historical manual MDM enrolment still associated with the device. Cleanup must focus first on removing the stale MDM relationship in Intune and on the endpoint, then rerunning the device through a clean Autopilot flow while preserving the correct Windows Autopilot registration.