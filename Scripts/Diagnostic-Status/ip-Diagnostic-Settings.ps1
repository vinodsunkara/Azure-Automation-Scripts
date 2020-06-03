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

    Write-Host "Retrieving details of all public IP addresses..."
    $publicIPAddresses = $(& $azcli resource list --resource-type "Microsoft.Network/publicIPAddresses") | ConvertFrom-Json
    Write-Host "Total public IP addresses :: $($publicIPAddresses.Count)"
    $publicIPAddressesStatus = @()
    foreach ($publicIPAddress in $publicIPAddresses) {
        Write-Host "Current IP Address [$($publicIPAddress.name)]"
        $diagsettingsObject = $(& $azcli monitor diagnostic-settings list --resource $publicIPAddress.id --query 'value') | ConvertFrom-Json
        $publicIPAddressesStatusTemp = New-Object psobject
        $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name IP_Name -Value $publicIPAddress.Name
        $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $publicIPAddress.resourceGroup
        $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name Location -Value $publicIPAddress.location
        $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $subscriptionId
        
        if($diagsettingsObject.logs){
            $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Configured"
            $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name WorkSpaceName -Value $diagsettingsObject.workspaceId.Split('/')[-1]
            foreach($diaglog in $diagsettingsObject.logs){
                $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name $diaglog.category -Value $diaglog.enabled
            }
        }else{
            $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Not Configured"
            $publicIPAddressesStatusTemp | Add-Member -MemberType NoteProperty -Name WorkSpaceName -Value "Not Configured"
        }
        
        $publicIPAddressesStatus += $publicIPAddressesStatusTemp
    }

    $diagonsticSettingsList += $publicIPAddressesStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/ip_DiagonsticSettingsList-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$diagonsticSettingsList | Export-Csv -Path $CsvFile -Force


