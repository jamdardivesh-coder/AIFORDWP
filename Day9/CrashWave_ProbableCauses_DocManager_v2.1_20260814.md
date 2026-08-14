# Crash Wave Analysis - DocManager.exe (Legal-Win11)
Date: 2026-08-14
Scope: Legal-Win11 group (45 devices)

## Working Position
This is a ranked hypothesis list, not a final root cause. Ranking is weighted heavily by timing (v2.1 deployed this morning; crash wave and DEX degradation started mid-morning shortly after).

## Ranked Most Likely Causes

### 1) v2.1 post-install indexing behavior causing high disk I/O and intermittent crashes on low-RAM devices (most likely)
Status: to confirm

Why this fits scope facts:
- Direct timing alignment: issues began shortly after the morning v2.1 rollout and were not present earlier in the day.
- Vendor release note explicitly flags this exact pattern: high disk I/O plus intermittent crashes during first hours after install.
- Device mix includes 4 GB RAM endpoints, matching the known limitation profile.
- Prior version v2.0 was stable for 6 weeks, increasing probability that the new version changed runtime behavior.

Single fastest check:
- On 2-3 affected 4 GB devices, verify whether a DocManager-related indexing process is active and disk queue/read-write spikes coincide with DocManager.exe crash timestamps in the first post-install hours.

### 2) Memory pressure/regression in v2.1 on mixed-hardware fleet (especially 4 GB endpoints)
Status: to confirm

Why this fits scope facts:
- Crashes plus DEX decline and higher disk I/O can indicate memory pressure causing paging/thrashing.
- Mixed 4 GB/8 GB fleet creates uneven impact; lower-RAM devices are more vulnerable to startup indexing workloads.
- Onset closely follows new version deployment, consistent with a workload footprint increase introduced by v2.1.

Single fastest check:
- Compare crash incidence by RAM tier (4 GB vs 8 GB) for the same time window; a strong concentration in 4 GB devices supports memory-pressure contribution.

### 3) v2.1 indexing component defect or race condition during first-run initialization
Status: to confirm

Why this fits scope facts:
- The symptom wave is concentrated around initial post-deploy period, suggesting first-run path risk rather than steady-state operation.
- Vendor note indicates a first-few-hours instability window, which is often tied to init/indexing code paths.
- Install success (0 failures) does not exclude runtime defects after launch.

Single fastest check:
- Review Windows Application logs or WER buckets for DocManager.exe faulting module/exception signature clustering around indexing-related modules during first-launch period.

### 4) v2.1 storage-access pattern change amplifying disk contention on already busy devices
Status: to confirm

Why this fits scope facts:
- Observed disk I/O rise is a primary concurrent signal with crashes.
- If v2.1 introduced heavier synchronous file operations, devices with slower disks or active background tasks may cross stability thresholds.
- Timing still supports deployment-linked behavior even without install failures.

Single fastest check:
- On one impacted and one less-impacted device, capture a short resource trace (disk active time, queue length, top I/O processes) during app launch/indexing to confirm whether DocManager dominates contention at crash moments.

### 5) Environment compatibility edge in Legal-Win11 profile surfaced by v2.1 (policy, AV scanning, or profile data volume interaction)
Status: to confirm

Why this fits scope facts:
- Impact is currently scoped to one device group, suggesting a potential group-specific interaction.
- New version could trigger different file/system behavior that collides with existing controls (for example, heavier file scanning or profile indexing footprint).
- Lower probability than vendor-known limitation, but still plausible if issue intensity varies by endpoint configuration.

Single fastest check:
- Compare one affected Legal-Win11 device against a non-affected or less-affected peer for policy/AV exclusions and user profile size; check whether crash frequency drops when DocManager process/path is temporarily excluded in a controlled test.

## Why Ranking Is Weighted This Way
- Strongest evidence chain is: deployment timing + exact symptom match in vendor release note + low-RAM presence.
- Install success only confirms package deployment, not runtime stability.
- Alternative causes are kept in scope but ranked lower until distribution and fault-signature checks are complete.

## Immediate Validation Sequence (fast triage order)
1. Correlate crash timestamps with active post-install indexing and disk I/O on affected 4 GB devices.
2. Split crash rate by RAM tier (4 GB vs 8 GB).
3. Confirm common faulting module/exception from event logs/WER.
4. Validate whether issue naturally reduces after indexing window closes.
5. If not explained, test environment interaction hypotheses (AV/policy/profile).
