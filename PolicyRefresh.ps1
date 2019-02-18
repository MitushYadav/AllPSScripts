Function Refresh-Policy {

    param(
        [string]$ComputerName
    )
    Write-Host "Request & Evaluate User Policy" -ForegroundColor Green
    nvoke-Command -ComputerName $ComputerName -ScriptBlock {
    $CPAppletMgr = New-Object -ComObject "CPApplet.CPAppletmgr"
    $Action = $CPAppletMgr.GetClientActions() | ? {$_.ActionID -eq "{8EF4D77C-8A23-45c8-BEC3-630827704F51}"}
    $Action.PerformAction()
    Sleep 5
    Write-Host 'Global Targetted Policy Refresh' -ForegroundColor Green
    $Action1 = $CPAppletMgr.GetClientActions() | ? {$_.ActionID -eq "{00000000-0000-0000-0000-000000000123}"}
    $Action1.PerformAction()
    }
}