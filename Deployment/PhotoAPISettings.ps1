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
$connectionStrings=$webApp.SiteConfig.ConnectionStrings
$webAppSettings = $webApp.SiteConfig.AppSettings

$settings=@{}
foreach($set in $webAppSettings){ 
    $settings[$set.Name]=$set.Value
}

$connections = @{}
foreach($connection in $connectionStrings){
	if ($connection.Name -ne "FixedQuery") {
		$connections[$connection.Name]=@{Type=if ($connection.Type -eq $null){"Custom"}else{$connection.Type.ToString()};Value=$connection.ConnectionString}
	}
}

Log "Sets new subscription key"
$settings["SubscriptionKey"]=$subscription.PrimaryKey

Log "Sets new data connection"
$connections["FixedQuery"]=@{Type="Custom";Value="https://$APIManagementName.azure-api.net/$APIPrefix/fixed-query/"}

Set-AzureRmWebApp -ResourceGroupName $APIResourceGroupName -Name $PhotoAPIName -ConnectionStrings $connections

Log "Job well done!"