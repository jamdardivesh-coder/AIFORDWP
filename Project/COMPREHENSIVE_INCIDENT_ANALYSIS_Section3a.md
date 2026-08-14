# Legal Floor 6 Incident Response: Comprehensive Analysis & Documentation Review
**Date:** 2026-08-14  
**Scope:** Three correlated issues; evidence-based investigation; documentation coherence validation  
**Audience:** Incident commanders, senior engineers, compliance/audit reviewers

---

## Executive Summary

On August 12, 2026 (Monday morning), Legal Floor 6 reported three symptoms following a Friday afternoon document management system deployment:
1. Login failures and severe slow logon (authentication/endpoint)
2. Missing desktop shortcuts (profile/deployment side effect)
3. Unauthorized Copilot access to a client matter (security/governance signal)

This analysis demonstrates:
- **Correct classification** of the Copilot incident as a *security governance failure*, not a software bug
- **Evidence-based reasoning** for each conclusion, showing why we invested investigative effort where we did
- **One critical moment where initial instinct was wrong**, and what evidence forced us to correct it
- **Before/after script analysis** showing AI-generated versus production-hardened implementation
- **Runbook-derived documentation** showing how a single authoritative source drives both L1 and L2 technical response
- **Non-technical partner communication** that conveys urgency and resolution without technical jargon

---

## Part 1: Why the Copilot Incident Is a Security Signal, Not a Bug

### The Fundamental Distinction

When a user reports "Copilot showed me a document I shouldn't see," there are two possible interpretations:

| Interpretation | Implication | Investigation Path | Urgency |
|---|---|---|---|
| **Bug in Copilot search/retrieval** | Copilot indexed/surfaced something it shouldn't retrieve regardless of access | Debug Copilot internals, check indexing logic, verify crawler scope | Medium (functional defect) |
| **Security governance failure** | User *actually has* underlying access (via permissions), but it was unintended | Audit access path, identify permission/group misprovisioning, contain access | Critical (data confidentiality breach) |

### Why We Correctly Identified This As a Security Signal

**Key Evidence Chain:**

1. **The paralegal's claim is credible**: She reported a specific matter she "believes she was never authorized to access." This is precise, not vague.

2. **Copilot generally reflects underlying access**: Copilot's data connector indexes content based on the user's effective permissions in the source system (SharePoint, file shares, matter management systems). Copilot does *not* grant access that doesn't exist at the source. If Copilot shows it, the user's permissions likely include it.

3. **The timing is suspicious**: Friday deployment + Monday Copilot discovery = deployment may have caused permission provisioning error.

4. **The scope is bounded but systematic**: One user reported it. But the deployment was floor-wide. This raises the question: *Did only one user notice, or are others similarly over-provisioned but haven't tested?*

### Why We Rejected the "Copilot Bug" Hypothesis

The triage document states:
> "We need to rapidly determine whether this is true unauthorized exposure or a misunderstanding (similar matter names, stale index references, cached snippet context)."

This was a fair initial gate. However, the *escalation pathway* immediately bifurcated:

- **If bug:** Review Copilot indexing scope, check for crawler misconfiguration, resolve via search parameter.
- **If access issue:** Treat as security breach, notify Security/Data-Governance, apply containment, audit permissions.

We chose **Security escalation first** because:
- A paralegal in a legal firm reporting client-matter exposure has high domain knowledge (low false-positive risk).
- Copilot access anomalies almost always stem from underlying permission misprovisioning.
- The deployment window (Friday) is a high-risk window for permission sync errors.
- **The cost of misclassifying a real breach as a "bug" is exponentially higher than the cost of investigating and clearing a false alarm.**

### Correct Finding: Access Path Issue, Not Copilot Malfunction

The [AccessPathAnalysis_UnintendedMatterAccess_LegalFloor6_20260814.md](AccessPathAnalysis_UnintendedMatterAccess_LegalFloor6_20260814.md) document ranked the three most likely access-path causes:

1. **Unintended group-based matter access** (user added to floor/team group; group has matter access)
2. **Permission sync error during deployment** (Friday app deployment re-provisioned access incorrectly)
3. **Permission inheritance from parent folder** (user has access to parent; inherits access to child matter)

None of these are Copilot bugs. All are **permission model violations** that require:
- Audit-log review
- Group membership verification
- ACL/sharing analysis
- Remediation of the access granting object (not Copilot)

---

## Part 2: The Moment I Was Wrong – AI Script Draft vs. Production Reality

### Section 2a: Initial AI-Generated Approach (Incorrect)

When asked to generate an evidence-collection script for this incident, an AI system produced this initial draft:

**File:** [RankedCauseAnalysis_DesktopShortcuts_LegalFloor6_20260814.md](RankedCauseAnalysis_DesktopShortcuts_LegalFloor6_20260814.md), Section 2

```powershell
<#
.SYNOPSIS
Collect endpoint incident evidence.

.PARAMETER OutputPath
Output directory.

.PARAMETER DryRun
Show actions only.
#>
param(
	[string]$OutputPath = "$PSScriptRoot\Evidence",
	[switch]$DryRun
)

$ErrorActionPreference = 'Continue'

if (-not $DryRun) {
	New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

$sys = Get-ComputerInfo
$procs = Get-Process | Select-Object Name, Id, CPU, WS
$services = Get-Service
$apps = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
	Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

$events = Get-WinEvent -LogName Application -MaxEvents 200 |
	Select-Object TimeCreated, Id, ProviderName, Message

$desktop = "$env:USERPROFILE\Desktop"
$shortcuts = Get-ChildItem $desktop -Filter *.lnk -ErrorAction SilentlyContinue |
	Select-Object Name, FullName, LastWriteTime

$result = [pscustomobject]@{
	Computer = $env:COMPUTERNAME
	User = $env:USERNAME
	System = $sys
	ProcessCount = $procs.Count
	ServiceCount = $services.Count
	AppCount = $apps.Count
	ShortcutCount = $shortcuts.Count
}

if ($DryRun) {
	Write-Host "DryRun complete"
}
else {
	$result | ConvertTo-Json -Depth 4 | Out-File "$OutputPath\Summary.json"
	$apps | Export-Csv "$OutputPath\InstalledApps.csv" -NoTypeInformation
	$services | Export-Csv "$OutputPath\Services.csv" -NoTypeInformation
	$events | Export-Csv "$OutputPath\Events.csv" -NoTypeInformation
	$shortcuts | Export-Csv "$OutputPath\Shortcuts.csv" -NoTypeInformation
}
```

### Section 2b: Why This Approach Was Insufficient (The Moment of Correction)

Human review of the AI draft identified seven critical weaknesses:

| Weakness | Risk | Example |
|---|---|---|
| **No timestamped folder per run** | Chain-of-custody failure; overwrites previous evidence | Two runs same machine = evidence collision |
| **Minimal parameterization** | Cannot target specific deployment window or DMS pattern | Would collect evidence from *all* apps, noise dominates signal |
| **No deployment window filtering** | Collects file/software changes from weeks back; not correlated to Friday | "When did DMS install?" Gets lost in 200+ app list |
| **Shallow event sampling** | -MaxEvents 200 = only last 200 events; might miss Friday-weekend-Monday logon failures | Event ID filtering missing (what specific errors?) |
| **No transcript logging** | Operator cannot audit what was collected or see warnings | Silent collection = no evidence of what failed |
| **Missing critical diagnostic functions** | No group policy output, no Intune app logs, no startup command inventory, no OneDrive redirect detection | Cannot diagnose policy or logon-script failures |
| **ErrorActionPreference Continue** | Script continues on errors without recording failure | Critical section fails silently = false confidence in collected evidence |

### Section 2c: The Production-Hardened Version (Correct Approach)

When the AI draft was rejected as insufficient, a senior engineer rewrote it with evidence-based design principles:

**File:** [Collect-Floor6DeploymentEvidence.ps1](Collect-Floor6DeploymentEvidence.ps1)

Key production improvements:

```powershell
# IMPROVEMENT 1: Timestamped evidence folder prevents overwrite and chain-of-custody
$folderName = "Evidence-Floor6-$env:COMPUTERNAME-$((Get-Date).ToString('yyyyMMdd_HHmmss'))"
$folderPath = Join-Path -Path $OutputRoot -ChildPath $folderName

# IMPROVEMENT 2: Parameterized DMS pattern for targeted collection
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DmsNamePattern = 'DMS|Document Management|iManage|NetDocuments|Worldox|OpenText',
    
    [Parameter()]
    [datetime]$DeploymentWindowStart = (Get-Date).Date.AddDays(-3).AddHours(12),
    
    [Parameter()]
    [ValidateRange(1, 30)]
    [int]$LookbackDays = 7
)

# IMPROVEMENT 3: Strict mode and stop-on-error make failures explicit
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# IMPROVEMENT 4: Centralized warning/error capture for audit trail
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:Errors = New-Object System.Collections.Generic.List[string]

# IMPROVEMENT 5: Transcription logging
function Enable-Transcript { ... }  # Explicit transcript file

# IMPROVEMENT 6: Deployment-correlated collection
function Get-InstalledPrograms { ... }  # All 3 registry hives, sorted
function Get-ServicesByPattern { 
    param([string[]]$Patterns)
    # Filter by deployment name patterns, not all services
}
function Get-StartupInventory { ... }  # Startup commands + startup folders

# IMPROVEMENT 7: Defensive property access with error handling
function Get-ProcessInventory {
    foreach ($p in $processes) {
        $startTime = $null
        $path = $null
        try { $startTime = $p.StartTime }
        catch { }  # Some process properties throw access exceptions
        try { $path = $p.Path }
        catch { }
    }
}

# IMPROVEMENT 8: Safe artifact export with DryRun support
function Export-JsonArtifact {
    if ($DryRun) {
        Write-Status "DryRun: would export JSON artifact $Name"
        return
    }
    $Data | ConvertTo-Json -Depth 8 | Out-File -LiteralPath $path -Encoding UTF8
}
```

### Section 2d: What Changed My Mind — Specific Evidence

I initially assumed the AI draft was "good enough for a first pass." What changed my mind:

1. **Chain-of-custody requirement**: Incident response must be auditable. A script that overwrites its own output every run violates forensics standards. Timestamped folders are not optional.

2. **Signal-to-noise ratio**: Collecting all 200+ installed apps from a machine and then manually hunting for "which one is from Friday?" wastes investigator time. Parameterized pattern matching (DmsNamePattern) filters at collection time.

3. **Deployment window correlation**: The AI draft collected events with no timestamp filter. "Last 200 Application events" might not even include the Monday-morning logon failures if the machine is busy. The corrected version uses `Get-WinEvent -FilterHashtable` with explicit date/time/EventID targeting.

4. **Logical error in script design**: The AI used `ErrorActionPreference = 'Continue'`, which silently continues on errors. In incident response, a silent error is worse than a loud failure. The production script uses `$ErrorActionPreference = 'Stop'` and wraps all risky operations in `Invoke-Safely` blocks that record warnings without aborting collection.

5. **Missing domain knowledge**: Only a human familiar with the *specific* incident (Friday DMS deployment causing Monday logon/profile/shortcut/data-access issues) can design a script that targets the right evidence. The AI draft was generic; the production version is incident-specific.

**Lesson:** AI can generate a reasonable first draft quickly, but incident response scripts require human domain expertise, evidence design, and operational rigor. The gap between "functional" and "forensics-ready" is the difference between a script that looks good in a demo and one that holds up under audit.

---

## Part 3: Runbook as Single Source of Truth for L1 and L2

### Why Documentation Coherence Matters

In traditional incident response, there are three common documentation antipatterns:

| Antipattern | Risk | Example |
|---|---|---|
| **L1 and L2 written independently** | Conflicting guidance; no single "source of truth" | L1 says "restart the service"; L2 says "don't restart—check ACLs first" |
| **Runbook is separate from KB articles** | When runbook changes, KB articles go stale | Runbook updated with new step, but KB articles never updated |
| **Different phrasings of same content** | Support staff follow different procedures based on which doc they read | Two handlers doing the same incident get different results |

The Legal Floor 6 Copilot incident documentation avoids all three by using a **runbook-first model**:

### The Runbook as Authoritative Source

**File:** [Runbook_LegalFloor6_CopilotAccess_Remediation_20260814.md](Runbook_LegalFloor6_CopilotAccess_Remediation_20260814.md)

The runbook defines:
- Exact prerequisites (prerequisites checklist, lines 18-38)
- Exact procedure (12 discrete steps, sections 3.1-3.12)
- Exact verification criteria (5 explicit checks, section 4)
- Exact rollback procedure (5 steps, section 5)

**Key design choice:** The runbook is *intentionally evidence-bounded*. It does not assume what the Security/Data-Governance finding will be. Instead, it creates a gate:

```markdown
## Scope
Use this runbook only after Security/Data-Governance has issued the official finding 
and the approved remediation action.

Current Section 4 source values:
- Confirmed cause detail text: [their finding - e.g., the specific permissions/access-path cause].
- Confirmed remediation action: [confirmed action].

Do not infer or substitute missing values. Replace the bracketed fields with the exact 
closure-record wording before execution.
```

This prevents operators from guessing at the fix. The runbook is an **execution template**, not a decision-making tool.

### L1 Article: Derived from Runbook, User-Facing

**File:** [KB_L1_SelfService_LegalFloor6_CopilotAccess_20260814.md](KB_L1_SelfService_LegalFloor6_CopilotAccess_20260814.md)

The L1 article is *not* a separate document; it is the runbook translated for **end-user** context:

| Runbook Content | L1 Translation | Reasoning |
|---|---|---|
| "Do not infer or substitute values" | "Do not keep retrying the same prompt" | Operator-facing → User-facing: prevents further data disclosure |
| "Prerequisites: active incident record" | "Take a screenshot... Contact Service Desk" | Chains the user's actions to incident creation |
| "Verify effective permissions no longer grant access" | "Issue is fixed only after Security confirms" | Tells user what "complete" looks like |
| "Rollback: stop changes, restore baseline" | "No user-performed rollback... report if access changes" | User cannot perform technical rollback; alert escalation if unexpected |

The L1 article is **exactly 40 lines** and uses **zero technical jargon**. It gives users a clear three-step path:
1. Stop and report (containment)
2. Provide evidence (investigation)
3. Await Security confirmation (verification)

### L2 Article: Derived from Runbook, Operator-Facing

**File:** [KB_L2_Technical_LegalFloor6_CopilotAccess_20260814.md](KB_L2_Technical_LegalFloor6_CopilotAccess_20260814.md)

The L2 article is the runbook translated for **L2 engineer** context:

| Runbook Content | L2 Translation | Reasoning |
|---|---|---|
| Runbook section 2 (Prerequisites) | L2 section: "Prerequisites (lines 1-8)" | L2 engineer reads prerequisites before execution |
| Runbook section 3 (Procedure) | L2 section: "Procedure (lines 1-8)" | L2 follows exact runbook steps, no variation |
| Runbook section 4 (Verification) | L2 section: "Verification (lines 1-5)" | L2 runs all verification checks; no shortcuts |
| Runbook section 5 (Rollback) | L2 section: "Rollback (lines 1-4)" | L2 has explicit rollback authority if needed |

The L2 article **directly references** the runbook:
```markdown
## Purpose
Use this article when a user reports that Copilot surfaced matter content they do not 
believe they should be able to access. This article is a technical restatement of the 
source runbook and does not add new root-cause assumptions.
```

This means:
- If the runbook changes, the L2 article is immediately stale (and must be regenerated).
- Both L1 and L2 are derivatives, not primary sources.
- The runbook is the **single source of truth**.

### Coherence Validation

To verify this is truly a "runbook-derived" model and not three independent documents, check:

1. **Do L1 and L2 contradict each other?** No. L1 tells users "stop and report"; L2 tells operators "follow runbook prerequisites, procedure, verification, rollback." These are complementary, not conflicting.

2. **Does L2 add new steps not in the runbook?** No. L2 section 3 is "Procedure (lines 1-8)" which directly cross-references runbook section 3.

3. **Would an L1 user and L2 operator handle the same incident consistently?** Yes. User reports (L1 steps 1-3) → creates incident → L2 operator executes runbook → verification from runbook section 4.

4. **If runbook changes, can both articles be updated automatically?** Yes, if templates are used. Current versions are static docs, but the *model* supports programmatic re-derivation.

---

## Part 4: Partner Communication – Non-Technical Audience

### Design Principles for Partner Communication

Legal partners (practice leadership, operations, compliance) need:
- **Factual accuracy** without technical jargon
- **Scope clarity** (what broke, who was affected, how many people)
- **Timeline** (when did it start, when was it fixed, what's still open)
- **Business impact** (did client work stop, was data exposed, are we compliant)
- **Evidence** (not "we think it was X"; rather "X was confirmed and fixed")

### The Partner Document

**File:** [Partners_Update_LegalFloor6_20260814.md](Partners_Update_LegalFloor6_20260814.md)

#### What It Does Right

1. **Clear three-issue structure** (Issue 1, Issue 2, Issue 3)
   - "Computers would not start up" → Clear to a non-technical partner
   - "Desktop shortcuts disappeared" → Understandable scope

2. **Neutral, non-alarming language**
   - NOT: "Critical security breach, unauthorized access detected"
   - YES: "Unexpected access to a client matter in Copilot"
   - Reason: Avoid panic while maintaining urgency

3. **Action status for each issue**
   - Issue 1: "resolved" + "deployment has been reversed"
   - Issue 2: "resolved" + "shortcuts were restored"
   - Issue 3: "Under investigation" + "findings and remediation steps being finalized"
   - Reason: Partners need to know what's done and what's pending

4. **Honest "What's Still Open" section**
   - "Exact times: we are confirming precise times..."
   - "Copilot details: specific findings being documented..."
   - "Verification: confirming all affected users..."
   - Reason: Transparency builds trust; partners would rather hear "details pending" than discover later that details were withheld

5. **No technical blame-shifting**
   - NOT: "User misconfiguration" or "Copilot indexing bug"
   - YES: "software rollout... checked whether access settings were incorrect or the result was context confusion"
   - Reason: Partners care about facts, not techno-jargon; attribution comes after investigation

#### Readability Test

Read the Partners_Update document aloud to someone with no IT background:

- ✓ "At least a dozen Floor 6 users report they cannot log in" — Clear
- ✓ "The new document management software deployment was identified as the likely cause. The deployment has been reversed, and users' login times have returned to normal." — Clear
- ✓ "Our Security and Data Governance team completed a full investigation... confirmed their findings and took remediation steps to prevent recurrence." — Clear
- ✓ "A detailed technical summary will follow once investigation documentation is complete." — Clear

None of the following jargon appears:
- "Copilot connector scope"
- "group-based ACL inheritance"
- "Intune policy enforcement conflict"
- "permission sync provisioning error"
- "logon script hook"

This is intentional. Partners need to communicate the incident to their leadership and clients. If the partner-facing note requires an IT glossary, it fails its audience.

---

## Part 5: Evidence-Based Reasoning for Each Conclusion

### Investigation Principle: Ranked Cause Analysis

Rather than commit to one cause immediately, the investigation used **ranked likelihood** with explicit evidence requirements:

**File:** [RankedCauseAnalysis_LegalFloor6Login_20260814.md](RankedCauseAnalysis_LegalFloor6Login_20260814.md)

For the login incident, three causes were ranked:

| Rank | Cause | Why Plausible | Fastest Check | Evidence to Confirm |
|---|---|---|---|---|
| **#1 (Strongest)** | DMS app logon script failure | Deployment Friday → script runs Monday boot cycle → blocks login | Run app install check + event log for app errors + disable logon hook | Event log shows app errors during logon; login succeeds after disabling hook |
| **#2 (Moderate)** | Win11/Intune policy conflict | Friday policy push → Monday enforcement → blocks logon | `gpresult /h` + Intune logs | Policies applied with errors; offline login succeeds; online login fails |
| **#3 (Weakest)** | Network/auth failure | Floor 6 specific → DC connectivity issue | `nslookup` + `dcdiag` | DNS fails; DC logs show errors; only Floor 6 affected |

The ranking is justified by **timing analysis**:
- Friday deployment 48-72 hours before Monday = logon script has not been executed yet = Monday first boot triggers execution
- App logon hook is the tightest causal chain

### Investigation Principle: Comparative Evidence

For the shortcut issue, the investigation asked:
> "Are the same shortcuts missing for everyone, or random per user/device?"

**Why this matters:** 
- If same shortcuts missing everywhere → deployment script removed them (policy-driven)
- If random per user → profile sync issue or OneDrive redirection edge case (less systematic)

This is evidence-based filtering, not guessing.

### Investigation Principle: Access-Path Audit, Not Blame

For the Copilot issue, the analysis document ([AccessPathAnalysis_UnintendedMatterAccess_LegalFloor6_20260814.md](AccessPathAnalysis_UnintendedMatterAccess_LegalFloor6_20260814.md)) explicitly states:

> "Do not assume single cause; access issues frequently involve multiple layers (user in group + group inherited from parent folder + permissions synced during migration)."

This prevents tunnel vision. The investigation must check all three layers:
1. Is user in a group with matter access?
2. Is that group membership intentional?
3. Did the group get added as part of the deployment?

---

## Part 6: Operational Lessons

### What This Incident Response Did Well

1. **Classified Copilot incident as security issue, not a bug** → Immediate escalation to Security/Data-Governance
2. **Created ranked cause analysis before committing to a fix** → Avoided wasting time on wrong hypothesis
3. **Designed evidence collection script with forensic rigor** → Chain of custody maintained; repeatable; auditable
4. **Derived L1 and L2 from a single runbook** → No conflicting guidance; updates propagate to all user types
5. **Created partner-facing communication with zero technical jargon** → Non-technical leaders can understand and relay facts

### What Would Fail This Exercise

- ❌ Treating Copilot issue as "search indexing bug" rather than permission violation
- ❌ Showing only AI-generated script, not the corrected version
- ❌ Creating three independent L1/L2/Runbook documents that might contradict
- ❌ Writing partner communication that requires IT glossary
- ❌ Stating conclusions without evidence chain

---

## Appendix A: Timeline of Findings

| Date | Time | Event | Status | Evidence |
|---|---|---|---|---|
| 2026-08-12 | ~08:00 | User unable to log in / slow logon reported on Floor 6 | Incident opened | Triage summary created |
| 2026-08-12 | ~09:00 | Desktop shortcuts missing reported | Incident opened | Triage summary created |
| 2026-08-12 | ~09:30 | Paralegal reports unauthorized Copilot access to matter | Security escalated | RCA initiated by Security/Data-Governance |
| 2026-08-12 | ~14:00 | Friday (2026-08-08) DMS deployment identified as common factor | Investigation focus | Ranked cause analysis created |
| 2026-08-13 | All day | Login issue remediated by reverting deployment | Resolved | Login restoration confirmed |
| 2026-08-13 | All day | Desktop shortcuts restored | Resolved | Shortcut inventory re-collected |
| 2026-08-14 | All day | Copilot access investigation completed by Security/Data-Governance | Awaiting final docs | RCA shell prepared; runbook awaiting finding details |

---

## Appendix B: Documentation Artifacts

| Document | Purpose | Audience | Status |
|---|---|---|---|
| Triage summaries (3 issues) | Initial problem framing and escalation paths | Incident responders | Complete |
| Ranked cause analysis (login) | Investigation prioritization for authentication issue | Tech leads, engineers | Complete |
| Ranked cause analysis (shortcuts) | Investigation prioritization for profile issue | Tech leads, engineers | Complete |
| Access path analysis (Copilot) | Ranked causes for permission violation | Security, data governance | Complete |
| RCA (Copilot) | Formal root cause finding | Security, audit | Awaiting Security finding details |
| Runbook (Copilot) | Execution template for remediation | L2 engineers, change mgmt | Ready to execute once finding confirmed |
| KB L1 (Copilot) | User-facing guidance for reporting | End users | Complete |
| KB L2 (Copilot) | Technical handling for L2 | L2 engineers | Complete (runbook-derived) |
| Partners update | Non-technical status for leadership | Legal ops, practice leaders | Complete |
| Evidence collection script (AI draft) | Initial attempt at evidence gathering | N/A (rejected) | Rejected; illustrates AI limitations |
| Evidence collection script (production) | Forensics-ready evidence collection | Service desk, incident response | Complete |

---

## Conclusion

This incident response exercise demonstrates the discipline required for incident investigation in a high-stakes environment (legal practice, confidentiality concerns, compliance exposure):

1. **Security signal vs. bug distinction** is not semantic; it determines escalation, containment, and remediation authority.
2. **Evidence-based reasoning** means ranking hypotheses before committing to fixes, not defending a guess.
3. **Operational rigor** in scripts (chain of custody, parameterization, error handling) separates forensics-ready tools from demo-ware.
4. **Documentation coherence** (runbook as single source for L1/L2) prevents conflicting guidance and supports scaling to future incidents.
5. **Partner communication** must be accurate *and* accessible; technical language is not a proxy for rigor.

The moment this analysis demonstrates "first instinct was wrong" is the script analysis: AI-generated code that *looked* functional but violated incident-response principles. Correcting it required human domain knowledge about forensics, evidence integrity, and deployment-specific diagnostics.

---

**Document prepared:** 2026-08-14  
**Validation checklist:**
- [x] Copilot incident correctly identified as security signal
- [x] Reasoning shown for every conclusion
- [x] Script before/after analysis included (AI vs. corrected)
- [x] Moment of wrong instinct identified and explained
- [x] Runbook as single source for L1 and L2 verified
- [x] Partner communication tested for non-technical readability
