# Known Error Record — Autopilot Enrolment Failure Due to Existing Legacy MDM Enrolment (INC-2024-0315-AUTOPILOT-FB099)

Symptom     : Windows Autopilot enrolment fails with error 0x80180014 ("The device is already enrolled in MDM"). Zero policy profiles are applied, the compliance engine cannot evaluate, and the device cannot be managed through the intended Autopilot deployment path.

Cause       : The device carries a pre-existing legacy manual MDM enrolment (source: 2023-11-04) that was not removed before the Autopilot enrolment attempt. Autopilot detects the conflicting active management relationship and terminates the enrolment flow.

Scope       : Any Windows device previously enrolled by manual or legacy MDM methods that is reused for an Autopilot deployment without first removing the old management relationship. In the recorded incident: device DESKTOP-FB099, user FINBRIDGE\rthomas, 2024-03-15.

Workaround  : Delete the stale Intune managed device record from Intune admin center (Devices > All devices), then disconnect the old work or school connection on the endpoint (Settings > Accounts > Access work or school > Disconnect), and restart the device. This removes the blocking enrolment state without yet rerunning Autopilot.

Permanent fix: Remove the stale managed device record from Intune and the legacy connection from the endpoint, reset the device to an Autopilot-ready OOBE state, and rerun Autopilot while preserving the valid Windows Autopilot device registration. Add a mandatory preflight cleanup step to the rebuild runbook so that no previously manually enrolled device reaches the Autopilot flow without first being de-enrolled.

How to spot it: Look for EnrollmentState = Failed, ErrorCode = 0x80180014, and ErrorDescription = "The device is already enrolled in MDM" in the MDM diagnostic export. Corroborate with MDMEnrolled = Yes (previous enrolment), EnrolmentSource showing a legacy or manual path, ProfilesApplied = 0 of N, and ComplianceEngine reporting "Could not evaluate / Enrolment not complete". Licensing present and all network endpoints reachable confirm that neither licensing nor connectivity is the cause.
