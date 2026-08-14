# Ranked Cause Analysis: Legal Floor 6 Login Incident
**Date:** 2026-08-14  
**Incident:** Dozen+ users unable to log in / severe login delay  
**Scope:** Legal Floor 6 (45 staff, Win11/Intune migrated, Friday app deployment)

---

## Ranking: 3 Most Likely Causes

### Cause #1: Document Management App Logon Script/Hook Failure
**Why this fits scope facts:**
- Timing is tightest match: deployed Friday afternoon → issues Monday morning (user boot cycle initiated post-weekend)
- Logon scripts often execute during authentication; if app's logon hook is broken or calling non-existent dependency, it blocks login
- Symptom (login hangs or fails) directly aligns with script/hook malfunction
- Floor-specific deployment fits floor-specific impact
- High probability given direct temporal link and symptom match

**Fastest check to confirm/eliminate:**
Run on affected machine: `wmic logicaldisk get name` then check app install directory for corruption/missing files, review Application event log for app-related logon failures. Temporarily disable app's logon script (via registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run`) and attempt login.

**Evidence to confirm app as cause:**
- Event log shows errors from app executable/service during logon phase
- Login succeeds immediately after disabling app's logon hook
- Event timing correlates to Friday deployment timestamp in software inventory
- No logon errors observed on machines where app not deployed

**Evidence to rule out app as cause:**
- Logon script runs cleanly with no errors in event log
- Login failure occurs before app logon script execution point
- Non-affected users on Floor 6 also have app installed (deployment was floor-wide)
- Users on other floors with same app do not have login issues

---

### Cause #2: Win11/Intune Policy Enforcement Conflict (Post-Migration)
**Why this fits scope facts:**
- All affected users share recent Win11+Intune migration history (common denominator)
- Monday morning often triggers full policy re-evaluation/sync cycle after weekend
- Conflicting GPO or Intune configuration deployed Friday could trigger enforcement Monday
- Intune enrollment + Win11 = higher complexity for policy application; timing allows for delayed sync
- Performance degradation (slow login) aligns with heavy policy processing

**Fastest check to confirm/eliminate:**
On affected machine run: `gpresult /h report.html` and review for policy application errors; check Intune app logs (`%programdata%\Microsoft\IntuneManagementExtension\Logs\`) for policy deployment failures. Temporarily set machine to offline mode and attempt login (bypass policy fetch).

**Evidence to confirm Intune/policy as cause:**
- `gpresult` report shows unapplied policies with error codes (e.g., script execution failures)
- Intune logs show policy push completed Friday; machines began applying Monday
- Policy targets all Win11 machines or Legal Floor 6 specifically
- Offline login succeeds; online login fails (confirms policy is blocker)

**Evidence to rule out Intune/policy as cause:**
- All policies applied cleanly with no errors in `gpresult` or Intune logs
- Affected users show identical policy versions to unaffected users on same floor
- Win11 machines outside Legal Floor 6 with same Intune policies do not have issues
- Issue persists even after manually forcing policy refresh (`gpupdate /force`)

---

### Cause #3: Network/Authentication Service Failure (Floor 6 Specific)
**Why this fits scope facts:**
- "At least a dozen" and "all on Legal Floor 6" suggests network or local domain controller connectivity issue specific to that location
- Monday morning: weekend authentication token cache expiration could trigger re-auth failures
- Physical network issue (switch, DNS scope to that floor) fits floor-specific pattern
- Performance symptom (slow login) aligns with network latency or DC unavailability

**Fastest check to confirm/eliminate:**
From affected machine: `nslookup <domain controller name>` and `ping <DC IP>` to verify network path. Check `dcdiag` output for domain controller health. Verify NTP sync (`w32tm /status`). Test login from different floor on same subnet, and from same floor on guest/separate network.

**Evidence to confirm network/auth as cause:**
- DNS resolution fails or times out when querying domain controllers
- Specific floor's network switch shows high latency or packet loss to DC
- Domain controller logs show authentication request flood or service issues starting Monday
- Users can log in when connected to different network segment
- Issue affects all machines on Floor 6 regardless of app deployment

**Evidence to rule out network/auth as cause:**
- DNS resolution and DC connectivity test cleanly
- Domain controllers report normal request volume and no errors
- Non-affected users on same floor connect successfully
- Issue is random across floor, not all machines (suggests client-side, not network)

---

## Weighting the Ranking

**Timing Clue Analysis: "Friday afternoon deployment → Monday morning onset"**

This 48-72 hour gap is critical:

| Cause | Timing Fit | Reasoning |
|-------|-----------|-----------|
| **App logon script** | **STRONGEST** | Deployment Friday → first Monday boot cycle triggers script execution → failure blocks login immediately. Direct causal chain. |
| **Win11/Intune policy** | **MODERATE** | Policy pushed Friday, but Intune often delays enforcement to Monday AM. Requires policy evaluation on login; 48-72 hr gap is plausible for policy sync + Monday re-eval. |
| **Network/auth** | **WEAKEST** | No mechanism explains why network failure would wait until Monday after Friday deployment. More likely weekend coincidence. Timing gap is hard to justify. |

**App deployment is the strongest causal link** because:
- Logon scripts execute on *next user login attempt*, not immediately after deployment
- First user logins on Monday morning = predictable trigger point
- Friday-to-Monday gap matches typical behavior of unexecuted logon hooks

---

## Conclusion (No Commitment Yet)

**Investigation priority: Cause #1 (App) → Cause #2 (Intune) → Cause #3 (Network)**

First diagnostic must verify whether app logon script is executing without errors. If clean, escalate to policy conflict. If both clear, investigate network/auth. Do not assume all three causes are independent; app deployment could have triggered Intune re-evaluation, compounding the issue.
