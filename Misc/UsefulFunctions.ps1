function Write-Log {
    <#
    .SYNOPSIS
    This function writes logging to the packagelog, using a date/time stamp
    
    .DESCRIPTION
    This function writes logging to the log
    
    .PARAMETER message
    None
    
    .EXAMPLE
    Write-RLog "Starting packaging"
    
    .NOTES
    Author: Robin Ramaekers
    Version: 1.0
    #>
    param(
        [String[]] $message
    )
    $time = New-TimeStamp
    $message = $message.split("`n")
    $message | foreach {
        $logstring = "$time - $_"
        Write-Verbose "$logstring"
        if ($LogLocation) {
            Out-File -FilePath "$LogLocation" -NoClobber -Append -InputObject "$logstring"
        }
        start-sleep -Milliseconds 5
    }
}

get-rdusersession -ConnectionBroker prod482.prod.telenet.be -CollectionName "RA Universal PRD" | where UserName -eq "dkomarul" | ForEach-Object { invoke-rduserlogoff -HostServer $PSItem.HostServer -UnifiedSessionID $PSItem.UnifiedSessionId -Force -Verbose } 