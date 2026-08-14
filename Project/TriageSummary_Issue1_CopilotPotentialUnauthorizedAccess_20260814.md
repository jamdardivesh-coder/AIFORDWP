# Triage Summary - Issue 1: Potential Unauthorized Client Matter Exposure via Copilot

## Separate Problem Statement
A paralegal on Floor 6 reported that Copilot surfaced a client matter they believe they have never been authorized to access.

## Urgency
Critical (P1) - Potential confidentiality/security incident.

## What We Check First (and Why)
1. **Immediate access verification for the reported user and client matter**
   - **Check:** Confirm the exact user account, timestamp, prompt, and the matter/document identifier shown.
   - **Why first:** We need to rapidly determine whether this is true unauthorized exposure or a misunderstanding (similar matter names, stale index references, cached snippet context).

2. **Permission path on source systems (DMS, SharePoint, file ACLs, matter workspace ACLs)**
   - **Check:** Effective permissions for the reporting user and any groups at the time of incident.
   - **Why first:** Copilot generally reflects underlying access. If permissions are wrong, this is the likely root and must be contained quickly.

3. **Containment actions if exposure is plausible**
   - **Check/Do now:** Temporarily restrict Copilot/data-source connector for impacted scope (user, floor cohort, or affected repository) and open Security/Privacy incident.
   - **Why first:** Prevents further potential data disclosure while evidence is preserved.

4. **Audit and telemetry review**
   - **Check:** Copilot interaction logs, DMS audit logs, access token/group changes, Friday deployment-related policy changes.
   - **Why first:** Establishes whether data was retrieved from authorized context, inherited permissions, or misconfiguration after rollout.

5. **Correlation to Friday app rollout**
   - **Check:** Any newly applied groups, sync jobs, indexing scopes, or connector mappings tied to the document management deployment.
   - **Why first:** A single change window may explain multiple users and allows targeted rollback.

## What We Do Right Now
- Open a **security-severity ticket** and notify Security/Compliance immediately.
- Preserve evidence: screenshots, timestamp, prompt text, matter ID/name, user UPN.
- Apply temporary safeguard on Copilot/data connector scope if risk remains unconfirmed.
- Start parallel ACL audit on the specific matter and user group memberships.

## What We Tell Partners by Lunch (Non-Technical)
- "We are treating this as a priority confidentiality check."
- "We have put temporary safeguards in place while we verify whether access settings were incorrect or the result was context confusion."
- "No broad conclusions yet; we will provide a factual update after permission and audit-log validation this morning."
- "If there is any confirmed overexposure, we will share impact scope, containment, and remediation steps immediately."

## Current Working Hypothesis
Most likely causes are either:
- access inheritance/group assignment drift after Friday rollout, or
- a misinterpreted result (similar client/matter metadata).

## Owner Routing
- Primary: Security + Identity + DMS platform owner
- Supporting: Floor 6 service desk lead, Copilot admin
