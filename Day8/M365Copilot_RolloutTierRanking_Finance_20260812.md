# Microsoft 365 Copilot Rollout — Tier Ranking & Risk Justification
**Department:** Finance (~200 users)
**Prepared by:** DWP Endpoint Engineering
**Date:** 2026-08-12
**Reference checklist:** M365Copilot_Readiness_Checklist_Finance_20260812.md

---

## Why This Document Exists

Not all readiness checklist items carry equal risk. A client build being one version behind is recoverable within hours. Copilot surfacing a board pack or payroll file to the wrong person is a data breach — with regulatory, legal, and reputational consequences that are not recoverable in hours. This document ranks every checklist item by rollout gating tier and provides the Finance-specific justification for the ordering.

---

## Tier Definitions

| Tier | Label | Meaning |
|------|-------|---------|
| 🔴 MUST | Blocking — rollout cannot proceed | Skipping this item creates an unacceptable risk of data breach, licence failure, or a broken user experience at the point of enablement |
| 🟡 SHOULD | High risk if skipped — complete before rollout where possible | Skipping creates elevated risk or degraded experience; acceptable only with documented, time-bound remediation plan |
| 🟢 CAN | Lower risk — complete during or after rollout | Skipping has manageable consequences; can be addressed in the weeks following licence assignment |

---

## Tier 1 — 🔴 MUST Complete Before Rollout (Blocking)

These items must be resolved and signed off before a single Copilot licence is assigned to a Finance user.

| Ref | Item | Why it is a hard blocker |
|-----|------|--------------------------|
| 1.1.1 | Export full SharePoint permissions report for all Finance sites | You cannot remediate what you have not measured. This is the foundation of the entire permissions audit. |
| 1.1.2 | Revoke "Everyone" / "Everyone except external users" / "All Company" broad shares | Copilot will retrieve and surface content accessible to the signed-in user. A broad share means Copilot can relay that content to anyone in Finance — regardless of whether they should see it. |
| 1.1.3 | Remove stale 2019 migration legacy permission groups | Legacy groups may include users who have left the organisation, changed roles, or belong to unrelated teams. These are invisible access grants that will be exploited by Copilot's retrieval. |
| 1.1.4 | Confirm broken inheritance on sensitive libraries (payroll, M&A, board packs) | Without explicit library-level permissions, a user navigating a parent site could have inherited read access to payroll data. Copilot will find and return it. |
| 1.1.7 | Written sign-off from Finance Head / Information Governance lead | Establishes accountability and confirms the audit outcome is accepted. Without this, rollout is proceeding without a named owner accepting the residual risk. |
| 1.2.3 | Enforce sharing policy restricting OneDrive to "Specific people" or internal-only | Prevents new overshares being created in the window between audit completion and rollout. |
| 1.4.1 | Sensitivity labels applied to payroll, board pack, and M&A libraries | Labels with encryption are a backstop control: even if a permission is misconfigured, an encrypted label limits who Copilot can decrypt content for. |
| 1.4.3 | Remediate unlabelled sensitive content identified in Purview Content Explorer scan | Unlabelled files are unprotected files. Copilot has no label-based signal to treat them as sensitive. |
| 2.1 | Confirm all 200 users hold active M365 E5 licences | Copilot cannot be assigned without the prerequisite licence. A failed licence assignment produces a broken, confusing experience on day one. |
| 2.2 | Confirm Copilot add-on SKU is available with sufficient seat count | As above — no seats, no rollout. |
| 3.1 | Confirm Microsoft 365 Apps for Enterprise (not perpetual/LTSC) on all endpoints | Copilot features do not exist in perpetual Office. Users on LTSC will see no Copilot UI despite holding a licence — generating support noise and eroding trust in the rollout. |
| 3.2 | Confirm build ≥ Version 2302 (build 16130) | Below this build, Copilot buttons and features are absent regardless of licence. |
| 3.4 | Confirm Click-to-Run deployment (not MSI) | MSI-based Office installs cannot receive Copilot features at all. |
| 3.5 | Confirm new Teams client (not Teams classic) | Copilot in Teams meetings requires new Teams. Classic Teams will silently fail to show meeting summaries. |
| 4.2 | MFA enforced for all 200 Finance users | MFA is a Microsoft prerequisite for Copilot. It is also a baseline security control for a department holding this class of data. No exceptions. |
| 4.4 | No shared/generic Finance accounts hold a Copilot licence | A shared account with a Copilot licence will surface content from every email, file, and chat associated with that account to whoever is signed in at that moment. This is an immediate data breach vector. |
| 5.2 | Sensitivity label policy published to Finance users | Without published labels, users cannot apply them and auto-labelling has no client-side enforcement. |

---

## Tier 2 — 🟡 SHOULD Complete Before Rollout (High Risk if Skipped)

These items significantly reduce risk but can proceed with a documented remediation plan if completion before the rollout date is not achievable.

| Ref | Item | Risk if skipped / deferred |
|-----|------|---------------------------|
| 1.2.1 | Run oversharing report for OneDrive broad internal shares | Without this, Finance users' personal OneDrive content may be accessible to colleagues outside the team. Lower severity than SharePoint libraries but still a meaningful exposure for a Finance context. |
| 1.2.2 | Revoke "Anyone with link" shares in OneDrive | Anonymous links are a data leakage risk independent of Copilot; Copilot makes it more likely these links are found and forwarded. |
| 1.2.4 | Set default sharing link type to "Specific people" for Finance sites | Prevents the next person who shares a document from accidentally creating a broad link. A configuration change, not an audit — should be low effort. |
| 1.3.1 | Audit Finance Teams private channels | M&A and exec comms held in private channels with stale membership is a realistic risk. Defer only if channel membership has been reviewed within the last 6 months. |
| 1.3.3 | Review broad M365 Groups / distribution lists Finance users belong to | Copilot can surface content shared with any group the user is a member of — including groups they joined years ago for a project that has since ended. |
| 4.1 | Confirm Entra ID sync health for all Finance accounts | A sync error can cause a user's licence assignment to fail silently or their Copilot context to be incomplete. Low probability but high confusion impact. |
| 4.3 | Validate Conditional Access policies do not block Copilot endpoints | If a CA policy blocks Copilot service endpoints, the feature silently fails after licence assignment. Test this in a pre-prod environment or with the CA What If tool before rollout. |
| 5.1 | Confirm Purview label taxonomy is Finance-appropriate | If the existing taxonomy lacks a "Highly Confidential — Payroll/M&A" tier, labelling is imprecise and encryption policies may not apply correctly. |
| 5.3 | Default label policy set to "Confidential — Finance" for new documents | Without a default, new documents created after rollout are unlabelled until a user manually applies one. Auto-labelling can compensate but only retrospectively. |
| 5.4 | Auto-labelling policies configured for financial data patterns | Reduces the unlabelled document backlog over time. Not a day-one blocker but should be active by week 2. |
| 6.1 | Finance-specific Copilot acceptable use briefing produced | Users proceeding without any guidance will make mistakes — sharing Copilot outputs externally, copy-pasting AI-generated financial summaries without verification. The briefing reduces this risk. |
| 6.2 | 30-minute live briefing or recorded walkthrough delivered | Adoption without training generates support tickets and erodes confidence. Can be delivered on the day of licence assignment if scheduling is tight, but must not be skipped entirely. |

---

## Tier 3 — 🟢 CAN Complete During or After Rollout (Lower Risk)

These items improve the rollout experience, governance posture, or adoption rate but do not create acute data risk if deferred briefly.

| Ref | Item | Notes on deferral |
|-----|------|-------------------|
| 1.3.2 | Audit shared mailbox delegates for Finance | Lower Copilot attack surface than SharePoint/OneDrive. Complete within 30 days post-rollout. |
| 2.4 | Document licence assignment method | Operational hygiene. The method will be apparent from whichever approach was used. Document within 2 weeks. |
| 2.5 | Confirm Copilot usage captured in M365 usage analytics | Needed for adoption reporting but has no day-one impact. Enable within the first week post-rollout. |
| 3.3 | Plan channel switch for Semi-Annual Enterprise Channel devices | If devices on SAEC meet the minimum build, this is not a blocker — but a channel migration to MEC or Current Channel should be planned within 60 days to ensure prompt feature access. |
| 3.6 | Confirm Connected Experiences not blocked by policy | Worth checking during pre-rollout testing; if Copilot works in test, this is not blocked. |
| 4.5 | Confirm privileged Finance accounts use separate admin accounts | Best practice identity hygiene. Should already be in place; if not, remediate within 30 days. |
| 4.6 | Confirm Entra ID audit logs retained ≥ 90 days | Needed for post-incident investigation, not prevention. Verify within 2 weeks. |
| 5.5 | Validate Copilot-generated content inherits highest source label | Important to validate in a pilot but does not block general availability if a small pilot group is used first. |
| 5.6 | Confirm RMS-encrypted label access is not inadvertently blocked | Validate during pilot. A label misconfiguration will surface quickly when pilot users cannot open documents. |
| 6.3 | Identify Finance Copilot Champions | Accelerates adoption but is not a safety control. Identify in week 1 post-rollout. |
| 6.4 | Create feedback channel for unexpected content surfacing | Should be in place by day 1 but setting it up on rollout day is acceptable. |
| 6.5 | Service Desk briefing on common Copilot issues | Brief the desk within the first week. A brief delay here creates some extra ticket volume, not a data risk. |
| 6.6 | 4-week post-rollout review scheduled | Schedule at rollout; the review itself is 4 weeks away. |

---

## Why the Permissions & Oversharing Audit Is MUST Tier — Detailed Justification

### The core principle: Copilot does not grant access — it *reveals* access that already exists

Microsoft 365 Copilot uses Microsoft Graph to retrieve content on behalf of the signed-in user. It will only return content the user already has permission to read. The common misconception is that this makes permissions a lower-priority concern ("Copilot can only show them what they could already find themselves"). This reasoning is dangerously flawed for three reasons specific to this Finance department.

---

### Reason 1: Discoverability vs. Surfaceability

Before Copilot, a Finance analyst could theoretically navigate to a SharePoint site they inherited access to from a 2019 migration and find a board pack buried in a folder structure. In practice, they would never do this — they do not know it is there, the folder path is not intuitive, and there is no reason to look.

With Copilot, the same analyst types: *"Summarise the latest board pack"* — and Copilot finds it, reads it, and delivers a clean summary in seconds.

**The permission existed before Copilot. The effective exposure did not.** Copilot converts theoretical access into trivial, instant, searchable access. This is the fundamental reason permissions must be audited before Copilot is enabled — not after.

---

### Reason 2: The 2019 Migration Debt Is Unusually High-Risk

A standard SharePoint permissions audit would be important for any Copilot rollout. For this Finance department, the risk is compounded:

- Permissions were inherited from a legacy environment seven years ago and have never been formally reviewed.
- In seven years, the Finance team will have had significant staff turnover, restructuring, and role changes. People who left in 2020 may still have access rights sitting in legacy groups from the migration.
- M&A documents created in 2021–2025 will have been stored under site structures that inherited those 2019 permissions, meaning sensitive deal data may be readable by anyone in a legacy "Finance-All" group that includes current and former staff.
- Payroll data is subject to UK GDPR and the Data Protection Act 2018. Unlawful access — even accidental, even AI-mediated — is a reportable incident to the ICO.

Licensing is technically simpler to verify. But a misconfigured licence is fixed in minutes with no data impact. A Copilot-mediated payroll disclosure to an ineligible user triggers an ICO notification obligation within 72 hours.

---

### Reason 3: Sensitivity Labels Cannot Compensate for Missing Permission Remediation

Labels with Rights Management encryption are a meaningful backstop — but only for labelled files. The Content Explorer scan required in checklist item 1.4.2 is expected to identify a significant volume of unlabelled financial content in a department whose permissions have not been audited since 2019. Until that content is labelled, encryption provides no protection.

The correct sequence is:
1. Fix permissions (Section 1.1 / 1.2) → reduce who can access what
2. Label and encrypt sensitive content (Section 1.4 / Section 5) → protect what remains accessible
3. Assign Copilot licences → enable the feature on a clean foundation

Reversing this sequence — assigning licences, then auditing permissions — means accepting that Copilot operates on a broken permissions model for the entire audit period. Given the data classes involved (payroll, M&A, board packs), that is not a risk DWP engineering can accept on Finance's behalf.

---

### Why Licensing and Client Version — Though Simpler — Are Also MUST Tier

For completeness: licensing and client version prerequisites are in MUST tier not because they are high data-risk, but because they are hard functional blockers. A user without the Copilot licence or on an unsupported build will see no Copilot features at all. This produces a failed rollout experience, erodes user trust, and generates support demand. They are simple to verify — which is precisely why there is no justification for skipping them.

The distinction from permissions is this: a licensing failure is immediately visible (Copilot icon absent) and has zero data risk. A permissions failure may be invisible (Copilot appears to work correctly) while silently surfacing restricted content. **Invisible failures in a high-sensitivity environment are categorically more dangerous than visible ones.**

---

## Summary Risk Matrix

| Checklist Area | Tier | Data Risk if Skipped | Recoverability |
|----------------|------|----------------------|----------------|
| Permissions & Oversharing Audit | 🔴 MUST | Critical — potential data breach | Low — disclosure cannot be undone |
| Sensitivity Labels on sensitive content | 🔴 MUST | High — unlabelled content unprotected | Low — exposure window before remediation |
| Licensing prerequisites | 🔴 MUST | None — functional failure only | High — fixable in minutes |
| Client version / Teams client | 🔴 MUST | None — functional failure only | High — fixable same day |
| MFA enforcement | 🔴 MUST | Critical — account compromise risk | Medium — MFA can be enforced rapidly |
| No shared accounts with Copilot licences | 🔴 MUST | Critical — immediate data breach vector | Medium — licence can be revoked |
| OneDrive oversharing controls | 🟡 SHOULD | Medium — personal drives less targeted | Medium — can be swept post-rollout |
| Auto-labelling policies | 🟡 SHOULD | Medium — unlabelled backlog persists | Medium — policies apply retrospectively |
| User comms & training | 🟡 SHOULD | Low-Medium — user error risk | Medium — training can follow rollout |
| Adoption tooling (champions, feedback channel) | 🟢 CAN | Low — adoption impact only | High — no data risk |
| Audit log retention | 🟢 CAN | None preventive — investigative only | High — configure anytime |

---

*For questions on this tier ranking, contact the DWP M365 Endpoint Engineering team. This document should be reviewed alongside the readiness checklist and updated if the permissions audit reveals materially different conditions from those assumed here.*
