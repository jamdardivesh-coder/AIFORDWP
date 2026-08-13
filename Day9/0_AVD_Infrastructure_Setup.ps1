# AVD Infrastructure & Control Plane Setup Script
# Purpose: Create Azure infrastructure, resource groups, host pool, app group, and workspace
# Date: 2026-08-13
# Prerequisites: Azure CLI logged in with Owner/Contributor role

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId = "145f9e32-b16f-4140-8278-a0931da98d82",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup = "dwpai-lab-rg",
    
    [Parameter(Mandatory=$true)]
    [string]$Region = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$HostPoolName = "POOL-FIN-01",
    
    [Parameter(Mandatory=$false)]
    [string]$AppGroupName = "POOL-FIN-01-DAG",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceName = "FinBridge-Workspace",
    
    [Parameter(Mandatory=$false)]
    [string]$VNetName = "vnet-avd",
    
    [Parameter(Mandatory=$false)]
    [string]$SubnetName = "subnet-avd",
    
    [Parameter(Mandatory=$false)]
    [string]$NSGName = "nsg-avd"
)

Write-Host "=========================================="
Write-Host "AVD Infrastructure Setup Script"
Write-Host "=========================================="
Write-Host ""

# Set subscription
Write-Host "Setting subscription: $SubscriptionId"
az account set --subscription $SubscriptionId
if ($?) {
    Write-Host "✓ Subscription set"
}
else {
    Write-Error "Failed to set subscription"
    exit 1
}

Write-Host ""

# 1. Create Resource Group
Write-Host "1. Creating Resource Group"
Write-Host "   Name: $ResourceGroup"
Write-Host "   Region: $Region"
$rgExists = az group exists -n $ResourceGroup | ConvertFrom-Json
if ($rgExists) {
    Write-Host "   ⊘ Resource group already exists"
}
else {
    az group create --name $ResourceGroup --location $Region
    Write-Host "   ✓ Resource group created"
}

Write-Host ""

# 2. Create Virtual Network
Write-Host "2. Creating Virtual Network"
Write-Host "   Name: $VNetName"
Write-Host "   Address Space: 172.190.0.0/16"
try {
    $vnetExists = az network vnet show -g $ResourceGroup -n $VNetName --query name -o tsv 2>$null
    if ($vnetExists) {
        Write-Host "   ⊘ Virtual network already exists"
    }
    else {
        az network vnet create `
            --resource-group $ResourceGroup `
            --name $VNetName `
            --address-prefix 172.190.0.0/16 `
            --subnet-name $SubnetName `
            --subnet-prefix 172.190.1.0/24
        Write-Host "   ✓ Virtual network created"
    }
}
catch {
    Write-Warning "   ⚠ Error with VNet: $_"
}

Write-Host ""

# 3. Create Network Security Group
Write-Host "3. Creating Network Security Group"
Write-Host "   Name: $NSGName"
try {
    $nsgExists = az network nsg show -g $ResourceGroup -n $NSGName --query name -o tsv 2>$null
    if ($nsgExists) {
        Write-Host "   ⊘ NSG already exists"
    }
    else {
        az network nsg create `
            --resource-group $ResourceGroup `
            --name $NSGName
        Write-Host "   ✓ NSG created"
        
        # Add RDP rule
        Write-Host "   Adding RDP rule..."
        az network nsg rule create `
            --resource-group $ResourceGroup `
            --nsg-name $NSGName `
            --name allow-rdp `
            --priority 300 `
            --source-address-prefixes '*' `
            --source-port-ranges '*' `
            --destination-address-prefixes '*' `
            --destination-port-ranges 3389 `
            --access Allow `
            --protocol Tcp
        Write-Host "   ✓ RDP rule created"
    }
}
catch {
    Write-Warning "   ⚠ Error with NSG: $_"
}

Write-Host ""

# 4. Associate NSG with Subnet
Write-Host "4. Associating NSG with Subnet"
try {
    az network vnet subnet update `
        --resource-group $ResourceGroup `
        --vnet-name $VNetName `
        --name $SubnetName `
        --network-security-group $NSGName
    Write-Host "   ✓ NSG associated with subnet"
}
catch {
    Write-Warning "   ⚠ Error associating NSG: $_"
}

Write-Host ""

# 5. Create Host Pool
Write-Host "5. Creating Host Pool"
Write-Host "   Name: $HostPoolName"
Write-Host "   Type: Pooled (BreadthFirst)"
try {
    $hpExists = az desktopvirtualization hostpool show -g $ResourceGroup -n $HostPoolName --query name -o tsv 2>$null
    if ($hpExists) {
        Write-Host "   ⊘ Host pool already exists"
    }
    else {
        az desktopvirtualization hostpool create `
            --resource-group $ResourceGroup `
            --name $HostPoolName `
            --host-pool-type Pooled `
            --load-balancer-type BreadthFirst `
            --preferred-app-group-type Desktop `
            --location $Region `
            --registration-info expiration-time="2026-12-31T23:59:59Z"
        Write-Host "   ✓ Host pool created"
    }
}
catch {
    Write-Warning "   ✗ Error creating host pool: $_"
}

Write-Host ""

# 6. Create Application Group
Write-Host "6. Creating Application Group"
Write-Host "   Name: $AppGroupName"
Write-Host "   Type: Desktop"
try {
    $agExists = az desktopvirtualization application-group show -g $ResourceGroup -n $AppGroupName --query name -o tsv 2>$null
    if ($agExists) {
        Write-Host "   ⊘ Application group already exists"
    }
    else {
        az desktopvirtualization application-group create `
            --resource-group $ResourceGroup `
            --name $AppGroupName `
            --application-group-type Desktop `
            --host-pool-name $HostPoolName `
            --location $Region
        Write-Host "   ✓ Application group created"
    }
}
catch {
    Write-Warning "   ✗ Error creating application group: $_"
}

Write-Host ""

# 7. Create Workspace
Write-Host "7. Creating Workspace"
Write-Host "   Name: $WorkspaceName"
try {
    $wsExists = az desktopvirtualization workspace show -g $ResourceGroup -n $WorkspaceName --query name -o tsv 2>$null
    if ($wsExists) {
        Write-Host "   ⊘ Workspace already exists"
    }
    else {
        az desktopvirtualization workspace create `
            --resource-group $ResourceGroup `
            --name $WorkspaceName `
            --location $Region
        Write-Host "   ✓ Workspace created"
    }
}
catch {
    Write-Warning "   ✗ Error creating workspace: $_"
}

Write-Host ""

# 8. Link Application Group to Workspace
Write-Host "8. Linking Application Group to Workspace"
try {
    $agId = "/subscriptions/$SubscriptionId/resourcegroups/$ResourceGroup/providers/Microsoft.DesktopVirtualization/applicationgroups/$AppGroupName"
    az desktopvirtualization workspace update `
        --resource-group $ResourceGroup `
        --name $WorkspaceName `
        --application-group-references $agId
    Write-Host "   ✓ Application group linked to workspace"
}
catch {
    Write-Warning "   ⚠ Error linking application group: $_"
}

Write-Host ""

# 9. Configure RDP Properties for Entra ID
Write-Host "9. Configuring RDP Properties (Entra ID Auth)"
$customRdp = "drivestoredirect:s:;usbdevicestoredirect:s:;redirectclipboard:i:0;redirectprinters:i:0;audiomode:i:0;videoplaybackmode:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;targetisaadjoined:i:1;enablerdsaadauth:i:1;"

try {
    az desktopvirtualization hostpool update `
        --resource-group $ResourceGroup `
        --name $HostPoolName `
        --custom-rdp-property "$customRdp"
    Write-Host "   ✓ RDP properties configured"
    Write-Host "   ✓ Entra ID auth flags enabled"
}
catch {
    Write-Warning "   ⚠ Error configuring RDP properties: $_"
}

Write-Host ""
Write-Host "=========================================="
Write-Host "Infrastructure Setup Complete!"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Create session host VM (Windows 11/2022)"
Write-Host "2. Join VM to Entra ID (AADLoginForWindows extension)"
Write-Host "3. Install AVD Agent using registration token"
Write-Host "4. Assign RBAC roles to users"
Write-Host ""
Write-Host "Retrieve registration token with:"
Write-Host "  az desktopvirtualization hostpool retrieve-registration-token -g $ResourceGroup -n $HostPoolName --query token -o tsv"

exit 0
