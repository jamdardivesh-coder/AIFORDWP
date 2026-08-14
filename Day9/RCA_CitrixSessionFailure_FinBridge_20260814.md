# Root Cause Analysis (RCA): Citrix/AVD Session Failure - FinBridge
Date: 2026-08-14
Incident Type: End-user virtual desktop launch/sign-in failure
Environment: dwpai-lab-rg / POOL-FIN-01 / FinBridge-Workspace / avdsh-fin-01
Status: Resolved

## 1. Incident Summary
Users encountered session access failure symptoms (`No resources`, `Sign in failed`) while attempting to access the FinBridge virtual desktop. Control plane and session host were provisioned and reported healthy/available. Investigation determined the primary fault was host pool authentication RDP configuration incompleteness for Entra-auth session initiation.

## 2. Impact
- Affected service: User launch and sign-in to FinBridge virtual desktop.
- User impact: Unable to discover or launch assigned desktop consistently.
- Business impact: Access delay to virtualized workload; elevated support effort.

## 3. Supporting Evidence

### 3.1 Platform State Evidence
- Host pool present and active: `POOL-FIN-01`.
- Session host registered as `Available`.
- Agent version documented at `1.0.15008.300` (with bootloader installed).

Interpretation:
- This ruled out primary host registration failure as the active blocker at incident close stage.

### 3.2 Symptom Evidence
- Client-facing symptoms captured as text:
  - `No resources`
  - `Sign in failed`

Interpretation:
- These indicate identity/authorization/context failure paths, not necessarily host runtime faults.

### 3.3 Configuration Evidence
- Host pool required explicit Entra-auth RDP properties including:
  - `targetisaadjoined:i:1`
  - `enablerdsaadauth:i:1`
  - `enablecredsspsupport:i:1`
  - `redirectwebauthn:i:1`
- Resolution notes confirm adding these properties as part of successful recovery.

### 3.4 Scope and Access Evidence
- Required roles needed across App Group, Host Pool, Workspace, and VM scopes.
- Notes indicate role assignments were expanded for reliability.

### 3.5 Error Code Statement
- No numeric error code appears in collected incident artifacts.
- No inferred error-code meaning is asserted in this RCA.

## 4. Timeline (Reconstructed)
All times are relative sequence markers because absolute timestamps were not captured in the shared notes.

1. T0: Environment deployment completed; session host registered.
2. T1: Users report inability to access desktop (`No resources` / `Sign in failed`).
3. T2: Investigation validates host availability and agent state; host outage path deprioritized.
4. T3: Tenant-context and authentication configuration reviewed.
5. T4: Host pool custom RDP properties updated to include explicit Entra-auth flags.
6. T5: RBAC assignments reinforced at multiple scopes.
7. T6: Client sign-in retested with correct tenant-scoped URL; session access recovered.

## 5. 5 Whys Analysis

Problem statement: Users could not reliably launch/sign in to their assigned virtual desktop.

1. Why did users fail to launch/sign in?
Because session authentication and resource resolution failed at client launch stage.

2. Why did authentication/resource resolution fail?
Because host pool/client path was not consistently aligned to Entra-auth requirements and tenant context.

3. Why was Entra-auth alignment incomplete?
Because required custom RDP properties were not fully enforced/validated at host pool configuration time.

4. Why were required properties not enforced?
Because deployment flow lacked a mandatory post-provisioning compliance gate for host pool auth properties.

5. Why was there no compliance gate?
Because operational runbook prioritized provisioning completion over deterministic launch-readiness checks.

Root cause conclusion:
- Process and configuration control gap: missing mandatory validation of Entra-auth RDP flags on host pool before user onboarding.

Contributing factors:
- Potential stale or incorrect tenant-scoped bookmarks.
- RBAC propagation/scope complexity increased troubleshooting surface area.

## 6. Final Hypothesis (Confirmed)
Primary confirmed cause:
- Incomplete host pool custom RDP auth configuration for Entra-joined session launch (specifically `targetisaadjoined` and `enablerdsaadauth`, with supporting auth flags).

Why confirmed:
- The configuration change is directly documented in the successful remediation path and aligns with observed symptom profile while host remained available.

## 7. Remediation Executed (Exact Steps)
1. Validate user entry URL points to the correct tenant-scoped AVD web client.
2. Query existing host pool `customRdpProperty`.
3. Apply required Entra-auth flags to host pool RDP properties.
4. Verify property persistence via host pool read-back.
5. Ensure user signs out and reauthenticates with clean client context.
6. Re-test desktop launch and sign-in.
7. Confirm session host heartbeat/status remains healthy.

Reference command pattern:
```bash
customRdp="drivestoredirect:s:;usbdevicestoredirect:s:;redirectclipboard:i:0;redirectprinters:i:0;audiomode:i:0;videoplaybackmode:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;targetisaadjoined:i:1;enablerdsaadauth:i:1;"

az desktopvirtualization hostpool update \
  --resource-group dwpai-lab-rg \
  --name POOL-FIN-01 \
  --custom-rdp-property "$customRdp"
```

## 8. Correct Order of Operations
1. Confirm correct tenant URL and account context.
2. Read current host pool RDP settings.
3. Update host pool RDP settings with required Entra flags.
4. Verify update completion.
5. Refresh client auth session and re-test launch.
6. Audit RBAC scopes only if issue persists.

## 9. Verification of Resolution
Verification checks performed/required:
- Host pool custom RDP property includes all required Entra-auth flags.
- Users can discover workspace resources.
- Desktop launches without `Sign in failed` symptom.
- Session host remains `Available` with current heartbeat.

Verification command examples:
```bash
az desktopvirtualization hostpool show -g dwpai-lab-rg -n POOL-FIN-01 --query "customRdpProperty" -o tsv

az rest --method get \
  --uri "https://management.azure.com/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" \
  --query "value[].{name:name,status:properties.status,lastHeartBeat:properties.lastHeartBeat}" -o table
```

## 10. Preventive Actions
1. Add deployment guardrail:
   - CI/CD or post-provision script must fail if host pool RDP flags are missing required Entra-auth values.
2. Standardize client onboarding:
   - Distribute one canonical tenant-scoped URL and remove legacy bookmarks.
3. Add readiness checklist before user pilot:
   - Host status, RDP property compliance, RBAC scope audit, test launch by non-admin test user.
4. Improve observability:
   - Capture incident timestamps and command outputs in a structured runbook template for faster RCA precision.

## 11. Lessons Learned
- Healthy host registration alone does not guarantee successful user sign-in/launch.
- Entra-auth host pool properties are critical and must be treated as mandatory baseline.
- URL tenant context and RBAC scope layering can produce identical user-facing symptoms; deterministic checks reduce triage time.

## 12. Closure Statement
Incident is considered resolved after host pool auth properties were corrected and client context validated. Preventive controls have been defined to reduce recurrence risk and improve launch-readiness assurance.
