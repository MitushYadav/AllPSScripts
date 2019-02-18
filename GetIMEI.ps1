# $ComputerName = 'PANFT'
# Enter-PSSession -ComputerName $ComputerName

# $ComputerName = 'panft'

  $properties = 'Name', 'Description', 'GUID', 'Physical Address', 'State', 'Device type', 'Cellular class', 'Device Id', 'Manufacturer', 'Model', 'Firmware Version', 'Provider Name', 'Roaming', 'Signal'
  $result = '' | Select-Object -Property $properties
  & netsh.exe mbn show interface | ForEach-Object {
    $key, $value = $_.Split(':', 2) | ForEach-Object {$_.Trim()}
    If ($properties -contains $key) {
      $result.$key = $value
    }
  }


# $SIMCardInfo  = Invoke-Command $sb


#Check if broadbandclass exists, if not write data into a wmi class (which then can be inventories by SCCM, then queried)
#Get-WmiObject -Class mobilebroadband -Namespace root\cimv2

$CimInstance = (Get-CimInstance -ClassName MobileBroadband)
if ($CimInstance) {  $CimInstance | Remove-CimInstance}

function New-Broadbandclass{

  $newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null); 

  $newClass["__CLASS"] = "MobileBroadband"; 
  
  
  $newClass.Qualifiers.Add("Static", $true)

  $newClass.Properties.Add("DeviceID",[System.Management.CimType]::String, $false)
  $newClass.Properties["DeviceID"].Qualifiers.Add("Key", $true)  
  
  $newClass.Qualifiers.Add("Static", $true)
  
  $newClass.Properties.Add("PhysicalAddress",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("Name",[System.Management.CimType]::String, $false)

  $newClass.Properties.Add("Description",[System.Management.CimType]::String, $false)

  $newClass.Properties.Add("GUID",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("State",[System.Management.CimType]::String, $false)
  
  
  $newClass.Properties.Add("DeviceType",[System.Management.CimType]::String, $false)

  $newClass.Properties.Add("CellularClass",[System.Management.CimType]::String, $false)

    
  
  $newClass.Properties.Add("Manufacturer",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("Model",[System.Management.CimType]::String, $false)
  
  $newClass.Properties.Add("FirmwareVersion",[System.Management.CimType]::String, $false)
  
  
  $newClass.Properties.Add("Roaming",[System.Management.CimType]::String, $false)
    
  $newClass.Put()

}
New-Broadbandclass

New-CimInstance -ClassName MobileBroadband -Property @{



  Name="$($($SIMCardInfo.Name).trim())";

  Description="$($($SIMCardInfo.Description).trim())";

  GUID="$($($SIMCardInfo.GUID).trim())";
     
  PhysicalAddress ="$($($SIMCardInfo.'Physical Address').trim())";
          
  State="$($($SIMCardInfo.State).trim())";
     
  DeviceType ="$($($SIMCardInfo.'Device type').trim())";
     
  CellularClass ="$($($SIMCardInfo.'Cellular class').trim())";
     
  DeviceId = "$($($SIMCardInfo.'Device Id').trim())";
     
  Manufacturer="$($($SIMCardInfo.Manufacturer).trim())";
     
  Model ="$($($SIMCardInfo.Model).trim())";
  
  FirmwareVersion ="$($($SIMCardInfo.'Firmware Version').trim())";  
  
  Roaming ="$($($SIMCardInfo.'Roaming').trim())";    
   
  
}
