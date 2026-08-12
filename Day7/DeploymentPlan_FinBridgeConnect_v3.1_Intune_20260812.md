# Phased Intune Deployment Plan: FinBridge Connect v3.1

Scope: Deploy FinBridge Connect v3.1 to 10,000 Windows 11 endpoints in 3 weeks, with Finance (500 users) receiving the app by end of Week 1, while preserving rollback to v3.0.

## 1. RING STRUCTURE

Ring design uses targeted assignments in Intune with explicit exclusion logic for at-risk devices (4 GB RAM) until broad validation is complete.

Ring 1 (Pilot)
- Size: 500 devices (5% of fleet)
- Duration: 3 calendar days minimum active deployment + monitoring
- Who to include:
  - 200 IT and service desk endpoints (high observability and fast feedback)
  - 150 power users from non-Finance business units
  - 150 representative users from mixed hardware/network profiles
  - Exclude 4 GB RAM devices from this ring except a controlled sample of 25 devices for compatibility signal
- Purpose:
  - Validate deployment mechanics (install, detection, supersedence behavior)
  - Validate core app stability and authentication/connectivity workflows
  - Detect high-frequency defects before wider exposure
- Intune assignment group type:
  - Azure AD dynamic device group for pilot criteria
  - One static include subgroup for named testers
  - One static exclude group for known unstable endpoints

Ring 2 (Early)
- Size: 2,500 devices (25% of fleet), including Finance 500 users
- Duration: 5 calendar days minimum active deployment + monitoring (target completion by end of Week 1 for Finance)
- Who to include:
  - Finance users (500, highest priority)
  - Additional 2,000 users across Operations, HR, and regional offices
  - Include 4 GB RAM pilot expansion: 150 devices (out of ~500 at-risk total)
- Purpose:
  - Validate business-critical usage at scale (especially Finance workflows)
  - Confirm reliability across wider hardware/network diversity
  - Confirm service desk load remains manageable
- Intune assignment group type:
  - Azure AD dynamic user group for Finance users
  - Azure AD dynamic device group for general early adopters
  - Assignment filters to stage at-risk hardware separately

Ring 3 (Broad)
- Size: Remaining 7,000 devices (70% of fleet)
- Duration: Week 2 to Week 3 completion window (up to 13 calendar days including post-release monitoring)
- Who to include:
  - All remaining production users/devices not in Rings 1-2
  - 4 GB RAM devices only after explicit ring isolation checks pass
- Purpose:
  - Complete enterprise rollout inside deadline
  - Maintain controlled pace with daily telemetry checkpoints
  - Preserve rollback readiness until final stabilization checkpoint
- Intune assignment group type:
  - Azure AD dynamic all-Win11 production device group
  - Exclusion groups for active incidents and deferred devices

## 2. ADVANCE CRITERIA

Evaluation source: Intune app install status, device install status, detection status, and incident tickets tagged "FinBridge v3.1" in the ITSM queue.

Ring 1 -> Ring 2 advance criteria
- Install success rate: >= 97.0% over a minimum 72-hour monitoring period after Ring 1 assignment starts
- Error rate threshold: <= 2.0% combined Intune install error states over same 72-hour period
- User-reported issues: <= 8 tickets per 100 users (<= 8%) within first 72 hours, with no Sev1 tickets open > 4 hours
- Monitoring period: minimum 72 hours and at least one full business day after 90% of Ring 1 devices report install state
- Time-bound decision point: Go/No-Go review at Day 4, 10:00 local time

Ring 2 -> Ring 3 advance criteria
- Install success rate: >= 98.0% across Ring 2 devices measured over minimum 96-hour window
- Error rate threshold: <= 1.5% Intune install errors sustained for 48 consecutive hours inside that 96-hour window
- User-reported issues: <= 5 tickets per 100 users (<= 5%), and <= 1 Sev2 recurring defect category
- Monitoring period: minimum 96 hours and at least 2 Finance business cycles (close/open tasks)
- Time-bound decision point: Go/No-Go review at end of Week 1 Day 5, 16:00 local time

Hold condition (pause without full rollback)
- Trigger: If install success remains between 94.0% and 96.9% for 24 hours, or ticket rate rises above threshold but no Sev1 business outage exists, pause ring expansion and remediate.
- Example: Ring 2 reaches 95.4% success with repeated detection-rule mismatches on a subset of devices. Action: keep current ring assigned, stop new ring assignments, correct detection rule logic/package metadata, force sync, re-evaluate after 24 hours.

## 3. ROLLBACK TRIGGERS

All rollback triggers are explicit and measurable. Rollback authority is pre-assigned to avoid delays.

Trigger A: Install failure rate automatic halt
- Condition: Install failure rate >= 7.0% in any rolling 12-hour window after ring assignment
- Decision maker: Endpoint Engineering Lead + Major Incident Manager (joint approval)
- Decision window: 60 minutes from threshold breach alert
- Intune action:
  - Remove required assignment of v3.1 from active rollout groups (Ring 2 or Ring 3 as applicable)
  - Reassign same groups to v3.0 as Required
  - Keep v3.1 available only to IT validation group for troubleshooting

Trigger B: Application crash rate rollback consideration
- Condition: Crash rate >= 3 crashes per 100 active devices in 24 hours, sustained for two consecutive 24-hour periods
- Decision maker: Service Owner (FinBridge) + Endpoint Engineering Lead
- Decision window: 4 hours after second-period confirmation
- Intune action:
  - Freeze advancement immediately
  - If approved to rollback: switch required assignment from v3.1 to v3.0 for impacted rings
  - Add exclusion of impacted groups from all v3.1 required assignments

Trigger C: Business-critical failure immediate rollback
- Condition: Finance users cannot complete payment batch submission (core business transaction) for > 30 minutes due to v3.1 defect
- Decision maker: Incident Commander (single authority for immediate action)
- Decision window: Immediate (<= 15 minutes)
- Intune action:
  - Emergency unassign v3.1 required deployment from Finance group
  - Assign v3.0 as Required to Finance group immediately
  - Keep v3.1 blocked for Finance via exclusion group until post-incident CAB approval

Trigger D: 4 GB RAM at-risk hardware isolation
- Condition: Failure rate on 4 GB RAM cohort >= 12.0% in 24 hours, or performance-related tickets >= 10 per 100 users in that cohort
- Decision maker: Endpoint Engineering Lead
- Decision window: 2 hours from alert
- Intune action:
  - Remove 4 GB RAM assignment filter from current ring rollout target
  - Place 4 GB RAM devices into isolated hold group
  - Continue rollout only for >= 8 GB devices while compatibility remediation proceeds

## 4. FINANCE DEADLINE RESOLUTION

Option A - Compress pilot to bring Finance into Ring 2 by end of Week 1
- Minimum safe pilot duration: 72 hours (not less), with at least 90% of Ring 1 devices reaching final install state before decision
- Risk introduced: Reduced time to observe low-frequency defects (for example, day-2 authentication token refresh failures)
- Compensating control: Increase pilot observability with twice-daily telemetry checkpoints, mandatory Sev1 triage bridge, and pre-staged v3.0 reassignment scriptbook

Option B - Finance as separate priority Ring 0 before main pilot
- Ring 0 structure:
  - Size: 120 Finance users across key functions (AP, AR, Treasury, Controller)
  - Duration: 48 hours
  - Assignment: Dedicated Azure AD dynamic user group + explicit exclusion from broader rings
- Ring 0 advance conditions:
  - >= 98% install success in Ring 0
  - <= 1.5% Intune install errors
  - 0 Sev1 incidents and <= 3 tickets per 100 users over 48 hours
- Ring 0 rollback plan:
  - If any Sev1 Finance workflow outage occurs or install failure exceeds 5% in 24 hours, remove v3.1 required assignment from Ring 0 and reassign v3.0 required within 30 minutes

Recommendation (single clear choice)
- Recommend Option A.
- Justification:
  - It preserves a representative pilot across cross-functional users before exposing Finance, reducing business risk versus a Finance-first Ring 0.
  - A 72-hour pilot still allows Finance to enter Ring 2 and complete by end of Week 1.
  - Operationally simpler: one main ring framework, fewer exception paths, and cleaner reporting/compliance views in Intune.
  - Risk from compressed timeline is acceptable when paired with the compensating controls above and an explicitly rehearsed rollback-to-v3.0 path.
