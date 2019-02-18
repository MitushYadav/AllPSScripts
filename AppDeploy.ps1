Import-module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

Set-Location prd:

$apps = Get-Content C:\workingDir\prod609.txt

foreach($app in $apps) {

Start-CMApplicationDeployment -Name $app -CollectionName "UAT - DCO - PROD609" -DeployAction Install -DeployPurpose Required

}