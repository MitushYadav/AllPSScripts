Function Get-CMAppDeployTestResult {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [int]
        $RequestID,
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationName,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Install", "Uninstall")]
        [string]
        $Method = "Install"
    )

    $Application = Get-CimInstance -ClassName "CCM_Application" -Namespace "root\CCM\ClientSDK" | Where-Object Name -eq $ApplicationName

    $CmdArgs = @{
        Id = $Application.Id
        Revision = $Application.Revision
        IsMachineTarget = $Application.IsMachineTarget #True if device deployment, False if user deployment
        EnforcePreference = [UInt32] 0
        Priority = 'High'
        IsRebootIfNeeded = $false
    }

    $null = Invoke-CimMethod -ClassName "CCM_Application" -Namespace "root\CCM\ClientSDK" -MethodName $Method -Arguments $CmdArgs

    Start-Sleep -Seconds 30 # average time to download and install the application package

    #keep checking the state till it succeeds or fails
    do {
        $Application = Get-CimInstance -ClassName "CCM_Application" -Namespace "root\CCM\ClientSDK" | Where-Object Name -eq $ApplicationName
        if ($Application.EvaluationState -eq 1 -or $Application.EvaluationState -eq 4) {
            $FinalEvalState = $Application.EvaluationState
            break
        }
        Start-Sleep -Seconds 10
    } until ($Application.EvaluationState -eq 1 -or $Application.EvaluationState -eq 4)

    if ($FinalEvalState -eq [UInt32]1) {
        return $true
    }
    else {
        return $false
    }
}
