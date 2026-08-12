# Copilot Legal Tickets - Incident Triage and End-User Communication (2026-08-12)

## Ticket 1
**Scenario**: Paralegal asked Copilot to summarize a client NDA in SharePoint and got "I don't have access to that content." She has not opened that folder before.

### Incident triage
- **Likely cause (ranked)**:
  1. permissions/access boundary
  2. sensitivity label restriction
  3. guest/external sharing limitation
  4. data indexing lag
  5. license/client prerequisite issue
  6. genuine Copilot fault
- **Fastest check**: Ask the user to open the exact NDA link directly in SharePoint with her account; confirm whether access is denied.
- **Is this actually a Copilot bug?**: **No**. The explicit "I don't have access" response and the user's statement that she has never opened that folder strongly point to normal access controls, not Copilot malfunction.

### End-user communication
Hi - we checked this and your data is safe. Copilot can only read files you already have permission to access, and this NDA is currently outside your access scope. This is why you saw the access message. Next step is for the document owner or matter admin to grant you the right SharePoint folder permission. Once that is applied, Copilot should be able to summarize the file normally. You do not need to change anything in Copilot.

---

## Ticket 2
**Scenario**: New associate (started this week) says Copilot in Outlook cannot find case emails needed for context.

### Incident triage
- **Likely cause (ranked)**:
  1. data indexing lag
  2. license/client prerequisite issue
  3. permissions/access boundary
  4. sensitivity label restriction
  5. guest/external sharing limitation
  6. genuine Copilot fault
- **Fastest check**: Confirm the associate can manually find the same emails in Outlook search (without Copilot).
- **Is this actually a Copilot bug?**: **Unclear (leaning No)**. New starters commonly hit mailbox/search/index readiness delays or provisioning prerequisites before Copilot context becomes complete.

### End-user communication
Hi - your data is safe, and this usually happens during the first days after a new account setup. Copilot relies on the same mailbox/search signals as Outlook, and those can take a bit of time to fully settle for new users. We are checking your mailbox/search readiness and Copilot setup now. If you can already find the emails with normal Outlook search, Copilot coverage should improve as indexing completes. No action is needed from you right now.

---

## Ticket 3
**Scenario**: Partner says Copilot surfaced and summarized a draft settlement from a matter they are not assigned to; they did not know they could see that folder.

### Incident triage
- **Likely cause (ranked)**:
  1. permissions/access boundary
  2. data indexing lag
  3. sensitivity label restriction
  4. guest/external sharing limitation
  5. license/client prerequisite issue
  6. genuine Copilot fault
- **Fastest check**: Validate whether the partner can directly open that draft/folder in SharePoint using the document URL.
- **Is this actually a Copilot bug?**: **No (based on current evidence)**. If the user could receive a summary, they likely had effective access rights; this indicates an access model/assignment issue rather than Copilot bypassing security.

### End-user communication
Hi - we reviewed this and your data remains protected by Microsoft 365 permissions. Copilot does not bypass access controls; it only uses content your account can already access. We are now checking why this matter content is visible to your account and will correct folder permissions if needed. You do not need to take action in Copilot. We will confirm once access boundaries are tightened.

---

## Ticket 4
**Scenario**: Legal ops manager reports all 40 Legal team users suddenly lost Copilot access this morning after it worked last week.

### Incident triage
- **Likely cause (ranked)**:
  1. license/client prerequisite issue
  2. genuine Copilot fault
  3. permissions/access boundary
  4. data indexing lag
  5. sensitivity label restriction
  6. guest/external sharing limitation
- **Fastest check**: Check one affected user in Microsoft 365 admin center for active Copilot license/service plan state and recent group-based assignment changes.
- **Is this actually a Copilot bug?**: **Unclear**. A team-wide sudden outage is often licensing/provisioning or tenant configuration drift; classify as product fault only if licensing/prerequisites are confirmed healthy across affected users.

### End-user communication
Hi - your information is safe. We can see this is a broad access issue affecting multiple Legal users, and we are actively working it now. The fastest path is validating tenant licensing/provisioning status and restoring any changed assignment immediately. This is not caused by anything you did. No action is required from individual users right now; we will send an update as soon as access is restored.

---

## Ticket 5
**Scenario**: Contract specialist gets vague/generic Copilot answers about clauses in the contract template library; Copilot seems not to read the documents.

### Incident triage
- **Likely cause (ranked)**:
  1. data indexing lag
  2. permissions/access boundary
  3. sensitivity label restriction
  4. license/client prerequisite issue
  5. guest/external sharing limitation
  6. genuine Copilot fault
- **Fastest check**: Ask Copilot for a direct quote/citation from one known template document and verify whether that file is cited.
- **Is this actually a Copilot bug?**: **Unclear (leaning No)**. Generic responses more commonly indicate retrieval/indexing or access-to-source-content issues rather than a platform defect.

### End-user communication
Hi - your documents are safe. We found that Copilot is currently returning broad guidance instead of pulling precise clause text from your template library. This is usually temporary and tied to content retrieval/index readiness or access scope, not data loss. We are validating source access and search/index status on the library now. You do not need to change anything, and we will confirm once targeted document grounding is back to normal.
