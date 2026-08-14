# Ranked Access-Path Analysis: Unintended Matter Access (Legal Floor 6 Paralegal)
**Date:** 2026-08-14  
**Incident:** Paralegal on Legal Floor 6 discovered client matter in Copilot she states she never had access to  
**Investigation Focus:** Permissions/access-path issue (NOT Copilot malfunction)  
**Escalation:** Security/Data-Governance Team  
**Available Facts:** Minimal—no detail on group memberships, recent access changes, or matter-level permission structure

---

## Ranking: 3 Most Likely Access-Path Causes

### Cause #1: Unintended Group-Based Matter Access (Floor 6 or Document Management Team)
**Why this is plausible:**
- Legal Floor 6 is cohort with common characteristics (Win11/Intune migration, app deployment, same location)
- User likely member of "Legal Floor 6 Team," "Floor 6 Staff," or "Document Management Users" group
- Matter permissions often granted at *group* level, not individual level; user may be unaware group she joined has matter access
- Group-based access is opaque to individual users and frequently over-provisioned
- Common scenario: user added to floor/team group for one purpose (location, role assignment, app deployment); group also has broader matter access

**Fastest check to confirm or rule out:**
Query user's group memberships from Active Directory/Entra ID. Cross-reference each group against matter permissions in the underlying data repository (SharePoint, matter management system, file share ACLs). Identify which group(s) have access to the specific matter. Confirm user's inclusion in each group and whether she should have access based on job function.

**Evidence to confirm group-based access:**
- User is member of a group (e.g., "Legal Floor 6," "Document Mgmt Users") that has explicit matter permissions
- Matter permissions do not include user individually, only via group membership
- User was added to group for unrelated reason (floor assignment, app deployment, migration cohort)
- Other users in same group also report access to this matter (indicates systematic over-provisioning)

**Evidence to rule out group-based access:**
- User has no group memberships with matter access
- User is not member of any floor-wide or document-management groups
- Matter permissions target specific job titles/roles user does not hold

---

### Cause #2: Permission Sync/Provisioning Error During Friday Deployment or Win11/Intune Migration
**Why this is plausible:**
- Friday document management app deployment and ongoing Win11/Intune migration are high-risk windows for permission misprovisioning
- Migrations often rely on automated permission sync/mapping scripts that can introduce unintended access
- App deployment may have re-provisioned access based on incorrect user/group targeting
- User's Intune enrollment or profile refresh could have triggered a permission sync that included her in broader matter-access groups
- Timing window (Friday deployment, to confirm issue discovered Monday) aligns with permission-sync lag

**Fastest check to confirm or rule out:**
Pull user's access-provision logs from the document management system or SharePoint audit logs covering Friday deployment through Monday morning. Look for:
- Automated permission assignments or group additions on Friday/weekend
- App deployment script logs that modified user permissions
- Intune or domain-sync logs showing this user targeted for access provisioning
- Comparison of user's matter permissions before and after Friday deployment

**Evidence to confirm provisioning error:**
- Access audit log shows automatic permission grant or group addition on Friday or over weekend
- Deployment script or Intune policy includes this user in matter-access group
- User's permission state changed post-Friday; was not present in pre-deployment audit
- Error log or deployment warning flag noting over-provisioned access to this user/group
- Same matter access provisioning occurred for other Floor 6 users (indicates systematic error)

**Evidence to rule out provisioning error:**
- No audit log entries for this user's permissions between Friday and issue discovery
- User's permission state consistent with pre-deployment state
- Deployment script targeted specific roles/titles; user does not match criteria
- Intune policy audit shows no changes to this user's group membership or access

---

### Cause #3: SharePoint/File Share Permission Inheritance from Parent Folder or Team Site
**Why this is plausible:**
- Legal matters often organized in hierarchical folder structures (Matters > Subfolder > Client > Case)
- Parent folders/team sites frequently shared with broad groups (e.g., "Legal Department," "Floor 6") for operational ease
- Individual user granted access to parent folder/team site for unrelated reason; automatically inherits access to child matter
- User unaware that folder-level access grants access to all child matters
- Document management app may index all inherited-access content, surfacing matters user did not knowingly get access to

**Fastest check to confirm or rule out:**
Identify where the matter is stored (SharePoint site, file share, matter management system). Pull the folder hierarchy and permission inheritance chain from parent to matter. For each parent-level folder/site, check:
- Who has access to parent folder (especially groups)
- Whether this user is member of any of those groups
- Whether permission inheritance is enabled (explicit vs. inherited permissions)
- When access to parent folder was granted

**Evidence to confirm inheritance as cause:**
- Matter stored as subfolder within a parent folder/team site the user has access to
- Parent folder shared with a group this user is member of
- Permission inheritance enabled; user does not have explicit matter-level permissions
- User has no direct role/ownership in matter, but has access through parent container
- Matter was never explicitly shared with user's role/group; access is incidental to parent access

**Evidence to rule out inheritance as cause:**
- Matter is at root level with no parent folder, or parent folder access does not grant child access
- Permission inheritance disabled; each matter has isolated permissions
- User has explicit matter-level permission grant (not inherited)
- User is not member of any group with parent-folder access

---

## Investigation Approach for Security/Data-Governance Team

### Critical Information to Gather (Priority Order)

1. **Matter Identification & Permission Model**
   - Exact matter/case name and where it's stored (SharePoint, file share, matter management system)
   - Matter permission model: individual, group-based, or hierarchical (folder inheritance)?
   - Who is *supposed* to have access to this matter? (Matter owner, team, role-based criteria)

2. **User Access Profile**
   - Pull full group memberships for this user (Active Directory, Entra ID, matter management system)
   - Job title, role, and team assignment (to determine intended access scope)
   - When were groups joined? (Pre-migration, post-deployment, or coincidental to Friday?)

3. **Access Grant Audit Trail**
   - User's permission history for this matter (when added, how: direct or via group?)
   - Deployment/sync logs from Friday showing any permission changes
   - Intune policy or app-deployment logs targeting this user/group

4. **Comparative Analysis**
   - Do other Floor 6 users also have access to this matter? (Suggests floor-wide over-provisioning)
   - Do other paralegals report similar unintended access? (Indicates systematic issue)
   - How many users have access to this matter vs. intended scope?

### Cross-Cause Investigation

**If Cause #1 (Group) + Cause #2 (Deployment) suspected together:**
- Check if user was added to matter-access group AS PART OF Friday deployment
- Verify whether deployment script intended to add user, or whether it was error in targeting

**If Cause #1 (Group) + Cause #3 (Inheritance) suspected together:**
- Check if user's group has parent-folder access, and whether inheritance cascades to matter
- Determine if permission model is hierarchical (access = unintended consequence) or flat (access = intentional group grant)

---

## Conclusion

**Cause correlation status: TO CONFIRM**

Do not assume single cause; access issues frequently involve multiple layers (user in group + group inherited from parent folder + permissions synced during migration).

**Escalation confidence:** This is a **legitimate data-access violation** requiring immediate investigation. Frame to security/data-governance as:
- Not a Copilot bug—user has actual underlying access
- Not a one-off incident—investigate whether other Floor 6 users or other matters show same pattern
- Likely tied to Friday deployment or Win11/Intune migration
- Requires audit-log review and permission model clarification

**Do not close this as "user error"** until group memberships, matter permissions, and deployment logs are reviewed.
