# This script is to create a new winows vm using azure cli. 

#Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription = "" ,
    [Parameter(Mandatory=$false)][string]$name = "" ,
    [Parameter(Mandatory=$false)][string]$location = "" ,
    [Parameter(Mandatory=$false)][string]$adminUserName = "" ,
    [Parameter(Mandatory=$false)][string]$AdminPassword = ""
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

Write-Host "INFO: Creating Windows virtual machine.."
& $azcli vm create --resource-group $resourceGroup.name --name $name --image win2016datacenter --admin-username $adminUserName --admin-password $AdminPassword --location $location
if(!$?){
    Write-Host "ERROR: Could not create the windows virtual machine [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created the virtual machine [$name]"
}

#Configure the VM
Write-Host "INFO: Opening port 3389 for RDP connection..."
& $azcli vm open-port --port 3389 --resource-group $resourceGroup.name --name $name
if(!$?){
    Write-Host "ERROR: Could not open the port 3389 for windows virtual machine [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully opened the port 3389 for virtual machine [$name]"
}