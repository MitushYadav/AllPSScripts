Function Start-CCMRerunAdvertisement {
    
    <#
        .SYNOPSIS
            Restarts an SCCM advertisement on a remote computer.
        .DESCRIPTION
            This script will remotely connect to a computer running the CCM Client,
            find an advertisement by the Advertisement ID or the Package ID (or
            both), and then restart the advertisement.
        .NOTES
            File Name  : Start-CCMRerunAdvertisement.ps1
            Version    : 2017-09-21 (v1.0)
            Author     : Christopher Kibble (www.ChristopherKibble.com)
            Tested     : PowerShell Version 5
        .PARAMETER ComputerName
            The name of the remote computer to connect to.
        .PARAMETER AdvertisementID
            All or part of the Advertisement ID to run.  Wildcards accepted.
            Defaults to *.  Either this or PackageID must be specified.
        .PARAMETER PackageID
            All or part of the Package ID to run.  Wildcards accepted.
            Defaults to *.  Either this or AdvertisementID must be specified.
        .PARAMETER MaxRun
            If more than one advertisement meets your criteria, how many of the
            advertisements to run.  Defaults to 1.
        .PARAMETER MoreThanPing
            In environments where ICMP may not allow pinging a remote computer,
            this switch will make the script attempt to connect to C$ on the remote
            computer in order to determine if it's online.
        .EXAMPLE
            Start-CCMRerunAdvertisement -ComputerName SANDIAGO-001 -AdvertisementID "US000001"
    #>
 
    [CmdLetBinding()]Param(
        [Parameter(Mandatory=$true)][string]$computerName,
        [Parameter(Mandatory=$false)][string]$advertisementId = "*",
        [Parameter(Mandatory=$false)][string]$packageId = "*",
        [Parameter(Mandatory=$false)][int]$maxRun = 1,
        [Parameter(Mandatory=$false)][switch]$moreThanPing = $false
    )
 
    # TODO LIST:
    #
    #    - Better error control when WMI connections fail.
    #    - Are we using the best method to sort when using MaxRun?
    #
 
    if($advertisementId -eq "*" -and $packageId -eq "*") {
        Write-Error "You must supply either an AdvertisementID or a PackageID"
        return "Missing Parameters"
        break
    }
 
    $searchString = "$advertisementId-$packageId-*" 
 
    if(!(Test-Connection -ComputerName $computername -ErrorAction SilentlyContinue)) {
    
        if($moreThanPing) { 
            if(!(Get-ChildItem "\\$computername\c$" -ErrorAction SilentlyContinue)) {
                Write-Error "System Offline"
                Return "System Offline"
                break
            }
        } else {
            Return "System Offline"
            break
        }
 
    }
 
    Write-Verbose "Getting ID of ScheduleMessage on $computername"
 
    $schMsgs = Get-WmiObject -ComputerName $computername -Namespace "root\ccm\policy\machine\actualconfig" -Class CCM_Scheduler_ScheduledMessage
 
    $thisMsg = $schMsgs | ? { $_.ScheduledMessageID -like $searchString } | Sort ActiveTime -Descending | select -First $maxRun
 
    if(!$thisMsg) {
        Write-Verbose "Cannot Find Advertisement/Package on Target Computer"
        Return "Cannot Find Advertisment"
        break
    }
 
    $thisMsg | % {
 
        [xml]$activeMessage = $_.activeMessage
 
        $amProgramId = $activeMessage.SoftwareDeploymentMessage.ProgramID
        $amAdvId = $activeMessage.SoftwareDeploymentMessage.AdvertisementID
        $amPkgId = $activeMessage.SoftwareDeploymentMessage.PackageID
        $ScheduledMessageId = $_.ScheduledMessageId
 
        Write-Verbose  "Restarting $amArogramId (ADV=$amAdvId) (PKG=$amPkgId) for Schedule Message $ScheduledMessageId"
 
        $softwareDist = Get-WmiObject -ComputerName $computername -Namespace "root\ccm\policy\machine\actualconfig" -Class CCM_SoftwareDistribution -Filter "ADV_AdvertisementID = '$amAdvId' and PKG_PackageID = '$amPkgId'"
 
        $original_Rerun = $softwareDist.ADV_RepeatRunBehavior
 
        if($original_Rerun -ne "RerunAlways") {
            write-verbose "Changing Rerun Status from $original_Rerun to RerunAlways"
            $softwareDist.ADV_RepeatRunBehavior = "RerunAlways"
            $softwareDist.put() | Out-Null
        }
 
        Write-Verbose "Triggering Schedule on $computername"
        Invoke-WmiMethod -ComputerName $computername -Namespace "root\ccm" -Class "SMS_CLIENT" -Name TriggerSchedule $ScheduledMessageId | Out-Null
        
        Write-Verbose "Sleeping for 5 seconds"
        Start-Sleep -Seconds 5
 
        if($original_Rerun -ne "RerunAlways") {
            Write-Verbose "Changing Rerun Status back to $original_Rerun"
            $softwareDist.ADV_RepeatRunBehavior = "$original_Rerun"
            $softwareDist.put() | Out-Null
        }
 
        Return "Reran Advertisement"
   
    }
 
}