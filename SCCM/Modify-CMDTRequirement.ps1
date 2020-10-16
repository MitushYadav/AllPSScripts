# Remove Windows 7 Requiremment and Add windows 2012 r2

Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

Add-Type -Path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.dll"

# Windows/All_x64_Windows_Server_2012_R2

$site = Get-PSDrive -PSProvider CMSite | Select-Object -ExpandProperty Name
$siteDrive = $site + ":"
Set-Location "$siteDrive"           

$ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
$pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Other

$GlobalCondition = "OperatingSystem"

$operator = "OneOf"

$Value = "Windows/All_x64_Windows_Server_2012_R2"

$ExpressionOperator = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator

$Annotation = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation
$Annotation.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList @("DisplayName", "$GlobalCondition $operator $Value", $null)

$ExpressionBase.Add($Value)
$expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList @($ExpressionOperator, $ExpressionBase)


$newRule = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule -ArgumentList @("$($GlobalCondition)Rule_$([Guid]::NewGuid().ToString())", [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $Annotation, $expression)

# ApplicationName needs to be passed here
$ApplicationList = Get-Content "C:\workingDir\fix.txt"

ForEach ($ApplicationName in $ApplicationList) {
$App1 = Get-CMApplication -Name "$ApplicationName"
	
$App1XML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($App1.SDMPackageXML)

if ($App1XML.DeploymentTypes.Length -gt 1) {
for ($i=0; $i -lt $App1XML.DeploymentTypes.Length; $i++) {
$App1XML.DeploymentTypes[$i].Requirements.Remove()
}
}
	
$App1XML.DeploymentTypes[0].Requirements.Add($newrule)
$App1.SDMPackageXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Serialize($App1XML)
$App1.Put() | Out-Null
}