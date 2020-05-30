#Script to check diagnostic settings configuration of network security groups.
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

    Write-Host "Retrieving details of all network security groups..."
    $networkSecurityGroups = $(& $azcli resource list --resource-type "Microsoft.Network/networkSecurityGroups") | ConvertFrom-Json
    Write-Host "Total network security groups :: $($networkSecurityGroups.Count)"
    $networkSecurityGroupsStatus = @()
    foreach ($networkSecurityGroup in $networkSecurityGroups) {
        Write-Host "Current network security group [$($networkSecurityGroup.name)]"
        $diagsettingsObject = $(& $azcli monitor diagnostic-settings list --resource $networkSecurityGroup.id --query 'value') | ConvertFrom-Json
        $networkSecurityGroupsStatusTemp = New-Object psobject
        $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name NSG_Name -Value $networkSecurityGroup.Name
        $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $networkSecurityGroup.resourceGroup
        $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name Location -Value $networkSecurityGroup.location
        $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $subscriptionId
        
        if($diagsettingsObject.logs){
            $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Configured"
            $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name WorkSpaceName -Value $diagsettingsObject.workspaceId.Split('/')[-1]
            foreach($diaglog in $diagsettingsObject.logs){
                $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name $diaglog.category -Value $diaglog.enabled
            }
        }else{
            $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name DiagnosticLogStatus -Value "Not Configured"
            $networkSecurityGroupsStatusTemp | Add-Member -MemberType NoteProperty -Name WorkSpaceName -Value "Not Configured"
        }
        
        $networkSecurityGroupsStatus += $networkSecurityGroupsStatusTemp
    }

    $diagonsticSettingsList += $networkSecurityGroupsStatus
}
$date = Get-Date -Format "yyyyMMdd"
$CsvFile = "$PSScriptRoot/nsg_DiagonsticSettingsList-$environment-$date.csv"
Write-Host "Exporting output to csv file [$($CsvFile)]..."
$diagonsticSettingsList | Export-Csv -Path $CsvFile -Force


