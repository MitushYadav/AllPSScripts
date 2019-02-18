#Script to be run on each Terminal server individually. It will publish all the assigned apps to all the logged on users.
# MUST BE RUN AS AN ADMINISTRATOR

$invokingHost = hostname



$AllLoggedOnUsers = Get-RDUserSession -ConnectionBroker "PROD481.prod.telenet.be" | Where HostServer -eq "$invokingHost.prod.telenet.be"

Function Get-CorrectXML {
  $XMLDetails = @()
  $eachdetail = @{}
  $AppVData = Get-AppvClientPackage -all
  $locns = 'E:\ccmcache','C:\Windows\ccmcache','C:\Temp','C:\Users\dpoduval\Desktop'

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

  $NameXMLDetails = Get-CorrectXML

  $Groups = Get-ADGroup -SearchBase 'OU=App-V,OU=Software W7,OU=IT,DC=prod,DC=telenet,DC=be' -filter * -Credential $mycreds | sort-object name | Select-Object -ExpandProperty Name

ForEach($user in $AllLoggedOnUsers.Username) {
  $sid = (Get-ADUser $user -Credential $mycreds).SID.Value
  forEach($group in $Groups) {
    #if part of the group
    if((Get-ADGroupMember -Recursive -Identity $group).name -contains $User){
      #connect group to application
      $spGroup = $Group.Split('-')
      $Gvendor = $spGroup[3]
      $GapplicationName = $spGroup[4]

      $ToPublish = $NameXMLDetails | Where Name -like "*$Gvendor - $GapplicationName *"
      
      If($ToPublish -ne $null -and $ToPublish.Length -eq 1) {
        If($ToPublish.Path -ne '' -and $ToPublish.Path -ne $null) {

          Write-Host "Publishing $($ToPublish.Name) for user $user" -ForegroundColor DarkBlue
          Publish-AppvClientPackage -UserSID $sid -Name $($ToPublish.Name) -DynamicUserConfigurationPath $($ToPublish.Path)
        }
      }
      Else { Write-Host "Could not find relevant application data for $Gvendor - $GapplicationName" -ForegroundColor Red }
    }
  }
  }
  