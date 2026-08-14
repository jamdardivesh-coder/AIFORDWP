# Triage Summary - Issue 3: Desktop Shortcuts Missing for Some Users

## Separate Problem Statement
A user reports that desktop shortcuts have disappeared on Floor 6.

## Urgency
Medium (P3) - User experience/productivity impact, but lower than potential confidentiality and logon outage.

## What We Check First (and Why)
1. **Determine whether shortcuts are actually deleted vs hidden/redirected**
   - **Check:** Desktop folder path redirection (OneDrive/Known Folder Move), visibility settings, icon cache state, and whether shortcuts exist in public/user desktop locations.
   - **Why first:** Fastest way to differentiate cosmetic/state issue from data loss.

2. **Rollout package behaviors and scripts from Friday**
   - **Check:** Installation scripts/MSI transforms that modify Start Menu/Desktop links, profile cleanup logic, or enforced layout policies.
   - **Why first:** Strong temporal link to new document-management app deployment.

3. **Profile and shell health on affected endpoints**
   - **Check:** Temporary profile events, Explorer startup errors, OneDrive sync conflicts, FSLogix/profile container issues (if used).
   - **Why first:** Profile mount/sync issues can make shortcuts appear missing.

4. **Consistency across affected users**
   - **Check:** Are the same shortcuts missing for everyone, or random per user/device?
   - **Why first:** Pattern tells us whether this is policy-driven or profile-specific.

## What We Do Right Now
- Capture one affected and one unaffected device comparison.
- Restore critical shortcuts via approved script/GPO if business-critical apps are inaccessible.
- If rollout script is confirmed causal, disable that component and redeploy corrected shortcut policy.

## What We Tell Partners by Lunch (Non-Technical)
- "This appears to be a usability/configuration issue and is being handled separately from the higher-priority login and confidentiality investigations."
- "We are checking whether Friday's software rollout changed desktop shortcut settings."
- "If confirmed, we can restore standard shortcuts quickly and prevent recurrence via a corrected deployment."

## Current Working Hypothesis
Most likely a deployment/policy/profile redirection side effect, not permanent data loss.

## Owner Routing
- Primary: Endpoint Engineering / EUC Packaging
- Supporting: OneDrive/Profile management owner
