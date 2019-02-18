Function Get-SCCMApplication($name) {
    $smsApp = Get-CMApplication -Name $name
    $currSDMobj = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($smsapp.SDMPackageXML)
    return $currSDMobj
 }

Function Set-SCCMApplication($name, $app) {
    $smsApp = Get-CMApplication -Name $name
    $currSDMXmlNew = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($app)
    $smsApp.SDMPackageXML = $currSDMXmlNew.Replace("Publish=`"true`"","Publish=`"false`"")                                                                            
    Set-CMApplication -InputObject $smsApp | Out-Null
 }

$site = Get-PSDrive -PSProvider CMSite | Select-Object -ExpandProperty Name
$siteDrive = $site + ":"
Set-Location "$siteDrive"

function Copy-SCCMApplication {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Source,
        [Parameter(Position=1)]
        [System.String]
        $Destination = "$Source - NOSHORTCUT"        
    )

    New-CMApplication -Name $Destination | Out-Null
    $oldSDM = (Get-SCCMApplication -name $Source)
    $newSDM = Get-SCCMApplication -name $Destination
    $newSDM.CopyFrom($oldSDM)
    $newSDM.DeploymentTypes.ChangeId()
    $newSDM.Title = $Destination
    Set-SCCMApplication -name $Destination -app $newSDM
    
    #Moving the new application to PRD\RDS-App-V-NOSHORTCUT folder
    Move-CMObject -InputObject (Get-CMApplication -Name $Destination) -FolderPath "PRD:\Application\PRD\RDS-App-V-NOSHORTCUT"  
  }