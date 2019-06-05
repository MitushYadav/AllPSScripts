#XML Creation
[xml]$CGFile = New-Object System.Xml.XmlDocument

$dec = $CGFile.CreateXmlDeclaration("1.0","UTF-8",$null)
$CGFile.AppendChild($dec)

$AppConnectionGroup = $CGFile.CreateNode("element","AppConnectionGroup",$null)
$AppConnectionGroup.SetAttribute("AppConnectionGroupId",$GroupID)
$AppConnectionGroup.SetAttribute("VersionId",$VersionID)
$AppConnectionGroup.SetAttribute("Priority","0")
$AppConnectionGroup.SetAttribute("DisplayName",$displayName)
$AppConnectionGroup.SetAttribute("xmlns","http://schemas.microsoft.com/appv/2010/virtualapplicationconnectiongroup")

#Packages node
$Packages = $CGFile.CreateNode("element","Packages",$null)

#Package Node 1
$Package1 = $CGFile.CreateNode("element","Package",$null)
$Package1.SetAttribute("PackageId",$Package1PID)
$Package1.SetAttribute("VersionId",$Package1VID)

#Package Node 2
$Package2 = $CGFile.CreateNode("element","Package",$null)
$Package2.SetAttribute("PackageId",$Package2PID)
$Package2.SetAttribute("VersionId",$Package2VID)

$Packages.AppendChild($Package1) | Out-Null
$Packages.AppendChild($Package2) | Out-Null

$AppConnectionGroup.AppendChild($Packages) | Out-Null

$CGFile.AppendChild($AppConnectionGroup) | Out-Null

$CGFile.Save("C:\workingDir\XMLTest.XML")