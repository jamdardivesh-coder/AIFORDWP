# End-User Communications — AVD Black Screen Incident (2024-03-15)

## Audience 1 — Non-Technical Executive
Your access is restored, and your data is safe. On 2024-03-15, about 40 Finance users in POOL-FIN-01 across 8 hosts saw black screens after sign-in from about 07:00 to 10:00 after an overnight 02:00 update. We rolled all 8 hosts back to the previous working version and confirmed stable logins with no repeat errors. Future updates will use pilot testing and health checks. No action needed unless it returns; contact Service Desk.

## Audience 2 — Affected End-User Team (10 People)
Hi team, your access is back and your data stayed safe. On 2024-03-15, from about 07:00 to 10:00, an overnight 02:00 update caused black screens after sign-in for about 40 Finance users in POOL-FIN-01 across 8 hosts. We rolled all 8 hosts back to the previous working version and confirmed 12 of 12 successful logins, sessions stable beyond 5 minutes, and no repeat errors in a 30-minute check. Future updates will use pilot testing and health checks. If you see this again, contact Service Desk and reference INC-2024-0315-AVD-BLACKSCREEN-FIN01.

## Audience 3 — Engineer-to-Engineer Internal Note
Access is restored and no data loss or security impact occurred.

Incident facts:
- Date/time: 2024-03-15, user impact window ~07:00-10:00.
- Scope: ~40% of Finance pool users (~40 users) in POOL-FIN-01.
- Affected hosts: SHFIN-01-A through SHFIN-01-H (8 hosts).
- Symptom: post-auth black screen.

Root cause:
- 02:00 image/update wave on POOL-FIN-01 introduced Intel GPU driver igdumd64.dll v31.0.101.4146.
- DWM (dwm.exe) crashed on login path (Application Error/Event 1000, exception 0xc0000005; corresponding DWM exit events).
- Control comparison supported causality: POOL-FIN-02 stayed on v31.0.100.9999 and remained unaffected.

Exact action taken:
- Rolled back GPU driver on all 8 affected POOL-FIN-01 hosts to v31.0.100.9999.
- Rebooted hosts and re-enabled load balancing after recovery checks.

Configuration detail:
- Bad version: v31.0.101.4146 (igdumd64.dll) in POOL-FIN-01 post-update.
- Working baseline: v31.0.100.9999 (POOL-FIN-02 baseline and rollback target).

Verification:
- 12/12 user login validation passes.
- Session duration stable beyond 5 minutes.
- 30-minute post-fix monitoring showed no recurrence and no new crash pattern in validation window.

Preventive action needed:
- Enforce mandatory pre-production pilot testing for image/driver updates.
- Run immediate post-update health checks (login validation + event log scan) before declaring rollout success.

If recurrence occurs, route through Service Desk under INC-2024-0315-AVD-BLACKSCREEN-FIN01 and initiate rollback runbook first.