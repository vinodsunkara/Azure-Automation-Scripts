#Variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

Write-Host "Azure Login.............."
& $azcli login
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
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name EnabledForTemplateDeployment -Value $kvInfo.properties.enabledForTemplateDeployment
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name EnabledForDiskEncryption -Value $kvinfo.properties.enabledForDiskEncryption
        $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name EnabledForDeployment -Value $kvInfo.properties.enabledForDeployment

        $keyVaultsPolicyStatus += $keyVaultPolicyTemp
        
    }

    $keyVaultPolicyList += $keyVaultsPolicyStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/keyVaultPolicies-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$keyVaultPolicyList | Export-Csv -Path $CsvFile -Force