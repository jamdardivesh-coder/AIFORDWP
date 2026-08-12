# Analysis: Most Likely Causes of Startup Performance Drop

Date: 2026-08-12
Scope basis: Finance-Win11 only (215 devices) showed an immediate startup-score drop after the 2026-08-04 02:00 configuration deployment; IT-Win11 (40 devices) with no config change remained stable.

## Ranked Top 3 Likely Causes

1. Startup script overhead introduced by the new security baseline
Why it fits the evidence:
- The degradation starts exactly on 2026-08-04, immediately after the 02:00 deployment.
- The change was applied only to Finance-Win11, and only that group regressed.
- IT-Win11 had no config change and stayed flat, which strongly supports a change-scoped startup-path effect.
Fastest check:
- On a few affected devices, capture script execution duration during logon (event/trace timestamps) and compare against pre-change or unaffected devices; if script runtime aligns with the added startup delay window, confirm.

2. Additional Defender scan policy increasing logon-time scan activity
Why it fits the evidence:
- The new baseline explicitly added extra Defender scan policy at the same change point.
- A scan policy can create broad, repeatable overhead across many devices, matching multi-day elevated startup medians.
- Unchanged IT-Win11 performance is consistent with this being policy-scoped to Finance-Win11 only.
Fastest check:
- Compare Defender operational logs and endpoint performance counters during startup between affected Finance-Win11 devices and IT-Win11; confirm if scan activity/time spikes only on Finance devices after 2026-08-04.

3. Combined baseline load effect (startup script + Defender policy interaction)
Why it fits the evidence:
- The score drop is large and sustained (not a one-day spike), which fits additive overhead from two newly introduced controls in the same deployment.
- Timing is exact to the deployment window, and the clean control group without the deployment remains stable.
- Group-scoped persistence across multiple days supports a systemic config-load pattern rather than isolated endpoint behavior.
Fastest check:
- Use a controlled A/B rollback on a small Finance-Win11 test subset: remove/disable one component at a time (script first, then scan policy) and measure next-login startup median deltas to isolate single vs combined impact.