# Triage Summary

## Summary (one line)
Ticket T-1004: Company app fails to install from Company Portal with error 0x87D1041C.

## Impact (who/how many/ business urgency)
- Who: Reported user/device in this ticket (to-verify identity).
- How many: 1 known case so far (to-verify if broader app deployment impact).
- Business urgency: To-verify based on app criticality for user role.

## known facts
- Ticket ID: T-1004.
- Symptom: Company app installation fails.
- Install source: Company Portal.
- Reported error: 0x87D1041C.

## Missing information to gather
- User/device identity and managed device compliance state.
- Exact app name/version and whether failure is on required or available deployment.
- Full Company Portal error details and timestamp.
- Whether other users/devices can install the same app.
- Network condition and whether retry after sync/restart changes behavior.

## likely catagory
Endpoint application deployment failure via Company Portal/management channel (to-verify).

## First diagnostic step
Confirm app assignment and device management sync status, then reproduce install attempt while capturing the same error code and timestamp for correlation (to-verify).
