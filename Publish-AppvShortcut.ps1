Function Publish-AppvShortcut {
<# The script takes username and hostname and publishes the appv by using the original userdeployment XML located on the CCMcache 
#>
param(
[string]$userid,
[string]$hostname,
[string]$application
)

$ses = New-PSSession -ComputerName $hostname

try{
$sid = (get-aduser $userid | select SID).SID.Value
}
catch {
Write-Host "Please run this on a computer with Active Directory module installed"
exit
}

$apps = invoke-command -Session $ses -ScriptBlock { param($x) Get-appvclientpackage -name "*$x*" -all } -ArgumentList $application

If ($apps.Count -gt 1) {
Write-Host "Please select which application to publish for user"
$i = 0
foreach($app in $apps) {
Write-Host "$i $($app.Name)"
$i++
}
$choice = Read-Host -Prompt "Enter the serial number of the package"
$pack = $apps[$choice]
}
else { $pack = $apps }

$conf = Read-Host "Are you sure you want to publish $($pack.Name) for user $userid ? y/n"

If ($conf -eq 'y') {

$loc = Invoke-Command -Session $ses -ScriptBlock { param($x) Get-ChildItem E:\ccmcache\*\* -Filter *.xml | where name -like "*$($x.Name)*_UserConfig.xml" } -ArgumentList $pack

If($loc.Count -gt 1) {
$finalLoc = $loc[0]  #can use better logic but this works for now
}

Invoke-Command -Session $ses -ScriptBlock { param($x,$y,$z) Publish-AppvClientPackage -UserSID $x -PackageID $($y.PackageID) -VersionID $($y.VersionID) -DynamicUserConfigurationPath $z.FullName } -ArgumentList $sid,$pack,$finalLoc
Write-Host "Published!"
}

Else { Write-Host "You chose not to confirm" }

Remove-PSSession $ses
}


