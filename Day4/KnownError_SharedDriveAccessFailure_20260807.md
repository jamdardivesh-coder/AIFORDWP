# Known Error Record - Shared Drive Access Failure (Finance)

Symptom: Finance users cannot access shared drives, and the expected mapped drive is not assigned. In this incident, service impact started around 08:00 and affected 45 users.

Cause: The verified root cause is an execution-context mismatch after drive mapping was migrated from GPO USER logon script to Intune SYSTEM script. The script was not updated for SYSTEM context timing and credential behavior, causing UNC mapping failure.

Scope: Affected systems were DESKTOP-FB* devices in OU=Finance. Affected users were Finance users, with 45 users impacted in this incident.

Workaround: Disable or unassign the failing SYSTEM-context Intune mapping path for the affected scope. Restore or use USER-context mapping at sign-in to recover drive access.

Permanent fix: Keep shared-drive mapping in logged-on USER context and remove conflicting duplicate mapping assignments. Implement script resilience controls defined in RCA, including readiness checks and controlled retry behavior.

How to spot it: Look for ScriptRunner entries showing Map-FinBridgeDrives.ps1 running as SYSTEM, then failure at UNC path \\finbridge-fs01\Finance with error Network name cannot be found and exit code 1. Correlate with Service Control Manager Event 7036, GroupPolicy Event 1500 success, and Ntfs Event 98 indicating drive letter not assigned.
