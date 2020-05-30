# This script is to start all virtual machines in the passed subscription

#Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription = "9eb0392a-3427-4e5c-9356-e9026ba51da1"
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

#List all virtual machine names in a subscription
Write-Host "INFO: Retriving the names of Resource Groups"
$rgs = & $azcli group list --query [].name -o tsv
if(!$?){
    Write-Host "ERROR: Could not retrive the list of resource groups from [$subscription]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: retrived all resource groups from the [$subscription]"
}

foreach ($rg in $rgs) {
    Write-Host "INFO: Retriving the names of virtual machines in [$rg]"
    $vms = & $azcli vm list --resource-group $rg --query [].name -o tsv
    if(!$?){
        Write-Host "ERROR: Could not retrive the list of virtual machine names from [$rg]"
        Write-Host "Script has been aborted" -ErrorAction Stop
    }else{
        Write-Host "INFO: retrived the virtual machine details from [$rg]"
    }
    foreach ($vm in $vms) {
        Write-Host "INFO: starting the virtual machine [$vm]"
        & $azcli vm start --resource-group $rg --name $vm | Out-Null
        if(!$?){
            Write-Host "ERROR: Could not start the virtual machine [$vm]"
            Write-Host "Script has been aborted" -ErrorAction Stop
        }else{
            Write-Host "INFO: Successfully started the virtual machine [$vm]"
        }
    }
}

