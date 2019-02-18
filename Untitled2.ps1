
Function Test-RegValue {

    Param(
    [string]$regValue,
    [string]$keyName
        )

    $flag = $false

    try {
    If(Test-Path $regValue) {
        Get-ItemProperty $regValue -Name $keyName -ErrorAction Stop
        $flag = $true
        }
        }

    catch {
        
        }
            
    return $flag
}


Function Get-UninstallString {

# defining parameters

    Param(
    [string]$appName
        )

    
    $item = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Name

    ForEach ($guid in $item) {
        If (Test-RegValue -regValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid" -keyName "DisplayName") {
  
 

        $names = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid" -Name DisplayName).DisplayName

        ForEach ($name in $names) {
            If ($name -match $appName) {
                # to get the corresponding UninstallString value
                # select -property @{name='App';expression={ $name }}, (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid" -Name UninstallString).UninstallString
                Write-host $name, (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid" -Name UninstallString).UninstallString -Separator " : "
                }
                }
            }
        }
    }
