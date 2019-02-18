Function Get-ShortcutFromXML {
  param(
    [string]$XMLPath
  )
 
  $AppVParseData = @{
    '[{Start Menu}]'="$Env:AppData\Microsoft\Windows\Start Menu"
    '[{Programs}]'="$Env:AppData\Microsoft\Windows\Start Menu\Programs"
    '[{Common Programs}]'="C:\ProgramData\Microsoft\Windows\Start Menu\Programs"
  }
  
  $XMLData = [xml](Get-Content -Path $XMLPath)

  If($XMLData.DeploymentConfiguration.UserConfiguration.Subsystems.Shortcuts.Enabled)
  {
    $LNKLocation = $XMLData.DeploymentConfiguration.UserConfiguration.Subsystems.Shortcuts.Extensions.Extension.Shortcut.File
    
    $AppVParseData.GetEnumerator() | ForEach-Object {
        $LNKLocation = $LNKLocation.Replace($_.key,$_.value)
      }
    return $LNKLocation
    }
 
}
