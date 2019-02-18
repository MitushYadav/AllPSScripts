# $RDprdHosts = Get-RDSessionHost -ConnectionBroker PROD481.prod.telenet.be -CollectionName "RD Universal PRD" | Select-Object SessionHost

$TargetRDCollection = "RD ERICSSON TST"

$RDprdHosts = Get-RDSessionHost -ConnectionBroker PROD481.prod.telenet.be -CollectionName $TargetRDCollection | Select-Object SessionHost

$res = @()

Function Get-CorrectXML {

  $XMLDetails = @()
  $eachdetail = @{}
  
  $AppVData = Get-AppvClientPackage -all
  $locns = 'E:\ccmcache','C:\Windows\ccmcache','C:\Temp'

  ForEach( $appV in $AppVData ) {
    $AppVXMLName = $($appV.Name) + "_UserConfig.XML"
    $XMLFolder = Split-Path $appV.Path
    $XMLPath = $XMLFolder + "\$AppVXMLName"
      
    If(Test-Path $XMLPath ) 
    {
      $correctXMLPath = $XMLPath
      }
    Else {
      ForEach($locn in $locns) {
        If(Test-Path $locn) {
          $testXMLPath = (Get-ChildItem $locn -Recurse | Where Name -like $AppVXMLName).FullName
          If($testXMLPath) {
          $correctXMLPath = $testXMLPath }
          Else { $correctXMLPath = '' } 
        }
      }
    }
    $eachdetail.Name = $AppV.Name
    $eachdetail.Path = $correctXMLPath
    
    $XMLDetails += [PSCustomObject]$eachdetail 
    }
  Return $XMLDetails
  }

ForEach($RDhost in $RDprdHosts) {
  $res += Invoke-Command -ComputerName $RDhost.SessionHost -ScriptBlock ${function:Get-CorrectXML} -ErrorAction SilentlyContinue
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
      $XMLFinalPath = $resTarget.Path
    
      Write-Host "Publishing App-V $($resTarget.Name) for user $rdUser"
      Invoke-Command -Session ( $PSSessions | Where-Object ComputerName -like $($resTarget.PSComputerName) ) -ScriptBlock { param($x,$y,$z) Publish-AppvClientPackage -UserSID $x -Name $y.Name -DynamicUserConfigurationPath $z } -ArgumentList $sid,$resTarget,$XMLFinalPath 
    }  
    
  }
} 