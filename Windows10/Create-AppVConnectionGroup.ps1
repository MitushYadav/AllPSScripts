Import-Module AnyBox

# build the AnyBox
$CGBox = New-Object AnyBox.AnyBox

$CGBox.Title = "ConnectionGroupTester"
$CGBox.Message = "Enter the PackageID and VersionID of the AppVs to create Connection Group of"

$CGBox.Prompts = @(
    New-AnyBoxPrompt -Name "CGName" -Message "Connection Group Name"
    New-AnyBoxPrompt -Name "P1PID" -Message "Package 1: PackageID"
    New-AnyBoxPrompt -Name "P1VID" -Message "Package 1: VersionID"
    New-AnyBoxPrompt -Name "P2PID" -Message "Package 2: PackageID"
    New-AnyBoxPrompt -Name "P2VID" -Message "Package 2: VersionID"
    New-AnyBoxPrompt -Name "Global" -Message "Visibility" -ValidateSet "Global","Local"
)

$CGBox.Buttons = @(
    New-AnyBoxButton -Name "Create" -Text "Create!"
)

$response = $CGBox | Show-AnyBox
$displayName = $response['CGName']
$Package1PID = $response['P1PID']
$Package1VID = $response['P1VID']
$Package2PID = $response['P2PID']
$Package2VID = $response['P2VID']
#$CGBox = Show-AnyBox -Title "ConnectionGroupTester" -Message "Enter the PackageID and VersionID of the AppVs to create Connection Group of" -Prompts "Package 1: PackageID","Package 1: VersionID","Package 2: PackageID","Package 2: VersionID" -Buttons "Create!"

$CGguid = [GUID]::NewGuid()
$CGvid = [GUID]::NewGuid() 

#XML Creation
[xml]$CGFile = New-Object System.Xml.XmlDocument

$dec = $CGFile.CreateXmlDeclaration("1.0","UTF-8",$null)
$CGFile.AppendChild($dec)

$AppConnectionGroup = $CGFile.CreateNode("element","AppConnectionGroup",$null)
$AppConnectionGroup.SetAttribute("AppConnectionGroupId",$CGguid)
$AppConnectionGroup.SetAttribute("VersionId",$CGvid)
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

#save the file. can make it a selectable location
$CGFile.Save("C:\workingDir\XMLTest.XML")

#enable the connection group
If($response['Global'] -eq 'Global') {
    Add-AppvClientConnectionGroup -Path "C:\workingDir\XMLTest.XML" | Enable-AppvClientConnectionGroup -Global
}
else {
    Add-AppvClientConnectionGroup -Path "C:\workingDir\XMLTest.XML" | Enable-AppvClientConnectionGroup
}