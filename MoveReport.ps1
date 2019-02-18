$rootloc = "\\prod.telenet.be\adm\WSAAS\Software Deployment\Packages"

$vendors = Get-ChildItem -Path $rootloc

$final = @()

foreach($vend in $vendors) {
  $apps = get-childitem $($vend.FullName)
  foreach($app in $apps) {
    try { 
      $chi = Get-ChildItem "$($app.FullName)\2.SRC"
      foreach($ver in $chi) {
        $details = @{}
        $details.Vendor = $vend.Name
        $details.Application = $app.Name
        $details.Version = $ver.Name
        $tst = Get-ChildItem $($ver.FullName)
        If($tst.Count -gt 1) { $details.SRCPopulated = 'Yes'}
        else { $details.SRCPopulated = 'No' }
        $final += $details
      }
    }
    catch {
    Write-Host "Not-okay for $vend $app $ver" }
  }
}
       