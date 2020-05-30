#This script is to delete all resource groups from the subscription

#Variables
$subscription = "9eb0392a-3427-4e5c-9356-e9026ba51da1"
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

#Login
Write-Host "INFO: Azure Login"
& $azcli login
& $azcli account set -s $subscription | Out-Null
if(!$?){
    Write-Host "ERROR: Could not set [$subscription]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}

#Get the names of all resource groups in a subscription
Write-Host "INFO: Retriving the names of resource groups"
$rgs = & $azcli group list --query [].name -o tsv
if(!$?){
    Write-Host "ERROR: Could not retrive the list of resource groups from [$subscription]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
    Write-Host "INFO: retrived all resource groups from the [$subscription]"
}

#Main
foreach ($rg in $rgs) {
    Write-Host "INFO: Deleting Resource Group [$rg] from the [$subscription]"
    & $azcli group delete -n $rg --yes | Out-Null
    if(!$?){
        Write-Host "ERROR: Could not delete the [$rg]"
        Write-Host "Script has been aborted" -ErrorAction Stop
    }else{
        Write-Host "INFO: Successfully deleted the [$rg] from the [$subscription]"
    }
}
