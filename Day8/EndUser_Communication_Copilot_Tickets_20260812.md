# End-User Communication: Microsoft 365 Copilot Ticket Updates
Date: 2026-08-12

This update explains each reported issue in plain English and what you can do next.

## Ticket 1: Copilot cannot summarize Q3 board pack in SharePoint
What is happening: You can open the board pack yourself, but Copilot may still be blocked from using it if protection settings are applied to the file.

What to do next:
1. Confirm the board pack sensitivity label and encryption settings.
2. Ask your SharePoint or M365 admin to verify whether Copilot is allowed to process content with that label.
3. Retry after any policy updates are applied.

Expected outcome: Once policy allows it, Copilot should be able to summarize the file.

## Ticket 2: New hire Copilot in Outlook does not know recent emails
What is happening: For very new accounts, Copilot often needs more time to finish setup and indexing before recent mailbox content appears in responses.

What to do next:
1. Confirm Copilot license assignment is complete.
2. Wait for indexing and provisioning to finish.
3. Retry later the same day or next business day.

Expected outcome: Copilot responses should improve as mailbox indexing completes.

## Ticket 3: HR manager got "I don't have access to that content"
What is happening: Copilot can only use files the signed-in account is allowed to access. This message usually means a permission or policy block.

What to do next:
1. Confirm your access to the spreadsheet through normal sharing permissions.
2. Ask the file owner or admin to check whether label restrictions limit Copilot use.
3. Retry once access and policy are confirmed.

Expected outcome: If permission and policy allow it, Copilot can use the spreadsheet content.

## Ticket 4: Sales rep cannot find contract shared via guest link from another org
What is happening: Guest or external link content from another organization is often outside Copilot's normal grounding boundary in your home tenant.

What to do next:
1. Confirm whether the contract is only available through an external guest link.
2. Request an internal copy in your tenant (if policy allows).
3. Retry Copilot using the internal copy.

Expected outcome: Copilot works more reliably when the content is stored and shared internally.

## Ticket 5: Copilot stopped for entire Finance team this morning
What is happening: A team-wide sudden issue is usually linked to licensing or service configuration changes, not a single user error.

What to do next:
1. IT should check Copilot license and service plan status for at least one affected Finance user.
2. IT should review any overnight policy or service changes.
3. If no config issue is found, escalate with timestamps and impacted user list.

Expected outcome: Most broad outages are resolved by correcting entitlement or policy drift.

## Ticket 6: Copilot summarized a file user forgot they had access to
What is happening: Copilot can find and summarize files you are authorized to access, even if you forgot that permission existed.

What to do next:
1. Review your access to that folder or file.
2. If access is no longer appropriate, request access removal from the folder owner.
3. Re-test after access changes propagate.

Expected outcome: Copilot behavior should align with your current access permissions.

## Ticket 7: Copilot gives generic answers and ignores internal SharePoint
What is happening: Generic responses usually mean Copilot is not using the correct work context, lacks entitlement, or cannot retrieve internal content yet.

What to do next:
1. Confirm you are signed into your work account and using Microsoft 365 Copilot work context.
2. Confirm your Copilot license is active.
3. Verify you can directly access the SharePoint content you expect Copilot to use.
4. Retry after indexing time if content is newly added.

Expected outcome: Responses become more specific once context, entitlement, and retrieval conditions are correct.

## Ticket 8: Executive assistant cannot access shared mailbox calendar through Copilot
What is happening: Shared mailbox and delegate scenarios can fail when delegate permissions or feature support boundaries are not fully met.

What to do next:
1. Confirm delegate permissions on the shared mailbox calendar.
2. Confirm the assistant is using the correct account and mailbox context in Outlook.
3. Ask IT to validate shared mailbox support requirements for your tenant setup.

Expected outcome: Copilot access should improve after delegate and mailbox context checks are complete.

## If your issue is still not resolved
Please provide the following when replying:
1. Screenshot of the exact Copilot error text.
2. Time of the failed attempt.
3. App used (Outlook, Word, Teams, SharePoint).
4. File or mailbox involved.

This helps us complete a faster and more accurate fix.
