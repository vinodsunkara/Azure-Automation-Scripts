#Using Module "..\..\..\commonCode\common.module.psm1" 
#Input Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription ,
    [Parameter(Mandatory=$false)][string]$environment ,
    [Parameter(Mandatory=$false)][string]$vnetName ,
    [Parameter(Mandatory=$false)][string]$subNetAddressPrefix 
)

#Trim parameters
for($parameter=0; $parameter -lt @($PsBoundParameters).Keys.Length; $parameter++){
        Set-Variable -Name $(@($PsBoundParameters).Keys[$parameter]) -Value $(@($PsBoundParameters).Values[$parameter].Trim())
}

#Variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
$subnetName = "AzureBastionSubnet"
$bastionName = $VnetName -ireplace('VNET','BASTION')
$publicIPName = $VnetName -ireplace('VNET','BASTION-IPAddress')

$subnetAddressFlag = $false
[int]$subnetAddressCheck = $subNetAddressPrefix.Split('/')[1]
if($subnetAddressCheck -ge 27){
    $subnetAddressFlag = $true
}

if($subnetAddressFlag){
    #Login
    #Azure-Login($environment)
    az login 
    az account set -s $subscription

    #Set subscription context
    #Set-Subscription($subscription)

    #Get the details of VNet
    Write-Host "INFO: Retriving the details of Virtual Network [$vnetName]"
    $vnet = & $azcli resource list --name $vnetName --resource-type "Microsoft.Network/virtualNetworks" | ConvertFrom-Json
    if (!$?) {
        Write-Host "ERROR: Could not retrive the details of Virtual Network [$vnetName]"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }

    #Listing all subnets under the given Virtual network
    Write-Host "INFO: Listing all subnets under Virtual network [$vnetName]"
    $subnets = & $azcli network vnet subnet list -g $vnet.resourceGroup --vnet-name $vnetName | ConvertFrom-Json
    if (!$?) {
        Write-Host "ERROR: Could not list subnets under Virtual network [$vnetName]"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }

    #Check if AzureBastionSubnet is already exists in the Virtual network. If it does not exist, create a new AzureBastionSubnet
    if ($subnets.name -contains $subnetName) {
        Write-Host "INFO: Subnet [$subnetName] is already exists under Virtual network [$vnetName]"
    }
    else {
        Write-Host "INFO: Subnet [$subnetName] does not exists under Virtual network [$vnetName]"
        Write-Host "INFO: Creating subnet [$subnetName] under Virtual network [$vnetName]"
        & $azcli network vnet subnet create -n $subnetName --vnet-name $vnetName -g $vnet.resourceGroup --address-prefixes $subNetAddressPrefix | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create subnet [$subnetName] under Virtual network [$vnetName]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }
        else {
            Write-Host "INFO: Created subnet [$subnetName] under Virtual network [$vnetName]"
        }
    }

    #Create Public IP Address
    Write-Host "INFO: Creating public IP Address"
    & $azcli network public-ip create -g $vnet.resourceGroup -n $publicIPName --sku Standard --location $vnet.location | Out-Null
    if (!$?) {
        Write-Host "ERROR: Could not create public IP Address for AzureBastionSubnet"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }else{
        Write-Host "INFO: Successfully creted the public IP Address for AzureBastionSubnet"
    }

    #Create Bastion
    Write-Host "INFO: Creating [$bastionName]"
    & $azcli network bastion create --name $bastionName --public-ip-address $publicIPName --resource-group $vnet.resourceGroup --vnet-name $vnetName --location $vnet.location | Out-Null
    if (!$?) {
        Write-Host "ERROR: Could not create the Azure bastion"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }else{
        Write-Host "Successfully creted the Azure bastion"
    }
}else{
    Write-Host "ERROR: SubnetAddressPrefix should be /27"
}