Function Get-CMFolderApplications {

param([string]$FolderName)

$SMSSiteCode = 'CMC'

$SMSSiteServer = 'EWP001704.prod.telenet.be'

$FolderID = (Get-WMIObject -Namespace "ROOT\SMS\Site_$SMSSiteCode" -ComputerName $SMSSiteServer -Query "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name LIKE '$FolderName' AND ObjectType='6000'").ContainerNodeID

$Instancekeys = (Get-WmiObject -Namespace "ROOT\SMS\Site_$SMSSiteCode" -ComputerName $SMSSiteServer -query "select InstanceKey from SMS_ObjectContainerItem where ObjectType='6000' and ContainerNodeID='$FolderID'").instanceKey

foreach ($key in $Instancekeys)
{
(Get-WmiObject -Namespace "ROOT\SMS\Site_$SMSSiteCode" -ComputerName $SMSSiteServer -Query "select LocalizedDisplayName from SMS_Applicationlatest where ModelName = '$key'").LocalizedDisplayName
}

}