# Windows Application Intake Guide For Intune App Catalog (DWP)

## Version Header
- Version: v1.0
- Date: 11/08/2026
- Status: Draft
- Audience: DWP Endpoint Engineering (L1-L3)
- Scope: Step-by-step guide for adding a Windows application to the Intune app catalog before any phased rollout begins

## Worked Example Used Throughout
- Application name: FinBridge Connect v3.1
- Packaging type: Windows LOB app packaged as `.intunewin`
- Install command: `FinBridgeConnect_Setup.exe /silent`
- Uninstall command: `FinBridgeConnect_Setup.exe /uninstall /silent`
- Detection method: Registry key
- Detection path: `HKLM\SOFTWARE\FinBridge\Connect`
- Detection value name: `Version`
- Expected value: `3.1`

## Important UI Warning
- Exact Intune admin center labels can vary by tenant version, portal updates, preview features, and role-based views.
- Use the navigation labels in this guide as a working baseline, but verify each label live in your own tenant before proceeding.
- If a label differs slightly, follow the closest matching Apps, Windows, Add, Create, Assignments, Monitor, or Device status path rather than assuming the portal is wrong.

## Purpose Of This Guide
This guide is for the point before any phased rollout begins. The objective is to get the application into the Intune app catalog correctly, configure the minimum required metadata and install logic, assign it only to a small pilot group first, and verify that installation reporting works before any wider deployment.

## Exact Navigation Baseline
- Primary app catalog path: Intune admin center > Apps > All apps
- Add app path baseline: Intune admin center > Apps > All apps > Add
- Monitoring baseline after creation: Intune admin center > Apps > All apps > [App name] > Monitor
- UI label change risk: Medium. Some tenants show Add app, Create, Select app type, or App type as slightly different labels. Verify live before selecting.

## Step-By-Step Guide

### 1. Open the Intune app catalog
1. Sign in to the Intune admin center with an account that can create and assign apps.
2. Go to Apps > All apps.
3. Verify you are in the tenant where the application should be published.
4. Select Add.
5. If your tenant shows Add app or Create instead of Add, use that option and verify it opens the app creation flow.

### 2. Select the correct app type
1. In the Select app type panel, locate the Platform dropdown and select Windows.
2. In the app type picker, identify the app category for the package you are uploading.
3. For a Windows LOB app packaged as `.intunewin`, select Windows app (Win32).
4. For a Microsoft Store application, select the Microsoft Store app option shown by your tenant, commonly Microsoft Store app (new).
5. For a web link, select Web link.
6. Do not select Microsoft Store app or Web link for FinBridge Connect v3.1, because the worked example is a packaged Windows application delivered as `.intunewin`.
7. UI label change risk: High. Some engineers informally call this a Windows LOB app, but in Intune the `.intunewin` flow is normally surfaced as Windows app (Win32). Verify the upload flow accepts an `.intunewin` package before continuing.

### 3. Start the FinBridge Connect app creation flow
1. After selecting Windows app (Win32), choose Select or Create depending on the portal label shown.
2. On the App package file step, browse to and upload the `FinBridge Connect v3.1` `.intunewin` package.
3. Wait for Intune to process the package metadata.
4. Confirm the package upload completes without validation error before moving to the next page.

### 4. Complete the required app information fields
1. Open the App information section.
2. Enter Name as `FinBridge Connect v3.1`.
3. Enter Description as a clear operational description, for example: `FinBridge Connect desktop client for managed Windows devices.`
4. Enter Publisher as `FinBridge`.
5. Enter Version as `3.1` if the portal exposes an explicit version field for the app metadata.
6. Add optional fields such as category, developer contact details, information URL, privacy URL, logo, or notes only if your tenant standard requires them.
7. Verify that the name and publisher are correct because these fields will be used later by engineers reviewing catalog entries and deployment reports.
8. UI label change risk: Medium. Some tenants surface App version, Display version, or allow version to be inferred from package metadata. Verify the field naming live.

### 5. Configure the program section
1. Open the Program section.
2. Set Install command to `FinBridgeConnect_Setup.exe /silent`.
3. Set Uninstall command to `FinBridgeConnect_Setup.exe /uninstall /silent`.
4. Set Install behavior to System for this worked example.
5. Use System context when the application should install for the device and write under `HKLM`, install to `Program Files`, or not depend on the signed-in user profile.
6. Use User context only when the application installs per-user and depends on the user session or user-writable profile paths.
7. For FinBridge Connect v3.1, System is the correct default because the detection rule is under `HKLM\SOFTWARE`, which implies a machine-level install footprint.
8. If the portal exposes device restart behavior, leave it aligned to the package owner’s tested guidance and document any forced restart before pilot assignment.
9. UI label change risk: Medium. Some tenants show Install behavior, Device restart behavior, or Command-line arguments with slightly different page layouts. Verify the live fields before saving.

### 6. Configure requirements
1. Open the Requirements section.
2. Set Operating system architecture to the architecture supported by the package.
3. If FinBridge Connect v3.1 is intended only for modern corporate Windows 11 endpoints, set architecture to 64-bit.
4. Set Minimum operating system to the lowest supported Windows version for your estate standard.
5. If your DWP standard is Windows 11 only, select the minimum Windows 11 release required by the application and confirm it matches platform support testing.
6. Do not set requirements broader than the tested support matrix, because unsupported devices can receive the app and then fail installation.
7. UI label change risk: Medium. Some tenants group these under Requirements rules, Operating system, or Minimum OS. Verify live before finalizing.

### 7. Configure detection rules
1. Open the Detection rules section.
2. Choose Manually configure detection rules if the package is not MSI-based or if you need a custom success check.
3. For FinBridge Connect v3.1, use a registry-based detection rule.
4. Set Rule type to Registry.
5. Set Key path to `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect` or the portal equivalent without the expanded hive prefix if required by that UI.
6. Set Value name to `Version`.
7. Set Detection method to String comparison or Value equals, depending on the wording shown in your tenant.
8. Set the expected value to `3.1`.
9. Save the rule and verify the summary clearly shows that Intune will treat the app as installed only when that registry value exists and equals `3.1`.
10. Detection rule alternatives you may see in other apps:
- MSI product code: Use when the app is MSI-based and the Windows Installer product code is the best unique identifier.
- File or folder path: Use when a stable executable or file path proves installation more reliably than registry data.
- Registry key: Use when the vendor reliably writes a unique machine or user registry marker for the installed version.
11. For this worked example, registry detection is appropriate because the required proof point is `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`.
12. UI label change risk: High. The detection UI varies between tenants and package types. Verify whether the portal expects Key path, Registry path, Value name, Detection method, Associated with a 32-bit app on 64-bit clients, or similar fields.

### 8. Configure dependencies
1. Open the Dependencies section after completing Detection rules.
2. Dependencies are applications that must already be installed on the device before Intune will attempt to install this app.
3. If FinBridge Connect v3.1 has no prerequisite applications, leave this section empty and proceed. No results is the expected default for most standalone applications.
4. If a dependency is required, select Add and search for the prerequisite app that already exists in the Intune catalog.
5. For each dependency added, review the Automatically Install toggle.
6. Set Automatically Install to Yes if Intune should silently install the dependency app before installing FinBridge Connect v3.1 when the dependency is not already detected on the device.
7. Set Automatically Install to No if Intune should only block installation of FinBridge Connect v3.1 when the dependency is missing, without attempting to install it automatically.
8. A maximum of 100 child dependency apps can be added, and the total dependency graph including the parent app cannot exceed 101 apps.
9. For FinBridge Connect v3.1 in this worked example, no dependencies are required. Leave the section empty unless the package owner confirms a prerequisite.
10. UI label change risk: Low. The Dependencies tab label and layout are generally consistent, but the Automatically Install toggle label may vary slightly. Verify live before saving.

### 9. Configure supersedence
1. Open the Supersedence section after completing Dependencies.
2. Supersedence defines whether this app replaces or updates a previous version or a different application already present on the device.
3. If FinBridge Connect v3.1 supersedes an older version such as FinBridge Connect v3.0, select Add and choose the older app from the Intune catalog.
4. For each superseded app, review the Uninstall previous version toggle.
5. Set Uninstall previous version to Yes if Intune should remove the older app before installing this version. Use this when the old and new versions cannot coexist on the same device.
6. Set Uninstall previous version to No if the installer handles the upgrade silently and the old app does not need to be removed separately by Intune.
7. If this is the first version of FinBridge Connect entering the catalog and no previous version exists in Intune, leave the Supersedence section empty and proceed.
8. Do not add supersedence relationships without confirming with the package owner whether the installer handles in-place upgrade or requires a clean uninstall first.
9. UI label change risk: Medium. Some tenants label this Supersedence, Supersedes, or Replaces. Verify the live label before saving.

### 10. Review return codes
1. Open the Return codes section.
2. Review the default Intune return code mappings shown by the portal before saving.
3. Ensure the installer’s actual exit codes are mapped correctly.
4. At minimum, confirm which codes Intune will treat as Success, Soft reboot, Hard reboot, Retry, or Failed.
5. If the package owner confirms only exit code `0` indicates success, keep `0` mapped to Success and leave unverified non-zero codes mapped conservatively until tested.
6. If the vendor provides additional known codes such as reboot-required or retryable codes, add them explicitly before pilot rollout.
7. Do not guess at unfamiliar exit codes. Verify them against the application packaging notes or installer documentation.
8. UI label change risk: Medium. Some portals show Return codes as a separate page and others show it near Program. Verify live.

### 11. Complete scope tags if your tenant uses them
1. Open Scope tags if your operational model requires them.
2. Apply the correct DWP scope tag for ownership and delegated administration.
3. If scope tags are not used in your tenant, leave this section unchanged.

### 12. Review and create the app
1. Open Review + create.
2. Check that the app type is Windows app (Win32).
3. Check that the uploaded package is the correct `.intunewin` file.
4. Check that the app information fields show `FinBridge Connect v3.1`, publisher `FinBridge`, and version `3.1`.
5. Check that the install and uninstall commands exactly match the tested syntax.
6. Check that Install behavior is System.
7. Check that the requirements match the intended target estate.
8. Check that the detection rule points to the correct registry location and value.
9. Select Create.
10. Wait for the app object to appear in the Intune catalog.

## Assignment Basics

### 13. Understand the three main assignment types
1. Required means Intune pushes the app automatically to the targeted user or device group without the user choosing to install it.
2. Available means the app is offered to the targeted users, usually through Company Portal, and the user can choose to install it.
3. Uninstall means Intune removes the app from the targeted group if the app is currently installed and the uninstall command works.
4. Required is the riskiest assignment type because it actively deploys the app to every member of the target group.
5. Available is the safest first option when you want controlled user-led testing.
6. Uninstall should be used deliberately and never assigned broadly without confirming the uninstall command and detection logic are correct.

### 14. Assign the new app to a pilot group first
1. Open the Assignments section of the app.
2. Do not assign a new app directly to the full production estate.
3. Create or select a small pilot group first, for example a DWP engineering validation group or a small controlled business test group.
4. Add the pilot group under Required if you need a forced installation test, or under Available if you want the test users to self-install through Company Portal.
5. For an initial packaging validation, a small pilot group is essential because it limits blast radius if the install command, detection rule, uninstall command, or return code mapping is wrong.
6. A bad direct assignment to a 10,000-device fleet can generate mass failures, repeated retries, support tickets, and unnecessary endpoint churn.
7. Save the assignments only after confirming the group name and assignment intent.
8. UI label change risk: Medium. Some tenants show Add group, Included groups, Required, Available for enrolled devices, or Uninstall with slightly different layouts. Verify live before saving.

## Verification Steps

### 15. Confirm the app appears correctly in the catalog
1. Return to Apps > All apps.
2. Search for `FinBridge Connect v3.1`.
3. Confirm the app exists and the Type reflects the Win32 application flow used by your tenant.
4. Open the app object and verify the Overview or Properties page shows the correct name, publisher, commands, detection logic summary, and assignments.
5. If the app does not appear, refresh the page and verify the create action completed successfully.

### 16. Check install status on an assigned test device
1. Open Apps > All apps > `FinBridge Connect v3.1`.
2. Go to Monitor.
3. Open Device install status or a similarly named view in your tenant.
4. Locate the assigned pilot device.
5. Review the reported install state after the device has checked in.
6. If the app was assigned as Available, confirm the user installed it from Company Portal before expecting an Installed state.
7. If the app was assigned as Required, allow for normal Intune check-in time before troubleshooting.
8. If needed, open the device record and trigger a Sync to accelerate reporting.
9. UI label change risk: High. Some tenants split these views into Device status, User status, Monitor, Managed apps, or Installation details. Verify live.

### 17. Interpret the main status values
1. Installed means Intune believes the application installed successfully and the detection rule confirmed its presence.
2. Failed means Intune attempted the installation or uninstall and received an error, an unmapped return code, or the detection rule did not confirm success after the install attempt.
3. Not applicable means the targeted device did not meet the app requirements or the assignment does not apply in that context.
4. If you see Not applicable, check the architecture, minimum OS version, assignment target type, and install context first.
5. If you see Failed, check the install command, return code mapping, package integrity, and detection rule next.
6. If you see Installed but the app is missing for the user, check whether the detection rule is too broad or pointing to stale evidence.

### 18. Verify the worked example specifically
1. On a pilot device that received the app, confirm the application is present.
2. Confirm the registry key `HKLM\SOFTWARE\FinBridge\Connect` exists.
3. Confirm the `Version` value equals `3.1`.
4. Confirm Intune reports the device as Installed for `FinBridge Connect v3.1`.
5. If the registry value is missing or different, treat the package or detection rule as incorrect and do not widen the rollout.

## Minimum Pre-Rollout Decision Checkpoint
1. The app exists in the catalog with the correct type.
2. The app metadata is accurate and readable.
3. Install and uninstall commands are confirmed.
4. System versus User context is intentionally chosen.
5. Requirements match the supported Windows estate.
6. Detection rules correctly identify the installed version.
7. Return codes are reviewed and not guessed.
8. The app is assigned only to a small pilot group.
9. At least one pilot device shows a valid Installed state.
10. No full-estate assignment should begin until all nine checks above are satisfied.

## Common Early Mistakes To Avoid
- Selecting the wrong app type for the package.
- Using a user-context install for a machine-wide application.
- Using a detection rule that proves the app once existed rather than proving the correct version is installed now.
- Treating all non-zero return codes as failure without checking vendor documentation.
- Assigning Required to the full estate before pilot validation.
- Ignoring tenant UI label differences and clicking through the wrong wizard path.

## Working Navigation Summary
- Create app baseline: Intune admin center > Apps > All apps > Add > Windows app (Win32)
- Assign app baseline: Intune admin center > Apps > All apps > [App] > Assignments
- Monitor app baseline: Intune admin center > Apps > All apps > [App] > Monitor > Device install status

## DWP Recommendation
Use this process for every new Windows application intake into Intune. Treat package upload, detection logic, and pilot assignment as separate quality gates. The first goal is not broad deployment. The first goal is proving that Intune can install, detect, and report the application correctly on a small controlled set of devices before any phased rollout begins.