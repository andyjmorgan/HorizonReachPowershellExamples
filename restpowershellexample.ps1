<#
.SYNOPSIS
This function translates the Horizon ID model (containing a /) to a web friendly format

.DESCRIPTION
This function translates the Horizon ID model (containing a /) to a web friendly format

.PARAMETER id
A horizon object id, such as a pool, farm, etc. id.

.EXAMPLE
$safeID = translateHorizonID -ID $ID

.NOTES
General notes
#>#
function translateHorizonID(){
    param(
        [string]$id
    )
    $ret = [System.Web.HttpUtility]::UrlEncode($id) 
    $ret
}
<#
.SYNOPSIS
this function simply instructs powershell to ignore cert errors

.DESCRIPTION
this function simply instructs powershell to ignore cert errors

.EXAMPLE
Ignore-SSLErrors

.NOTES
General notes
#>
function Ignore-SSLErrors(){
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
}
<#
.SYNOPSIS
This function will take an active or expired JWT token and renew it.

.DESCRIPTION
This function will take an active or expired JWT token and renew it, this will only work as long as the web sessions timeout configured in Horizon Reach. A new token is passed back to be used later.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
$jwt = Update-HorizonReachtoken -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Update-HorizonReachToken(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $refreshObject = new-object psobject -property @{
        refreshToken = $token.refreshToken
    }
    invoke-restmethod -method 'Post' -uri "$url/api/refresh" -body ($refreshObject|ConvertTo-Json) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function creates a Horizon Reach Header and appends the JWT Token to it.

.DESCRIPTION
As Reach uses JWT For authentication, the token must be presented as a header in each call

.PARAMETER token
The JWT token returned from the logon call or refresh call

.EXAMPLE
New-HorizonReachHeader -token $token

.NOTES
General notes
#>
function New-HorizonReachHeader(){
    param(
        [Parameter(Mandatory=$true)]$token   
    )
    if($null -ne $token){
        $header = @{
            authorization = "bearer $($token.jwt)"           
        }
        $header
    }
}
<#
.SYNOPSIS
This function opens a connection to a Horizon Reach server.

.DESCRIPTION
This function passes the provided credentials to the reach server and returns a JWT token, if successful, to be used in future calls

.PARAMETER username
the username to authenticate as (this can be an Active Directory username in UPN format if configured).

.PARAMETER password
The password to authenticate with

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
$jwt = Open-HorizonReachConnection -username "administrator" -password "Heimdall123" -url $ReachURL

.NOTES
General notes
#>
function Open-HorizonReachConnection(){
    param(
        [Parameter(Mandatory=$true)][string]$username,
        [Parameter(Mandatory=$true)][string]$password,
        [Parameter(Mandatory=$true)][string]$url
    )
    $logonObject = new-object psobject -property @{
        username = $username
        password = $password
    }
    invoke-restmethod -method 'Post' -uri "$url/api/logon" -body ($logonobject|ConvertTo-Json) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will log out the current session.

.DESCRIPTION
The token is passed to the server to destroy the session on the server side, once done, the token can no longer be used.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon Reach URL

.EXAMPLE
An example

.NOTES
General notes
#>
function Close-HorizonReachConnection(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)]$url
    )
    $refreshObject = new-object psobject -property @{
        refreshToken = $token.refreshToken
    }
    invoke-restmethod -method 'Post' -uri "$url/api/logout" -body ($refreshObject|ConvertTo-Json) -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will List the connection servers discovered by Reach.

.DESCRIPTION
This function will List the connection servers discovered by Reach.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
Get-HorizonReachConnectionServer -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Get-HorizonReachConnectionServer(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $baseURI = "$url/api/connectionServer"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Farms discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Farms discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, further information can be retrieved (summary view vs detail view)

.PARAMETER token
The JWT token returned from the logon call or refresh call.

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443.

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachFarm -token $jwt -url $ReachURL 

Get a specific item:
Get-HorizonReachFarm -token $jwt -url $ReachURL -ID $farm.id

.NOTES
General notes
#>
function Get-HorizonReachFarm(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/farms"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will list Gateways discovered in Horizon Reach.

.DESCRIPTION
This function will list Gateways discovered in Horizon Reach. Gateways must be configured in the Horizon Console for them to be discovered

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
Get-HorizonReachGateway -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Get-HorizonReachGateway(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $baseURI = "$url/api/Gateway"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Global Entitlements discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Global Entitlements discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, further information can be retrieved (summary view vs detail view)

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachGlobalEntitlement -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachGlobalEntitlement -token $jwt -url $ReachURL -ID $ge.id

.NOTES
General notes
#>
function Get-HorizonReachGlobalEntitlement(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/GlobalEntitlements"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Global Application Entitlements discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Global Application Entitlements discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, further information can be retrieved (summary view vs detail view)

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachGlobalApplicationEntitlement -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachGlobalApplicationEntitlement -token $jwt -url $ReachURL -ID $ge.id

.NOTES
General notes
#>
function Get-HorizonReachGlobalApplicationEntitlement(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/GlobalApplicationEntitlements"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Pods discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Pods discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, just one item.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachPod -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachPod -token $jwt -url $ReachURL -ID $pod.podid

.NOTES
General notes
#>
function Get-HorizonReachPod(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/pods"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function can be used to check when Horizon Reach has new data.

.DESCRIPTION
This function can be used to check when Horizon Reach has new data. Each time reach performs a discovery, this number will increase.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
List all objects:
Get-HorizonReachPollCount -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Get-HorizonReachPollCount(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $baseURI = "$url/api/Getpollcount"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Desktop Pools discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Desktop Pools discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, further information can be retrieved (summary view vs detail view)

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachPool -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachPool -token $jwt -url $ReachURL -ID $pool.id

.NOTES
General notes
#>
function Get-HorizonReachPool(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/pools"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Problem Machines discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve  Problem Machines discovered by Horizon Reach.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
Get-HorizonReachProblemMachines -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Get-HorizonReachProblemMachines(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $baseURI = "$url/api/problemMachines"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will List the security servers discovered by Reach.

.DESCRIPTION
This function will List the security servers discovered by Reach.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
Get-HorizonReachSecurityServer -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Get-HorizonReachSecurityServer(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $baseURI = "$url/api/SecurityServer"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will get User Sessions associated with a pool / farm / vcenter / uag etc.

.DESCRIPTION
Get User Sessions associated with a pool / farm / vcenter / uag etc.

.PARAMETER token
The JWT token returned from the logon call or refresh call.

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
The ID of a pool, pod, farm, global entitlement, UAG, vCenter, etc.

.EXAMPLE
Get-HorizonReachSessions -token $jwt -url $ReachURL -ID $poolid

.NOTES
General notes
#>
function Get-HorizonReachSessions(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [Parameter(Mandatory=$true)][string]$ID
    )
    $baseURI = "$url/api/GetSessionsForObject"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Sites discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Sites discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, just one item.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachSite -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachSite -token $jwt -url $ReachURL -ID $siteid

.NOTES
General notes
#>
function Get-HorizonReachSite(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/Sites"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Unified Access Gateways discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Unified Access Gateways discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, further information can be retrieved (summary view vs detail view)

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachUAG -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachUAG -token $jwt -url $ReachURL -ID $uagid

.NOTES
General notes
#>
function Get-HorizonReachUAG(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/UAG"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve Tracked Alarms discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve Tracked Alarms discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, it will pull the alarms associated with that object

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachTrackedAlarm -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachTrackedAlarm -token $jwt -url $ReachURL -ID $podID

.NOTES
General notes
#>
function Get-HorizonReachTrackedAlarm(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/TrackedAlarms"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function will retrieve vCenters discovered by Horizon Reach.

.DESCRIPTION
This function will retrieve vCenters discovered by Horizon Reach. By Default it will list all items, if an ID is passed in, it will pull the alarms associated with that object

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.PARAMETER ID
(Optional) the ID of the item you wish to Get.

.EXAMPLE
List all objects:
Get-HorizonReachvCenter -token $jwt -url $ReachURL

Get a specific item:
Get-HorizonReachvCenter -token $jwt -url $ReachURL -ID $vCenterID

.NOTES
General notes
#>
function Get-HorizonReachvCenter(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/vCenters"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
<#
.SYNOPSIS
This function can be used to check when the Horizon Reach version.

.DESCRIPTION
This function can be used to check when the Horizon Reach version.

.PARAMETER token
The JWT token returned from the logon call or refresh call

.PARAMETER url
The Horizon reach server url, e.g. https://reach.domain.local:9443

.EXAMPLE
List all objects:
Get-HorizonReachVersion -token $jwt -url $ReachURL

.NOTES
General notes
#>
function Get-HorizonReachVersion(){
    param(
        [Parameter(Mandatory=$true)]$token,
        [Parameter(Mandatory=$true)][string]$url
    )
    $baseURI = "$url/api/GetVersion"
   
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}



### only use this if your ssl certificate is untrusted ###

Ignore-SSLErrors

###



#logon
$ReachURL = "https://servername.domain.local:8443"
$jwt = Open-HorizonReachConnection -username "administrator" -password "Heimdall123" -url $ReachURL


###Examples of calling for data below


#all sites
$sites = Get-HorizonReachSite -token $jwt -url $ReachURL
foreach($site in $sites.Sites){
    Get-HorizonReachSite -token $jwt -url $ReachURL -ID $site.siteID
}

#all pods
$pods = Get-HorizonReachPod -token $jwt -url $ReachURL
foreach($pod in $pods.pods){
    Get-HorizonReachPod -token $jwt -url $ReachURL -ID $pod.podid
}

#all ConnectionServers
$connectionServers = Get-HorizonReachConnectionServer -token $jwt -url $reachURL

#all farms
$farms = Get-HorizonReachFarm -token $jwt -url $ReachURL
foreach($farm in $farms){
    Get-HorizonReachFarm -token $jwt -url $ReachURL -ID $farm.id
}


#all gateways - doesnt support sub items
$gateways = Get-HorizonReachGateway -token $jwt -url $ReachURL

#Get all global application entitlements, there's a bug here as the globalentitlement will list apps to, you can work around it here:
$globalEntitlements = Get-HorizonReachGlobalEntitlement -token $jwt -url $ReachURL
foreach($ge in $globalEntitlements){
    if($ge.type -eq "Desktop"){
        Get-HorizonReachGlobalEntitlement -token $jwt -url $ReachURL -ID $ge.id
    }
    else{ ## assumed application type "Application"
        Get-HorizonReachGlobalApplicationEntitlement -token $jwt -url $ReachURL -ID $ge.id
    }
}

#all pools
$pools = Get-HorizonReachPool -token $jwt -url $ReachURL
foreach($pool in $pools){
    Get-HorizonReachPool -token $jwt -url $ReachURL -ID $pool.id
    if($pool.sessions -gt 0){
        Get-HorizonReachSessions -token $jwt -url $ReachURL -ID $pool.id
    }
}


$UAGS = Get-HorizonReachUAG -token $jwt -url $ReachURL
foreach($UAG in $UAGS){
    Get-HorizonReachUAG -token $jwt -url $ReachURL -ID $UAG.id
}

### List problem machines and Get the vCenters if they are part of a vCenter object
$problemMachines = Get-HorizonReachProblemMachines -token $jwt -url $ReachURL
foreach($problemMachine in $problemMachines){
    if($null -ne $problemMachine.vCenterID){
        $vCenter = Get-HorizonReachvCenter -token $jwt -url $ReachURL -ID $problemMachine.vCenterID
    }
}


#using the data to create an object
New-Object -TypeName psobject -property @{
    pods = $pods.pods.Count
    farms = $farms.Count
    pools = $pools.Count
    connectionservers = $connectionServersSummary.connectionServers.Count
    securityservers = $securityservers.Count
} | Format-Table

#Refresh the jwt if needed (401 error)
$jwt = Update-HorizonReachtoken -token $jwt -url $ReachURL
write-host "Poll Count $(Get-HorizonReachPollCount -token $jwt -url $reachurl)"

#logout and delete the jwt
Close-HorizonReachConnection -url $ReachURL -token $jwt

