Function Start-ESXi_Investigation {

    <#
    .SYNOPSIS
    The Start-ESXi_Investigation function retrieves some artifacts on ESXi hosts and can also generate an ESXi support bundle.

    .EXAMPLE
    
    PS C:\>Get-VMHost | Start-ESXi_Investigation


    Dump artifacts from all ESXi hosts
    .EXAMPLE 
    
    Start-ESXi_Investigation -Name %ESXi% -ESXBundle
    Dump artifacts a particular ESXi host and generate a support bundle.

    #>
   [CmdletBinding(DefaultParametersetName='None')] 
    param (

        [Parameter(Mandatory = $false)]
        [String]$logfile = "Start-ESXi_Investigation.log",
        [Parameter(Mandatory = $false)]
        [switch]$ESXBundle,
        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory = $true)]    
        [string]$Name

    )
    
    begin
        {
        $currentpath = (get-location).path
        $logfile = $currentpath + "\" +  $logfile
        $vccon = Test-VCconnection -logfile $logfile
        if($vccon -eq $true)
            {
            "Successfully connected to VC" | Write-Log -LogPath $logfile 
            }
        else
            {
            write-host "Connect to VCenter before launching the collection"
            break
            }
        }
     process
        {
        foreach($esx in $Name)
            {  
            "Processing $($esx)"  | Write-Log -LogPath $logfile
            write-host "Processing $($esx)" 
            try
                {
                $esxhost = Get-VMHost -Name $esx
                }
            catch
                {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                "Error retrieving $($esx) object: Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Error"   
                }

            if($esxhost)
            {
            $foldertoprocess = $currentpath + "\" + $esx
            if ((Test-Path $foldertoprocess) -eq $false){New-Item $foldertoprocess -Type Directory | out-null}
	    "Dumping $($esx) general information"  | Write-Log -LogPath $logfile
 	    $esxhost | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_General.csv"  
            "Retrieving services on $($esx)"  | Write-Log -LogPath $logfile
                try {
                    $esxhost | Get-VMHostService | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Services.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving services on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
            
                "Retrieving domain join information on $($esx)"  | Write-Log -LogPath $logfile
                try {
                    $esxhost | Get-VMHostAuthentication | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_DomJoin.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving domain join information on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
            try
                {
                $esxcli = $esxhost | Get-esxcli -V2
                }
            catch
                {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                   "Error retrieving CLI for $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Error"   
                }
            if($esxcli)
                {
                "Retrieving system information on $($esx)"  | Write-Log -LogPath $logfile
                try {
                    $esxcli.system.version.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_version.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving system version for $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.system.account.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_accounts.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving user accounts for $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.system.permission.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_permissions.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving permissions for $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.system.module.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_modules.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving modules for $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }      
                try {
                    $esxcli.system.process.list.invoke()  | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_process.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving processes on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }    
                try {
                    $esxcli.system.security.certificatestore.list.invoke()   | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_Certstore.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving certificate store on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                if([system.version]$esxhost.version -ge [system.version]"7.0.2")
                {            
                try {
                    $esxcli.system.settings.encryption.get.invoke()  | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_ExecPolicy.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving execution policy on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                       
                try {
                    $esxcli.system.settings.gueststore.repository.get.invoke()  | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_Guestrepo.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving guest store repository on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                }
                try {
                    #Only non default settings are retrieved https://blogs.vmware.com/vsphere/2012/09/identifying-non-default-advanced-kernel-settings-using-esxcli-5-1.html
                    $esxargs = $esxcli.system.settings.advanced.list.CreateArgs()
                    $esxargs.delta = $true
                    $esxcli.system.settings.advanced.list.invoke($esxargs)  | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_Advanced-Delta.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving advanced system settings on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    #Only non default settings are retrieved https://blogs.vmware.com/vsphere/2012/09/identifying-non-default-advanced-kernel-settings-using-esxcli-5-1.html
                    $esxargs = $esxcli.system.settings.kernel.list.CreateArgs()
                    $esxargs.delta = $true
                    $esxcli.system.settings.kernel.list.invoke($esxargs)  | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_Kernel-Delta.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving advanced system settings on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }


                try {
                    $esxcli.system.syslog.config.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_System_Guestrepo.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving syslog configuration on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                "Retrieving software and storage information on $($esx)"  | Write-Log -LogPath $logfile
                if([system.version]$esxhost.version -ge [system.version]"7.0.0")
                {  
                try {
                    $esxcli.software.vib.signature.verify.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Software_VIBSigCheck.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving VIB signature status on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }

                try {
                    $esxcli.software.baseimage.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Software_Baseimage.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving base image information on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                }
                try {
                    $esxcli.software.vib.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Software_VIB.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving VIBs on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.software.profile.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Software_Profile.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving software profile on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.storage.iofilter.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Storage_IOFilter.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving IO filters on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.storage.filesystem.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Storage_Filesystem.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving file systems on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                "Retrieving network information on $($esx)"  | Write-Log -LogPath $logfile
                try {
                    $esxcli.network.ip.interface.ipv4.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_IPv4.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving IPv4 configuration on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                if($esxhost.NetworkInfo.IPv6Enabled -eq $true)
                {
                try {
                    $esxcli.network.ip.interface.ipv6.get.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_IPv6.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving IPv6 configuration on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                    try {
                    $esxcli.network.ip.route.ipv6.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_IPv6routes.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving IPv6 routes on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                }
                else
                {
                 "IPv6 disabled on $($esx)"  | Write-Log -LogPath $logfile 
                }
                try {
                    $esxcli.network.ip.route.ipv4.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_IPv4routes.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving IPv4 routes on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                
                try {
                    $esxcli.network.ip.neighbor.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_ARPCache.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving ARP cache on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.network.ip.dns.server.list.invoke()  | select-object @{N='DNSServers';E={[string]::join(";",($_.DNSServers))}} | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_DNS.csv"    
          
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving DNS configuration on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.network.ip.connection.list.invoke() | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_Netstat.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving active connections on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }                              
                try {
                    $esxcli.network.vm.list.invoke() | select-object Name, @{N='Networks';E={[string]::join(";",($_.Networks))}}, NumPorts, WorldID | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_VMs.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving virtual machines on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                try {
                    $esxcli.network.vswitch.standard.list.invoke() | select-object Name, CDPStatus, Class, @{N='Portgroups';E={[string]::join(";",($_.Portgroups))}} ,  @{N='Uplinks';E={[string]::join(";",($_.Uplinks))}} , MTU, ConfiguredPorts, NumPorts, UsedPorts, BeaconEnabled, BeaconInterval, BeaconRequiredBy, BeaconThreshold | export-csv -NoTypeInformation -Path "$($foldertoprocess)\ESXi_$($esx)_Network_vSwitchs.csv"                
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Error retrieving virtual switches on $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                    }
                if($ESXBundle -eq $true)
                    {
                    "Creating support bundle for $($esx)"  | Write-Log -LogPath $logfile
                    $supportbundlesfolder = $currentpath + "\Support_Bundles"
                    if ((Test-Path $supportbundlesfolder) -eq $false){New-Item $supportbundlesfolder -Type Directory | out-null }
                    try
                        {
                         $bundle = Get-Log -VMHost $esxhost -Bundle -DestinationPath $supportbundlesfolder -runasync
                        }
                        catch
                        {
                        $ErrorMessage = $_.Exception.Message
                        $FailedItem = $_.Exception.ItemName
                        "Error retrieving hostd log for $($esx) : Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning"    
                        }
                        if($bundle)
                        {
                        "Support bundle for $($esx) created with $($bundle.id) ID"  | Write-Log -LogPath $logfile
                        $nbtasks = (get-task | where-object{($_.State -eq "Running") -or ($_.State -eq "Queued")} | measure-object).count
                        while($nbtasks -ge 4)
                            {
                                start-sleep -seconds 5
                                $nbtasks = (get-task | where-object{($_.State -eq "Running") -or ($_.State -eq "Queued")} | measure-object).count
                                "Four Support bundles being created at the sale time, waiting for one support bundle to complete"  | Write-Log -LogPath $logfile
                            }
                        }

                    

                    }
                else{
                    try
                    {
                    (get-log -VMHost $esxhost hostd).Entries | out-file "$($foldertoprocess)\ESXi_$($esx)_Hostd.log"  -encoding UTF8
                    }
                    catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                     "Error retrieving hostd log for $($esx): Item $($FailedItem) Error message $($ErrorMessage)"  | Write-Log -LogPath $logfile -LogLevel "Warning"   
                    }
                }

                }
                }
            }
        }
        end
        {
        if($ESXBundle -eq $true)
            {   
                
                $currenttask = get-task | where-object{($_.State -eq "Running") -or ($_.State -eq "Queued")}
                if($currenttask)
                    {
                    "Waiting for support bundle to complete..."  | Write-Log -LogPath $logfile
                    write-host "Waiting for support bundle to complete"  
                    while($currenttask)
                            {
				$nbcurrenttask = ($currenttask | measure-object).count
                                "$($nbcurrenttask) support bundles remaining - waiting 30 seconds..."  | Write-Log -LogPath $logfile
                                start-sleep -seconds 30
                                $currenttask= get-task | where-object{($_.State -eq "Running") -or ($_.State -eq "Queued")}
                            }

                    } 
                $taskserror = get-task | where-object{($_.State -eq "Error")}
                if($taskserror)
                    {
                    foreach($taskerr in $taskserror)
                        {
                        
                         "The support budle with task ID $($taskerr.id) started on $($taskerr.starttime) failed"  | Write-Log -LogPath $logfile -LogLevel "Warning" 
                        }
                    } 
                
            }

        "Collection completed"  | Write-Log -LogPath $logfile
        write-host "Done!"
        
        }

}