function translateHorizonID(){
    param(
        [string]$id
    )
    $ret = [System.Web.HttpUtility]::UrlEncode($id) 
    $ret
}

function Ignore-SSLErrors(){
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
}

function New-HorizonReachHeader(){
    param(
        $token   
    )
    if($token -ne $null){
        $header = @{
            authorization = "bearer $($token.jwt)"           
        }
        $header
    }
}
function Open-HorizonReachConnection(){
    param(
        $username,
        $password,
        $url
    )
    $logonObject = new-object psobject -property @{
        username = $username
        password = $password
    }
    invoke-restmethod -method 'Post' -uri "$url/api/logon" -body ($logonobject|ConvertTo-Json) -ContentType 'application/json'
}

function Update-HorizonReachToken(){
    param(
        $token,
        $url
    )
    $refreshObject = new-object psobject -property @{
        refreshToken = $token.refreshToken
    }
    invoke-restmethod -method 'Post' -uri "$url/api/refresh" -body ($refreshObject|ConvertTo-Json) -ContentType 'application/json'
}
function Close-HorizonReachConnection(){
    param(
        $token,
        $url
    )
    $refreshObject = new-object psobject -property @{
        refreshToken = $token.refreshToken
    }
    invoke-restmethod -method 'Post' -uri "$url/api/logout" -body ($refreshObject|ConvertTo-Json) -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}

function get-HorizonReachPod(){
    param(
        $token,
        [string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/pods"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
function get-HorizonReachConnectionServers(){
    param(
        $token,
        [string]$url
    )
    $baseURI = "$url/api/connectionServer"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
function get-HorizonReachGateways(){
    param(
        $token,
        [string]$url
    )
    $baseURI = "$url/api/Gateway"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
function get-HorizonReachSecurityServers(){
    param(
        $token,
        [string]$url
    )
    $baseURI = "$url/api/SecurityServer"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
function get-HorizonReachPool(){
    param(
        $token,
        [string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/pools"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}
function get-HorizonReachFarm(){
    param(
        $token,
        [string]$url,
        [string]$ID
    )
    $baseURI = "$url/api/farms"
    if($ID -ne $null){
        $safeID = translateHorizonID -ID $ID
        $baseURI = $baseURI + "/" + $safeID
    }
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}

function get-HorizonReachPollCount(){
    param(
        $token,
        [string]$url
    )
    $baseURI = "$url/api/getpollcount"
    Invoke-RestMethod -method 'Get' -uri $baseURI -Headers (New-HorizonReachHeader -token $token) -ContentType 'application/json'
}

### only use this if your ssl certificate is untrusted ###

Ignore-SSLErrors

###



#logon
$ReachURL = "https://servername.domain.local:8443"
$jwt = Open-HorizonReachConnection -username "administrator" -password "Heimdall123" -url $ReachURL

#all objects
$pods = get-HorizonReachPod -token $jwt -url $ReachURL
$farms = get-HorizonReachFarm -token $jwt -url $ReachURL
$pools = get-HorizonReachPool -token $jwt -url $ReachURL
$connectionServersSummary = get-HorizonReachConnectionServers -token $jwt -url $ReachURL
$SecurityServerSummary = get-HorizonReachSecurityServers -token $jwt -url $ReachURL


#specific object
$pod = get-HorizonReachPod -token $jwt -url $ReachURL -ID $pods.pods[0].podID
$farm = get-HorizonReachFarm -token $jwt -url $ReachURL -ID $farms[0].id
$pool = get-HorizonReachPool -token $jwt -url $ReachURL -ID $pools[0].id



#create custom views
$Connectionservers = $pods.pods | %{$_.connectionservers.connectionservers}
$securityservers = $pods.pods | %{$_.securityServerSummary.securityservers}


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
write-host "Poll Count $(get-HorizonReachPollCount -token $jwt -url $reachurl)"
#logout and delete the jwt
# Close-HorizonReachConnection -url $ReachURL -token $jwt << this doesnt work yet


