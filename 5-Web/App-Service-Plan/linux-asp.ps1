# This script is to create a new linux appservice plan using azure cli. 

#Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription = "" ,
    [Parameter(Mandatory=$false)][string]$resourceGroupName = "" ,
    [Parameter(Mandatory=$false)][string]$location = "" ,
    [Parameter(Mandatory=$false)][string]$sku = "" 

)

#Variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

#Login
Write-Host "INFO: Azure Login"
& $azcli login
& $azcli account set -s $subscription | Out-Null
if(!$?){
    Write-Host "ERROR: Could not set [$subscription]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}

Write-Host "INFO: Retriving the details of resource group"
$resourceGroup = & $azcli group exists --name $resourceGroupName 
if($resourceGroup -eq "false"){
    Write-Host "INFO: Resource group '$resourceGroupName' does not exist."
    Write-Host "INFO: Creating a new Resource Group '$resourceGroupName'"
    $resourceGroup = & $azcli group create --location $location --name $resourceGroupName | ConvertFrom-Json
    if(!$?){
        Write-Host "ERROR: Could not create the resource group [$resourceGroupName]"
        Write-Host "Script has been aborted" -ErrorAction Stop
    }else{
        Write-Host "INFO: Successfully created the resource group [$resourceGroupName]"
    }
}else{
    Write-Host "INFO: Using existing resource group '$resourceGroupName'"
    $resourceGroup = & $azcli group show --name $resourceGroupName | ConvertFrom-Json
}

#Main
Write-Host "INFO: Creating Linux app service plan.."
& $azcli appservice plan create --name $resourceGroup.name --resource-group $resourceGroup.name --location $resourceGroup.location --sku $sku --is-linux | Out-Null
if(!$?){
    Write-Host "ERROR: Could not create an appservice plan [$resourceGroupName]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created an appservice plan [$resourceGroupName]"
}
