[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$environment = 'dev'
)

az login
#Azure-Login($environment)

$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"
Write-Host "Retrieving details of all subscriptions..."

$subscriptionIds = & $azcli account list --query "[].id" -o tsv
Write-Host "Total Subscriptions retrieved :: $($subscriptionIds.Count)"
$keyVaultPolicyList = @()

foreach($subscriptionId in $subscriptionIds){
    Write-Host "Current Subscription ID :: $($subscriptionId)" 
    #Set-Subscription($subscriptionId)
    & $azcli account set -s $subscriptionId

    Write-Host "Retrieving details of all key vaults..."
    $keyVaults = $(& $azcli resource list --resource-type "Microsoft.KeyVault/vaults") | ConvertFrom-Json
    Write-Host "Total Key Vaults :: $($keyVaults.Count)"

    $keyVaultsPolicyStatus = @()
    foreach($keyVault in $keyVaults){
        $keyVaultPolicyTemp = New-Object psobject
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name KeyVaultName -Value $keyVault.Name
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $keyVault.resourceGroup
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name Location -Value $keyVault.location
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $subscriptionId

        $kvInfo = $(& $azcli keyvault show --name $keyVault.Name --resource-group $keyVault.resourceGroup ) | ConvertFrom-Json
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name FireWall_Rules -Value $kvInfo.properties.networkAcls.ipRules
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name VirtualNetworkRules -Value $kvinfo.properties.networkAcls.virtualNetworkRules

        $keyVaultsPolicyStatus += $keyVaultPolicyTemp
        
    }

    $keyVaultPolicyList += $keyVaultsPolicyStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/keyVault-Rules-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$keyVaultPolicyList | Export-Csv -Path $CsvFile -Force