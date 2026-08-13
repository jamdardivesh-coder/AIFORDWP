# AVD Health Check & Verification Script
# Purpose: Validate AVD deployment status, session host health, and RBAC assignments
# Date: 2026-08-13
# Prerequisites: Azure CLI logged in with appropriate permissions

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId = "145f9e32-b16f-4140-8278-a0931da98d82",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "dwpai-lab-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$HostPoolName = "POOL-FIN-01",
    
    [Parameter(Mandatory=$false)]
    [string]$VMName = "avdsh-fin-01"
)

Write-Host "=========================================="
Write-Host "AVD Environment Health Check"
Write-Host "=========================================="
Write-Host ""

# 1. Check Host Pool Status
Write-Host "1. Host Pool Status"
Write-Host "   Checking: $HostPoolName"
try {
    $hostPool = az desktopvirtualization hostpool show `
        -g $ResourceGroup `
        -n $HostPoolName `
        -o json | ConvertFrom-Json
    
    Write-Host "   ✓ Host Pool Name: $($hostPool.name)"
    Write-Host "   ✓ Type: $($hostPool.properties.hostPoolType)"
    Write-Host "   ✓ Load Balancer: $($hostPool.properties.loadBalancerType)"
    
    if ($hostPool.properties.customRdpProperty) {
        $rdpHasEntraAuth = $hostPool.properties.customRdpProperty -match "enablerdsaadauth:i:1"
        $rdpHasAADJoin = $hostPool.properties.customRdpProperty -match "targetisaadjoined:i:1"
        
        if ($rdpHasEntraAuth -and $rdpHasAADJoin) {
            Write-Host "   ✓ Entra ID Auth: ENABLED (RDP properties configured)"
        }
        else {
            Write-Host "   ⚠ Entra ID Auth: PARTIAL (Check RDP properties)"
        }
    }
}
catch {
    Write-Warning "   ✗ Error retrieving host pool: $_"
}

Write-Host ""

# 2. Check Session Host Status
Write-Host "2. Session Host Status"
Write-Host "   Checking: $VMName"
try {
    $sessionHosts = az rest --method get `
        --uri "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName/sessionHosts?api-version=2024-04-03" `
        -o json | ConvertFrom-Json
    
    if ($sessionHosts.value -and $sessionHosts.value.Count -gt 0) {
        foreach ($host in $sessionHosts.value) {
            $hostName = $host.name.Split('/')[-1]
            Write-Host "   Host: $hostName"
            Write-Host "   ✓ Status: $($host.properties.status)"
            Write-Host "   ✓ Agent Version: $($host.properties.agentVersion)"
            Write-Host "   ✓ Last Heartbeat: $($host.properties.lastHeartBeat)"
            Write-Host ""
        }
    }
    else {
        Write-Warning "   ⚠ No session hosts found in host pool"
    }
}
catch {
    Write-Warning "   ✗ Error retrieving session hosts: $_"
}

Write-Host ""

# 3. Check VM Services (RDAgent, RDAgentBootLoader)
Write-Host "3. Session Host Services (via VM)"
try {
    $services = az vm run-command invoke `
        -g $ResourceGroup `
        -n $VMName `
        --command-id RunPowerShellScript `
        --scripts @"
        `$svcs = @('RDAgent', 'RDAgentBootLoader')
        `$svcs | ForEach-Object {
            `$svc = Get-Service -Name `$_ -ErrorAction SilentlyContinue
            if (`$svc) {
                Write-Host "Service: `$(`$svc.Name) - Status: `$(`$svc.Status) - StartType: `$(`$svc.StartType)"
            }
            else {
                Write-Host "Service: `$_ - NOT FOUND"
            }
        }
"@ -o json | ConvertFrom-Json
    
    if ($services.value -and $services.value[0].message) {
        $services.value[0].message -split [System.Environment]::NewLine | Where-Object {$_} | ForEach-Object {
            Write-Host "   $($_)"
        }
    }
}
catch {
    Write-Warning "   ⚠ Could not run remote command on VM (VM may be stopped or inaccessible)"
}

Write-Host ""

# 4. Check RBAC Assignments
Write-Host "4. RBAC Assignments"
try {
    $appGroupScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/*"
    $assignments = az role assignment list `
        --scope "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup" `
        -o json | ConvertFrom-Json
    
    $desktopVirtUsers = $assignments | Where-Object {$_.roleDefinitionName -eq "Desktop Virtualization User"} | Measure-Object | Select-Object -ExpandProperty Count
    $vmLoginUsers = $assignments | Where-Object {$_.roleDefinitionName -match "Virtual Machine.*Login"} | Measure-Object | Select-Object -ExpandProperty Count
    
    Write-Host "   ✓ Desktop Virtualization Users: $desktopVirtUsers"
    Write-Host "   ✓ VM Login Assignments: $vmLoginUsers"
    
    Write-Host ""
    Write-Host "   User Assignments:"
    $userAssignments = $assignments | Where-Object {$_.principalType -eq "User"} | Group-Object -Property principalName
    foreach ($group in $userAssignments) {
        Write-Host "   - $($group.Name): $($group.Count) roles assigned"
    }
}
catch {
    Write-Warning "   ✗ Error retrieving RBAC assignments: $_"
}

Write-Host ""

# 5. Check Application Group & Workspace
Write-Host "5. AVD Control Plane Resources"
try {
    $appGroup = az desktopvirtualization application-group show `
        -g $ResourceGroup `
        -n "POOL-FIN-01-DAG" `
        -o json 2>$null | ConvertFrom-Json
    
    if ($appGroup) {
        Write-Host "   ✓ App Group: $($appGroup.name) ($($appGroup.properties.applicationGroupType))"
    }
}
catch {
    Write-Host "   ⚠ App Group check skipped"
}

try {
    $workspace = az desktopvirtualization workspace show `
        -g $ResourceGroup `
        -n "FinBridge-Workspace" `
        -o json 2>$null | ConvertFrom-Json
    
    if ($workspace) {
        Write-Host "   ✓ Workspace: $($workspace.name)"
    }
}
catch {
    Write-Host "   ⚠ Workspace check skipped"
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Health Check Complete"
Write-Host "=========================================="
Write-Host ""
Write-Host "Legend:"
Write-Host "  ✓ = Healthy/Found"
Write-Host "  ⚠ = Warning/Partial"
Write-Host "  ✗ = Error/Not Found"

exit 0
