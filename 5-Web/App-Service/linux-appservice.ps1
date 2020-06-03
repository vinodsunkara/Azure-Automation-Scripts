# This script is to create a new linux vm using azure cli. 

#Note: If you are creating a Lixu Web App, you must pass the --runtime or -i value. 
#If not you will get an error like "usage error: --runtime | --deployment-container-image-name | --multicontainer-config-type TYPE --multicontainer-config-file FILE"
#Please see the below code for more details
#https://github.com/LukaszStem/azure-cli/blob/68e02275584b985913b91f5c74a62a3fbe8b953e/src/command_modules/azure-cli-appservice/azure/cli/command_modules/appservice/custom.py#L68

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

Write-Host "INFO: Creating linux app service plan.."
& $azcli appservice plan create --name $name --resource-group $resourceGroup.name --location $location --sku FREE --is-linux | Out-Null
if(!$?){
    Write-Host "ERROR: Could not create an appservice plan [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created an appservice plan [$name]"
}

#Create web app
Write-Host "INFO: Creating linux web app..."
& $azcli webapp create --resource-group $resourceGroup.name --plan $name --name $name -i nginx
if(!$?){
    Write-Host "ERROR: Could not create the web app [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created the web app [$name]"
}