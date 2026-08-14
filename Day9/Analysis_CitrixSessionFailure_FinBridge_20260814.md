# Analysis: Citrix/AVD Session Failure - FinBridge
Date: 2026-08-14
Environment: dwpai-lab-rg / POOL-FIN-01 / avdsh-fin-01

## Scope Facts Used
- Session host `avdsh-fin-01` reached `Available` state with agent version `1.0.15008.300`.
- Users reported `No resources` and `Sign in failed` during client access.
- Evidence showed tenant-scoped URL mismatch risk in bookmarks and direct links.
- Host pool required Entra-auth RDP properties (`targetisaadjoined:i:1`, `enablerdsaadauth:i:1`, plus auth-supporting flags).
- Evidence documented permission dependency across App Group, Host Pool, Workspace, and VM scopes.
- No numeric error code was captured in the source evidence. `No resources` and `Sign in failed` are treated as symptom text, not code identifiers.

## Ranked Top 3 Likely Causes (Most Probable First)

### 1) Host Pool Entra Authentication RDP Properties Missing/Incomplete
Why it fits the evidence:
- The failure pattern (`Sign in failed` with available host) aligns with Entra-auth handshake issues.
- The documented fix explicitly added `targetisaadjoined:i:1;enablerdsaadauth:i:1;` and additional auth-related flags.
- The issue narrative confirms this change was part of the successful resolution path.

Fastest check to confirm or eliminate:
- Run:
```bash
az desktopvirtualization hostpool show -g dwpai-lab-rg -n POOL-FIN-01 --query "customRdpProperty" -o tsv
```
- Confirm the returned string includes all required values:
  - `targetisaadjoined:i:1`
  - `enablerdsaadauth:i:1`
  - `enablecredsspsupport:i:1`
  - `redirectwebauthn:i:1`

Specific remediation if confirmed:
- Update host pool custom RDP property with required Entra-auth flags.
- Restart user client session and re-test launch.

### 2) Tenant Context/URL Mismatch in Client Entry Point
Why it fits the evidence:
- `No resources` strongly correlates with authenticating into the wrong tenant/workspace context.
- The troubleshooting notes explicitly call out wrong tenant ID in bookmark/link as a root cause.

Fastest check to confirm or eliminate:
- Validate the exact URL used by the user and compare tenant ID segment with expected `fa8443c6-5a39-4df5-a018-9c876455adf9`.
- Ask user to sign in through a clean InPrivate/Incognito session using only the canonical workspace URL.

Specific remediation if confirmed:
- Replace saved bookmark with correct tenant-scoped URL.
- Clear stale workspace/account cache in client and re-subscribe.

### 3) RBAC Scope Gap (Assignment Missing at One Required Layer)
Why it fits the evidence:
- AVD authorization is evaluated across multiple scopes; partial assignment can produce resource visibility/launch failures.
- Notes explicitly mention remediation required assignments at app group, host pool, workspace, and VM scopes.

Fastest check to confirm or eliminate:
- List assignments at all four scopes and verify target user presence for:
  - `Desktop Virtualization User` (App Group, Host Pool, Workspace)
  - `Virtual Machine User Login` or `Virtual Machine Administrator Login` (VM)

Specific remediation if confirmed:
- Apply missing role assignment(s), wait for propagation, then force client refresh and retry.

## Finalized Single Hypothesis
### Final hypothesis selected:
Missing/incomplete Entra-auth custom RDP properties on host pool (`targetisaadjoined` / `enablerdsaadauth`) was the primary blocker for session launch.

Rationale for final selection:
- It directly explains `Sign in failed` despite healthy host registration.
- It is explicitly tied to the successful remediation sequence in the evidence.
- It is a control-plane configuration defect with deterministic verification.

## Exact Remediation Steps
1. Retrieve current custom RDP property string from host pool.
2. Build a corrected property string including required Entra flags:
   - `enablecredsspsupport:i:1`
   - `redirectwebauthn:i:1`
   - `targetisaadjoined:i:1`
   - `enablerdsaadauth:i:1`
3. Apply update to host pool.
4. Confirm property persisted successfully.
5. Have user sign out of client, reopen in InPrivate session, and sign in using correct tenant-scoped URL.
6. Launch desktop and validate session establishment.

## Correct Order of Operations
1. Validate tenant URL correctness (to avoid false-negative testing).
2. Read existing host pool custom RDP property.
3. Apply corrected host pool custom RDP property.
4. Verify host pool update success.
5. Refresh client authentication context (sign-out + InPrivate sign-in).
6. Re-test desktop launch.
7. If still failing, execute RBAC scope audit as secondary branch.

## Verification Check After Remediation
Success criteria:
- `az desktopvirtualization hostpool show` output contains all required Entra-auth flags.
- User can see workspace resources and launch `POOL-FIN-01-DAG` without `Sign in failed` symptom.
- Session establishes to `avdsh-fin-01` and remains stable.

Recommended verification commands:
```bash
az desktopvirtualization hostpool show -g dwpai-lab-rg -n POOL-FIN-01 --query "customRdpProperty" -o tsv

az rest --method get \
  --uri "https://management.azure.com/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" \
  --query "value[].{name:name,status:properties.status,lastHeartBeat:properties.lastHeartBeat}" -o table
```

## Preventive Action
- Enforce a post-change compliance check in deployment pipeline: fail deployment if host pool `customRdpProperty` does not include required Entra-auth flags.
- Publish a single canonical tenant-scoped client URL and retire all legacy bookmarks.
- Add an RBAC + hostpool health script to pre-production smoke tests.

## Confidence and Limitations
- Confidence: High for ranking and selected hypothesis, because it is directly supported by documented resolution notes.
- Limitation: No formal numeric error code captured in source data; therefore no code-meaning interpretation is asserted.
