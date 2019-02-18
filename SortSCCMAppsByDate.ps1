Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

$sitecode = (Get-PSDrive -PSProvider CMSite).Name
Set-Location "$($sitecode):"

Get-CMApplication -Fast | where DateCreated -lt ((Get-Date).AddMonths(-6))