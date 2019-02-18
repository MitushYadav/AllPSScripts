Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

Add-Type -Path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.dll"

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
$ApplicationName = "AVI - C - Apache - JMeter - 3.2 (1.0) - NOSHORTCUT"
$App = Get-CMApplication -Name "$ApplicationName"
	
$AppXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($app.SDMPackageXML)

$DeploymentTypeName = "$ApplicationName"
	
$AppXML.DeploymentTypes[0].Requirements.Add($newrule)
$app.SDMPackageXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::Serialize($AppXML)
$app.Put() | Out-Null
