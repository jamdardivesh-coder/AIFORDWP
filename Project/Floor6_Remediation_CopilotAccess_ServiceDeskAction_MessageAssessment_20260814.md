# Floor 6 Copilot Access Issue — Service Desk Immediate Action & Communication Assessment
**Date:** 2026-08-14  
**Incident:** Paralegal reports Copilot surfaced client matter user believes unauthorized  
**Status:** Escalated to Security/Data-Governance — Investigation Ongoing  
**Known Scope:** One individual confirmed affected; no validated root cause  

---

## Immediate Service Desk Action

**This is NOT a service-desk resolution. Do not attempt technical fixes. This is an active security investigation.**

### Required Actions (Next 15 Minutes):

1. **Confirm Escalation Logged**
   - Verify that a **P1 Security Incident** ticket has been created and assigned to **Security + Data-Governance team**
   - Ticket must include:
     - Affected user UPN / employee ID
     - Exact timestamp of issue discovery (user report time)
     - Matter/case name and document identifier
     - Exact Copilot prompt and response text (screenshot preferred)
     - Access path (was matter shown in Copilot search, suggested content, or other?)

2. **Preserve Evidence**
   - Request screenshot or screen recording from affected user showing the matter/Copilot result
   - Do NOT ask user to reproduce the issue (prevents log overwriting)
   - Store evidence in secure ticket attachment or designated evidence repository
   - Document user's statement: "Has never had access before" or paraphrase user's exact concern

3. **Confirm with Security/Data-Governance**
   - **Handoff:** "Escalation logged under [ticket #]. User [name] is aware investigation is underway. Awaiting your access audit and permission review."
   - Ensure they have direct contact info for the reporting user if follow-up questions arise
   - Confirm **estimated update time** for permission validation (typically within 2–4 hours)

4. **Inform Affected User (Individual, Not Floor-Wide)**
   - **Do NOT disclose investigation details to other floor staff**
   - **Tell the paralegal only:**
     > "Thank you for reporting this. We've escalated it to our security team as a priority confidentiality check. They're reviewing whether access permissions are correct. We'll confirm with you what they find. In the meantime, do not share or act on that content, and contact us if you see it again."
   - Provide direct contact: Service Desk case number and escalation contact for follow-ups

5. **Do Not Speculate or Reassure**
   - Do NOT say "It's probably just a permissions mistake" or "Don't worry, you shouldn't have access"
   - Do NOT suggest it's a Copilot bug or misunderstanding without evidence
   - Keep tone neutral: "We're investigating. Security team will validate."

---

## Communication Assessment: Floor-Wide Message

### Is a Floor-6-Wide Message Appropriate at This Stage?

**NO. Do not send a floor-wide message.**

### Reasoning:

1. **Scope is single-user, not floor-wide**
   - Only one individual has reported this issue (the paralegal)
   - No evidence yet that other Floor 6 users are affected
   - Floor-wide alert creates false sense of crisis when incident is isolated

2. **Investigation is ongoing; no facts confirmed**
   - No root cause determined (could be permission error, access inheritance, misunderstanding, or other)
   - No containment measures yet deployed
   - Premature communication risks alarming users or compromising security investigation

3. **Premature communication risks security/privacy**
   - Broadcasting issue to floor could alert potential bad actors or cause defensive changes to audit logs
   - Specific matter name/client should not be disclosed floor-wide
   - Incident may involve confidential clients or sensitive access controls

4. **No actionable guidance for users**
   - If issue is real, users should NOT self-remediate or check their own access (noise in audit logs)
   - If issue is misunderstanding, floor message creates confusion
   - Security team needs data intact to investigate; user actions contaminate evidence

### If / When to Escalate to Floor-Wide Communication:

**Escalate ONLY if:**
- Security investigation confirms **systematic unauthorized access** (multiple users affected)
- Multiple users report similar issue within next 2–4 hours
- Containment action (e.g., temporary Copilot/data-source restriction) affects broad user base
- Legal/compliance determines incident-notification obligations require disclosure

**At that stage:**
- Use established incident communication channels (managed by Incident Commander)
- Coordinate messaging with Security + Legal + Communications
- Focus on factual containment actions, not speculation on cause

---

## Next Steps (Escalation Team Responsibilities)

- [ ] **Security/Data-Governance:** Validate user's group memberships and effective permissions on reported matter
- [ ] **Data-Governance:** Pull ACL/permission audit trail for matter (pre/post Friday deployment)
- [ ] **Copilot Admin:** Review Copilot interaction logs for this user and matter (confirm connector/index scope)
- [ ] **DMS Platform Owner:** Check if Friday app deployment modified permission sync, group scope, or connector mappings
- [ ] **Service Desk:** Stand by for escalation team to report findings (expect update within 4 hours)

---

## Key Principle

**Security investigations are not service-desk-resolution tickets.** Your role is:
- Accurate evidence capture ✓
- Rapid escalation ✓
- Containing information (do not broadcast) ✓
- Following up with user once investigation concludes ✓

**Your role is NOT:**
- Suggesting technical cause ✗
- Offering reassurance before facts ✗
- Creating floor-wide panic or false all-clear ✗
