

$rootpath = #!!!specify path here

$vendors = get-childitem -path $rootpath

foreach($vend in $vendors) {
  $apps = get-childitem $($vend.FullName)
  foreach($app in $apps) {
    $versions = get-childitem $($app.FullName)
    If($versions[0].Name -notlike "*SRC*") {
    If($versions.Count -gt 1) {
      New-Item "$rootpath\$($vend.Name)\$($app.Name)\2.SRC" -ItemType Directory
      foreach($ver in $versions) {
        Move-item -Path "$rootpath\$($vend.Name)\$($app.Name)\$($ver.Name)\2.SRC\*" -Destination "$rootpath\$($vend.Name)\$($app.Name)\2.SRC\$($ver.Name)" -Verbose
      }
    } 
    else {
      foreach($ver in $versions) {
        Rename-Item -Path "$rootpath\$($vend.Name)\$($app.Name)\$($ver.Name)" -NewName "$rootpath\$($vend.Name)\$($app.Name)\2.SRC" -Verbose
        Rename-Item -Path "$rootpath\$($vend.Name)\$($app.Name)\2.SRC\2.SRC" -NewName "$rootpath\$($vend.Name)\$($app.Name)\2.SRC\$($ver.Name)" -Verbose
      }
      }
    }
  }
}
        