#requires -version 4.0
 
#Demo-ServerInventoryXML.ps1
 
Param($Path="C:\WorkingDir\MyInventory.xml")
 
Write-Host "Creating computer list" -ForegroundColor Green
#process list of computers filtering out those offline
$computers = Get-Content C:\workingdir\myservers.txt | Where { Test-WSMan $_ -ErrorAction SilentlyContinue}
 
Write-Host "Getting Operating System information" -ForegroundColor Green
$os = Get-CimInstance Win32_Operatingsystem -ComputerName $computers |
Select @{Name="Computername";Expression={$_.PSComputername}},InstallDate,
Caption,Version,OSArchitecture
 
Write-Host "Getting Computer system information" -ForegroundColor Green
$cs = Get-Ciminstance Win32_Computersystem -ComputerName $computers | 
Select PSComputername,TotalPhysicalMemory,HyperVisorPresent,NumberOfProcessors,
NumberofLogicalProcessors 
 
Write-Host "Getting Services" -ForegroundColor Green
$services = Get-Ciminstance Win32_Service -ComputerName $computers |
Select PSComputername,Name,Displayname,StartMode,State,StartName
 
Write-Host "Initializing new XML document" -ForegroundColor Green
[xml]$Doc = New-Object System.Xml.XmlDocument
 
#create declaration
$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
#append to document
$doc.AppendChild($dec) | Out-Null
 
#create a comment and append it in one line
$text = @"
 
Server Inventory Report
Generated $(Get-Date)
v1.0
 
"@
 
$doc.AppendChild($doc.CreateComment($text)) | Out-Null
 
#create root Node
$root = $doc.CreateNode("element","Computers",$null)
 
#create a node for each computer
foreach ($computer in $Computers) {
 
 Write-Host "Adding inventory information for $computer" -ForegroundColor Green
 $c = $doc.CreateNode("element","Computer",$null)
 #add an attribute for the name
 $c.SetAttribute("Name",$computer) | Out-Null
 
 #create node for OS
 Write-Host "...OS" -ForegroundColor Green
 $osnode = $doc.CreateNode("element","OperatingSystem",$null)
 
 #get related data
 $data = $os | where({$_.computername -eq $Computer})
 
 #create an element
 $e = $doc.CreateElement("Name")
 #assign a value
 $e.InnerText = $data.Caption
 $osnode.AppendChild($e) | Out-Null
 
 #create elements for the remaining properties
 "Version","InstallDate","OSArchitecture" | foreach {
    $e = $doc.CreateElement($_)
    $e.InnerText = $data.$_
    $osnode.AppendChild($e) | Out-Null
 }
 
 #add to parent node
 $c.AppendChild($osnode) | Out-Null
 
 #create node for Computer system
 Write-Host "...ComputerSystem" -ForegroundColor Green
 $csnode = $doc.CreateNode("element","ComputerSystem",$null)
 #this is using the original property name
 
 $data = $cs | where({$_.pscomputername -eq $Computer})
 
 #get a list of properties except PSComputername
 $props = ($cs[0] | Get-Member -MemberType Properties | where Name -ne 'PSComputername').Name
 
 #create elements for each property
 $props | Foreach {
    $e = $doc.CreateElement($_)
    $e.InnerText = $data.$_
    $csnode.AppendChild($e) | Out-Null
 }
 
 #add to parent
 $c.AppendChild($csnode) | Out-Null
 
 #create node for services
 Write-Host "...Services" -ForegroundColor green
 $svcnode = $doc.CreateNode("element","Services",$null)
 
 #get a list of properties except PSComputername
 $props = ($services[0] | Get-Member -MemberType Properties | where Name -ne 'PSComputername').Name
 
 $data = $services.where({$_.pscomputername -eq $Computer})
 foreach ($item in $data) {
     #create a service node
     $s = $doc.CreateNode("element","Service",$null)
 
     #create elements for each property
     $props | Foreach {
        $e = $doc.CreateElement($_)
        $e.InnerText = $item.$_
        $s.AppendChild($e) | Out-Null
     }
 
     #add to parent
     $svcnode.AppendChild($s) | Out-Null
 }
 
 #add to grandparent
 $c.AppendChild($svcnode) | Out-Null
 
 #append to root
 $root.AppendChild($c) | Out-Null
} #foreach computer
 
#add root to the document
$doc.AppendChild($root) | Out-Null
 
#save file
Write-Host "Saving the XML document to $Path" -ForegroundColor Green
$doc.save($Path)
 
Write-Host "Finished!" -ForegroundColor green