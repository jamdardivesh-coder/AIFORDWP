# AVD FinBridge Provisioning Scripts - README

## Overview
This directory contains a complete set of PowerShell scripts and documentation for provisioning and managing an Azure Virtual Desktop environment for FinBridge Connect.

---

## Scripts Overview

### Execution Order

```
Phase 1: Infrastructure
├── 0_AVD_Infrastructure_Setup.ps1 ── Create VNet, NSG, Host Pool, App Group, Workspace

Phase 2: Session Host
├── Create VM in Azure Portal or via `az vm create`
├── Install AADLoginForWindows extension for Entra ID join
└── Assign system-managed identity

Phase 3: AVD Agent
├── 1_AVDAgent_Installation.ps1 ────── Download & install AVD Agent + Bootloader
└── Wait for host pool status to change to "Available"

Phase 4: Access Control
├── 2_AVD_RBAC_Assignment.ps1 ─────── Assign roles to users

Phase 5: Validation
└── 3_AVD_HealthCheck.ps1 ──────────── Verify deployment health
```

---

## Script Details

### 0_AVD_Infrastructure_Setup.ps1
**Purpose**: Create Azure infrastructure and AVD control plane resources  
**When to Run**: First time setup  
**Prerequisites**: 
- Azure CLI installed and authenticated
- Owner/Contributor role on subscription

**Usage**:
```powershell
.\0_AVD_Infrastructure_Setup.ps1 `
    -SubscriptionId "145f9e32-b16f-4140-8278-a0931da98d82" `
    -ResourceGroup "dwpai-lab-rg" `
    -Region "eastus" `
    -HostPoolName "POOL-FIN-01" `
    -AppGroupName "POOL-FIN-01-DAG" `
    -WorkspaceName "FinBridge-Workspace"
```

**Creates**:
- Resource Group: dwpai-lab-rg
- Virtual Network: vnet-avd (172.190.0.0/16)
- Subnet: subnet-avd (172.190.1.0/24)
- Network Security Group: nsg-avd (with RDP rule)
- Host Pool: POOL-FIN-01 (Pooled type, BreadthFirst)
- Application Group: POOL-FIN-01-DAG (Desktop)
- Workspace: FinBridge-Workspace
- Registration Token: Valid until 2026-12-31

**Output**: 
- Host pool with Entra ID RDP properties configured
- Registration token for session host agent installation
- Ready for VM provisioning

---

### 1_AVDAgent_Installation.ps1
**Purpose**: Install AVD Agent and Bootloader on session host VM  
**When to Run**: On each session host after VM creation  
**Prerequisites**: 
- Session host VM running Windows 11 or Windows Server 2022
- Registration token from host pool
- Script executed on guest VM via `az vm run-command invoke`

**Usage (from Control Machine)**:
```bash
# Get registration token
TOKEN=$(az desktopvirtualization hostpool retrieve-registration-token \
    -g dwpai-lab-rg -n POOL-FIN-01 --query token -o tsv)

# Execute script on VM
az vm run-command invoke \
    -g dwpai-lab-rg \
    -n avdsh-fin-01 \
    --command-id RunPowerShellScript \
    --scripts @'
    $token = "YOUR_TOKEN_HERE"
    .\1_AVDAgent_Installation.ps1 -RegistrationToken $token
'@
```

**Installs**:
- RDAgentBootLoader service (v1.0.9023.1100)
- RDAgent service (v1.0.15008.300)
- Registers session host with host pool

**Output**:
- MSI installation logs in C:\AVD\
- RDAgent and RDAgentBootLoader services start on next boot
- Session host appears as "Available" in host pool within 5 minutes after restart

**Key Files Created**:
- C:\AVD\AVD-Agent.msi
- C:\AVD\AVD-Bootloader.msi
- C:\AVD\agent-install.log
- C:\AVD\boot-install.log

---

### 2_AVD_RBAC_Assignment.ps1
**Purpose**: Automate role assignments for AVD users across all required scopes  
**When to Run**: After session host is available  
**Prerequisites**: 
- Azure CLI installed and authenticated
- Users exist in Entra ID
- Owner/Contributor role on subscription

**Usage**:
```powershell
.\2_AVD_RBAC_Assignment.ps1 `
    -SubscriptionId "145f9e32-b16f-4140-8278-a0931da98d82" `
    -ResourceGroup "dwpai-lab-rg" `
    -HostPoolName "POOL-FIN-01" `
    -AppGroupName "POOL-FIN-01-DAG" `
    -WorkspaceName "FinBridge-Workspace" `
    -VMName "avdsh-fin-01" `
    -UserEmails @("traininguser61@zippyops.in", "p41@zippyops.in") `
    -AccessLevel "User"
```

**Parameters**:
- `-UserEmails`: Array of user email addresses
- `-AccessLevel`: "User" (VM User Login) or "Admin" (VM Administrator Login)

**Role Assignments** (per user):
1. **App Group Scope**: Desktop Virtualization User
2. **Host Pool Scope**: Desktop Virtualization User
3. **Workspace Scope**: Desktop Virtualization User
4. **VM Scope**: 
   - "User" level → Virtual Machine User Login
   - "Admin" level → Virtual Machine Administrator Login

**Output**:
- List of assigned roles per user
- Duplicate assignments skipped with warning
- Command to verify assignments provided

---

### 3_AVD_HealthCheck.ps1
**Purpose**: Verify health of AVD environment and session hosts  
**When to Run**: After deployment to validate completion  
**Prerequisites**: 
- Azure CLI installed and authenticated
- Resources created by scripts 0-2

**Usage**:
```powershell
.\3_AVD_HealthCheck.ps1 `
    -SubscriptionId "145f9e32-b16f-4140-8278-a0931da98d82" `
    -ResourceGroup "dwpai-lab-rg" `
    -HostPoolName "POOL-FIN-01" `
    -VMName "avdsh-fin-01"
```

**Checks**:
1. **Host Pool Status**
   - Name, type, load balancer
   - Entra ID auth flag status

2. **Session Host Status**
   - Registration status (should be "Available")
   - Agent version
   - Last heartbeat timestamp

3. **Session Host Services**
   - RDAgent service status and start type
   - RDAgentBootLoader service status
   - Runs remote PowerShell command on VM

4. **RBAC Assignments**
   - Count of Desktop Virtualization Users
   - Count of VM Login assignments
   - List of users with assignments

5. **Control Plane Resources**
   - Application Group name and type
   - Workspace name and references

**Output Legend**:
- ✓ = Healthy/Found
- ⚠ = Warning/Partial
- ✗ = Error/Not Found

**Expected Healthy State**:
```
Host Pool Status: Available
Session Host Status: Available (after restart)
Agent Version: 1.0.15008.300
RDAgent: Running (Automatic)
RDAgentBootLoader: Running (Automatic)
Entra ID Auth: ENABLED
RBAC Assignments: Users present at all scopes
```

---

## User Login Instructions

After successful deployment, users can access AVD via:

### Method 1: Web Client (Recommended)
**URL**: https://windows.cloud.microsoft/webclient/avd/fa8443c6-5a39-4df5-a018-9c876455adf9
- Sign in with: user@zippyops.in
- Workspace: FinBridge-Workspace
- Desktop: POOL-FIN-01-DAG

### Method 2: Windows App Client
- Download from Microsoft Store: "Windows App"
- Add Workspace URL: https://client.wvd.microsoft.com/arm/webclient
- Sign in with: user@zippyops.in

### Method 3: Direct RDP (Admin Only)
- Host: Public IP of session host
- Port: 3389
- Username: user@zippyops.in
- Authentication: Microsoft Entra ID

---

## Troubleshooting

### Issue: Session host shows "Unavailable" after 10 minutes
**Cause**: Agent installation failed or registration token expired  
**Solution**:
1. Check MSI install logs: `C:\AVD\agent-install.log`
2. Retrieve new registration token
3. Re-run agent installation script
4. Restart VM

### Issue: User sees "No resources" in web client
**Cause**: 
1. Wrong tenant URL in bookmark (check tenant ID in URL)
2. Missing RBAC assignments
3. Entra ID auth not configured on host pool

**Solution**:
1. Use correct tenant-scoped URL
2. Run RBAC assignment script
3. Verify RDP properties include `enablerdsaadauth:i:1`

### Issue: User cannot sign in to AVD desktop
**Cause**: 
1. Entra ID auth RDP flags not configured
2. VM not Entra ID joined
3. Virtual Machine User Login role not assigned

**Solution**:
1. Verify AADLoginForWindows extension installed
2. Run `3_AVD_HealthCheck.ps1` to verify configuration
3. Verify RBAC assignments at VM scope
4. Use InPrivate browser session for fresh Entra ID auth

### Issue: RDAgent service not starting
**Cause**: 
1. Installation failed
2. Service pointing to wrong binary
3. Bootloader not installed

**Solution**:
1. Review MSI logs in C:\AVD\
2. Uninstall both MSIs and reinstall in correct order (bootloader first)
3. Ensure registration token is valid (not expired)

---

## Reference Information

### Key Environment Details
| Property | Value |
|----------|-------|
| Subscription ID | 145f9e32-b16f-4140-8278-a0931da98d82 |
| Tenant ID | fa8443c6-5a39-4df5-a018-9c876455adf9 |
| Tenant Domain | zippyops.in |
| Resource Group | dwpai-lab-rg |
| Region | eastus |
| VNet Address Space | 172.190.0.0/16 |
| Subnet Range | 172.190.1.0/24 |

### User Accounts
| Email | Role | Access Level |
|-------|------|--------------|
| traininguser61@zippyops.in | Admin | VM Administrator |
| p41@zippyops.in | Standard | VM User |

### Critical RDP Properties
```
targetisaadjoined:i:1              # VM is Entra ID joined
enablerdsaadauth:i:1               # Enable Entra ID RDP auth
enablecredsspsupport:i:1           # CredSSP for credential delegation
redirectwebauthn:i:1               # WebAuthn redirect support
```

---

## Cleanup & Decommissioning

To remove all resources:

```bash
# Delete entire resource group (cascades all resources)
az group delete --name dwpai-lab-rg --yes --no-wait
```

To selectively delete resources:

```bash
# Delete workspace
az desktopvirtualization workspace delete -g dwpai-lab-rg -n FinBridge-Workspace

# Delete app group
az desktopvirtualization application-group delete -g dwpai-lab-rg -n POOL-FIN-01-DAG

# Delete host pool
az desktopvirtualization hostpool delete -g dwpai-lab-rg -n POOL-FIN-01

# Delete VM
az vm delete -g dwpai-lab-rg -n avdsh-fin-01 --yes

# Delete VNet
az network vnet delete -g dwpai-lab-rg -n vnet-avd
```

---

## Additional Resources

- [Microsoft AVD Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [AVD Host Pool Concepts](https://learn.microsoft.com/en-us/azure/virtual-desktop/host-pool-load-balancing)
- [Entra ID Integration with AVD](https://learn.microsoft.com/en-us/azure/virtual-desktop/azure-ad-join)
- [Custom RDP Properties](https://learn.microsoft.com/en-us/azure/virtual-desktop/customize-rdp-properties)
- [AAD Login Extension](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/login-using-aad)

---

**Last Updated**: 2026-08-13  
**Created By**: Azure AVD Provisioning Process  
**Status**: Production Ready
