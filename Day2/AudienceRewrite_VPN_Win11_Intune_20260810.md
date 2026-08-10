Executive:
Your access is restored and your data is safe; no data was lost. After the Windows 11 upgrade removed the old VPN app, the new app was not automatically reinstalled because a deployment check missed it. We manually removed old VPN settings, forced a device-management sync, deployed the new client, applied split-tunnel settings, and confirmed connection to all internal subnets. You do not need to do anything.

Team:
Your access is back and your data is safe, with no data loss. What happened is that the Windows 11 upgrade removed the old VPN app, but the new one did not auto-install because a deployment check gap stopped the re-deployment. We manually removed old VPN settings, force-synced device management, deployed the new VPN client, applied split-tunnel settings, and confirmed connectivity to all internal subnets. If you see this again, contact the Service Desk.

Engineer:
Root cause:
- Win11 upgrade removed legacy VPN client.
- Intune did not trigger re-deployment of the new client due to a detection-rule gap.

Action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>.
- Force-triggered Intune sync.
- New client deployed.
- Split-tunnel config applied.

Verification:
- Connectivity confirmed to all internal subnets.
- No data loss.

Preventive action needed:
- Fix Intune detection-rule gap so Win11 post-upgrade state (legacy client removed) reliably triggers re-deployment of the new VPN client.