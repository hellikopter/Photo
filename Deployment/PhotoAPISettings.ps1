<#
.SYNOPSIS
Sets settings for API app.

.DESCRIPTION
Sets values of application settings.

.PARAMETER APIResourceGroupName
Name of the Resource Group where the API Management is.

.NOTES
This script is for use as a part of deployment in VSTS only.
#>

Param(
	[Parameter(Mandatory=$true)] [string] $APIResourceGroupName,
	[Parameter(Mandatory=$true)] [string] $APIManagementName,
	[Parameter(Mandatory=$true)] [string] $PhotoAPIName,
	[Parameter(Mandatory=$true)] [string] $APIPrefix
)
$ErrorActionPreference = "Stop"

function Log([Parameter(Mandatory=$true)][string]$LogText){
    Write-Host ("{0} - {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $LogText)
}

Log "Get API Management context"
$management=New-AzureRmApiManagementContext -ResourceGroupName $APIResourceGroupName -ServiceName $APIManagementName
Log "Retrives subscription"
$apiProduct=Get-AzureRmApiManagementProduct -Context $management -Title "$APIPrefix - Parliament [Photo]"
$subscription=Get-AzureRmApiManagementSubscription -Context $management -ProductId $apiProduct.ProductId

Log "Gets current settings"
$webApp = Get-AzureRmwebApp -ResourceGroupName $APIResourceGroupName -Name $PhotoAPIName
$webAppSettings = $webApp.SiteConfig.ConnectionStrings
$settings=@{}
foreach($set in $webAppSettings){ 
    $settings[$set.Name]=$set.Value
}

Log "Sets new data connection"
$settings["SparqlEndpoint"]="https://$APIManagementName.azure-api.net/$APIPrefix/sparql-endpoint/master?subscription-key=$($subscription.PrimaryKey)"
Set-AzureRmWebApp -ResourceGroupName $APIResourceGroupName -Name $PhotoAPIName -AppSettings $settings

Log "Job well done!"