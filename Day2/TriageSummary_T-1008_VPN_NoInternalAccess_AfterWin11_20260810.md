# Triage Summary

## Summary (one line)
Ticket T-1008: VPN connects but internal resources are unreachable after a Windows 11 upgrade.

## Impact (who/how many/ business urgency)
- Who: Reported user/device in this ticket (to-verify).
- How many: 1 known case so far (to-verify wider scope).
- Business urgency: High if user cannot reach core internal systems (to-verify specific business impact).

## known facts
- Ticket ID: T-1008.
- Symptom: VPN connection establishes successfully.
- Symptom: No internal resources are reachable.
- Timing context: After Windows 11 upgrade.

## Missing information to gather
- User/device identity and VPN client/version.
- Which internal resources fail (file shares, intranet, apps, DNS names, IP-based access).
- Whether issue affects all internal resources or specific targets only.
- Whether other users with same VPN profile are affected.
- Network type (home/office) and whether issue persists after reconnect/reboot.
- Any post-upgrade network/security policy changes.

## likely catagory
Post-upgrade remote connectivity or routing/name-resolution issue with VPN access (to-verify).

## First diagnostic step
Confirm scope by testing both name-based and IP-based access to known internal resources immediately after VPN connection to determine whether the primary failure is routing reachability or name resolution (to-verify).
