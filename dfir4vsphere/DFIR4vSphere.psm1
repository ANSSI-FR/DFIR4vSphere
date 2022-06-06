Function Write-Log {

    Param 
    ( 
        [Parameter(Mandatory=$true, 
        ValueFromPipeline = $true)] 
        [ValidateNotNullOrEmpty()] 
        [string]$Message, 
 
        [Parameter(Mandatory=$true)] 
        [Alias('LogPath')] 
        [string]$Path, 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warning","Info")] 
        [Alias('LogLevel')] 
        [string]$Level="Info" 

    ) 

    $logtime = "{0:yyyy-MM-dd} {0:HH:mm:ss}" -f (get-date) + ","

    switch ($Level) { 
        'Error' { 
            $LevelText = 'ERROR,' 
            } 
        'Warning' { 
            $LevelText = 'WARNING,' 
            } 
        'Info' { 
            $LevelText = 'INFO,' 
            } 
        }
     
    "$logtime $LevelText $Message" | Out-File -FilePath $Path -Append -Encoding UTF8
}


Function Test-VCconnection {

    Param 
    ( 
        [Parameter(Mandatory = $false)]
        [String]$logfile = "Start-VC_Investigation.log"

    ) 

    $connection = $global:defaultviserver

    if($connection.Productline -eq "vpx")
    {
        
        "Connected to VCenter $($connection.version). Connection URI is $($connection.ServiceUri.AbsoluteUri)" | Write-Log -LogPath $logfile
        return $true
    }
    elseif($connection.Productline -eq "embeddedEsx" -or $connection.Productline -eq "esx")
    {
        "Connected to ESX hypervisor, please connect to the VCenter." | Write-Log -LogPath $logfile -LogLevel "Error" 
        return $false
    }
    else
    {
        "No active VCenter connection found." | Write-Log -LogPath $logfile -LogLevel "Error" 
        return $false

    }
    
    }

    Function Get-VIEventPlus {
<#   
.SYNOPSIS  Returns vSphere events    
.DESCRIPTION The function will return vSphere events runs faster than the original Get-VIEvent cmdlet. 
.NOTES  Author:  Luc Dekens @LucD22 - The original function is here https://www.lucd.info/2013/03/31/get-the-vmotionsvmotion-history/ 
#>
        Param 
        (         
        
            [Parameter(Mandatory = $true)]
            [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entities,
            [Parameter(Mandatory = $true)]
            [VMware.Vim.ViewBase[]]$eventMgr,
            [Parameter(Mandatory=$true)]
            [DateTime]$Enddate,
            [Parameter(Mandatory=$true)]
            [DateTime]$StartDate,
            [Parameter(Mandatory=$false)]
            [string[]]$EventTypeId
        )

            $eventnumber = 100
            $events = @()
            $eventFilter = New-Object VMware.Vim.EventFilterSpec
            $eventFilter.disableFullMessage = $false
            $eventFilter.entity = New-Object VMware.Vim.EventFilterSpecByEntity
            $eventFilter.entity.recursion = "all"
            if($EventTypeId)
                {
                $eventFilter.eventTypeId = $EventTypeId
                }
            $eventFilter.time = New-Object VMware.Vim.EventFilterSpecByTime
            $eventFilter.time.beginTime = $StartDate
            $eventFilter.time.endTime = $Enddate
            
            foreach($Entity in $Entities)
            {
                $eventFilter.entity.entity = $Entity.ExtensionData.MoRef
                try
                    {
                    $eventCollector = Get-View ($eventMgr.CreateCollectorForEvents($eventFilter))
                    }
                catch
                    {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    "Falied to fetch events from EventManager: Item $($FailedItem) Error message $($ErrorMessage)" | Write-Log -LogPath $logfile -LogLevel "Warning"  
                   
                    }
                $eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
                while($eventsBuffer)
                {
                    $events += $eventsBuffer
                    $eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
                }
                $eventCollector.DestroyCollector()  
            }    
        return $events
    }