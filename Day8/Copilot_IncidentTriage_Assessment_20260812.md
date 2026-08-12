# Copilot Incident Triage Assessment (DWP)
Date: 2026-08-12

Scope: Ranked likely causes are restricted to the approved list only:
- permissions/access boundary
- data indexing lag
- sensitivity label restriction
- license/client prerequisite issue
- guest/external sharing limitation
- genuine Copilot fault (last resort)

## Ticket Assessments

| ID | Ticket (summary) | Likely cause (ranked, most probable first) | Fastest check (single first check) | Is this actually a Copilot bug? |
|---|---|---|---|---|
| 1 | Finance lead cannot summarize Q3 board pack in SharePoint, but can see it manually | 1) sensitivity label restriction 2) permissions/access boundary 3) data indexing lag 4) genuine Copilot fault | Check the board pack's sensitivity label and encryption permissions for that user account | **No (most likely).** The user being able to open a file does not guarantee Copilot can use it if label/encryption policy blocks AI access. |
| 2 | New hire (started yesterday): Copilot in Outlook knows nothing about recent emails | 1) data indexing lag 2) license/client prerequisite issue 3) permissions/access boundary 4) genuine Copilot fault | Check when the user's Copilot license was assigned and whether mailbox content is still in initial indexing window | **No (most likely).** Day-1/day-2 accounts commonly hit provisioning/indexing delays before Copilot grounding catches up. |
| 3 | HR manager in Word: salary spreadsheet returns "I don't have access to that content" | 1) permissions/access boundary 2) sensitivity label restriction 3) genuine Copilot fault | Verify the manager's effective permissions on that spreadsheet (directly and via group) | **No.** The explicit access-denied response strongly indicates an authorization or policy boundary, not model failure. |
| 4 | Sales rep in Teams cannot find client contract shared via guest link from another org | 1) guest/external sharing limitation 2) permissions/access boundary 3) genuine Copilot fault | Confirm the contract is only shared through an external guest link from another tenant | **No.** External/guest-shared content is commonly outside what Copilot can ground against in the home tenant context. |
| 5 | IT admin: Copilot stopped for whole Finance team this morning, worked yesterday | 1) license/client prerequisite issue 2) permissions/access boundary 3) genuine Copilot fault | Check one affected Finance user in M365 admin center for Copilot license/service plan status changes | **Unclear.** Team-wide sudden impact is usually licensing/configuration drift; classify as possible product fault only after admin and policy checks fail. |
| 6 | Manager: Copilot summarized a file from a folder they forgot they could access | 1) permissions/access boundary 2) genuine Copilot fault | Validate current effective ACLs for the manager on that folder/file | **No.** If the user has access, Copilot can legitimately retrieve and summarize that content. |
| 7 | Analyst: Copilot gives generic answers and seems to ignore internal SharePoint content | 1) license/client prerequisite issue 2) permissions/access boundary 3) data indexing lag 4) genuine Copilot fault | Confirm user is in Microsoft 365 Copilot work context and has active Copilot license/service plan | **Unclear (lean No).** Generic responses usually mean wrong client/context, missing entitlement, or lack of retrievable permissions before a true product defect. |
| 8 | Executive assistant: Copilot in Outlook cannot see shared mailbox calendar they manage for director | 1) permissions/access boundary 2) license/client prerequisite issue 3) genuine Copilot fault | Check delegate permissions on the shared mailbox calendar for the assistant account | **No (most likely).** Shared mailbox/delegate scenarios often fail due to permission scope and feature support boundaries, not core Copilot faults. |

## Triage Notes

- Apply "genuine Copilot fault" only after access, label, licensing/client, external-sharing, and indexing checks are exhausted.
- For broad-impact incidents (multiple users/team), prioritize license and policy drift checks before escalating as product defect.
