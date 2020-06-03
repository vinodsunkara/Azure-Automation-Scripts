# This script is to create a new linux vm using azure cli. 

#Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription = "" ,
    [Parameter(Mandatory=$false)][string]$name = "" ,
    [Parameter(Mandatory=$false)][string]$location = "" 
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

#Main
Write-Host "INFO: Creating Resource Group.."
$resourceGroup = & $azcli group create --location $location --name $name | ConvertFrom-Json
if(!$?){
    Write-Host "ERROR: Could not create resource group [$name] in [$subscription]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created the resource group [$name]"
}

Write-Host "INFO: Creating windows app service plan.."
& $azcli appservice plan create --name $name --resource-group $resourceGroup.name --location $location --sku FREE | Out-Null
if(!$?){
    Write-Host "ERROR: Could not create an appservice plan [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created an appservice plan [$name]"
}

#Create web app
Write-Host "INFO: Creating windows web app..."
& $azcli webapp create --resource-group $resourceGroup.name --plan $name --name $name
if(!$?){
    Write-Host "ERROR: Could not create the web app [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created the web app [$name]"
}