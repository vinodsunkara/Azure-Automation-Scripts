# This script is to create a resource group
# The resource group name will be created based on the input parameters

#Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription ,
    [Parameter(Mandatory=$false)][string]$name ,    
    [Parameter(Mandatory=$false)][string]$location ,
    [Parameter(Mandatory=$false)][string]$project ,
    [Parameter(Mandatory=$false)][string]$environment 
)

#Variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
$rgname = "$name" + "-$project" + "-$environment"

#Login
Write-Host "INFO: Azure Login"
& $azcli login
& $azcli account set -s $subscription | Out-Null
if(!$?){
    Write-Host "ERROR: Could not set [$subscription]"
    Write-Host "Script has been aborted" -ErrorAction Stop
}

#Create Resource Group
Write-Host "INFO: Creating resource in subscription [$subscription]"
& $azcli group create -l $location -n $rgname | Out-Null
if(!$?){
        Write-Host "ERROR: Could not create resource group [$rgname]"
        Write-Host "Script has been aborted" -ErrorAction Stop
    }else{
        Write-Host "INFO: Successfully created the resource group [$rgname] in the [$subscription]"
    }

