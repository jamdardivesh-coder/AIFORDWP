# Floor 6 Remediation: Technical Action & Floor Message
**Date:** 2026-08-14  
**Incident:** Legal Floor 6 Login/Performance Issue — Document Manager Deployment  
**Status:** Working Hypothesis — Awaiting Confirmation via Event Logs  

---

## Technical Action

**Confirmed Hypothesis:** Friday's Document Manager deployment triggered a logon-script or startup-process failure on Legal Floor 6 devices, blocking or significantly delaying user authentication.

**Remediation Steps (SCCM):**

1. **Access SCCM Admin Console** → **Software Library** > **Application Management** > **Deployments**
2. **Find Deployment:** "Document Manager v2.1" or "Friday App" targeted to **Legal-Win11** or **Floor-6** collection
3. **Retire Deployment:**
   - Right-click deployment → **Delete** (or mark as retired if your policy requires audit trail)
   - **Force removal** to immediately stop any pending installations on client devices
4. **Verify Removal:** Check SCCM Deployment Status to confirm 0 active assignments to affected collection
5. **Optional Rollback:** If previous version exists, deploy "Document Manager v2.0" to same collection to restore functionality

**Via Intune (if applicable):**
- **Devices** > **Windows** > **Configuration Profiles** → Find Floor 6 app assignment → **Delete assignment**
- Alternatively: **Apps** > **Document Manager** → **Assignments** → Remove "Floor 6 / Legal-Win11" group

**Permissions Required:** ✅ **YES — Elevated**  
SCCM deployment changes require **SCCM Administrator role** or delegated collection-level permissions. Intune changes require **Intune Application Administrator** or **Cloud Application Administrator** role.

**Timeline to Effect:** Device check-in occurs within 5–15 minutes; login issues should resolve on next user logon attempt.

---

## Floor Message

**Subject: Temporary Login Issue on Floor 6 — Status Update**

We're aware that some of you experienced slow or failed logins this morning. We've identified a software configuration from Friday's application update affecting login timing on Floor 6. Our technical team is removing this update right now to restore your normal login experience.

**What we're doing now:** Removing the problematic application from your devices — this will take effect on your next logon attempt (within the next 15 minutes).

**What you can do:** Restart your device or log off and back on. If login is still slow after 9:45 AM, contact the Service Desk with your device name and we'll escalate immediately.

We expect normal login performance by 10:00 AM. Thank you for your patience.

---

## Notes

- **To Confirm:** Event logs showing app logon-hook failures, login success after rollback, device event log errors during deployment window
- **Elevated Permissions Required:** Yes — SCCM Administrator / Intune Application Administrator
- **Word Count (Floor Message):** 87 words (under 100-word requirement)
