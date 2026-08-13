# AVD RBAC Assignment Script
# Purpose: Automate role assignments for AVD users across app group, host pool, workspace, and VM scopes
# Date: 2026-08-13
# Prerequisites: Azure CLI logged in with appropriate permissions

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId = "145f9e32-b16f-4140-8278-a0931da98d82",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "dwpai-lab-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$HostPoolName = "POOL-FIN-01",
    
    [Parameter(Mandatory=$true)]
    [string]$AppGroupName = "POOL-FIN-01-DAG",
    
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName = "FinBridge-Workspace",
    
    [Parameter(Mandatory=$true)]
    [string]$VMName = "avdsh-fin-01",
    
    [Parameter(Mandatory=$true)]
    [string[]]$UserEmails,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("User", "Admin")]
    [string]$AccessLevel = "User"
)

Write-Host "=========================================="
Write-Host "AVD RBAC Assignment Script"
Write-Host "=========================================="
Write-Host "Subscription: $SubscriptionId"
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Users: $($UserEmails -join ', ')"
Write-Host "Access Level: $AccessLevel"
Write-Host ""

# Determine roles based on access level
if ($AccessLevel -eq "Admin") {
    $vmRole = "Virtual Machine Administrator Login"
}
else {
    $vmRole = "Virtual Machine User Login"
}

$appGroupRole = "Desktop Virtualization User"

foreach ($email in $UserEmails) {
    Write-Host "Processing user: $email"
    
    # Get user object ID from Entra ID
    try {
        $user = az ad user show --id $email --query id -o tsv 2>$null
        if (-not $user) {
            Write-Warning "User $email not found in Entra ID"
            continue
        }
        Write-Host "  ✓ Found user object ID: $user"
    }
    catch {
        Write-Warning "Error looking up user: $_"
        continue
    }
    
    # Build resource scopes
    $appGroupScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationGroups/$AppGroupName"
    $hostPoolScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/hostPools/$HostPoolName"
    $workspaceScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/workspaces/$WorkspaceName"
    $vmScope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$VMName"
    
    # Function to safely create role assignment
    function Assign-Role {
        param(
            [string]$ObjectId,
            [string]$Role,
            [string]$Scope,
            [string]$ScopeName
        )
        
        try {
            $existing = az role assignment list --assignee-object-id $ObjectId --role "$Role" --scope $Scope --query "[0]" -o json 2>$null
            if ($existing) {
                Write-Host "    ⊘ $Role on $ScopeName (already assigned)"
            }
            else {
                az role assignment create `
                    --assignee-object-id $ObjectId `
                    --assignee-principal-type User `
                    --role "$Role" `
                    --scope $Scope 2>&1 | Out-Null
                Write-Host "    ✓ $Role on $ScopeName"
            }
        }
        catch {
            Write-Warning "    ✗ Failed to assign $Role on $ScopeName: $_"
        }
    }
    
    # Assign roles at each scope
    Write-Host "  Assigning roles..."
    Assign-Role -ObjectId $user -Role $appGroupRole -Scope $appGroupScope -ScopeName "App Group"
    Assign-Role -ObjectId $user -Role $appGroupRole -Scope $hostPoolScope -ScopeName "Host Pool"
    Assign-Role -ObjectId $user -Role $appGroupRole -Scope $workspaceScope -ScopeName "Workspace"
    Assign-Role -ObjectId $user -Role $vmRole -Scope $vmScope -ScopeName "VM"
    
    Write-Host ""
}

Write-Host "Role assignment complete!"
Write-Host ""
Write-Host "To verify assignments, run:"
Write-Host "  az role assignment list --query \"[?principalName=='$($UserEmails[0])']\" -o table"

exit 0
