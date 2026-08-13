# Azure Virtual Desktop (AVD) FinBridge Deployment Guide
## Date: 2026-08-13
## Environment: dwpai-lab (fa8443c6-5a39-4df5-a018-9c876455adf9)

---

## Executive Summary
This document captures the complete end-to-end provisioning of an Azure Virtual Desktop environment for FinBridge Connect, including host pool creation, session host setup, Entra ID integration, role assignments, and troubleshooting discoveries.

**Final State:**
- Host Pool: POOL-FIN-01 (Available)
- Session Host: avdsh-fin-01 (Available, Agent 1.0.15008.300)
- Workspace: FinBridge-Workspace
- App Group: POOL-FIN-01-DAG (Desktop Virtualization)
- Users: traininguser61@zippyops.in, p41@zippyops.in

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Virtual Desktop (AVD)                  │
│                   FinBridge Deployment Topology                 │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────┐
    │         Resource Group: dwpai-lab-rg                 │
    │     Subscription: 145f9e32-b16f-4140-8278-...        │
    │     Tenant: fa8443c6-5a39-4df5-a018-9c876455adf9     │
    └──────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
        ┌───────────┐   ┌────────────┐  ┌─────────┐
        │ Host Pool │   │ Workspace  │  │  Vnet   │
        │POOL-FIN-01    │ FinBridge- │  │172.190  │
        │               │ Workspace  │  │  0/16   │
        └─────┬─────┘   └────────────┘  └─────────┘
              │
        ┌─────┴──────────┐
        │                │
    ┌─────────────┐  ┌──────────────┐
    │  App Group  │  │ Session Host │
    │ POOL-FIN-01 │  │avdsh-fin-01  │
    │    -DAG     │  │(Windows 11)  │
    └─────────────┘  └──────────────┘
        │
    ┌─────────────────────────┐
    │    Users (RBAC)         │
    ├─────────────────────────┤
    │ traininguser61@...      │
    │ p41@zippyops.in         │
    └─────────────────────────┘
```

---

## Prerequisites

### Azure Subscription
- Subscription ID: 145f9e32-b16f-4140-8278-a0931da98d82
- Tenant ID: fa8443c6-5a39-4df5-a018-9c876455adf9
- Region: eastus

### Entra ID
- Tenant Domain: zippyops.in
- Hybrid Join: Enabled (not pure AAD Join)
- Users Created:
  - traininguser61@zippyops.in (admin role)
  - p41@zippyops.in (standard user)

### Azure CLI & Tools
- Azure CLI 2.x
- PowerShell 7.x
- Appropriate RBAC role: Owner or Contributor on subscription

---

## Step-by-Step Provisioning

### Phase 1: Infrastructure Setup

#### 1.1 Create Resource Group
```bash
az group create \
  --name dwpai-lab-rg \
  --location eastus
```

#### 1.2 Create Virtual Network
```bash
az network vnet create \
  --resource-group dwpai-lab-rg \
  --name vnet-avd \
  --address-prefix 172.190.0.0/16 \
  --subnet-name subnet-avd \
  --subnet-prefix 172.190.1.0/24
```

#### 1.3 Create Network Security Group
```bash
az network nsg create \
  --resource-group dwpai-lab-rg \
  --name nsg-avd

# Allow RDP
az network nsg rule create \
  --resource-group dwpai-lab-rg \
  --nsg-name nsg-avd \
  --name allow-rdp \
  --priority 300 \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 3389 \
  --access Allow \
  --protocol Tcp
```

#### 1.4 Associate NSG with Subnet
```bash
az network vnet subnet update \
  --resource-group dwpai-lab-rg \
  --vnet-name vnet-avd \
  --name subnet-avd \
  --network-security-group nsg-avd
```

---

### Phase 2: AVD Control Plane Setup

#### 2.1 Create Host Pool
```bash
az desktopvirtualization hostpool create \
  --resource-group dwpai-lab-rg \
  --name POOL-FIN-01 \
  --host-pool-type Pooled \
  --load-balancer-type BreadthFirst \
  --preferred-app-group-type Desktop \
  --location eastus \
  --registration-info expiration-time="2026-12-31T23:59:59Z"
```

**Output**: Registration token issued (valid until 2026-12-31)

#### 2.2 Create Application Group (Desktop)
```bash
az desktopvirtualization application-group create \
  --resource-group dwpai-lab-rg \
  --name POOL-FIN-01-DAG \
  --application-group-type Desktop \
  --host-pool-name POOL-FIN-01 \
  --location eastus
```

#### 2.3 Create Workspace
```bash
az desktopvirtualization workspace create \
  --resource-group dwpai-lab-rg \
  --name FinBridge-Workspace \
  --location eastus
```

#### 2.4 Link Application Group to Workspace
```bash
az desktopvirtualization workspace update \
  --resource-group dwpai-lab-rg \
  --name FinBridge-Workspace \
  --application-group-references \
    "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourcegroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationgroups/POOL-FIN-01-DAG"
```

#### 2.5 Configure Host Pool RDP Properties for Entra ID Auth
```bash
# Add Entra ID authentication support
customRdp="drivestoredirect:s:;usbdevicestoredirect:s:;redirectclipboard:i:0;redirectprinters:i:0;audiomode:i:0;videoplaybackmode:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;targetisaadjoined:i:1;enablerdsaadauth:i:1;"

az desktopvirtualization hostpool update \
  --resource-group dwpai-lab-rg \
  --name POOL-FIN-01 \
  --custom-rdp-property "$customRdp"
```

---

### Phase 3: Session Host Provisioning

#### 3.1 Create Virtual Machine
```bash
az vm create \
  --resource-group dwpai-lab-rg \
  --name avdsh-fin-01 \
  --image Win2022Datacenter \
  --size Standard_D4s_v5 \
  --location eastus \
  --nics nic-avdsh-fin-01 \
  --os-disk-size-gb 128 \
  --enable-secure-boot true \
  --enable-vtpm true \
  --security-type TrustedLaunch \
  --public-ip-address pubip-avdsh-fin-01 \
  --vnet-name vnet-avd \
  --subnet subnet-avd
```

**Output**: VM Created with IP 172.190.67.51, Public IP assigned

#### 3.2 Enable System-Assigned Identity
```bash
az vm identity assign \
  --resource-group dwpai-lab-rg \
  --name avdsh-fin-01
```

#### 3.3 Install Entra ID Login Extension
```bash
az vm extension set \
  --resource-group dwpai-lab-rg \
  --vm-name avdsh-fin-01 \
  --name AADLoginForWindows \
  --publisher Microsoft.Azure.ActiveDirectory \
  --version 2.2
```

---

### Phase 4: AVD Agent Installation

#### 4.1 Retrieve Host Pool Registration Token
```bash
TOKEN=$(az desktopvirtualization hostpool retrieve-registration-token \
  -g dwpai-lab-rg \
  -n POOL-FIN-01 \
  --query token -o tsv)
```

#### 4.2 Install AVD Agent via Run Command (In-Guest Execution)

**Step 1: Download MSI packages**
```powershell
New-Item -Path C:\AVD -ItemType Directory -Force | Out-Null
$agentUrl = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$bootUrl  = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$agentMsi = 'C:\AVD\AVD-Agent.msi'
$bootMsi  = 'C:\AVD\AVD-Bootloader.msi'
Invoke-WebRequest -Uri $agentUrl -OutFile $agentMsi -UseBasicParsing
Invoke-WebRequest -Uri $bootUrl  -OutFile $bootMsi -UseBasicParsing
```

**Command**: Run via `az vm run-command invoke`

**Step 2: Install Bootloader**
```powershell
msiexec.exe /i 'C:\AVD\AVD-Bootloader.msi' /qn /norestart /l*v 'C:\AVD\boot-install.log'
```

**Expected Result**: Exit code 0, service RDAgentBootLoader created at version 1.0.9023.1100

**Step 3: Install Agent with Registration Token**
```powershell
msiexec.exe /i 'C:\AVD\AVD-Agent.msi' REGISTRATIONTOKEN=$TOKEN /qn /norestart /l*v 'C:\AVD\agent-install.log'
```

**Expected Result**: Exit code 0, agent version 1.0.15008.300 installed

#### 4.3 Restart VM for Registration Finalization
```bash
az vm restart -g dwpai-lab-rg -n avdsh-fin-01
```

**Wait Time**: 2-5 minutes for host to appear as Available in host pool

---

### Phase 5: Role-Based Access Control (RBAC)

#### 5.1 Assign Desktop Virtualization User (traininguser61)
```bash
PRINCIPAL_ID=$(az ad user show --id traininguser61@zippyops.in --query id -o tsv)

# App Group scope
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Desktop Virtualization User" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG"

# VM scope (admin access)
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Virtual Machine Administrator Login" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.Compute/virtualMachines/avdsh-fin-01"
```

#### 5.2 Assign Desktop Virtualization User (p41)
```bash
PRINCIPAL_ID=$(az ad user show --id p41@zippyops.in --query id -o tsv)

# App Group scope
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Desktop Virtualization User" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG"

# Host Pool scope
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Desktop Virtualization User" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01"

# Workspace scope
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Desktop Virtualization User" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/workspaces/FinBridge-Workspace"

# VM scope (user login)
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Virtual Machine User Login" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.Compute/virtualMachines/avdsh-fin-01"

# VM scope (admin for troubleshooting)
az role assignment create \
  --assignee-object-id $PRINCIPAL_ID \
  --assignee-principal-type User \
  --role "Virtual Machine Administrator Login" \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.Compute/virtualMachines/avdsh-fin-01"
```

---

## Final Configuration & Login Details

### Deployment Summary
| Component | Value |
|-----------|-------|
| Host Pool Name | POOL-FIN-01 |
| Host Pool Type | Pooled / BreadthFirst |
| Session Host | avdsh-fin-01 |
| Session Host OS | Windows 11 (Win2022 equivalence) |
| Session Host Status | Available |
| Agent Version | 1.0.15008.300 |
| Workspace | FinBridge-Workspace |
| App Group | POOL-FIN-01-DAG |
| Public IP | 172.190.67.51 |
| Tenant ID | fa8443c6-5a39-4df5-a018-9c876455adf9 |

### User Access Methods

**Option 1: Web Client (Recommended)**
- URL: https://windows.cloud.microsoft/webclient/avd/fa8443c6-5a39-4df5-a018-9c876455adf9
- Sign-in with: traininguser61@zippyops.in OR p41@zippyops.in
- Workspace: FinBridge-Workspace
- Desktop: POOL-FIN-01-DAG

**Option 2: Windows App Client (Native)**
- Download from Microsoft Store
- Feed URL: https://client.wvd.microsoft.com/arm/webclient
- Sign-in account: traininguser61@zippyops.in OR p41@zippyops.in
- Tenant: zippyops.in

**Option 3: Direct RDP (Admin Only)**
- Host: 172.190.67.51:3389
- Username: traininguser61@zippyops.in (or p41 with admin role)
- Auth: Microsoft Entra ID (Windows Login extension required)
- Note: Requires "Virtual Machine Administrator Login" role

---

## Key Discoveries & Troubleshooting Notes

### Issue 1: AVD Agent Service Registration Failure
**Problem**: VM had only Azure Guest Agent (WaAppAgent.exe) running as "RDAgent", not the true AVD agent.

**Root Cause**: First registration script was attempting to execute with inline token but service context isolation prevented script execution.

**Resolution**:
1. Download MSI packages explicitly to guest VM
2. Run msiexec separately for bootloader and agent
3. Ensure explicit exit code capture for MSI validation
4. Reboot VM after agent install for registration finalization

**Key Command**:
```powershell
msiexec.exe /i 'C:\AVD\AVD-Agent.msi' REGISTRATIONTOKEN=$TOKEN /qn /norestart /l*v 'C:\AVD\agent-install.log'
```

### Issue 2: "No Resources" in Windows App / Sign-in Failure
**Problem**: User with assigned roles still saw "No resources" error or "Sign in failed" message.

**Root Causes Identified**:
1. Tenant mismatch in web client URL (wrong tenant ID in bookmark/link)
2. Missing Entra ID authentication RDP properties on host pool
3. Insufficient RBAC scope coverage (missing workspace/host pool level assignments)

**Resolution**:
1. Correct web client URL with proper tenant ID
2. Added RDP properties: `targetisaadjoined:i:1;enablerdsaadauth:i:1;`
3. Applied redundant RBAC assignments at multiple scopes (app group, host pool, workspace, VM)

**Key Command**:
```bash
customRdp="...targetisaadjoined:i:1;enablerdsaadauth:i:1;"
az desktopvirtualization hostpool update --resource-group dwpai-lab-rg --name POOL-FIN-01 --custom-rdp-property "$customRdp"
```

### Issue 3: Certificate/Trust Chain on Entra-Joined Host
**Problem**: In-session credential prompts with Entra-joined hosts can fail if RDP auth methods are not explicitly enabled.

**Resolution**: Host pool custom RDP properties must explicitly enable:
- CredSSP support: `enablecredsspsupport:i:1`
- Web Authentication: `redirectwebauthn:i:1`
- Target AAD joined flag: `targetisaadjoined:i:1`
- RDS AAD auth: `enablerdsaadauth:i:1`

---

## Health Checks

### Verify Host Pool Status
```bash
az desktopvirtualization hostpool show -g dwpai-lab-rg -n POOL-FIN-01 \
  --query "{name:name,status:properties, customRdp:customRdpProperty}" -o json
```

### Verify Session Host Status
```bash
az rest --method get \
  --uri "https://management.azure.com/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/hostPools/POOL-FIN-01/sessionHosts?api-version=2024-04-03" \
  --query "value[].{name:name, status:properties.status, agentVersion:properties.agentVersion, lastHeartBeat:properties.lastHeartBeat}" -o table
```

### Verify RBAC Assignments
```bash
# App Group
az role assignment list \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.DesktopVirtualization/applicationGroups/POOL-FIN-01-DAG" \
  -o table

# VM
az role assignment list \
  --scope "/subscriptions/145f9e32-b16f-4140-8278-a0931da98d82/resourceGroups/dwpai-lab-rg/providers/Microsoft.Compute/virtualMachines/avdsh-fin-01" \
  -o table
```

---

## Cleanup & Decommissioning

### Remove All Resources
```bash
# Delete resource group (cascades all resources)
az group delete --name dwpai-lab-rg --yes --no-wait
```

### Selective Cleanup (if needed)
```bash
# Remove workspace
az desktopvirtualization workspace delete -g dwpai-lab-rg -n FinBridge-Workspace

# Remove app group
az desktopvirtualization application-group delete -g dwpai-lab-rg -n POOL-FIN-01-DAG

# Remove host pool
az desktopvirtualization hostpool delete -g dwpai-lab-rg -n POOL-FIN-01

# Remove VM
az vm delete -g dwpai-lab-rg -n avdsh-fin-01 --yes

# Remove VNet
az network vnet delete -g dwpai-lab-rg -n vnet-avd
```

---

## Lessons Learned

1. **Run Command Output Handling**: In-guest PowerShell scripts via `az vm run-command` need explicit error handling and output capture. Long scripts may timeout; break into smaller atomic commands.

2. **Entra-Joined Session Hosts**: Require explicit RDP property flags (`targetisaadjoined`, `enablerdsaadauth`) that are not always set by default. Must be applied at host pool level.

3. **RBAC Redundancy**: AVD permission checks happen at multiple scopes (app group, host pool, workspace, VM). Assigning at multiple scopes ensures no hidden permission gaps.

4. **Agent Registration**: The AVD agent registration token is time-bound and must be injected during MSI installation with the `/qn` flag for silent mode. Registration finalizes only after reboot.

5. **Tenant Context**: Web client URLs and login flows can route to unexpected tenants if bookmarks or direct URLs contain wrong tenant IDs. Always use the correct tenant-scoped URL.

---

## Reference Links

- [Microsoft AVD Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [AVD Host Pool Configuration](https://learn.microsoft.com/en-us/azure/virtual-desktop/host-pool-load-balancing)
- [Entra ID Integration with AVD](https://learn.microsoft.com/en-us/azure/virtual-desktop/azure-ad-join)
- [AVD Custom RDP Properties](https://learn.microsoft.com/en-us/azure/virtual-desktop/customize-rdp-properties)
- [AAD Login Extension for Windows VMs](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/login-using-aad)

---

**Document Created**: 2026-08-13  
**Environment**: dwpai-lab-rg (eastus)  
**Status**: Deployment Complete & Validated  
**Next Steps**: User acceptance testing & workload baseline setup
