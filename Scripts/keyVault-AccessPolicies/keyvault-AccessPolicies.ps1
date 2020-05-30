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

foreach ($subscriptionId in $subscriptionIds) {
    Write-Host "Current Subscription ID :: $($subscriptionId)" 
    #Set-Subscription($subscriptionId)
    & $azcli account set -s $subscriptionId

    Write-Host "Retrieving details of all key vaults..."
    $keyVaults = $(& $azcli resource list --resource-type "Microsoft.KeyVault/vaults") | ConvertFrom-Json
    Write-Host "Total Key Vaults :: $($keyVaults.Count)"

    $keyVaultsPolicyStatus = @()
    foreach ($keyVault in $keyVaults) {
        $kvInfo = $(& $azcli keyvault show --name $keyVault.Name --resource-group $keyVault.resourceGroup ) | ConvertFrom-Json
        Write-Host "INFO: $($kvinfo.properties.accessPolicies.Count) access policies configured on key vault [$($keyVault.Name)]."
        foreach ($accessPolicy in $kvinfo.properties.accessPolicies) {
            $keyVaultPolicyTemp = New-Object psobject
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name KeyVaultName -Value $keyVault.Name
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $keyVault.resourceGroup
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name Location -Value $keyVault.location
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $subscriptionId

            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name ObjectID -Value $accessPolicy.objectId
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name Certificates_Permissions -Value ($accessPolicy.permissions.certificates -join ',')
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name Keys_Permissions -Value ($accessPolicy.permissions.keys -join ',')
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name Secrets_Permissions -Value ($accessPolicy.permissions.secrets -join ',')
            $keyVaultPolicyTemp | Add-Member -MemberType NoteProperty -Name Storage_Permissions -Value ($accessPolicy.permissions.storage -join ',')

        }

        $keyVaultsPolicyStatus += $keyVaultPolicyTemp
        
    }

    $keyVaultPolicyList += $keyVaultsPolicyStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/keyVaultPolicies-ver2-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$keyVaultPolicyList | Export-Csv -Path $CsvFile -Force