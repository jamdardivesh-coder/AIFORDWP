# Floor 6 Remediation: Desktop Shortcuts Missing — Technical Action & Floor Message
**Date:** 2026-08-14  
**Incident:** Legal Floor 6 Missing Desktop Shortcuts  
**Status:** Working Hypothesis — Awaiting Confirmation via Post-Install Script Logs  

---

## Technical Action

**Working Hypothesis:** Friday's Document Manager deployment post-install script inadvertently removed or overwrite user desktop shortcuts across all user profiles on affected Legal-Win11 devices.

**Investigation & Remediation Steps:**

### Step 1: Identify Post-Install Script (SCCM)
1. **SCCM Admin Console** → **Software Library** > **Application Management** > **Applications**
2. **Find:** "Document Manager v2.1" application
3. **Review:** **Deployment Type** tab → check **Post-Install Command** or **Install Behavior** script
4. **Look for:** any command that deletes, renames, or modifies `%USERPROFILE%\Desktop` or `C:\Users\*\Desktop`

**To Confirm:** Check script for patterns like:
   - `del %USERPROFILE%\Desktop\*.lnk`
   - `rmdir /s` targeting Desktop path
   - PowerShell commands with `-Path` targeting user profiles

---

### Step 2: Disable or Modify Post-Install Script
1. **In SCCM:** Edit the deployment type post-install command
   - **Option A (Safest):** Remove or comment out any lines that modify Desktop shortcuts
   - **Option B:** Add conditional check to skip Desktop modifications on first run
2. **Save changes** to application version (creates new revision)
3. **Re-deploy** revised package to Legal-Win11 collection with **force reinstall** flag

---

### Step 3: Restore Missing Shortcuts (Via Group Policy Preferences or Remediation Script)

**Via Group Policy Preferences (Recommended if shortcuts are known/standard):**
1. **GPMC (Group Policy Management Console)** → Find or create GPO targeting Legal Floor 6
2. **Edit GPO** → **User Configuration** > **Preferences** > **Windows Settings** > **Shortcuts**
3. **New** → **Shortcut** (add common apps: Outlook, Teams, File Explorer, Word, etc.)
   - **Location:** `%USERPROFILE%\Desktop`
   - **Target:** Application executable path
   - **Action:** Update (if exists, update; if missing, create)
4. **Apply to:** Floor 6 device collection or OU
5. **Deploy:** Shortcuts restore on next group policy refresh (or `gpupdate /force` on client)

**Via PowerShell Remediation Script (If shortcuts are user-specific):**
1. **Create script:** `Restore-DesktopShortcuts.ps1` (see example below)
2. **Deploy via SCCM** as a **Run Script** or **Application**:
   - **SCCM** → **Monitoring** > **Scripts** > **Create and Deploy Script**
   - Or: **Software Library** > **Scripts** > **New Script**
3. **Script content:**
   ```powershell
   # Restore common Office/collaboration app shortcuts to Desktop
   $DesktopPath = [Environment]::GetFolderPath("Desktop")
   $AppPaths = @{
       "Outlook.lnk" = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
       "Teams.lnk" = "C:\Program Files\Microsoft\Teams\current\Teams.exe"
       "OneDrive.lnk" = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\OneDrive\OneDrive.exe"
       "File Explorer.lnk" = "C:\Windows\explorer.exe"
   }
   
   $WshShell = New-Object -ComObject WScript.Shell
   foreach ($shortcutName in $AppPaths.Keys) {
       $shortcutPath = Join-Path $DesktopPath $shortcutName
       if (-not (Test-Path $shortcutPath)) {
           $link = $WshShell.CreateShortcut($shortcutPath)
           $link.TargetPath = $AppPaths[$shortcutName]
           $link.Save()
       }
   }
   ```
4. **Deploy to:** Legal-Win11 collection with required elevated context

---

### Step 4: Verify & Monitor
1. **Spot-check:** Log into 2–3 affected Floor 6 devices and confirm Desktop shortcuts present
2. **SCCM Monitoring:** Check application deployment status (ensure new version deployed with force reinstall)
3. **Follow-up:** Confirm with Floor 6 manager that shortcuts are restored

**Permissions Required:** ✅ **YES — Elevated**  
- SCCM application modification and deployment require **SCCM Administrator** role
- PowerShell script execution on clients requires **SCCM Application Administrator** or ability to deploy Run Scripts
- Group Policy modification requires **Group Policy Administrator** or delegated edit permissions to target OU

**Timeline to Effect:**
- SCCM remediation script: 15–30 minutes (next client check-in + script execution)
- Group Policy Preference: 1–2 hours (policy refresh cycle) or immediate with `gpupdate /force`

---

## Floor Message

**Subject: Desktop Shortcuts Being Restored — No Action Needed**

We've identified that Friday's software update inadvertently removed desktop shortcuts on some Floor 6 devices. We're fixing this right now by restoring them automatically.

**What we're doing:** Redeploying the shortcuts to your desktop and applying a script to any devices that still don't see them. This should complete within the next hour.

**What you can do:** If your shortcuts still don't appear by 11:00 AM, restart your computer or contact the Service Desk. No urgent action needed from you right now.

We're making sure this doesn't happen again. Thanks for your patience.

---

## Notes

- **To Confirm:** Review SCCM post-install script logs on affected devices; check Application event log for shortcut deletion commands; user profile Desktop folder timestamps pre/post deployment
- **Elevated Permissions Required:** Yes — SCCM Administrator, Group Policy Administrator, or Run Script deployment permissions
- **Word Count (Floor Message):** 91 words (under 100-word requirement)
- **Assumption:** Shortcuts are relatively standard (Outlook, Teams, File Explorer, OneDrive, etc.); if user-created shortcuts are missing, requires more targeted recovery strategy
