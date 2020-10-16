#requires -version 4.0
 
#Demo-ServerInventoryXML.ps1
<#
.DESCRIPTION
Create XML using the System.XML.XMLDocument class
General guidelines:
XML structure:

<?xml version="1.0" encoding="utf-8" ?>  => XML declaration
<WindowsPrinterSettings xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> => root node
  <PrinterMappings> => child node of WindowsPrinterSettings
    <PrinterMapping> => child node of PrinterMappings
      <POSPrinterName>Printer1</POSPrinterName> => Element, with innervalue of "Printer1". Elements inherit from nodes.
      <LocalPrinterName>FO01</LocalPrinterName>
    </PrinterMapping>
    <PrinterMapping>
      <POSPrinterName>Printer2</POSPrinterName>
      <LocalPrinterName>BO01</LocalPrinterName>
    </PrinterMapping>
  </PrinterMappings>
</WindowsPrinterSettings>


XML Declaration  => [[[$dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null); $doc.AppendChild($dec) | Out-Null]]]
root node => $root = $doc.CreateNode("element","Computers",$null) ; $<parentNode>.AppendChild($root)*** note that all elements are nodes, but not vice versa
element => $e1 = $doc.CreateElement("POSPrinterName") ; $e1.InnerText = "Printer1" ; $<parentNode>.AppendChild($e1)

The namespace explanation is later in the document

#>
 
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

<#
To create XML schema declarations in the root node, it is best to create the Attribute first, set the value and add it to the node. Eg:
$attr = $doc.CreateAttribute("xmlns:xsd")
$attr.Value = "http://www.w3.org/2001/XMLSchema"
$root.SetAttributeNode($attr)

Other definitions of CreateAttribute create xmlns:xsd and xsd:xmlns attributes. Using NamespaceManager is complicated for this simple example.
#>
 
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