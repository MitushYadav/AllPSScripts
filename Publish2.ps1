# $RDprdHosts = Get-RDSessionHost -ConnectionBroker PROD481.prod.telenet.be -CollectionName "RD Universal PRD" | Select-Object SessionHost

$TargetRDCollection = "RD ERICSSON TST"

$RDprdHosts = Get-RDSessionHost -ConnectionBroker PROD481.prod.telenet.be -CollectionName $TargetRDCollection | Select-Object SessionHost

$res = @()

ForEach($RDhost in $RDprdHosts) {
  $res += Invoke-Command -ComputerName $RDhost.SessionHost -ScriptBlock { Get-AppvClientPackage -all | Select-Object Name,Path } -ErrorAction SilentlyContinue
  }
  
$PSSessions = @()

ForEach($RDhost in $RDprdHosts) {
  $PSSessions += New-PSSession -ComputerName $RDhost.SessionHost -ErrorAction SilentlyContinue
  }



$Groups = Get-ADGroup -SearchBase 'OU=App-V,OU=Software W7,OU=IT,DC=prod,DC=telenet,DC=be' -filter * | sort-object name | Select-Object -ExpandProperty Name

$AllLoggedOnUsers = Get-RDUserSession -CollectionName $TargetRDCollection -ConnectionBroker "PROD481.prod.telenet.be"

ForEach($rdUser in $AllLoggedOnUsers.UserName) {
  $LoggedOnHost = ($AllLoggedOnUsers | Where-Object UserName -eq $rdUser).HostServer
  ForEach($group in $Groups) {
    if((Get-ADGroupMember -Recursive -Identity $group).name -contains $rdUser) {
      $spGroup = $Group.Split('-')

      $vendor = $spGroup[3]
      $applicationName = $spGroup[4]
    
      $sid = (Get-ADUser $rdUser).SID.Value
      
      $resTarget = $res | Where-Object { $_.Name -like "*$vendor - $applicationName -*" -and $_.PSComputerName -eq $LoggedOnHost }
      $XMLFolder = Split-Path $resTarget.Path
      $XMLPath = $XMLFolder + "\$($resTarget.Name)" + "_UserConfig.XML"
      
      $sid = (Get-ADUser $rdUser).SID.Value
      Function Publish-AppVXML {
        param(
          [string]$AppV5PRDGroup,
          [string]$userSID
        )
        
        $spGroup = $AppV5PRDGroup.Split('-')

        $vendor = $spGroup[3]
        $applicationName = $spGroup[4]
   
        $AppVToPublish = Get-AppvClientPackage -all | Where-Object Name -like "*$vendor - $applicationName -*"
        
        $resTarget = $res | Where-Object { $_.Name -like "*$vendor - $applicationName -*" -and $_.PSComputerName -eq $LoggedOnHost }
        $XMLFolder = Split-Path $resTarget.Path
        $XMLPath = $XMLFolder + "\$($resTarget.Name)" + "_UserConfig.XML"
        
        if((Get-ADGroupMember -Recursive -Identity $group).name -contains $rdUser)
          
      }
    
      Write-Host "Publishing App-V $resTarget.Name for user $rdUser"
      Invoke-Command -Session ( $PSSessions | Where-Object ComputerName -like $resTarget.PSComputerName ) -ScriptBlock { param($x,$y,$z) Publish-AppvClientPackage -UserSID $x -Name $y.Name -DynamicUserConfigurationPath $z } -ArgumentList $sid,$resTarget,$XMLPath 
    }  
    
  }
} 