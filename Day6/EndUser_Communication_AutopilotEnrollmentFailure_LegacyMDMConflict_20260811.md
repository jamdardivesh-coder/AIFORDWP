# End-User Communications — Autopilot Enrolment Failure, Legacy MDM Conflict (2024-03-15)

## Audience 1 — Non-Technical Executive
Your device is being reprovisioned and will be ready shortly. On 2024-03-15, DESKTOP-FB099 used by rthomas could not complete its automated Windows setup because it still held a previous IT management record from 2023 that was not removed before the new setup began. No data was lost and no security breach occurred. IT has confirmed the cause and is clearing the old record so the device can complete setup correctly. Future device rebuilds will include a mandatory cleanup check before automated setup begins.

## Audience 2 — Affected End User (rthomas)
Hi, your device DESKTOP-FB099 ran into a problem during its automated setup on 2024-03-15. It kept a connection to an older IT management record from 2023 that blocked the new setup from completing. This is an IT configuration issue and nothing you did caused it. Your data is safe and no security issue occurred. IT is clearing the old record and will rerun the setup. Once complete, you will receive your device back ready to use. If you have questions in the meantime, contact the Service Desk and quote reference INC-2024-0315-AUTOPILOT-FB099.

## Audience 3 — Engineer-to-Engineer Internal Note
No data loss or security impact. Device DESKTOP-FB099 will require a stale managed device record cleanup and a clean Autopilot rerun before it is usable.

Incident facts:
- Date/time: 2024-03-15 09:18:44 failure recorded.
- Affected device: DESKTOP-FB099.
- Affected user: FINBRIDGE\rthomas.
- OS build at time of export: 22621.2861.
- Enrollment type: Autopilot.

Root cause:
- Device carried a legacy manual MDM enrolment from 2023-11-04 that was not removed before Autopilot was attempted.
- Autopilot reported EnrollmentState = Failed, ErrorCode = 0x80180014, ErrorDescription = "The device is already enrolled in MDM".
- Policy application returned 0 of 4 profiles applied; compliance engine could not evaluate; both are downstream of the enrolment failure.
- Licensing (Intune P1, M365) and network reachability (all endpoints OK, no proxy) confirmed as not causal.

Exact action required:
1. Intune admin center > Devices > All devices: record device identifiers, then delete the stale managed device record.
2. Confirm the valid Autopilot device registration is preserved in Devices > Windows > Windows enrollment > Devices > Windows Autopilot devices.
3. On the device: Settings > Accounts > Access work or school > Disconnect the legacy connection.
4. Restart the device.
5. Reset or wipe to OOBE.
6. Rerun Autopilot with the intended user account.

Verification required before returning device:
- New managed device object appears in Intune with current check-in time.
- Applied profile count is no longer 0.
- Compliance evaluation can run.
- Device-side Access work or school shows only the current management connection.

Preventive action needed:
- Add mandatory preflight check to the rebuild runbook: verify no legacy MDM managed device record exists in Intune and no obsolete work or school connection remains on the endpoint before Autopilot is started.
- Flag previously manually enrolled devices in the asset or rebuild workflow so field and service desk engineers know cleanup is required before redeployment.

If recurrence occurs, route through Service Desk under INC-2024-0315-AUTOPILOT-FB099 and run the preflight cleanup check first.