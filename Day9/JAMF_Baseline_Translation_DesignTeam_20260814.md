# macOS JAMF Baseline Translation (DWP Design Team)

## Version Header
- Version: v1.2
- Date: 14/08/2026
- Status: Draft
- Audience: DWP Endpoint Engineering (L2/L3)
- Scope: Translate baseline controls to JAMF Pro configuration profile and compliance-style monitoring settings for a 25-device Design team fleet

## Policy Context
- Management platform: JAMF Pro
- Device platform: macOS (mixed Apple Silicon and Intel possible)
- Baseline input date: 2026-08-14
- Tenant-validated navigation baseline:
	- Computers > Configuration Profiles
	- Computers > Smart Computer Groups
	- Computers > Search Inventory
- Recommended policy objects:
	- Configuration Profiles for on-device enforcement controls
	- Smart Groups for posture reporting and scoped remediation

## Critical Label-Verification Discipline (Same as Intune Day 6)
JAMF Pro payload names, pane groupings, and setting labels can move between releases. Apple also changes preference-domain behavior across macOS versions.

Do not treat exact wording in this document as immutable UI truth.
Verify exact payload label text and option values in your own JAMF Pro tenant before rollout.

## Exact UI Creation Sequence (Tenant-Validated Baseline)
1. Open JAMF Pro console > Computers > Configuration Profiles > New.
2. In General payload, set Name, Description, Category, and Distribution Method.
3. Set Scope to pilot Smart Group first (do not target all Design devices initially).
4. Add and configure required payloads listed in the requirement mapping section below.
5. Save profile and review for payload conflict warnings.
6. Force inventory/check-in on pilot endpoints, then confirm profile installation status in inventory.
7. Create or update Smart Groups for reporting-based controls (for example, minimum macOS version).
8. Validate pilot behavior for one full business day, then expand scope to production Design fleet.

## Baseline Profile Object Strategy
- Profile A: Core Security Baseline
	- FileVault
	- Gatekeeper
	- Firewall
- Profile B: Authentication/Session Baseline
	- Password required after sleep or screen saver
	- Login window/session lock controls (as applicable)
- Profile C: Update Baseline
	- Automatic security updates
	- System data files and security response controls

Why split profiles:
- Reduces rollback blast radius.
- Makes control ownership and troubleshooting clearer.
- Prevents unrelated payload failures from blocking all baseline controls.

## Requirement-to-Setting Mapping

### Requirement 1: FileVault disk encryption must be enabled
- Settings name: Enable FileVault
- Settings name: Escrow personal recovery key
- Payload type: Security and Privacy > FileVault (exact naming can vary by JAMF version).
- Value:
	- Enable FileVault.
	- Escrow personal recovery key to JAMF Pro.
	- Enforce enablement at login/logout if immediate silent enablement is not possible.
- UI path template: Computers > Configuration Profiles > New > Security and Privacy > FileVault.
- UI path change risk: Medium.
- Effect: Full-disk encryption is enforced and recovery key governance is centralized.
- False-positive risk: During in-progress encryption, immediately after OS update, or when escrow upload is delayed, healthy devices can appear noncompliant.
- Recommendation: Keep mandatory. Add runbook checks for both encryption state and escrow receipt before escalation.
- Verify label in tenant: Required.
- Operational verification points:
	- Inventory/security view shows FileVault enabled.
	- Recovery key escrow timestamp exists.
	- No endpoint remains in deferred-enable state beyond one sign-out/sign-in cycle.

### Requirement 2: Gatekeeper must be enabled (identified developers only)
- Settings name: App access allowed from identified developers
- Settings name: Do not allow Anywhere/unsigned app execution baseline
- Payload type: Security and Privacy > Gatekeeper (or Restrictions equivalent, depending on tenant/version).
- Value: Allow apps from App Store and identified developers only. Do not allow Anywhere.
- UI path template: Computers > Configuration Profiles > New > Security and Privacy > Gatekeeper.
- UI path change risk: Medium.
- Effect: Blocks unsigned or untrusted binaries, reducing malware execution risk.
- False-positive risk: Temporary local user override behavior, test tooling modifying quarantine handling, or delayed profile re-apply can create short-lived drift.
- Recommendation: Keep strict baseline. Sign/notarize approved internal tools instead of relaxing Gatekeeper globally.
- Verify label in tenant: Required.
- Operational verification points:
	- Endpoint settings reflect non-Anywhere app source policy.
	- No broad bypass profile is co-scoped.
	- Exceptions are temporary and tracked with owner and expiry.

### Requirement 3: Minimum macOS version must be current stable minus one point release
- Settings name: Operating System Version Smart Group criterion
- Settings name: Below-baseline remediation group membership
- Control model: Reporting/enforcement through Smart Groups (not always a single configuration profile payload).
- Value:
	- Define approved minimum version variable as current stable minus one point release.
	- Build Smart Group criteria to identify devices below threshold.
	- Review baseline monthly or per Apple point release.
- UI path template:
	- Smart Group creation: Computers > Smart Computer Groups > New > Criteria.
	- Remediation flow: use Smart Group output in service operations and user communications.
- UI path change risk: High.
- Effect: Devices below approved patch posture are identified quickly for remediation or access decisions.
- False-positive risk: Inventory lag, pending reboot, and delayed check-in can report old version temporarily.
- Recommendation: Treat as compliance logic, not profile-only enforcement.
- Verify label in tenant: Required.
- Smart Group criteria baseline example:
	- Criterion: Operating System Version
	- Operator: less than
	- Value: <approved minimum>
	- Membership action: add device to Design-macOS-Below-Baseline
- Operational verification points:
	- Membership decreases after patch window.
	- Pending-restart devices are separated from true below-baseline devices.

### Requirement 4: Firewall must be enabled
- Settings name: Enable Firewall
- Settings name: Enable Stealth Mode (optional, if approved)
- Payload type: Security and Privacy > Firewall.
- Value: Enable firewall. Optionally enable stealth mode if support tooling remains functional.
- UI path template: Computers > Configuration Profiles > New > Security and Privacy > Firewall.
- UI path change risk: Medium.
- Effect: Reduces inbound attack surface by blocking unsolicited incoming connections.
- False-positive risk: Reboot-time state transitions, stale inventory, or conflicting local scripts can generate temporary noncompliance.
- Recommendation: Keep mandatory and validate core collaboration tools in pilot.
- Verify label in tenant: Required.
- Operational verification points:
	- Firewall enabled after reboot and inventory update.
	- No legacy scripts toggling firewall state.
	- Design collaboration workflows remain functional.

### Requirement 5: Login password required after sleep or screen saver
- Settings name: Require password after sleep or screen saver
- Settings name: Grace period after sleep or screen saver
- Payload type: Login Window and/or Security and Privacy authentication controls (version-dependent).
- Value: Require password immediately after sleep/screen saver starts, or approved short grace period if formally accepted.
- UI path template:
	- Computers > Configuration Profiles > New > Login Window
	- or Computers > Configuration Profiles > New > Security and Privacy authentication controls
- UI path change risk: High.
- Effect: Prevents unauthorized access to unattended endpoints.
- False-positive risk: Local setting conflicts, accessibility exceptions, or inconsistent grace-period controls can produce noisy findings.
- Recommendation: Default to immediate prompt. If Design workflow requires grace period, define one approved value and scope exceptions narrowly.
- Verify label in tenant: Required.
- Operational verification points:
	- Manual sleep/wake test enforces authentication as configured.
	- No contradictory profile payload applied.
	- Accessibility exceptions are isolated in dedicated scoped groups.

### Requirement 6: Automatic security updates must be enabled
- Settings name: Automatically check for updates
- Settings name: Automatically install security updates and system data files
- Settings name: Install Rapid Security Responses where available
- Payload type: Software Update payload, with supplemental update controls where available.
- Value:
	- Enable automatic update checks.
	- Enable automatic installation of security updates and system data files.
	- Enable rapid security response installation if present in tenant/version.
- UI path template: Computers > Configuration Profiles > New > Software Update.
- UI path change risk: High.
- Effect: Reduces dependency on user-driven patch actions and shortens vulnerability exposure time.
- False-positive risk: Pending restart, Apple update service delays, deferred update windows, or stale inventory snapshots.
- Recommendation: Keep enabled and pair with restart communication windows to avoid disruption to creative sessions.
- Verify label in tenant: Required.
- Operational verification points:
	- Update preferences persist after reboot.
	- Security update events appear in history/inventory.
	- Repeated restart deferrals are tracked for targeted follow-up.

## Remediation Window Configuration (JAMF Equivalent to Intune Grace Period)
- Control type: Operational remediation SLA and Smart Group-based follow-up, not a native configuration profile grace-period setting.
- Value:
	- Day 0: detect and notify.
	- Day 2: force inventory refresh and send restart/update reminder.
	- Day 5: escalate to endpoint operations queue.
	- Day 7: treat as formal noncompliance for support and exception-review purposes.
- UI path: No exact one-for-one JAMF configuration profile setting equivalent. Implement through Smart Groups, notifications, dashboards, and operational workflow.
- UI path change risk: High, because this is process design rather than one fixed JAMF payload.
- Effect: Creates a controlled remediation window similar to an Intune grace period without pretending JAMF has the same built-in compliance action model.
- False-positive risk: Healthy devices with stale inventory or pending restart can remain in a remediation Smart Group longer than necessary if follow-up automation is weak.
- Recommendation: Keep the 7-day operational window, but ensure day-1 and day-5 user notifications are documented and monitored.
- Verify label in tenant: Required, strongly.

## Compliance-State Model and Remediation Timeline
- Recommended compliance states:
	- Compliant: Required controls applied and verified.
	- At risk: Expected controls present but stale data, pending restart, or pending escrow confirmation.
	- Noncompliant: Required control absent or failed after validation window.
- Recommended remediation schedule for 25-device Design fleet:
	- Day 0: detect drift and notify user.
	- Day 2: rerun inventory and issue restart reminder.
	- Day 5: escalate to endpoint operations queue.
	- Day 7: classify as high-priority remediation item.
- Exception model:
	- Use time-bound exception Smart Group.
	- Require owner and expiry.
	- Review and remove expired exceptions weekly.

## Working Navigation Baseline
- Create profile path: JAMF Pro > Computers > Configuration Profiles > New.
- Smart Group path: JAMF Pro > Computers > Smart Computer Groups > New.
- Post-deployment monitoring path: JAMF Pro > Computers > Search Inventory and Smart Computer Groups.

## Device Verification Path (Verify in Tenant)
- Path: JAMF Pro > Computers > Search Inventory > [Device] > Profiles/Security/General tabs.
- Best view: Check profile installation status first, then validate the corresponding security or OS posture value in inventory.
- Fastest drill-down: Open the device inventory record, confirm the baseline profile is installed, then compare that to the specific security control state.

## Post-Deployment Validation and Triage

### 1. Where to check baseline status on a specific Mac
- Primary check: Inventory record for profile installation and security posture fields.
- Secondary check: Smart Group membership for each baseline criterion.
- Fastest drill-down: Confirm profile install first, then underlying security state.

### 2. What healthy vs unhealthy means operationally
- Healthy: Profile installed, expected state confirmed, compliant Smart Group membership.
- At risk: Profile present but stale or contradictory state due to check-in/reboot timing.
- Unhealthy: Profile missing, overridden state, or below minimum OS baseline after validation window.
- Escalation trigger: Treat as true unhealthy only after one forced inventory refresh and one reboot cycle, unless a hard failure is already confirmed.

### 3. What the compliance states mean for access or support decisions
- Compliant: Device meets baseline and can remain in normal support and access posture.
- At risk: Device is likely healthy but still awaiting reboot, escrow confirmation, or fresh inventory; do not escalate immediately.
- Noncompliant: Device failed one or more baseline controls after the validation window and should be prioritized for remediation or exception review.

### 4. If FileVault appears noncompliant even when enabled, check these first
- Cause 1: Encryption still in progress.
	- Fast check: confirm local conversion status and retest after completion.
- Cause 2: Recovery key escrow incomplete.
	- Fast check: verify escrow receipt in JAMF inventory/security.
- Cause 3: Inventory stale.
	- Fast check: trigger inventory update and refresh device record.

### 5. If Gatekeeper appears out of baseline, check these first
- Cause 1: A local/admin workflow temporarily bypassed app assessment.
	- Fast check: confirm no local override or troubleshooting exception was applied.
- Cause 2: Multiple profiles are setting contradictory application security behavior.
	- Fast check: review effective profile set on the device for overlapping payloads.
- Cause 3: Inventory reflects stale posture after profile change.
	- Fast check: force inventory/check-in and re-evaluate device record.

### 6. If minimum macOS version appears noncompliant after patching, check these first
- Cause 1: Update installed but restart pending.
	- Fast check: verify pending restart and retest after reboot.
- Cause 2: Smart Group criteria value is outdated.
	- Fast check: compare criteria value to approved baseline in change record.
- Cause 3: Inventory not refreshed post-update.
	- Fast check: trigger inventory update and confirm current check-in timestamp.

### 7. If Firewall appears disabled even though the baseline profile is applied, check these first
- Cause 1: Another profile or local script is reverting firewall state.
	- Fast check: review recent management scripts and overlapping security payloads.
- Cause 2: Inventory captured a transient reboot-time state.
	- Fast check: retest after full reboot and fresh inventory update.
- Cause 3: Support or remote-access tooling requested a temporary exception.
	- Fast check: confirm whether the device is in an approved exception scope.

### 8. If password-after-sleep appears noncompliant, check these first
- Cause 1: The device has a grace period configured locally that differs from the baseline.
	- Fast check: compare current local setting to the approved grace-period value.
- Cause 2: Accessibility or kiosk-style exception handling is in place.
	- Fast check: verify the device is not mis-scoped into an exception group.
- Cause 3: The payload is installed but the behavior was not validated by an actual sleep/wake test.
	- Fast check: run a manual sleep test and confirm prompt behavior.

### 9. If automatic security updates appear noncompliant, check these first
- Cause 1: Update settings are applied but a restart is still pending.
	- Fast check: confirm restart requirement and retest after reboot.
- Cause 2: Apple update catalog or service connectivity failed during the reporting window.
	- Fast check: verify the issue is not tied to a temporary Apple service reachability problem.
- Cause 3: Another update-management control is deferring installation behavior.
	- Fast check: compare Software Update payload settings against any separate deferral policy.

### 10. First 24-hour validation checklist after assignment
- Confirm pilot devices receive profile without install errors.
- Verify FileVault, Firewall, and Gatekeeper states after at least one reboot cycle.
- Validate password-after-sleep behavior with actual lock/sleep test.
- Confirm Software Update settings persist through reboot.
- Confirm Smart Group logic correctly identifies below-baseline OS versions.

### 11. Recommended evidence to capture for audit or CAB handoff
- Screenshot or export of each configuration profile payload used for the baseline.
- Smart Group criteria showing minimum macOS version logic.
- Pilot device inventory views proving FileVault, Firewall, and profile install state.
- Evidence of recovery key escrow for at least one pilot device.
- One completed sleep/wake validation record and one software update posture validation record.

## Known Conflict Patterns and Preventive Controls
- Pattern: overlapping profiles set contradictory values.
	- Preventive control: one owning profile per control family and conflict review before production expansion.
- Pattern: local admin script reverts managed setting.
	- Preventive control: retire legacy local enforcement scripts once JAMF profile ownership is active.
- Pattern: stale inventory causes false noncompliance spikes.
	- Preventive control: include freshness threshold in dashboards and suppress stale-only incident auto-creation.

## Change and Rollback Guidance
- Pre-change capture:
	- Export or screenshot current payload settings and scope.
	- Record current Smart Group criteria and member counts.
- Rollback approach:
	- Unscope failing profile from pilot Smart Group first.
	- Revert only affected profile object (A, B, or C) instead of all controls.
	- Trigger inventory refresh and verify return to prior known-good state.
- Production expansion gate:
	- Minimum 24 hours pilot stability.
	- No unresolved FileVault escrow failures.
	- No sustained false positives caused by stale inventory.

## Implementation Notes for DWP
- Use a pilot ring of 3-5 devices first, covering both Apple Silicon and Intel where present.
- Pre-validate key creative applications before strict update/restart expectations.
- Do not weaken baseline globally for isolated exceptions.
- Use scoped, expiring exception groups with documented owner.
- Re-validate payload names and labels after every JAMF Pro major upgrade.
