Function AddTo-Path {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $FolderPath,
    [Parameter(Mandatory=$true, ParameterSetName="Position1")]
    [switch]
    $Prefix,
    [Parameter(Mandatory=$true, ParameterSetName="Position2")]
    [switch]
    $Suffix
  )
  
  $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
  
  if($Prefix) { $newPath = "$FolderPath;$oldPath" }
  if($Suffix) { $newPath = "$oldPath;$FolderPath" }
  
  Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}