# Triage Summary - Issue 2: Floor 6 Widespread Login Failures / Very Slow Logon

## Separate Problem Statement
At least a dozen users on Floor 6 report they cannot log in, or logon is taking an unusually long time this morning.

## Urgency
High (P1/P2 depending exact outage level) - Multi-user productivity impact.

## What We Check First (and Why)
1. **Scope and blast-radius confirmation**
   - **Check:** Exact count of affected users, device types, whether issue is only Floor 6, and whether other floors are impacted.
   - **Why first:** Distinguishes local floor/network issue from enterprise identity/authentication issue.

2. **Authentication service health (Entra AD/ADFS/DCs) and sign-in failures**
   - **Check:** Sign-in logs for common error codes, account lockouts, MFA failures, conditional access hits.
   - **Why first:** "Cannot log in" requires immediate confirmation of identity platform stability.

3. **Floor 6 network path and core dependencies**
   - **Check:** DNS/DHCP reachability, packet loss, authentication endpoints, VPN/proxy path (if applicable).
   - **Why first:** Slow logons commonly stem from network/DNS latency to domain/auth endpoints.

4. **Endpoint startup/logon processing delays**
   - **Check:** GPO processing time, profile load delays, login scripts, recent update installation state.
   - **Why first:** Explains "can log in but it takes forever" cases.

5. **Friday document-management rollout side effects**
   - **Check:** New login/startup agent, shell extension, policy package, or service trying to initialize at logon.
   - **Why first:** Time correlation is strong; one deployment could create floor-wide logon drag.

## What We Do Right Now
- Raise a major incident bridge for Floor 6 impact and assign identity/network/endpoint leads.
- Collect 3-5 representative affected devices for fast comparative triage (working vs failing).
- If rollout component is strongly implicated, pause or roll back the deployment policy to Floor 6.
- Provide workaround instructions (known good VDI/alternate login path where available).

## What We Tell Partners by Lunch (Non-Technical)
- "This is being treated as a floor-wide service degradation with active cross-team response."
- "We are verifying whether the issue is identity, local network, or a side effect of Friday's software rollout."
- "We have immediate mitigation actions underway, including rollback readiness if the rollout is confirmed as causal."
- "Next update will include affected-user count, confirmed cause, and expected recovery timeline."

## Current Working Hypothesis
Likely causes (in order):
- Floor-specific network/DNS/auth path degradation, or
- rollout-related startup/logon component contention.

## Owner Routing
- Primary: Identity + Network Operations + Endpoint Engineering
- Supporting: App deployment owner for Friday rollout
