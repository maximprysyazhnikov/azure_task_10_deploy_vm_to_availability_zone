# ============================
# Task 10: Deploy 2 VMs Across Availability Zones
# Region: Italy North (italynorth)
# ============================

# Region for ALL resources
$location = "italynorth"

$resourceGroupName        = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"

$virtualNetworkName = "vnet"
$subnetName         = "default"

$vnetAddressPrefix   = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"

$sshKeyName = "linuxboxsshkey"

# Two VMs in two different availability zones
$vmNames = @("matebox-1", "matebox-2")
$zones   = @("1", "2")

$vmImage = "Ubuntu2204"
$vmSize  = "Standard_B1s"


# -----------------------------
# Create/Update Resource Group
# -----------------------------
Write-Host "Creating a resource group $resourceGroupName in $location ..."
New-AzResourceGroup `
    -Name $resourceGroupName `
    -Location $location `
    -Force | Out-Null


# -----------------------------
# Create Network Security Group
# -----------------------------
Write-Host "Creating a network security group $networkSecurityGroupName ..."

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
    -Name "SSH" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22 `
    -Access Allow

$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig `
    -Name "HTTP" `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1002 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 8080 `
    -Access Allow

New-AzNetworkSecurityGroup `
    -Name $networkSecurityGroupName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -SecurityRules $nsgRuleSSH, $nsgRuleHTTP | Out-Null


# -----------------------------
# Create Virtual Network + Subnet
# -----------------------------
Write-Host "Creating a virtual network $virtualNetworkName and subnet $subnetName ..."

$subnet = New-AzVirtualNetworkSubnetConfig `
    -Name $subnetName `
    -AddressPrefix $subnetAddressPrefix

New-AzVirtualNetwork `
    -Name $virtualNetworkName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix $vnetAddressPrefix `
    -Subnet $subnet | Out-Null


# -----------------------------
# Create 2 VMs in 2 Availability Zones
# New-AzVm will:
#  - Generate SSH key pair
#  - Create SSH Public Key resource with name $sshKeyName
# -----------------------------
for ($i = 0; $i -lt $vmNames.Count; $i++) {

    $currentVmName = $vmNames[$i]
    $currentZone   = $zones[$i]

    Write-Host "Creating VM $currentVmName in Availability Zone $currentZone ..."

    New-AzVm `
        -ResourceGroupName $resourceGroupName `
        -Name $currentVmName `
        -Location $location `
        -Image $vmImage `
        -Size $vmSize `
        -VirtualNetworkName $virtualNetworkName `
        -SubnetName $subnetName `
        -SecurityGroupName $networkSecurityGroupName `
        -Zone $currentZone `
        -GenerateSshKey `
        -SshKeyName $sshKeyName
}

Write-Host "Deployment complete!"
