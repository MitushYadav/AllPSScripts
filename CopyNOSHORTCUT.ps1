#Script to Copy the computer type AVI - C AppV applications, set deployment type rule to Windows 7 SP1 x64 and move the application to the required folder

#To be added: Handling file names to point to the correct application

#Import required modules and assemblies

Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

Add-Type -Path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.dll"

# 1 Copy the Application

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
        $Source         
    )

    $Destination = "$Source - NOSHORTCUT"

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

#read contents on TXT file
$AVICapps = Get-Content "C:\workingDir\FinalList.txt"

  ForEach ($avic in $AVICapps) {

  $modavic = "AVI - C - $avic"
  
  # this copies the application
  Copy-SCCMApplication -Source $modavic

  # 2 set deployment type

$ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
$pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Other

$GlobalCondition = "OperatingSystem"

$operator = "OneOf"

$Value = "Windows/x64_Windows_7_SP1"

$ExpressionOperator = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator

$Annotation = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation
$Annotation.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList @("DisplayName", "$GlobalCondition $operator $Value", $null)

$ExpressionBase.Add($Value)
$expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList @($ExpressionOperator, $ExpressionBase)


$newRule = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule -ArgumentList @("$($GlobalCondition)Rule_$([Guid]::NewGuid().ToString())", [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $Annotation, $expression)

# ApplicationName needs to be passed here
$ApplicationName = "$modavic - NOSHORTCUT"
$App1 = Get-CMApplication -Name "$ApplicationName"
	
$App1XML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($App1.SDMPackageXML)

for ($i=0; $i -lt $App1XML.DeploymentTypes.Length; $i++) {
$App1XML.DeploymentTypes[$i].Requirements.Remove()
}
	
$App1XML.DeploymentTypes[0].Requirements.Add($newrule)
$App1.SDMPackageXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Serialize($App1XML)
$App1.Put() | Out-Null

}