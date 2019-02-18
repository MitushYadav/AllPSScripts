# script to publish shortcuts
$user= [Environment]::UserName
Write-Host "Running script for user: $user"

Write-Host "Getting All AppV Packages" -ForegroundColor Green
$AllAppV = Get-AppvClientPackage -all

Write-Host "Getting AD Groups for AppV" -ForegroundColor Green
$Groups = Get-ADGroup -SearchBase 'OU=App-V,OU=Software W7,OU=IT,DC=prod,DC=telenet,DC=be' -filter * | sort-object name | Select-Object -ExpandProperty Name

foreach ($Group in $Groups)
{
  if($member = (Get-ADGroupMember -Recursive -Identity $group).name -contains $user) {
    $spGroup = $Group.Split('-')
    #check if application name contains hyphens
    If($spGroup.Length -gt 5) {
      #logic to try all combinations of check against the appv name
      }
    $vendor = $spGroup[3]
    $applicationName = $spGroup[4]

    #get the latest application version and AppV Version
    $GroupAppV = Get-AppvClientPackage -Name "*$vendor - $applicationName*" -all

    If($GroupAppV.Length -gt 1) {
      #multiple AppV with same vendor - application name. Ingoring this as current deployment scenario adds only the required application versions
      }

    Foreach($appv in $GroupAppV) {
       #get XML Location
       $appvFolderPath = Split-Path $appv.Path
       $XMLPath = (Get-ChildItem $appvFolderPath | Where-Object Name -Like "*UserConfig.XML").FullName

       #Publish AppV
       Write-Host "$user is a member of $group, publishing application $($appv.Name)"
       Publish-AppvClientPackage -Package $appv -DynamicUserConfigurationPath $XMLPath | Out-Null
    }
  }
  else {
    Write-Host "$user is not a member of $group"
  }
}