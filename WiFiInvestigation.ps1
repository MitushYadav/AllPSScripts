$all7250 = Get-Content -Path "C:\workingDir\E7250.txt"
$fails = Get-Content -Path "C:\workingDir\fail.txt"
#$all7250 = "PPC08157","PPC08177"
$pcdata = @()

Function Get-WifiInvestigationData {

  $hn = hostname

  $wmio = Get-WmiObject -Class Win32_NetworkAdapter -Filter { Name LIKE '%7265' }
  $driverinfo = Get-WmiObject -Class Win32_SystemDriver -Filter "Name = '$($wmio.ServiceName)'"
  $bios = Get-WmiObject -Class Win32_BIOS
  $dinfo = Get-ItemProperty -Path $($driverinfo.Pathname)
  $gp = Get-ItemProperty -Path "C:\Program Files\Palo Alto Networks\GlobalProtect\PanGPA.exe"
  $ac = Get-ItemProperty -Path "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnagent.exe"
  If($hn -in $fails) { $failure = 'Y' } else { $failure = 'N' }
  
  $data = @{
    PnPDeviceID = $wmio.PNPDeviceID
    ServiceName = $wmio.ServiceName
    DriverVersion = $dinfo.VersionInfo.FileVersion
    BIOS = $bios.Version
    GlobalProtect = $gp.VersionInfo.ProductVersion
    AnyConnect = $ac.VersionInfo.ProductVersion
    ComputerName = $hn
    Failure = $failure
  }
  
  return $data

}

ForEach($pc in $all7250) {

  If(Test-Connection -ComputerName $pc -Count 1 -Quiet) {

  $newdata = Invoke-Command -ComputerName $pc -ScriptBlock ${Function:Get-WifiInvestigationData} -ErrorAction SilentlyContinue
  
  $pcdata += [PSCustomObject]$newdata

  }
  }
  
  $pcdata | format-table