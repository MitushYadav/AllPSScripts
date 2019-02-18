$ComputerName = 'PANFT'
#Enter-PSSession -ComputerName $ComputerName

<# The general format is
    0
    1   Ready information for interface Mobile Broadband Connection: 
    2    -------------------------------------
    3    State            : Ready to power up and register
    4    Emergency mode   : Off
    5    Subscriber Id    : 206050003270271
    6    SIM ICC Id       : 8941010000012702713
    7    Number of telephone numbers  : 0
    8
#>

<#$sb = {
  $properties = 'Name', 'SubscriberId', 'SIMIccId', 'NumberTelNos', 'Telephone#1', 'Telephone#2', 'Telephone#3'
  $result = '' | Select-Object -Property $properties
  & netsh.exe mbn show interface | ForEach-Object {
    $key, $value = $_.Split(':', 2) | ForEach-Object {$_.Trim()}
    If ($properties -contains $key) {
      $result.$key = $value
    }
  }
  $result
}
$SIMCardInfo  = Invoke-Command $sb
#>

$cmnd = & netsh mbn sh read i=*

$intInfo = @{}

$intInfo.Name = & hostname
$intInfo.SubscriberID = $cmnd[5].split(':',2)[1].Trim()
$intInfo.SIMIccID = $cmnd[6].split(':',2)[1].Trim()
$intInfo.NumberOfTelNos = $cmnd[7].split(':',2)[1].Trim()

#add logic so that the final trim is not performed on null data

If($intInfo.NumberOfTelNos -gt 0) {
  for($i=1;$i -le $intInfo.NumberOfTelNos;$i++) {
    $intInfo.(Telephone$i) = $cmnd[7+$i]
  }
}

#Check if broadbandclass exists, if not write data into a wmi class (which then can be inventories by SCCM, then queried)
#Get-WmiObject -Class mobilebroadband -Namespace root\cimv2

$CimInstance = (Get-CimInstance -ClassName MobileBroadband2)
if ($CimInstance) {  $CimInstance | Remove-CimInstance}

function New-Broadband2class{

  $newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null); 

  $newClass["__CLASS"] = "MobileBroadband2"; 
  
  
  $newClass.Qualifiers.Add("Static", $true)

  $newClass.Properties.Add("DeviceID",[System.Management.CimType]::String, $false)
  $newClass.Properties["DeviceID"].Qualifiers.Add("Key", $true)  
  
  $newClass.Qualifiers.Add("Static", $true)
  
  $newClass.Properties.Add("Name",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("SubscriberID",[System.Management.CimType]::String, $false)

  $newClass.Properties.Add("SIMIccID",[System.Management.CimType]::String, $false)

  $newClass.Properties.Add("NumberOfTelNos",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("Telephone1",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("Telephone2",[System.Management.CimType]::String, $false)

  $newClass.Properties.Add("Telephone3",[System.Management.CimType]::String, $false)
    
  $newClass.Put()

}
New-Broadband2class

New-CimInstance -ClassName MobileBroadband2 -Property @{



  Name="$($($intInfo.Name).trim())";

  SubscriberID="$($($intInfo.SubscriberID).trim())";

  SIMIccID="$($($intInfo.SIMIccID).trim())";
     
  NumberOfTelNos ="$($($intInfo.NumberOfTelNos).trim())";
          
  Telephone1="$($($intInfo.Telephone1).trim())";
     
  Telephone2 ="$($($intInfo.Telephone2).trim())";
     
  Telephone3 ="$($($intInfo.Telephone3).trim())"
  
}
