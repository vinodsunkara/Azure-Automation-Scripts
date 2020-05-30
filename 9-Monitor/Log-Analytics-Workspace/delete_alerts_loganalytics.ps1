#Input parameters
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)][string]$AlertNames = "Percentage CPU Utilization,Percentage CPU Utilization - Warning,Percentage Swap Space,Percentage Swap Space - Warning,Percentage Used Memory,Percentage Used Memory - Warning,Percentage Used Space,Percentage Used Space - Warning,VM Log Heartbeat Failed,Failed Backup Job"
)
$Alerts = $AlertNames.Split(',')
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

#Login
#Azure-Login($environment)
Write-Host "Retrieving details of all subscriptions..."
$subscriptionIds = & $azcli account list --query "[].id" -o tsv

Write-Host "INFO : Total Subscriptions retrieved :: $($subscriptionIds.Count)"

foreach ($subscription in $subscriptionIds) {
    #Set subscription context
    & $azcli account set -s $subscription | Out-Null
    if (!$?) {
        Write-Host "ERROR: Could not set subscription [$subscription] context"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }

    #List all schedule queries in current subscription context
    $LogAlerts =  & $azcli resource list --resource-type "Microsoft.Insights/scheduledQueryRules" | ConvertFrom-Json
    if (!$?) {
        Write-Host "ERROR: Could not list log alerts in this subscription [$subscription]"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }

    foreach($Alert in $Alerts){
            $LogAlert = $LogAlerts | ? {$_.Name -eq $Alert}
            if($LogAlert){
                Write-Host "INFO: Deleting log alert [$($LogAlert.Name)] in resource group [$($LogAlert.Name)]"
                & $azcli resource delete -g $($LogAlert.resourceGroup) -n $($LogAlert.Name) --resource-type "Microsoft.Insights/scheduledQueryRules"
                if (!$?) {
                    Write-Host "ERROR: Could not delete log alert [$($LogAlert.Name)] "
                    Write-Error "Script step has been aborted." -ErrorAction stop  
                }else{
                    Write-Host "INFO: Deleted log alert [$($LogAlert.Name)]"
                }

            }else{
                $MetricAlert = az monitor metrics alert list --query "[? name == '$Alert']" | ConvertFrom-Json
                if($MetricAlert){
                    Write-Host "INFO: Deleting metric alert [$($MetricAlert.Name)] in resource group [$($MetricAlert.resourceGroup)]"
                    & $azcli monitor metrics alert delete -g $($MetricAlert.resourceGroup) -n $($MetricAlert.Name)
                    if (!$?) {
                        Write-Host "ERROR: Could not delete metric alert [$($MetricAlert.Name)] "
                        Write-Error "Script step has been aborted." -ErrorAction stop  
                    }else{
                        Write-Host "INFO: Deleted metric alert [$($MetricAlert.Name)]"
                    }
                }else{
                    Write-Host "INFO: Metric Alert is not found [$($Alert)]"
                }
            }
    }
}