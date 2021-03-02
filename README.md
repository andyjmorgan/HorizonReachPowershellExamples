# HorizonReachPowershellExamples

The following repo is to demo the Horizon Reach RESTful API via powershell.

Example for consuming:

```
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
```
