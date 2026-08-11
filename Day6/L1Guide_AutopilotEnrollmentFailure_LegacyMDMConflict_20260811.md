# L1 Service Desk Guide — Autopilot Enrolment Failure, Device Already Enrolled in MDM

## Summary (one line)
Device fails Windows Autopilot enrolment with error 0x80180014 because a previous legacy MDM enrolment was never removed before the new setup was started.

## Impact (who / how many / business urgency)
- Who: Any user whose device was previously managed through a manual or legacy MDM process and is now being redeployed through Autopilot.
- How many: One confirmed device (DESKTOP-FB099, user rthomas) in the recorded incident; other reused legacy-enrolled devices may present the same symptom.
- Business urgency: High. The device cannot complete setup, cannot receive policy, and is not usable until the stale enrolment is removed and Autopilot is rerun.

## Known Facts
- Device: DESKTOP-FB099. User: FINBRIDGE\rthomas.
- Autopilot enrolment failed on 2024-03-15 with error 0x80180014 ("The device is already enrolled in MDM").
- A legacy manual MDM enrolment from 2023-11-04 was still active on the device.
- Zero policy profiles applied. Compliance could not evaluate. Both are a result of the enrolment failure, not additional separate faults.
- Licensing (Intune P1, M365) and network connectivity to Microsoft endpoints were confirmed healthy and are not the cause.

## What L1 Should Check First
1. Ask the user or reporting engineer: has this device been used before and was it previously set up manually with a work or school account?
2. In Intune admin center, go to Devices > All devices and search for the device by name or serial number. Check whether a managed device record already exists with an older check-in date.
3. Confirm the error code reported matches 0x80180014. If it does, the cause is a conflicting existing enrolment and this guide applies.

## What L1 Should NOT Attempt
- Do not delete any device records in Intune without L2/L3 confirmation. Deleting the wrong record can remove the valid Autopilot registration.
- Do not attempt to re-enrol the device without first clearing the stale managed device record.
- Do not troubleshoot licensing or network connectivity. These are confirmed not causal for this error code.

## L1 Action
1. Raise or escalate to L2/L3 with the following information collected:
   - Device hostname and serial number.
   - Username and department of the affected user.
   - Screenshot or note of the error code (0x80180014) if visible.
   - Confirmation of whether the device was previously manually enrolled (ask the user or check asset history).
2. Log the ticket with category: Endpoint — Autopilot enrolment failure — legacy MDM conflict.
3. Advise the user that the device cannot be used until IT completes the cleanup and rerun. Provide a realistic expectation that the device will need to be physically reset and reprovisioned.

## Escalation Trigger
Escalate immediately to L2/L3 if:
- The error code is confirmed as 0x80180014.
- Intune shows an existing managed device object for the affected hardware.
- The device was previously manually enrolled.

Do not attempt further troubleshooting at L1 beyond information gathering for this error code.

## What L2/L3 Will Do (for L1 awareness)
- Confirm the stale Intune managed device record and preserve the valid Autopilot registration.
- Delete the stale managed device record from Intune.
- Remove the old work or school connection from the device.
- Reset the device to out-of-box state and rerun Autopilot.
- Verify a new managed device object is created and policy applies before returning the device.

## Likely Category
Endpoint — Autopilot enrolment blocked by pre-existing legacy MDM enrolment.

## Reference
- Incident reference: INC-2024-0315-AUTOPILOT-FB099
- Detailed RCA: RCA_AutopilotEnrollmentFailure_LegacyMDMConflict_DetailedAnalysis_20260811.md
- Known Error: KnownError_AutopilotEnrollmentFailure_LegacyMDMConflict_20260811.md
