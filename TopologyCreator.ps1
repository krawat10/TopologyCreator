$Credential = Get-Credential
Add-PSSnapin "Microsoft.SharePoint.PowerShell"

$SearchAppPoolName = "SI Search App Pool Test11"
$SearchAppAccountName = "ti-s\SA_SP_Farm_Admin"
# "ti-s\SA_SP_Farm_Admin Test" 
$SearchServerName = (Get-ChildItem Env:\COMPUTERNAME).value
$SearchServiceName = "SI TestSearch Test11"
$SearchServiceProxyName = "SI TestSearchProxy Test11"
$DatabaseName = "SI Search_AdminDB Test11"

$SPAppPool = Get-SPServiceApplicationPool -Identity $SearchAppPoolName -ErrorAction SilentlyContinue

if(!$SPAppPool){
    $SPAppPool = New-SPServiceApplicationPool -Name $SearchAppPoolName -Account $SearchAppAccountName -Verbose
}

Start-SPEnterpriseSearchServiceInstance $SearchServerName -ErrorAction SilentlyContinue
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $SearchServerName -ErrorAction SilentlyContinue

$ServiceApplication = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceName -ErrorAction SilentlyContinue

if(!$ServiceApplication){
 $ServiceApplication = New-SPEnterpriseSearchServiceApplication -Partitioned -Name $SearchServiceName -ApplicationPool $SPAppPool.Name -DatabaseName $DatabaseName   
}

$Proxy = Get-SPEnterpriseSearchServiceApplicationProxy -Identity $SearchServiceProxyName -ErrorAction SilentlyContinue

if(!$Proxy){
    New-SPEnterpriseSearchServiceApplicationProxy -Partitioned -Name $SearchServiceProxyName -SearchApplication $ServiceApplication
}

$ServiceApplication.ActiveTopology

$ssa = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceName

if(!$ssa)
{
    Write-Host "Doesn't exsist"
}
#Create all components
$clone = $ssa.ActiveTopology.Clone()
$SSI = Get-SPEnterpriseSearchServiceInstance $SearchServerName
New-SPEnterpriseSearchAdminComponent -SearchTopology $clone -SearchServiceInstance $SSI
New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $clone -SearchServiceInstance $SSI
New-SPEnterpriseSearchCrawlComponent -SearchTopology $clone -SearchServiceInstance $SSI
New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $clone -SearchServiceInstance $SSI

#Prepare envoriment for index component and file
$IndexLocation = "c:\Data\ssaTest"
New-SPEnterpriseSearchIndexComponent -SearchTopology $clone -SearchServiceInstance $SSI -RootDirectory $IndexLocation
#Search/query component (next to front-end)
New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $clone -SearchServiceInstance $SSI


$clone.Activate()