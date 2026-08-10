# Triage Summary

## Summary (one line)
User reports the main printer on the 3rd floor is unavailable and the whole team is affected ahead of a client meeting at 2.

## Impact (who/how many/ business urgency)
- Who: Team on/using the 3rd floor main printer (exact team name to confirm).
- How many: Multiple users; reported as whole team affected (exact count to confirm).
- Business urgency: High; client meeting at 2 creates a time-critical printing dependency.

## known facts
- Symptom: "printer gone" (printer not available/visible).
- Affected device: "the big one on 3rd floor".
- Scope: "whole team affected".
- Time pressure: client meeting at 2.

## Missing information to gather
- Exact printer name/queue/server share name.
- Whether users cannot see printer, cannot connect, or print jobs fail.
- First time observed and whether issue is intermittent or constant.
- Whether any print jobs are stuck and any printer panel error/status.
- Which teams/users are affected and whether any users can still print.
- Whether other printers on same floor/site are working.
- Recent changes: print server updates, network changes, or maintenance.

## likely catagory
Shared network printer service disruption (to confirm).

## Suggest first diagnostic step
Verify scope and service state by checking whether the 3rd floor printer queue is visible/reachable from multiple affected users and confirming printer panel/network status, to distinguish endpoint mapping issues from a printer/print-server outage.
