# This script is to create a new linux vm using azure cli. 

#Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription = "9eb0392a-3427-4e5c-9356-e9026ba51da1" ,
    [Parameter(Mandatory=$false)][string]$name = "vinod-linux-vm" ,
    [Parameter(Mandatory=$false)][string]$location = "centralus" ,
    [Parameter(Mandatory=$false)][string]$adminUserName = "vinodsunkara" ,
    [Parameter(Mandatory=$false)][string]$AdminPassword = "Microsoft@123"
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

Write-Host "INFO: Creating Linux virtual machine.."
& $azcli vm create --resource-group $resourceGroup.name --name $name --image UbuntuLTS --admin-username $adminUserName --admin-password $AdminPassword --location $location
if(!$?){
    Write-Host "ERROR: Could not create the linux virtual machine [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully created the virtual machine [$name]"
}

#Configure the VM
Write-Host "INFO: Opening port 80..."
& $azcli vm open-port --port 80 --resource-group $resourceGroup.name --name $name
if(!$?){
    Write-Host "ERROR: Could not open the port 80 for linux virtual machine [$name]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: Successfully opened the port 80 for virtual machine [$name]"
}