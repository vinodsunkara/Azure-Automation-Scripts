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
$diagonsticSettingsList = @()
foreach ($subscriptionId in $subscriptionIds) {
    Write-Host "Current Subscription ID :: $($subscriptionId)" 
    #Set-Subscription($subscriptionId)
    & $azcli account set -s $subscriptionId

    Write-Host "Retrieving details of all virtual networks..."
    $virtualnetworks = $(& $azcli network vnet list) | ConvertFrom-Json
    Write-Host "Total virtual networks :: $($virtualnetworks.Count)"
    $vnetDiagnosticSettingsStatus = @()
    foreach ($virtualnetwork in $virtualnetworks) {
        Write-Host "Current vault[$($virtualnetwork.name)]"
        $diagsettingsObject = $(& $azcli monitor diagnostic-settings list --resource $virtualnetwork.id --query 'value') | ConvertFrom-Json
        $vnetDiagnosticSettingsStatusTemp = New-Object psobject
        $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name vnetName -Value $virtualnetwork.Name
        $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $virtualnetwork.resourceGroup
        $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name Location -Value $virtualnetwork.location
        $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $subscriptionId
        
        if($diagsettingsObject.logs){
            $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Configured"
            foreach($diaglog in $diagsettingsObject.logs){
                $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name $diaglog.category -Value $diaglog.enabled
            }
        }else{
            $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Not Configured"
        }
        
        if(!($diagsettingsObject.metrics)){
            $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name AllMetrics -Value "Not Configured"
        }else{
            $vnetDiagnosticSettingsStatusTemp | Add-Member -MemberType NoteProperty -Name AllMetrics -Value $diagsettingsObject.metrics.enabled
        }

        $vnetDiagnosticSettingsStatus += $vnetDiagnosticSettingsStatusTemp
    }

    $diagonsticSettingsList += $vnetDiagnosticSettingsStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/Vnet_DiagonsticSettingsList-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$diagonsticSettingsList | Export-Csv -Path $CsvFile -Force
