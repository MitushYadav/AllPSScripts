#get logged on users for each server and publish

$AllLoggedOnUsers = Get-RDUserSession -CollectionName "RD Universal PRD","RD ERICSSON TST","RD Universal TST" -ConnectionBroker "PROD481.prod.telenet.be"

$hostServers = $AllLoggedOnUsers.HostServer | Select-Object -unique

Function Publish-AppVXML {

  param(
  [string]$user,
  [string]

  $AllAppV = Get-AppvClientPackage -all

  $spGroup = $Group.Split('-')

      $vendor = $spGroup[3]
      $applicationName = $spGroup[4]

      #get the latest application version and AppV Version
      $GroupAppV = Get-AppvClientPackage -Name "*$vendor - $applicationName*" -all

      Foreach($appv in $GroupAppV) {
        #get XML Location
        $appvFolderPath = Split-Path $appv.Path
        $XMLPath = (Get-ChildItem $appvFolderPath | Where-Object Name -Like "*UserConfig.XML").FullName

        #Publish AppV
        Publish-AppvClientPackage -Package $appv -UserSID $sid -DynamicUserConfigurationPath $XMLPath | Out-Null
  }

ForEach($server in $hostServers) {
  $a = New-PSSession -ComputerName "VPC07755","VPC07759"
  }

ForEach($user in $AllLoggedOnUsers.UserName) {
  $sid = (Get-ADUser $user).SID
  
  $Groups = Get-ADGroup -SearchBase 'OU=App-V,OU=Software W7,OU=IT,DC=prod,DC=telenet,DC=be' -filter * | sort-object name | Select-Object -ExpandProperty Name

  Invoke-Command 
  
   }