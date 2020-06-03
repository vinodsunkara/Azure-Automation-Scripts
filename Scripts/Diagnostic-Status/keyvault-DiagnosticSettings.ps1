#Script to check the diagnostic settings configurations of keyvaults.
#Variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

Write-Host "Azure Login.............."
& $azcli login
Write-Host "Retrieving details of all subscriptions..."
$subscriptionIds = & $azcli account list --query "[].id" -o tsv
Write-Host "Total Subscriptions retrieved :: $($subscriptionIds.Count)"
$diagonsticSettingsList = @()
foreach ($subscriptionId in $subscriptionIds) {
    Write-Host "Current Subscription ID :: $($subscriptionId)" 
    #Set-Subscription($subscriptionId)
    & $azcli account set -s $subscriptionId

    Write-Host "Retrieving details of all keyvaults..."
    $keyvaults = $(& $azcli resource list --resource-type "Microsoft.keyvault/vaults") | ConvertFrom-Json
    Write-Host "Total keyvaults :: $($keyvaults.Count)"+
    $keyvaultsStatus = @()
    foreach ($keyvault in $keyvaults) {
        Write-Host "Current keyvault [$($keyvault.name)]"
        $diagsettingsObject = $(& $azcli monitor diagnostic-settings list --resource $keyvault.id --query 'value') | ConvertFrom-Json
        $keyvaultsStatusTemp = New-Object psobject
        $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name vaultName -Value $keyvault.Name
        $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $keyvault.resourceGroup
        $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name Location -Value $keyvault.location
        $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $subscriptionId
        
        if($diagsettingsObject.logs){
            $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Configured"
            $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name WorkSpaceName -Value $diagsettingsObject.workspaceId.Split('/')[-1]
            foreach($diaglog in $diagsettingsObject.logs){
                $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name $diaglog.category -Value $diaglog.enabled
            }
        }else{
            $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Not Configured"
            $keyvaultsStatusTemp | Add-Member -MemberType NoteProperty -Name WorkSpaceName -Value "Not Configured"
        }
        
        $keyvaultsStatus += $keyvaultsStatusTemp
    }

    $diagonsticSettingsList += $keyvaultsStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/keyvault_DiagonsticSettingsList-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$diagonsticSettingsList | Export-Csv -Path $CsvFile -Force


