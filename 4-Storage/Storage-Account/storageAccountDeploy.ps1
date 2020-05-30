#Input Parameters
param (
    [Parameter(Mandatory=$false)][string]$subscription ,
    [Parameter(Mandatory=$false)][string]$resourceGroup ,    
    [Parameter(Mandatory=$false)][string]$location ,
    [Parameter(Mandatory=$false)][string]$lobPrefix ,
    [Parameter(Mandatory=$false)][string]$project ,
    [Parameter(Mandatory=$false)][string]$environment ,
    [Parameter(Mandatory=$false)][string]$storageAccountName="",
    [Parameter(Mandatory=$false)][string]$accessTier="Hot",
    [Parameter(Mandatory=$false)][string]$sku="Standard_LRS",
    [Parameter(Mandatory=$false)][bool]$dataLake=$false
)

#Trim parameters
for($parameter=0; $parameter -lt @($PsBoundParameters).Keys.Length; $parameter++){
    if(!(@($PsBoundParameters).Keys[$parameter] -eq "dataLake")){
        Set-Variable -Name $(@($PsBoundParameters).Keys[$parameter]) -Value $(@($PsBoundParameters).Values[$parameter].Trim())
    }
}

#Variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
$baseRepoPath = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY"
$username = "7457ba0a-33d2-4ce3-a04c-e127dcc14242"
$tenant = "bcad51b8-ef4c-4445-b8e2-b6389e3529bc"
$password = "$baseRepoPath\_DevOps\certificate\Cert.pem"
if($storageAccountName -eq ""){
    $storageAccountName = $lobPrefix.Replace('-','') + $project + $environment 
    }
$storageAccountName = $storageAccountName.ToLower()
if($dataLake){
    $enableDataLake = "--enable-hierarchical-namespace true"
}else{
    $assignIdentity = "--assign-identity"
}

#Logout all accounts
Write-Host "INFO: Logout all azure accounts"
& $azcli logout

#Login
Write-Host "INFO: Azure Authentication"
& $azcli login --service-principal --username $username --tenant $tenant --password $password
if(!$?){
    Write-Host "ERROR: Could not create storage account ($storageAccountName)."
    Write-Error "Script step has been aborted." -ErrorAction stop  
}

# Set Subscription
Write-Host "INFO: Set Subscription ($subscription)."
& $azcli account set -s $subscription

#Main
Write-Host "INFO: Creating storage account ($storageAccountName)."
& $azcli storage account create --name $storageAccountName --resource-group $resourceGroup --access-tier $accessTier $assignIdentity --bypass AzureServices --default-action Deny $enableDataLake --encryption-services "blob" "file" "queue" "table" --https-only true --kind StorageV2 --location $location --sku $sku | Out-Null
if(!$?){
    Write-Host "ERROR: Could not create storage account ($storageAccountName)."
    Write-Error "Script step has been aborted." -ErrorAction stop  
}else{
    Write-Host "INFO: ($storageAccountName) deployment is done."
}