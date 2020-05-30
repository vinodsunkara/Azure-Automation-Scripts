#This script is to delete all resource groups from the subscription

#Variables
$subscription = "9eb0392a-3427-4e5c-9356-e9026ba51da1"
$resourceGroup = "VINOD-TEST" 
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
Write-Host "INFO: Deleting Resource Group [$resourceGroup] from the [$subscription]"
& $azcli group delete -n $resourceGroup --yes | Out-Null
if(!$?){
    Write-Host "ERROR: Could not delete the [$resourceGroup]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}else{
       Write-Host "INFO: Successfully deleted the [$resourceGroup] from the [$subscription]"
}

