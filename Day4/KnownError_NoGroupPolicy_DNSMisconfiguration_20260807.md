Symptom     : On affected Finance Floor 3 Windows 11 devices, Group Policy processing fails at startup/logon and domain settings are not applied. Users experience sign-in/session startup policy errors tied to inability to reach domain services.

Cause       : Verified root cause is DHCP scope misconfiguration that advertised decommissioned DNS servers (10.10.3.250 and 172.16.5.5) instead of 10.10.0.10. This caused DC name-resolution timeout and secure-channel failure, followed by Group Policy retrieval failures.

Scope       : Incident impact was 3 of 4 Windows 11 endpoints in OU=Finance on the Floor 3 subnet during 07:40-09:09 on 2024-03-15. A comparator endpoint with correct DNS (10.10.0.10) was unaffected.

Workaround  : Update affected clients to use valid DNS immediately, then renew DHCP lease, refresh DNS client state, and force Group Policy refresh. This restores service path while scope-level DHCP correction is being completed.

Permanent fix: Correct DHCP Option 006 on affected subnet(s) to approved DNS (including 10.10.0.10) and remove decommissioned DNS entries from scope options/reservations/policies. Validate recovery by confirming DC resolution/connectivity and successful Group Policy processing on previously affected devices.

How to spot it: Look for Netlogon Event 5719, DNS Client Event 1014, GroupPolicy Events 1058/1030/1129, and DHCP Client Event 50036 showing old DNS assignment. Typical error strings include failed resolution of FINBRIDGE-DC01.finbridge.local and inability to access \\FINBRIDGE-DC01\\sysvol\\...\\gpt.ini (error 0x3).