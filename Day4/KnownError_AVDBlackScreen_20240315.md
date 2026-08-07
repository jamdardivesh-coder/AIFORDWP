# Known Error Record — AVD Black Screen (INC-2024-0315-AVD-BLACKSCREEN-FIN01)

Symptom     : Users in POOL-FIN-01 complete sign-in, then see a black screen and may be disconnected shortly after login. During the incident window, this prevented desktop access.

Cause       : The POOL-FIN-01 overnight image update at 02:00 introduced Intel GPU driver igdumd64.dll v31.0.101.4146. Desktop Window Manager (dwm.exe) then crashed with access violation 0xc0000005, producing the black screen condition.

Scope       : Affected pool was POOL-FIN-01 only, on session hosts SHFIN-01-A through SHFIN-01-H (8 hosts). Impact was approximately 40% of the Finance desktop pool, about 40 users, between ~07:00 and 10:00 on 2024-03-15.

Workaround  : Roll back the Intel GPU driver on affected POOL-FIN-01 hosts to v31.0.100.9999 and reboot the hosts. This restores user desktop access and removes the immediate black screen condition.

Permanent fix: Keep POOL-FIN-01 on the working Intel GPU driver baseline v31.0.100.9999 instead of v31.0.101.4146. Enforce mandatory pilot-pool validation and immediate post-update health checks before production rollout.

How to spot it: Look for Event ID 1000 (Application Error) showing faulting application dwm.exe, faulting module igdumd64.dll, and exception code 0xc0000005. Corroborate with Event ID 9009 (Desktop Window Manager exited), successful Event ID 21 logon just before failure, and Event ID 40 disconnection; affected hosts show driver v31.0.101.4146 while control hosts remain stable on v31.0.100.9999.
