# Microsoft 365 Copilot Readiness Checklist — Finance Department
**Organisation:** DWP (Financial Services)
**Department:** Finance (~200 users)
**Prepared by:** DWP Endpoint Engineering
**Date:** 2026-08-12
**Licensing baseline:** Microsoft 365 E5 | Copilot add-on: NOT YET ASSIGNED

---

> **Risk note:** Finance holds payroll, board packs, M&A documents, and client financial data. SharePoint permissions were inherited from a 2019 migration and have never been formally audited. **Permissions and oversharing remediation must be completed and signed off before the Copilot licence is assigned.** Copilot surfaces content the user can access — misconfigured permissions become an AI-amplified data disclosure risk.

---

## ⚠️ SECTION 1 — Permissions & Oversharing Audit (HIGHEST PRIORITY — BLOCKER)

> This section must be fully completed and signed off by the Information Governance lead before any Copilot licence is assigned. Do not proceed to later sections until all items here are resolved.

### 1.1 SharePoint Site & Library Permissions Audit

- [ ] **1.1.1** Export a full permissions report for all SharePoint sites used by Finance using Microsoft 365 admin centre or a tool such as ShareGate / Valo Governance.
- [ ] **1.1.2** Identify every site where **"Everyone"**, **"Everyone except external users"**, or **"All Company"** sharing is enabled and revoke or scope those permissions.
- [ ] **1.1.3** Identify sites and libraries that were migrated in 2019 and still carry legacy permissions groups from the source environment (e.g. old AD groups, defunct distribution lists). Remove or replace all stale groups.
- [ ] **1.1.4** Confirm that **broken inheritance** exists on all sensitive document libraries (payroll, M&A, board packs) so permissions are explicitly managed at library or site level — not inherited from a parent site with broader access.
- [ ] **1.1.5** Confirm no Finance SharePoint site is set to **allow anonymous/external link sharing** unless explicitly approved and documented.
- [ ] **1.1.6** Document the intended access matrix (role → site → library → permission level) for Finance and validate the current state matches it.
- [ ] **1.1.7** Obtain written sign-off from Finance Head / Information Governance lead confirming the audit outcome and any accepted residual risk.

### 1.2 Oversharing Checks — OneDrive

- [ ] **1.2.1** Run the **SharePoint Advanced Management** oversharing report (or equivalent PowerShell via `Get-SPOSite` + `Get-SPOUser`) to identify OneDrive files shared broadly with internal users outside Finance.
- [ ] **1.2.2** Identify any OneDrive "Anyone with link" shares created by Finance users and revoke unless individually approved.
- [ ] **1.2.3** Enforce an organisation-wide or Finance-scoped sharing policy that restricts default OneDrive sharing to **"Specific people"** or **"People in your organisation"** (no anonymous links).
- [ ] **1.2.4** Confirm the **default sharing link type** in SharePoint admin is set to "Specific people" for Finance sites.

### 1.3 Oversharing Checks — Teams & Shared Mailboxes

- [ ] **1.3.1** Audit all Finance Teams channels: confirm private channels holding sensitive content (e.g. exec comms, M&A) are correctly scoped and membership is current.
- [ ] **1.3.2** Confirm shared mailboxes used by Finance do not have excessive delegates or send-as permissions from outside the team.
- [ ] **1.3.3** Review any broad distribution lists or M365 Groups that Finance users are members of; Copilot can surface content shared with those groups.

### 1.4 Sensitivity Label Coverage (Permissions dependency)

- [ ] **1.4.1** Confirm that sensitivity labels are applied to all documents in payroll, board pack, and M&A libraries before Copilot is enabled (labelled files carry encryption that limits Copilot's ability to surface them to unauthorised users).
- [ ] **1.4.2** Run a Content Explorer scan in Microsoft Purview to identify unlabelled files containing financial PII (account numbers, NI numbers, salary data) across Finance SharePoint and OneDrive locations.
- [ ] **1.4.3** Remediate unlabelled sensitive content identified in 1.4.2 — apply labels manually or via auto-labelling policy — before proceeding.

---

## SECTION 2 — Licensing Prerequisites

- [ ] **2.1** Confirm all ~200 Finance users hold an active **Microsoft 365 E5** licence in the M365 admin centre (Billing → Licences).
- [ ] **2.2** Confirm the tenant has a **Microsoft 365 Copilot** add-on SKU available with sufficient seat count (minimum 200 unassigned seats).
- [ ] **2.3** Do **not** assign Copilot licences until Section 1 (Permissions Audit) is fully signed off.
- [ ] **2.4** Identify a licence assignment method: individual assignment via admin centre, group-based licensing via Entra ID, or PowerShell bulk assignment. Document the chosen approach.
- [ ] **2.5** Confirm that Copilot usage data will be captured in **Microsoft 365 usage analytics** so adoption can be tracked post-rollout.

---

## SECTION 3 — Microsoft 365 Apps Client Version Requirements

- [ ] **3.1** All Finance endpoints must run **Microsoft 365 Apps for Enterprise** (not Office 2019 / LTSC / perpetual). Verify via Intune → Apps → Monitor or Microsoft 365 Apps admin centre.
- [ ] **3.2** Confirm the installed channel and build. Copilot in Word, Excel, PowerPoint, Outlook, and Teams requires **Version 2302 (build 16130) or later**. The recommended channel is **Current Channel** or **Monthly Enterprise Channel**.
- [ ] **3.3** If any devices are on **Semi-Annual Enterprise Channel**, confirm the installed build meets the minimum and plan a channel switch if it does not.
- [ ] **3.4** Confirm **Click-to-Run** (not MSI) deployment is in use — MSI-based Office installs do not support Copilot features.
- [ ] **3.5** Verify Microsoft Teams desktop client is on a supported version (Teams classic must be migrated to **new Teams**; new Teams is required for Copilot in Teams meetings).
- [ ] **3.6** Confirm that **Connected Experiences** and **optional connected experiences** are not blocked by policy for Finance users (required for Copilot to function in Office apps).

---

## SECTION 4 — Identity & MFA Readiness

- [ ] **4.1** Confirm all Finance user accounts are **cloud-only or hybrid-synced** Entra ID accounts in good standing (no sync errors in Entra Connect / Cloud Sync).
- [ ] **4.2** Confirm **Multi-Factor Authentication (MFA)** is enforced for all 200 Finance users — either via Conditional Access policy or per-user MFA. No exceptions.
- [ ] **4.3** Confirm that Conditional Access policies do not block the Copilot service endpoints (`*.microsoft.com`, `*.office.com`, `*.copilot.microsoft.com`). Test with the **Conditional Access What If** tool for a Finance user account.
- [ ] **4.4** Confirm **no Finance accounts are shared / generic accounts** (e.g. `finance-team@company.com` used by multiple people). Copilot is per-user and will surface all content accessible to that account.
- [ ] **4.5** Confirm that privileged Finance accounts (e.g. anyone with SharePoint admin or Global Admin) are using **separate admin accounts** and that admin accounts will not receive Copilot licences.
- [ ] **4.6** Confirm that **Microsoft Entra ID audit logs** are retained for at least 90 days to support any post-enablement investigation.

---

## SECTION 5 — Sensitivity Labelling Readiness

> See also Section 1.4 — label coverage is a permissions control, not just a compliance requirement.

- [ ] **5.1** Confirm **Microsoft Purview Information Protection** is configured with a label taxonomy appropriate for Finance (e.g. Internal, Confidential — Finance, Highly Confidential — Payroll/M&A).
- [ ] **5.2** Confirm sensitivity labels are **published to Finance users** via a label policy in the Purview compliance portal.
- [ ] **5.3** Confirm the **default label** policy for Finance applies at minimum "Confidential — Finance" to new documents created in SharePoint and OneDrive.
- [ ] **5.4** Configure and enable **auto-labelling policies** (client-side and service-side) to classify content matching financial data patterns (e.g. bank account numbers, salary keywords, NI numbers).
- [ ] **5.5** Confirm **Copilot-generated content inherits the highest label** of the source documents used. Validate this behaviour in a test tenant or pilot group before broad rollout.
- [ ] **5.6** Confirm that labels with encryption (Rights Management) are correctly configured so that encrypted documents remain accessible to authorised Finance users (avoid inadvertent access blocks caused by misconfigured RMS templates).

---

## SECTION 6 — End-User Communications & Enablement

- [ ] **6.1** Produce a **Finance-specific Copilot acceptable use briefing** that references the DWP Personal AI Usage Charter and covers: what Copilot can and cannot see, how sensitivity labels protect content, and responsibilities for data handling when using AI-generated outputs.
- [ ] **6.2** Schedule a **30-minute live briefing or recorded walkthrough** for Finance users before licence assignment, covering: how to use Copilot in Outlook, Teams, Word, and Excel; prompt best practice; and what to do if Copilot surfaces content they should not see.
- [ ] **6.3** Identify **Finance Copilot Champions** (2–3 power users) who will support peers and provide feedback to the engineering team in weeks 1–4 post-rollout.
- [ ] **6.4** Create a **feedback channel** (e.g. a Teams channel or ServiceNow category) for Finance users to report unexpected content surfacing, prompt failures, or data concerns.
- [ ] **6.5** Confirm that the **IT Service Desk** has been briefed on common Copilot issues (missing Copilot icon, licence not reflected, Teams meeting summary not appearing) and has an escalation path to the M365 engineering team.
- [ ] **6.6** Schedule a **4-week post-rollout review** with Finance management to assess adoption, address concerns, and review any data access incidents flagged through the feedback channel.

---

## Sign-Off & Gate Criteria

| Gate | Owner | Status |
|------|-------|--------|
| Section 1 — Permissions & Oversharing Audit complete and signed off | Information Governance Lead + Finance Head | ☐ Not started |
| Section 2 — Licensing confirmed and ready to assign | M365 Licencing Admin | ☐ Not started |
| Section 3 — All Finance endpoints on supported build | Endpoint Engineering | ☐ Not started |
| Section 4 — MFA and identity checks passed | Identity / IAM Team | ☐ Not started |
| Section 5 — Sensitivity labels deployed and validated | Purview / Security Team | ☐ Not started |
| Section 6 — User comms delivered | Change Management | ☐ Not started |
| **Copilot licence assignment approved** | **Service Owner** | **☐ Blocked pending above** |

---

*This checklist should be reviewed against the [Microsoft 365 Copilot adoption hub](https://adoption.microsoft.com/en-us/copilot/) and updated if Microsoft prerequisites change prior to rollout.*
