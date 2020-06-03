#Get subscription and log analytics details from csv file
$inputCsvFile = "subscription.csv"
$inputContents = Get-Content $inputCsvFile | ConvertFrom-Csv

#variables
$azcli = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

#Logic App Resource Ids
$snowMetricIncidentLogicAppId = ""
$snowLogAlertIncidentLogicAppId = ""

#Login
#Azure-Login($environment)

foreach ($inputItem in $inputContents) {
    
    $subscription = $inputItem.subscriptionId
    #Set subscription context
    #Set-Subscription($subscription)

    & $azcli account set -s $subscription | Out-Null
    if (!$?) {
        Write-Host "ERROR: Could not set subscription [$subscription] context"
        Write-Error "Script step has been aborted." -ErrorAction stop  
    }

    $workSpace = & $azcli resource list --name $inputItem.LogAnalyticsName --resource-type "Microsoft.OperationalInsights/workspaces" | ConvertFrom-Json

    #Get metric alert action group
    $metricActionGroupName = "Cloud_Infra_InfraPubCloudSupport_MetricAlertActionGroup"
    $ActionGroups = & $azcli monitor action-group list | ConvertFrom-Json
    $metrciActionGroup = $ActionGroups | ? {$_.Name -eq $metricActionGroupName}


    #Get log alert action group
    $logAlertActionGroupName = "Cloud_Infra_InfraPubCloudSupport_LogAlertActionGroup"
    $logAlertMetricActionGroup = $ActionGroups | ? {$_.Name -eq $logAlertActionGroupName}
    

    #Checking for metric alert action group existance
    if(!($metrciActionGroup)){
        Write-Host "INFO: Metric action group is not available. Creating new action group in resource group [$($workSpace.resourceGroup)]"
        $snowMetricLogicAppName = $snowMetricIncidentLogicAppId.Split('/')[-1]
        $snowMetricActionGroupShortName = "MetricA_AG" #Should be less than 12 characters
        $metricActionGroup = & $azcli group deployment create -g $($workspace.resourceGroup) --template-file "$PSScriptRoot\action-group-with-logic-app.json" --parameters action-group-name=$metricActionGroupName logicAppName=$snowMetricLogicAppName actionGroupShortName=$snowMetricActionGroupShortName logicAppResourceId=$snowMetricIncidentLogicAppId | ConvertFrom-Json
        if (!$?) {
            Write-Host "ERROR: Could not create metric action group [$($metricActionGroupName)] "
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created metric action group [$($metricActionGroupName)]"
        }
        $metricActionGroupId = $metricActionGroup.properties.outputResources.id
    }else{
        Write-Host "INFO: Metric action group [$metricActionGroupName] is already available in subscription [$subscription]"
        $metricActionGroupId = $metrciActionGroup.Id
    }

    #Checking for log alert acrion group existance
    if(!($logAlertMetricActionGroup)){
        Write-Host "INFO: Log alert action group is not available. Creating new action group in resource group [$($workSpace.resourceGroup)]"
        $snowLogLogicAppName = $snowLogAlertIncidentLogicAppId.Split('/')[-1]
        $snowLogActionGroupShortName = "LogAlert_AG" ##Should be less than 12 characters
        $logAlertMetricActionGroup = & $azcli group deployment create -g $($workspace.resourceGroup) --template-file "$PSScriptRoot\action-group-with-logic-app.json" --parameters action-group-name=$logAlertActionGroupName logicAppName=$snowLogLogicAppName actionGroupShortName=$snowLogActionGroupShortName logicAppResourceId=$snowLogAlertIncidentLogicAppId | ConvertFrom-Json
        if (!$?) {
            Write-Host "ERROR: Could not create log action group [$($logAlertActionGroupName)] "
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created log action group [$($logAlertActionGroupName)]"
        }
        $logAlertMetricActionGroupId = $logAlertMetricActionGroup.properties.outputResources.id
    }else{
        Write-Host "INFO: Log alert action group [$logAlertActionGroupName] is already available in subscription [$subscription]"
        $logAlertMetricActionGroupId = $logAlertMetricActionGroup.id
    }

        Write-Host "Adding metric alert to log analytics workSpace [$($workSpace.name)]"
        
        #Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization" --scopes $workSpace.id --condition "avg Average_% Processor Time >= 90" --window-size 6h --evaluation-frequency 15m --severity 2 --action $metricActionGroupId --description "Alert for average % processor time >= 90" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization] "
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization_Warning
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization_Warning" --scopes $workSpace.id --condition "avg Average_% Processor Time >= 85" --window-size 6h --evaluation-frequency 15m --description "Warning for average % processor time >= 85" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization_Warning]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageCPUutilization_Warning]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory" --scopes $workSpace.id --condition "avg average_% used memory >= 95" --window-size 6h --evaluation-frequency 15m --description "Alert for average % used memory >= 95" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory_Warning
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory_Warning" --scopes $workSpace.id --condition "avg average_% used memory >= 90" --window-size 6h --evaluation-frequency 15m --description "Warning for average % used memory >= 90" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory_Warning]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedMemory_Warning]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace" --scopes $workSpace.id --condition "avg average_% used space >= 95" --window-size 30m --evaluation-frequency 5m --severity 2 --action $metricActionGroupId --description "Alert for average % used space >= 95" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace_Warning
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace_Warning" --scopes $workSpace.id --condition "avg average_% used space >= 90" --window-size 30m --evaluation-frequency 5m --description "Warning for average % used space >= 90" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace_Warning]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSpace_Warning]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace" --scopes $workSpace.id --condition "avg average_% used swap space >= 90" --window-size 30m --evaluation-frequency 5m --severity 2 --action $metricActionGroupId --description "Alert for average % used swap space >= 90" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace]"
        }

        #Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace_Warning
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace_Warning" --scopes $workSpace.id --condition "avg average_% used swap space >= 85" --window-size 30m --evaluation-frequency 5m --description "Alert for average % used swap space >= 85" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace_Warning]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_PercentageUsedSwapSpace_Warning]"
        }

        #Cloud_Infra_InfraPubCloudSupport_VMLogHeartbeatFailed
        & $azcli monitor metrics alert create -g $workSpace.resourceGroup -n "Cloud_Infra_InfraPubCloudSupport_VMLogHeartbeatFailed" --scopes $workSpace.id --condition "total heartbeat < 1" --window-size 15m --evaluation-frequency 1m --severity 1 --action $metricActionGroupId --description "Alert when Heartbeat is less than 1" | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_VMLogHeartbeatFailed]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_VMLogHeartbeatFailed]"
        }
        
        #Cloud_Infra_InfraPubCloudSupport_FailedBackupJob
        & $azcli group deployment create -g $($workSpace.resourceGroup) --template-file "$PSScriptRoot\log-analytics-log-alert.json" --parameters workspacename=$($workSpace.name) location=$($workSpace.location) actionGroupId=$logAlertMetricActionGroupId | Out-Null
        if (!$?) {
            Write-Host "ERROR: Could not create alert [Cloud_Infra_InfraPubCloudSupport_FailedBackupJob]"
            Write-Error "Script step has been aborted." -ErrorAction stop  
        }else{
            Write-Host "INFO: Created alert [Cloud_Infra_InfraPubCloudSupport_FailedBackupJob]"
        }
}
