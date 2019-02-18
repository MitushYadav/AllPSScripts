Function Get-CorrectXML {

  $XMLDetails = @()
  $eachdetail = @{}
  
  $AppVData = Get-AppvClientPackage -all
  
  <#  
      #part to consider only the latest version and build. Exceptions to be handled manually, or later as a script feature
      $AppvFinalList = @()
      $AppvInterimList = @()
      $eachAppV = @{}
  
      $AppVData = Get-AppvClientPackage -all
  
      # foreach($AppVObject in $AppVData) {
      #if name contains hyphens
      If(([regex]::Matches($AppVObject.Name, "-")).Count -eq 2) {
      $spNames = $AppVObject.Name.Split('-')
      $eachAppV.Vendor = $spNames[0].Trim()
      $eachAppV.AppName = $spNames[1].Trim()
      $eachAppV.AppVersion = $spNames[2].Trim().Split(' ')[0].Trim()
      $eachAppV.AppBuild = $spNames[2].Trim().Split(' ')[1].Trim().Substring(1,3)
      }

      $AppvInterimList += [PSCustomObject]$eachAppV
    
      # if two apps have the same vendor and application, check app version and build number
  
      $AppvVInterim2 = $AppvInterimList | Select-Object Vendor, AppName | Group-Object -NoElement | ForEach-Object { $h = @{} } { $h[$_.Name] = $_.Count } { $h } 

      ForEach($item in $AppvVInterim2) {
      if($item.Value -gt 1) {
      #split the Name into values
      item 
      

      ForEach( $inItem in $AppvInterimList ) {
      If($inItem.Vendor
  
      #####################
  #>

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