Function Get-UserDeviceLogonInfo {
    <#
    .DESCRIPTION
    check the logon script information to get personal device info
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        [ValidateScript({Test-Path -PathType Container -Path $_})]
        $LogonScriptLogDirectory,
        # Username
        [Parameter(Mandatory=$true)]
        [string]
        $Username
    )

    If(Test-Path -Path "$LogonScriptLogDirectory\$Username.txt" -PathType Leaf) {
        $DeviceName = $(get-content -Path "$LogonScriptLogDirectory\$Username.txt" | ForEach-Object { $PSItem.split(' ')[4] } | Group-Object | Sort-Object -Property Count -Descending | Select-Object -First 1).Name
    }

    return $DeviceName
}