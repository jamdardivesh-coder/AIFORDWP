# Windows 11 Intune Compliance Policy Translation (DWP)

## Version Header
- Version: v1.0
- Date: 11/08/2026
- Status: Draft
- Audience: DWP Endpoint Engineering (L2/L3)
- Scope: Translate baseline controls to Microsoft Intune compliance policy settings for Windows 11 devices

## Policy Context
- Intune policy type: Device compliance policy
- Platform: Windows 10 and later (applies to Windows 11)
- Baseline input date: 2026-08-11
- Tenant-validated navigation baseline: Devices > Manage devices > Compliance

## Exact UI Creation Sequence (Tenant-Validated)
1. Intune admin center > Devices > Manage devices > Compliance > Policies > Create policy.
2. In Create a policy pane: Platform = Windows 10 and later, Profile type = Windows 10/11 compliance policy, then select Create.
3. Step 1 Basics: enter Name (required), optional Description, then Next.
4. Step 2 Compliance settings: configure categories and settings listed below.
5. Step 3 Actions for noncompliance: set Mark device noncompliant schedule to 7 days.
6. Step 4 Assignments: add target groups/users/devices and filters if used.
7. Step 5 Review + create: validate and create policy.

## Requirement-to-Setting Mapping

### Requirement 1: BitLocker must be enabled on the OS drive
- Settings name: Require BitLocker
- Value: Require
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > Device Health > Require BitLocker
- UI path change risk: Low (validated in tenant wizard flow from screenshots)
- Effect: Device is noncompliant unless BitLocker state is attested as enabled for OS drive protection.
- False-positive risk: Health attestation is measured at boot. A device that just finished encryption can still show noncompliant until restart and next check-in.
- Recommendation: Keep this setting at Require. Add operational runbook steps: force reboot after BitLocker enablement and trigger Company Portal sync before escalation.

### Requirement 2: Secure Boot must be enabled
- Settings name: Require Secure Boot to be enabled on the device
- Value: Require
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > Device Health > Require Secure Boot to be enabled on the device
- UI path change risk: Low (validated in tenant wizard flow from screenshots)
- Effect: Device is noncompliant if Secure Boot is disabled or cannot be attested.
- False-positive risk: Older/unsupported TPM hardware (especially non-TPM 2.0 scenarios) can report noncompliant even when endpoint is otherwise healthy for business use.
- Recommendation: Keep Require for corporate-managed Windows 11 hardware standards. Use assignment filters to exclude approved legacy exception devices instead of weakening the control.

### Requirement 3: Minimum OS build must be N-1 (22621.2861)
- Settings name: Minimum OS version
- Value: 10.0.22621.2861
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > Device Properties > Minimum OS version
- UI path change risk: Low (validated in tenant wizard flow from screenshots)
- Effect: Devices below build 22621.2861 are marked noncompliant and can be blocked by Conditional Access.
- False-positive risk: Reporting lag after update install (pending reboot) or stale check-in can temporarily show old build.
- Recommendation: Keep the minimum version. Pair with quality update ring deadlines and add user messaging to restart after patching.

### Requirement 4: Microsoft Defender antimalware and real-time protection must be on
- Settings name: Microsoft Defender Antimalware
- Value: Require
- Settings name: Real-time protection
- Value: Require
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > System Security > Defender > Microsoft Defender Antimalware and Real-time protection
- UI path change risk: Low (validated in tenant wizard flow from screenshots)
- Effect: Defender antimalware service must be enabled first, and real-time protection must also be enabled for the device to be compliant.
- False-positive risk: Third-party AV transitions, Defender service startup delays, tamper-protection conflicts, or missing Defender onboarding can cause Real-time protection to remain unavailable until Microsoft Defender Antimalware is enabled.
- Recommendation: Set both Microsoft Defender Antimalware and Real-time protection to Require. If you have a third-party AV strategy, confirm the device is still reporting Microsoft Defender Antimalware status correctly before enforcing this control.

### Requirement 5: Firewall must be enabled for all profiles
- Settings name: Firewall
- Value: Require
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > System Security > Device security > Firewall
- UI path change risk: Low (validated in tenant wizard flow from screenshots)
- Effect: Device is noncompliant if Windows Firewall is off. This is intended to enforce firewall-on posture across profiles.
- False-positive risk: Immediate post-boot sync can return transient Error/noncompliant, and conflicting on-prem GPO firewall settings can override Intune evaluation.
- Recommendation: Keep Require. Remove conflicting GPOs or migrate firewall config ownership to Intune to avoid policy collision.

### Requirement 6: A PIN or password must be configured
- Settings name: Require a password to unlock mobile devices
- Value: Require
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > System Security > Password > Require a password to unlock mobile devices
- UI path change risk: Low (validated in tenant wizard flow from screenshots; naming remains legacy)
- Effect: User must have an unlock secret (password/PIN) configured for device access.
- False-positive risk: Shared kiosks, specialty device modes, or mismatched local sign-in method policies can fail this check.
- Recommendation: Keep Require for user productivity devices. For stricter posture without extra noise, add Password type = Device default and Minimum password length aligned to your standard.

### Requirement 7: Device must not be jailbroken or rooted
- Settings name: Require the device to be at or under the machine risk score
- Value: Low
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 2 Compliance settings > Microsoft Defender for Endpoint > Require the device to be at or under the machine risk score
- UI path change risk: Low (validated in tenant wizard flow; visibility still depends on MDE integration health)
- Effect: Devices with elevated threat signals from Microsoft Defender for Endpoint are marked noncompliant.
- False-positive risk: This is not a literal jailbreak/root check for Windows. Sensor onboarding gaps, stale MDE telemetry, or temporary investigation signals can mark healthy devices noncompliant.
- Recommendation: Use this as the Windows equivalent control. Ensure 100% MDE onboarding health and tune SOC investigation workflow before moving from Medium to Low if your environment is noisy.

## Grace Period Configuration (All Settings)
- Settings name: Mark device non-compliant (action schedule)
- Value: Schedule (days after noncompliance) = 7
- UI path: Devices > Manage devices > Compliance > Policies > Create policy > Platform: Windows 10 and later > Profile type: Windows 10/11 compliance policy > Create > Step 3 Actions for noncompliance > Mark device noncompliant > Schedule (days after noncompliance) = 7
- UI path change risk: Low (action exists by default in all compliance policies; only tab layout can vary)
- Effect: Device can remain in grace period for 7 days after first noncompliant evaluation before full noncompliant enforcement applies.
- False-positive risk: Real noncompliant devices keep access during the grace window if Conditional Access is tied to compliance.
- Recommendation: Keep 7 days per requirement. Add email notifications at day 1 and day 5 to improve remediation speed without reducing security controls.

## Working Navigation Baseline
- Create policy path: Intune admin center > Devices > Manage devices > Compliance > Policies > Create policy > Platform = Windows 10 and later > Profile type = Windows 10/11 compliance policy > Create
- Post-deployment monitoring path: Intune admin center > Devices > Manage devices > Compliance > Monitor

## Post-Sync Validation and Triage

### 1. Where to check the device's compliance status for this specific policy
- Path: Intune admin center > Devices > Manage devices > Compliance > Policies > [Windows 11 Compliance Policy] > Monitor
- Best view: Device status for the overall policy result, then View report for device-level detail, then Per-setting status for individual setting results.
- Fastest drill-down: Open View report, locate the test device by Device name, then use Per-setting status if you need to confirm which control is driving noncompliance.

### 2. What the compliance states mean for Conditional Access
- Compliant: The device meets the policy and is allowed by Conditional Access, subject to any other CA controls.
- Not compliant: The device does not meet one or more policy settings and Conditional Access should block protected resources when compliance is required.
- In grace period: The device has failed one or more settings but is still inside the configured grace window, so Conditional Access can continue to allow access until the grace period expires.

### 3. If BitLocker shows noncompliant even though BitLocker is enabled, check these first
- Cause 1: BitLocker was enabled or resumed, but the device has not rebooted after the change.
	- Fastest check: Confirm the device has completed a post-change restart, then force a sync and recheck the BitLocker setting in Per-setting status.
- Cause 2: Intune is still showing stale compliance data because the device has not refreshed since the encryption state changed.
	- Fastest check: Go to Devices > Manage devices > Compliance > Policies > [Windows 11 Compliance Policy] > Monitor > View report and confirm the Last contacted time is current.
- Cause 3: BitLocker is enabled but device health attestation has not yet reported the state cleanly, or a TPM/boot-state issue is preventing the attestation from being accepted.
	- Fastest check: Verify the device can complete a clean boot, then confirm BitLocker protection state locally with manage-bde -status and compare it to the Intune per-setting result.

### 4. First 24-hour validation checklist after assigning the policy
- Check Device status for the policy shortly after the first sync and again after the first reboot cycle.
- Review Per-setting status and look for a narrow, temporary increase in In grace period rather than a broad spike in Not compliant.
- Confirm BitLocker, Secure Boot, Defender, and Firewall settings are trending toward Compliant after the next check-in.
- If BitLocker is the only noisy setting, validate whether the affected devices are still in post-upgrade reboot completion rather than treating it as a true policy failure.

## Implementation Notes for DWP
- Keep this as a single Windows compliance policy for standard user endpoints unless you have legacy hardware exceptions.
- Use assignment filters for exception cohorts (for example, approved legacy BIOS/TPM edge cases) instead of diluting global settings.
- Validate with a pilot ring first, then production rings, and review Per-setting status 24 hours after deployment.
