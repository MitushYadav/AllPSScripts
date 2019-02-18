$verint = get-content C:\workingDir\verint.txt

$final = @()

foreach($pc in $verint) {
  $details = @{}
  $details.PC = $pc
  $details.Status = 'Off'
  If(Test-Connection -ComputerName $pc -Count 1 -Quiet) {
    $details.Status = 'On'
    $details.Config = 'NOK'
    $details.Properties = 'NOK'
    $details.Cert = 'NOK'
    If(Test-Path "\\$pc\c$\Program Files (x86)\Java\jre1.8.0_151\lib\deployment.config") { $details.Config = 'OK' }
    If(Test-Path "\\$pc\c$\Program Files (x86)\Java\jre1.8.0_151\lib\deployment.properties") { $details.Properties = 'OK' }
    If((Get-ChildItem -Path "\\$pc\c$\Program Files (x86)\Java").Count -gt 1) { $details.Multiple = 'Yes' }
    $usr = ((Get-WMIObject -class Win32_ComputerSystem -ComputerName $pc | select username).username).substring(5)
    If(Test-Path "\\$pc\C$\Users\$usr\AppData\LocalLow\Sun\Java\Deployment\security\trusted.certs") { $details.Cert = 'OK' }
    }
  
  $final += [PSCustomObject]$details
  
}