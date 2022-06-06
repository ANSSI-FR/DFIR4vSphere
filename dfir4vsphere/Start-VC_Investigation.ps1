
Function Start-VC_Investigation {

    <#
    .SYNOPSIS
    The Start-VC_Investigation function dumps in JSON the VI Events logs and can also generate a VC support bundle.

    .EXAMPLE
    
    PS C:\>$enddate = get-date
    PS C:\>$startdate = $enddate.adddays(-7)

    PS C:\>Start-VC_Investigation -stardate $startdate -enddate $enddate

    Dump main configuration and all VI Events for the past week.
    .EXAMPLE 
    
    Start-VC_Investigation -stardate $startdate -enddate $enddate -LightVIEvents -VCBundle
    Dump main configuration and a subset of VI Events for the past week, also generates a VC support bundle.

    #>
    [CmdletBinding(DefaultParametersetName='None')] 
    param (

        [Parameter(Mandatory = $false)]
        [String]$logfile = "Start-VC_Investigation.log",
        [Parameter(Mandatory = $false)]
        [switch]$VCBundle,
        [Parameter(Mandatory=$true)]
        [DateTime]$Enddate,
        [Parameter(Mandatory=$true)]
        [DateTime]$StartDate,
        [Parameter(Mandatory = $false)]
        [switch]$LightVIEvents,
        [Parameter(Mandatory = $false)]
        #Full list of Event Types Id is available at https://github.com/lamw/vcenter-event-mapping , provided by William Lam (@lamw)
        [System.Array]$LightVIEventTypesId = ("ad.event.JoinDomainEvent","VmFailedToSuspendEvent","VmSuspendedEvent","VmSuspendingEvent","VmDasUpdateOkEvent","VmReconfiguredEvent","UserUnassignedFromGroup","UserAssignedToGroup","UserPasswordChanged","AccountCreatedEvent","AccountRemovedEvent","AccountUpdatedEvent","UserLoginSessionEvent","RoleAddedEvent","RoleRemovedEvent","RoleUpdatedEvent","TemplateUpgradeEvent","TemplateUpgradedEvent","PermissionAddedEvent","PermissionUpdatedEvent","PermissionRemovedEvent","LocalTSMEnabledEvent","DatastoreFileDownloadEvent","DatastoreFileUploadEvent","DatastoreFileDeletedEvent","VmAcquiredMksTicketEvent","com.vmware.vc.guestOperations.GuestOperationAuthFailure","com.vmware.vc.guestOperations.GuestOperation","esx.audit.ssh.enabled","esx.audit.ssh.session.failed","esx.audit.ssh.session.closed","esx.audit.ssh.session.opened","esx.audit.account.locked","esx.audit.account.loginfailures","esx.audit.dcui.login.passwd.changed","esx.audit.dcui.enabled","esx.audit.dcui.disabled","esx.audit.lockdownmode.exceptions.changed","esx.audit.shell.disabled","esx.audit.shell.enabled","esx.audit.lockdownmode.disabled","esx.audit.lockdownmode.enabled","com.vmware.sso.LoginSuccess","com.vmware.sso.LoginFailure","com.vmware.sso.Logout","com.vmware.sso.PrincipalManagement","com.vmware.sso.RoleManagement","com.vmware.sso.IdentitySourceManagement","com.vmware.sso.DomainManagement","com.vmware.sso.ConfigurationManagement","com.vmware.sso.CertificateManager","com.vmware.trustmanagement.VcTrusts","com.vmware.trustmanagement.VcIdentityProviders","com.vmware.cis.CreateGlobalPermission","com.vmware.cis.CreatePermission","com.vmware.cis.RemoveGlobalPermission","com.vmware.cis.RemovePermission","com.vmware.vc.host.Crypto.Enabled","com.vmware.vc.host.Crypto.HostCryptoDisabled","ProfileCreatedEvent","ProfileChangedEvent","ProfileRemovedEvent","ProfileAssociatedEvent")
       )
    
    $currentpath = (get-location).path
    $logfile = $currentpath + "\" +  $logfile
    $vccon = Test-VCconnection -logfile $logfile
    if($vccon -eq $true)
    {

    if($VCBundle)
        {   
        "Creating VCenter support bundle" | Write-Log -LogPath $logfile
        write-host "Creating VCenter support bundle"
        $supportbundlesfolder = $currentpath + "\Support_Bundles"
        if ((Test-Path $supportbundlesfolder) -eq $false){New-Item $supportbundlesfolder -Type Directory | out-null }
            try{
             $bundle = Get-Log -bundle -DestinationPath $supportbundlesfolder  -runasync
            }
            catch{
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            "Failed to create VCenter support bundle: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning"   
            }
        }

  
	write-host "Performing ESXi, users and permissions inventory"
	$vcname = ($global:defaultviserver).Name
	"Dumping VCenter connection information" | Write-Log -LogPath $logfile 
	$global:defaultviserver  | export-csv -NoTypeInformation -Path "$($currentpath)\VC_ConnectionInfo_$($vcname).csv"
        "Performing VCenter ESXi Inventory" | Write-Log -LogPath $logfile 
        try{
        $Inventory = Get-VMHost | Select-Object Name, Version, TimeZone, @{N="Cluster";E={get-cluster -VMHost $_}}, @{N="DataCenter ";E={get-Datacenter -VMHost $_}}
        }
        catch
        {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
         "Failed to perform VCenter Inventory: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning"    
        }

        if($Inventory){$Inventory  | export-csv -NoTypeInformation -Path "$($currentpath)\VC_ESXiInventory_$($vcname).csv"}
        
        "Creating VCenter permissions report" | Write-Log -LogPath $logfile 
        try{
        $permissions = Get-VIPermission | sort-object -Property Principal | Select-Object @{N="ObjectName";E={(get-view -Id $_.EntityID).name}},@{n='Entity';E={$_.Entity.Name}},@{N='Entity Type';E={$_.EntityId.Split('-')[0]}},@{N='vCenter';E={$_.Uid.Split('@:')[1]}}, EntityID, Role, IsGroup, Principal
        }

        catch
        {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
         "Falied to grab VCenter permissions: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning"    
        }

        if($permissions){$permissions  | export-csv -NoTypeInformation -Path "$($currentpath)\VC_Permissions_$($vcname).csv"}

        "Retrieving local and SSO users" | Write-Log -LogPath $logfile 
        try{
        $allvcusers = Get-VIAccount -domain ((get-view UserDirectory).DomainList[1])
	$allvcusers += Get-VIAccount
        }
        catch
        {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
         "Falied to grab VCenter Users: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning"    
        }

        if($allvcusers){$allvcusers  | export-csv -NoTypeInformation -Path "$($currentpath)\VC_Users_$($vcname).csv"}


        $retention = (Get-AdvancedSetting -entity $global:defaultviserver -Name "event.maxAge").value
        $timespanfromnow = (New-TimeSpan -Start $StartDate -End (get-date))
        if($timespanfromnow.days -gt $retention)
        {
            write-host "VCenter VI Events log retention is $($retention) days, some events will be missing"
            "VCenter log retention is $($retention), some events will be missing" | Write-Log -LogPath $logfile -LogLevel "Warning" 
        }
        else
        {
            "VCenter log retention is $($retention) days" | Write-Log -LogPath $logfile 
        }

        $totaltimespan = (New-TimeSpan -Start $StartDate -End $Enddate)

        if(($totaltimespan.hours -eq 0) -and ($totaltimespan.minutes -eq 0) -and ($totaltimespan.seconds -eq 0))
         {$totaldays = $totaltimespan.days
         $totalloops = $totaldays
         }
        else{
         $totaldays = $totaltimespan.days + 1
         $totalloops = $totaltimespan.days
         }

        
        $VIEventsfolder = $currentpath + "\VI_events_$($vcname)"
        if ((Test-Path $VIEventsfolder) -eq $false){New-Item $VIEventsfolder -Type Directory | out-null }
        "Loading EventManager and entities for VI Events log colletion" | Write-Log -LogPath $logfile
        try{
            $eventMgr = Get-View EventManager
            }
        Catch
            {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            "Failed to load EventManager: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning" 
            }
        try{
        $Entities = @(Get-Folder | where-object {$_.Type -eq "Datacenter"})
                }
            Catch
                {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                "Failed to list entites: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning" 
                }



if($LightVIEvents -eq $false)
    {
     "Processing all VI Events" | Write-Log -LogPath $logfile
     write-host "Processing all VI Events, it might take a while"
        For ($d=0; $d -le $totalloops  ; $d++)
        {

            if($d -eq 0)
                {
                $newstartdate = $StartDate
                $newenddate = get-date("{0:yyyy-MM-dd} 00:00:00.000" -f ($newstartdate.AddDays(1)))
                 }
            elseif($d -eq $totaldays)
                {
                $newenddate = $Enddate   
                $newstartdate = get-date("{0:yyyy-MM-dd} 00:00:00.000" -f ($newenddate))
                }
            else {
                $newstartdate = $newenddate
                $newenddate = $newenddate.AddDays(+1)
                }
            $totalhours = [Math]::Floor((New-TimeSpan -Start $newstartdate -End $newenddate).Totalhours) 
          if($totalhours -eq 24){$totalhours--}

        $datetoprocess = ($newstartdate.ToString("yyyy-MM-dd"))
        $foldertoprocess = $VIEventsfolder + "\" + $datetoprocess
        if ((Test-Path $foldertoprocess) -eq $false){New-Item $foldertoprocess -Type Directory | out-null }
        "Processing VI Events for $($datetoprocess)" | Write-Log -LogPath $logfile
        write-host "Processing VI Events for $($datetoprocess)"
        For ($h=0; $h -le $totalhours ; $h++)
            {
            
            if($h -eq 0)
                {
                $newstarthour = $newstartdate
                $newendhour = $newstartdate.AddMinutes(59 - $newstartdate.Minute).AddSeconds(60 - $newstartdate.Second)    
                }
            elseif($h -eq $totalhours)
                {
                $newstarthour = $newendhour
                $newendhour = $newenddate
                }
            else {
                $newstarthour = $newendhour
                $newendhour = $newstarthour.addHours(1)   
                 }
             $outputdate = "{0:yyyy-MM-dd}_{0:HH-00-00}" -f ($newstarthour)
             $outputfile = "$($foldertoprocess)\VIEvents_" + $outputdate + ".json"
            
             try{
             $vievents = Get-VIEventPlus -startdate $newstarthour -enddate $newendhour -Entities $Entities -eventMgr $eventMgr | convertto-json -depth 5 -compress
             }
             catch {
                "Falied to retrieve VIEvents for $($outputdate)" | Write-Log -LogPath $logfile -LogLevel "Warning" 
                 }
              if($vievents){$vievents | out-file $outputfile -encoding UTF8}    
            }
        }
    }
    elseif($LightVIEvents -eq $true)
    {
    "Dumping a subset of VI Events" | Write-Log -LogPath $logfile
    $nbLightVIEventTypesId = ($LightVIEventTypesId | Measure-Object).count
    if($nbLightVIEventTypesId -ne 64)
        {"Fetching $($nbLightVIEventTypesId) custom record types" | Write-Log -LogPath $logfile}
    Foreach ($VIEventTypeId in $LightVIEventTypesId)
            { 
            write-host "Processing $($VIEventTypeId) custom record types" 
            "Processing $($VIEventTypeId) custom record types" | Write-Log -LogPath $logfile
            $outputfile = "$($VIEventsfolder)\VIEvents_" + $VIEventTypeId + ".json"
            try
                {
                $vievents = Get-VIEventPlus -startdate $StartDate -enddate $enddate -Entities $Entities -eventMgr $eventMgr -EventTypeId $VIEventTypeId | convertto-json -depth 5 -compress
                }
             catch 
                {
                "Falied to retrieve VIEvents for $($VIEventTypeId)" | Write-Log -LogPath $logfile -LogLevel "Warning" 
                 }
            if($vievents){$vievents | out-file $outputfile -encoding UTF8} 
            }
    }

    if($VCBundle)
        {
        $currenttask = get-task | where-object{($_.State -eq "Running") -or ($_.State -eq "Queued")}
        if($currenttask)
        {
        "Waiting for support bundle to complete..."  | Write-Log -LogPath $logfile
        write-host "Waiting for support bundle to complete"  
        while($currenttask)
                            {
                                "waiting 30 seconds for support bundle to complete"  | Write-Log -LogPath $logfile
                                start-sleep -seconds 30
                                $currenttask= get-task | where-object{($_.State -eq "Running") -or ($_.State -eq "Queued")}
                            }

        }
        $taskserror = get-task | where-object{($_.State -eq "Error")}
        if($taskserror)
            {
            foreach($taskerr in $taskserror)
                {        
                 "The support bundle with task ID $($taskerr.id) started on $($taskerr.starttime) failed"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                }
            }
        else
            {
            "VCenter Support bundle to complete completed successfully"  | Write-Log -LogPath $logfile
            } 
                
        }




    "Data collection finished" | Write-Log -LogPath $logfile
    }
    else
        {
        write-host "Connect to VCenter before launching the collection, exiting"
        }
write-host "Done!"
}