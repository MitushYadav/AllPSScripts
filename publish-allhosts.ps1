Function Publish-AppvShortcutOnAllHosts {
  
  param(
    [string]$userid,
    [string]$application
    )

  $sid = (get-aduser $userid | Select-Object -Property SID).SID.Value
 
  # $PSses = New-PSSession -ComputerName PROD608,PROD609,PROD610,PROD611,EWP001231,EWP001232,EWP001233,EWP001234
  
  invoke-command -ComputerName PROD609 -ScriptBlock { param($x,$y) $appvpack = (get-appvclientpackage *$y* -all) ; Publish-AppvClientPackage -UserSID $x -Name $($appvpack.Name) -Verbose } -ArgumentList $sid,$application
  
  # Remove-PSSession -Session $PSses
     
     # ; Publish-AppvClientPackage -UserSID $x -Name $($appvpack.Name) -DynamicUserConfigurationPath $($appvpack.Path.Remove($appvpack.Path.Length-5) + '_UserConfig.xml')
  }