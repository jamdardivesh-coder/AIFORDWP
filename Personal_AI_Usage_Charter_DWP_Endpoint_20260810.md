# Personal AI Usage Charter - DWP Endpoint Engineering (Public AI Assistants)

## Purpose
Use public AI assistants to improve speed and quality of desktop/endpoint support while protecting users, services, and DWP data.

## 1) Appropriate DWP Tasks for Public LLM Help
Use public AI for low-risk, generic, and non-sensitive work such as:

- Rewriting and improving wording for incident updates, closure notes, KB drafts, and handover notes using anonymized details.
- Producing troubleshooting checklists for common endpoint symptoms (slow boot, Outlook launch delay, profile corruption signs, print queue issues, mapped drive errors).
- Explaining Windows logs, event IDs, and command output patterns when all identifiers are removed.
- Drafting PowerShell script skeletons for routine endpoint tasks (inventory, log collection, service checks, cleanup routines).
- Converting rough notes into structured formats (RCA headings, triage summaries, runbook steps, test plans).
- Generating test cases, rollback checklists, and validation criteria for planned desktop changes.
- Summarizing publicly documented Microsoft behavior (Windows, Intune, M365 client behavior) where no internal data is included.

Rule of thumb:
- If the prompt can be posted on a public forum without exposing DWP people, systems, or security posture, it is generally suitable.

## 2) Tasks Not Appropriate for Public LLM Help
Do not use public AI for work that includes sensitive or privileged operational context, including:

- Any live incident details containing user names, emails, phone numbers, employee IDs, device names, IPs, hostnames, tenant IDs, or ticket references.
- Credentials of any kind (passwords, passphrases, MFA codes, API keys, tokens, private cert material, recovery codes).
- Internal network and security details (firewall rules, conditional access specifics, SOC detections, vulnerability findings, privileged group membership).
- Production scripts or commands copied with real environment values when those values reveal infrastructure or identities.
- Raw log files, memory dumps, registry exports, or screenshots containing identifiable data.
- Any decision that changes production systems without human review and controlled execution.

Rule of thumb:
- If disclosure would trigger a security, privacy, or compliance concern, keep it out of public AI.

## 3) Data-Handling Rule for End-User PII and Credentials
Non-negotiable rule:

- Never paste end-user PII or credentials into a public AI assistant.

Apply this before every prompt:

1. Remove direct identifiers: names, usernames, emails, phone numbers, addresses, employee numbers.
2. Remove technical identifiers: hostnames, serials, IPs, ticket IDs, tenant-specific values, share paths tied to real org structure.
3. Replace with placeholders: <USER_A>, <DEVICE_01>, <DOMAIN_X>, <APP_Y>, <TIMESTAMP>.
4. Generalize quantities where possible (for example, "several users" instead of exact named list).
5. If unsure whether data is sensitive, treat it as sensitive and do not submit.

Credential handling:
- If a troubleshooting flow requires entering a secret, do it directly in approved tools and terminals only, never in AI chat.

## 4) Personal "Generate Then Verify" Rule (Scripts and System Changes)
AI output is a draft, not an instruction to run as-is.

Generate:
- Ask AI to produce scripts/commands with explicit assumptions, prerequisites, and rollback notes.
- Prefer least-privilege defaults and read-only checks first.

Verify before execution:

1. Read every line and confirm you understand purpose and side effects.
2. Check for destructive operations (delete, overwrite, service stop, policy change, registry edits).
3. Validate syntax and logic in a safe environment (lab/test endpoint) first.
4. Add guardrails: -WhatIf, confirmation prompts, logging, error handling, and backups where applicable.
5. Peer-check for medium/high-risk changes or anything touching multiple users/devices.
6. Run on one pilot endpoint/user first, then expand in controlled stages.
7. Record evidence: command used, output, timestamp, outcome, and rollback status in ticket/change notes.

Execution standard:
- No direct production rollout of AI-generated scripts without human validation and staged testing.

## Personal Commitment
I will use public AI to accelerate analysis and documentation, not to bypass DWP security, privacy, or change control. Speed is useful only when safety and correctness are preserved.
