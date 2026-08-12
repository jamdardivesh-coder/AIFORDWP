# End-User Communication Pack - Copilot Ticket Set
## Date: 2026-08-12

This note explains each reported issue in plain English and what to do next.

## Ticket 1 - Finance lead: Copilot won't summarize Q3 board pack in SharePoint
What this likely means:
You can open the file, but Copilot may still be blocked from using it if the file has protection rules (for example, a sensitivity label) that limit AI processing.

Next steps for you:
1. Open the board pack and check the Sensitivity label in Office/SharePoint file details.
2. If the label is highly restricted, ask your data owner if Copilot use is allowed for that label.
3. Retry after any policy change.

If still not fixed:
Share the file link and label name with IT so we can verify policy alignment.

## Ticket 2 - New hire: Copilot in Outlook knows nothing about recent emails
What this likely means:
For new accounts, Copilot often needs time to index mailbox content before it can use recent messages well.

Next steps for you:
1. Confirm you are signed into the correct work account in Outlook and Copilot.
2. Wait and retry later (indexing can take time for new starters).
3. Keep Outlook open and synced during this period.

If still not fixed:
Contact IT with your start date and first time you noticed the issue so we can check indexing status.

## Ticket 3 - HR manager: Copilot in Word cannot use sensitive salary spreadsheet
What this likely means:
The spreadsheet is likely protected by sensitivity or access policy. Copilot is correctly enforcing that protection.

Next steps for you:
1. Confirm you can directly open the spreadsheet with your own account.
2. Check the file's sensitivity/protection settings.
3. Ask the data owner whether Copilot use is permitted for this document type.

If still not fixed:
Send IT the exact error text and file location so we can validate policy behavior.

## Ticket 4 - Sales rep: Copilot in Teams cannot find contract shared via guest link from another org
What this likely means:
Guest/external sharing links from another organization are often outside Copilot's normal content boundary.

Next steps for you:
1. Ask the sender to share the document in a tenant-approved way (not guest-link only).
2. Ensure you have direct, internal access to the final document location.
3. Retry Copilot once access is confirmed.

If still not fixed:
Provide the sharing method and source organization details to IT for access-boundary checks.

## Ticket 5 - IT admin: Copilot stopped for whole Finance team this morning
What this likely means:
When an entire team is affected at once, this is usually a licensing, policy, or client configuration change rather than a Copilot product bug.

Next steps for you:
1. Have one affected user sign out and back in to Microsoft 365 apps.
2. Confirm the user's Copilot license is still assigned.
3. Confirm no policy change was made to Finance targeting this morning.

If still not fixed:
IT will run tenant-level checks and raise to Microsoft only if licensing/policy checks are clean.

## Ticket 6 - Manager: Copilot summarized a file they forgot they had access to
What this likely means:
Copilot can use content you have permission to access, even if you do not remember opening it recently.

Next steps for you:
1. Review your permissions on that folder/file.
2. If access is no longer appropriate, request access removal from the folder owner.
3. Ask IT for a permissions review of high-sensitivity locations.

If still concerned:
We can help audit and reduce inherited access so only required content is reachable.

## Ticket 7 - Analyst: Copilot gives generic answers, not using internal SharePoint content
What this likely means:
This usually indicates account/license context issues, missing access, or content not yet indexed.

Next steps for you:
1. Confirm you are using your work account and have a Copilot license.
2. Test with one known SharePoint file you can open directly.
3. Retry with a very specific prompt that names that file or site.

If still not fixed:
Send IT one sample prompt, expected source file, and actual response so we can trace grounding.

## Ticket 8 - Executive assistant: Copilot in Outlook cannot see shared mailbox calendar
What this likely means:
Shared mailbox and delegated calendar access often has boundary limits for Copilot grounding.

Next steps for you:
1. Verify your delegate permission level on the shared mailbox calendar.
2. Confirm you can open the calendar directly in Outlook.
3. Retry Copilot in the same signed-in profile.

If still not fixed:
IT will validate mailbox delegation and supported Copilot behavior for shared resources.

## General Guidance for All Users
1. Check you are signed into the correct work account.
2. Confirm you can open the source content directly first.
3. Capture exact error text and timestamp when reporting to IT.
4. Include links to the affected file/site/mailbox to speed triage.
