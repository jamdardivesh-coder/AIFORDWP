# Root Cause Analysis — AVD Black Screen at Login
## Incident Reference: INC-2024-0315-AVD-BLACKSCREEN

| Field              | Detail                                      |
|--------------------|---------------------------------------------|
| **Date**           | 2024-03-15                                  |
| **Time First Report** | ~07:00 (approximately 5 hours post-update)  |
| **Affected Users** | ~40% of POOL-FIN-01 (Finance desktop pool)  |
| **Unaffected Pool**| POOL-FIN-02 (IT team pool — no update)      |
| **Severity**       | High — blocks user login, ~40 users affected |
| **Impact Duration**| Ongoing at report time (30+ minutes)        |
| **Analyst**        | FinBridge Service Desk — Escalation Team    |
| **Status**         | Investigation / Remediation In Progress     |

---

## 1. Incident Summary

Following a scheduled overnight image update to the Finance AVD desktop pool (POOL-FIN-01) at 02:00, users reported a black screen upon login. The symptom manifests post-credential entry and lasts 5–30 seconds (or indefinitely) before either the desktop appears or the session fails. Approximately 40% of Finance pool users are affected. The parallel IT pool (POOL-FIN-02), which did not receive the update, is operating normally.

---

## 2. Key Observations

| Observation | Significance |
|-------------|--------------|
| Only POOL-FIN-01 affected; POOL-FIN-02 unaffected | Strong temporal and scope correlation with overnight image update |
| Issue began ~07:00 (5 hours after 02:00 update) | Lag time consistent with user login attempts; not an immediate failure |
| ~40% of affected pool shows symptoms, not 100% | Suggests update applied unevenly, or race condition in login sequence |
| Some sessions recover in 30 seconds; others never recover | Variable duration indicates timing-dependent failure or resource contention |
| No prior incidents on these pools | Rules out baseline architectural issue; points to recent change |
| Finance users report it; IT users (on unaffected pool) do not | Confirms issue is pool-specific and not infrastructure-wide |

---

## 3. Timeline of Events

| Time     | Event | Source |
|----------|-------|--------|
| 02:00    | Scheduled image update begins for POOL-FIN-01 (NOT POOL-FIN-02) | Change Management |
| ~02:45   | Update completes; session hosts restart | Assumed (typical update duration) |
| ~03:00 – ~07:00 | Night shift / early morning: few user logins; issue may have existed but unnoticed | Inference |
| ~07:00   | First user logins of day; black screen symptom reported | User Report (Maria Lopez) |
| 07:18    | Incident formally logged | Ticket System |
| **Current** | ~40% of POOL-FIN-01 users blocked; investigation underway | This Analysis |

---

## 4. Sequence of Events (Narrative)

1. **02:00** — A scheduled image update is pushed to all session hosts in POOL-FIN-01 (Finance pool). This update does NOT apply to POOL-FIN-02 (IT pool).

2. **02:00 – 02:45** — Session hosts in POOL-FIN-01 undergo the update, which likely includes:
   - Patched OS binaries
   - Updated drivers (GPU, network, storage)
   - Configuration changes
   - Service updates or new dependencies

3. **02:45 – ~07:00** — Overnight and early-morning period. Few users attempt login. No complaints reach the service desk (either no one logged in, or early users assumed it was their own PC/network and did not report).

4. **~07:00** — Morning shift users begin logging in. A percentage of them (estimated 40%) encounter a black screen after entering credentials. The screen remains black for:
   - ~30 seconds, then the desktop appears (Maria Lopez's experience)
   - Indefinitely, requiring a logout/reconnect (other users' experience)

5. **~07:18** — Maria Lopez reports the issue via the service desk. She notes it lasted ~30 seconds but is "fine now" (temporary recovery), whereas colleagues on the same pool report persistent black screens.

---

## 5. Root Cause Analysis — 5 Whys

### Problem Statement
> Users in the Finance AVD pool (POOL-FIN-01) experience a black screen upon login following an overnight image update, with variable recovery time and affecting approximately 40% of the pool.

---

### Why 1 — Why do users see a black screen after login?

**Because the RDP session is established (credentials accepted) but the desktop shell (Explorer.exe / Windows shell) or GPU drivers are failing to initialize or render the desktop within the expected timeframe.**

The black screen appears *after* credential entry, meaning the RDP transport and user authentication succeeded. The OS is booting, but the visual presentation layer — either the Windows desktop manager or the video driver — is either:
- Slow to initialize (30-second delay in Maria's case)
- Crashing / hanging (users who report "never comes back")
- Waiting on a resource or service that is delayed or failed

The variable duration (30 seconds vs. indefinite) suggests a timing-dependent issue, not a hard crash.

---

### Why 2 — Why is the desktop shell or GPU driver failing to initialize after the update?

**Because the overnight image update modified or introduced a defect that affects the display stack or driver initialization sequence, likely one of:**

**a) Incompatible or untested GPU driver update**
- Update may have rolled out a driver version that conflicts with the session host hardware or WDDM (Windows Display Driver Model) version
- No validation pass on a representative test pool before production rollout

**b) Display server / Rdp graphics initialization stalled by unstarted service**
- Update may have changed service startup order or dependencies (e.g., Themes service, Display driver service)
- A required service is missing, disabled, or hanging

**c) Login shell script timeout or hang**
- Update may have added a post-login script, Group Policy, or profile initialization that stalls
- Example: broken logon script, network share that is inaccessible, or a third-party agent (endpoint protection, compliance tool) blocking execution

**d) Partial or corrupted update on some session hosts**
- ~40% affected suggests not all session hosts applied the update identically
- Some hosts may have had network interruption, power loss, or disk corruption during update
- Rollback may have been incomplete on these hosts

---

### Why 3 — Why was the update released to production without pre-validation?

**Because there is no documented pre-deployment validation stage (pilot / test pool) and no automated regression testing before the update wave.**

If the update was deployed directly to POOL-FIN-01 (production) at 02:00 without first validating it on POOL-FIN-02 or a staging environment, then defects would not be caught before affecting users.

---

### Why 4 — Why is POOL-FIN-02 (IT pool) unaffected while POOL-FIN-01 is affected?

**Because the overnight update was scoped to only POOL-FIN-01 and not applied to POOL-FIN-02.**

This is the most informative observation: the two pools are likely identical in hardware, OS baseline, and user profile. The only differentiator is the update. This is classic cause-and-effect correlation and strongly points to the update as the root cause.

However, it also suggests that the update *could* have been validated on POOL-FIN-02 first, but was not, reducing the probability that QA / staging testing occurred.

---

### Why 5 — Why does the same update rollout process not include a pilot / test phase?

**Because there is no formalized change control policy requiring pre-production validation, and the update schedule prioritizes speed-to-deployment over risk mitigation.**

Common organizational causes:
- No Change Advisory Board (CAB) review for infrastructure updates
- No mandatory pilot pool or staging environment step
- No automated smoke testing / health check post-update
- Pressure to deploy security or compliance patches quickly, sacrificing testing rigor

---

## 6. Most Likely Root Cause

**The overnight image update to POOL-FIN-01 introduced a defective or incompletely tested driver, service configuration, or profile initialization that prevents or significantly delays the desktop shell from rendering after user login.**

**Evidence:**
- **Temporal correlation:** Issue started immediately after the update window (02:00 → 07:00).
- **Scope correlation:** Only the pool that received the update (FIN-01) is affected; the unaffected pool (FIN-02) did not receive it.
- **Partial impact:** ~40% (not 100%) suggests either:
  - Uneven update application across session hosts in the pool
  - A race condition triggered by specific hardware configurations or session host load
  - User profiles or cached state causing the issue only for certain users

**Secondary consideration:** The variable duration (30 sec recovery vs. indefinite hang) indicates a timing-dependent failure — likely a service or driver waiting on a resource, or a timeout being exceeded.

---

## 7. Contributing Factors

| Factor | Detail | Severity |
|--------|--------|----------|
| No pre-deployment validation | Update deployed directly to production (POOL-FIN-01) without pilot on POOL-FIN-02 or staging | High |
| No automated regression testing | No health check / smoke test post-update to catch rendering issues | High |
| Uneven update application | ~40% affected suggests possible partial rollback or network interruption during update on some hosts | High |
| No rollback procedure documented | If update is the root cause, unclear if update can be safely reverted | High |
| Variable symptom duration | Suggests resource contention or timeout, not a hard crash — difficult to troubleshoot without session logs | Medium |
| No session event logs reviewed yet | RDP session logs, driver event logs, and Application event logs not mentioned in incident details | Medium |

---

## 8. Immediate Troubleshooting / Remediation Steps

| Step | Purpose | Owner | Estimated Time |
|------|---------|-------|-----------------|
| **1. Collect diagnostics** | Pull Event Viewer logs (System, Application, RDP-Core) from affected session host | AVD Engineering | 15 min |
| **2. Check driver versions** | Compare GPU driver version pre/post-update; check Device Manager for warnings/errors | AVD Engineering | 15 min |
| **3. Review update changelog** | Identify what changed (drivers, services, profiles, scripts) in the 02:00 update | Change Management | 10 min |
| **4. Isolate one session host** | Halt the affected host from load balancer; test login interactively to rule out timing/load issues | AVD Ops | 10 min |
| **5. Test rollback on pilot host** | Revert the update on one non-critical session host and retest login | AVD Engineering | 20 min |
| **6. Expand rollback if successful** | If rollback fixes the issue, revert all hosts in POOL-FIN-01 | AVD Ops | 30 min |

**Estimated total time to remediation:** 60–90 minutes (assuming rollback is the fix).

---

## 9. Recommended Actions

| Priority | Action | Owner | Timeline |
|----------|--------|-------|----------|
| **P1 (Immediate)** | Collect session host diagnostics (Event Viewer, driver info) to confirm root cause | AVD Engineering | Now |
| **P1 (Immediate)** | If root cause is identified as the update, roll back POOL-FIN-01 to pre-update state | AVD Ops | Within 2 hours |
| **P2 (Today)** | Post-mortem: review what testing was done on the 02:00 update before deployment | Change Management + AVD Team | Same day |
| **P2 (This week)** | Establish mandatory pre-deployment validation: pilot on a non-critical pool (or on POOL-FIN-02) before rolling to production | AVD Ops + Change Mgmt | By EOW |
| **P3 (This month)** | Implement automated post-update smoke testing (user login simulation, desktop render check) | AVD Engineering | Within 2 weeks |
| **P3 (This month)** | Document rollback procedures for future image updates | Change Management | Within 1 week |

---

## 10. Communication to Users

**If rollback is initiated:**
```
Subject: AVD Finance Pool — Black Screen Issue — Rollback in Progress

We are aware that some users in POOL-FIN-01 (Finance desktop) experienced 
a black screen after login this morning. We have identified this to be a 
configuration issue related to last night's image update.

We are currently rolling back the update to restore normal service. Users 
may need to log out and log back in once the rollback completes (estimated 
30–45 minutes).

We apologize for the disruption and thank you for your patience.

Questions? Contact the Service Desk at [ext].
```
```

---

## 11. Lessons Learned

1. **Pre-deployment validation is non-negotiable:** Even "routine" image updates must be tested on a pilot pool or staging environment before production deployment.

2. **Partial / variable failures point to timing issues or incomplete updates:** When ~40% of users are affected, look for:
   - Uneven distribution of the update (corrupted update on some hosts)
   - Load-dependent or timing-dependent failures (race conditions)
   - Hardware or profile variance triggering the failure

3. **Correlation is powerful:** The fact that only the updated pool is affected (and the non-updated pool is fine) is overwhelming evidence that the update is the root cause. Use this to prioritize remediation.

4. **RDP session diagnostics are essential:** Session event logs, network traces, and driver logs are critical for diagnosing black-screen and rendering issues. Collect them early.

5. **Rollback procedures must exist before deploying:** Always have a tested, documented rollback plan for infrastructure updates.

---

## 12. Incident Closure Checklist

- [ ] Root cause confirmed (diagnostics reviewed)
- [ ] Rollback completed (if applicable)
- [ ] All affected users able to log in normally
- [ ] Post-update health checks passing
- [ ] Change record updated with findings
- [ ] Post-mortem meeting scheduled with Change Mgmt + AVD team
- [ ] Pre-deployment validation process updated
- [ ] User communication sent (all-clear or resolution update)

---

*Prepared by: FinBridge Service Desk — Escalation Team*
*Date: 2024-03-15*
*Status: Investigation / Remediation in progress*
