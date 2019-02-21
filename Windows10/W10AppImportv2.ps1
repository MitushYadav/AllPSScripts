Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

Add-Type -Path "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\Microsoft.ConfigurationManagement.ApplicationManagement.dll"

# Example: \\prod.telenet.be\adm\WSAAS\software deployment\Packages\Allround\PLSQLDeveloper\3.PKG\11.0.3\1.0\APPV
# => \\prod.telenet.be\adm\WSAAS\software deployment\Packages\<Vendor>\<Application>\3.PKG\<Version>\<build>\APPV

Function New-MYApplication {
    param(
        [parameter(Mandatory=$true)]
        [string]$SourcePath
#        [parameter(Mandatory=$true)]
#        [ValidateSet("Application","App-V")]
#        [string]$Type
        )

    #Set sidecode
    $SiteCode = 'CMC'

    #Extract data from Path variable
    $splitPath = $SourcePath.Replace('\\','').Split('\')
    $Vendor = $splitPath[5]
    $Application = $splitPath[6]
    $AppVersion = $splitPath[8]
    $BuildNumber = $splitPath[9]
    $AppType = $splitPath[10]

    If($AppType -eq "APPV") {
    #Get AppV file FullName
    $AppVFilePath = (Get-ChildItem $SourcePath -Filter *.appv).FullName
        }

    #Create CM Rule
    $ExpressionBase = new-object "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
    $pdDataType = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.DataType]::Other

    $GlobalCondition = "OperatingSystem"

    $operator = "OneOf"

    $Value = "Windows/All_x64_Windows_10_and_higher_Clients"

    $ExpressionOperator = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::$operator

    $Annotation = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation
    $Annotation.DisplayName = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList @("DisplayName", "$GlobalCondition $operator $Value", $null)

    $ExpressionBase.Add($Value)
    $expression = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList @($ExpressionOperator, $ExpressionBase)


    $newRule = new-object Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule -ArgumentList @("$($GlobalCondition)Rule_$([Guid]::NewGuid().ToString())", [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None, $Annotation, $expression)

    
    # Create application in SCCM

    $internalAppName = "$Vendor - $Application - $AppVersion ($BuildNumber)"

    Push-Location "$($SiteCode):\"

    If($AppType -eq 'APPV') {
        New-CMApplication -Name "AVI - $internalAppName" -Publisher $Vendor -SoftwareVersion $AppVersion -SupportContact "itservicedesk" -LocalizedName $internalAppName
        Add-CMAppv5XDeploymentType -DeploymentTypeName "$internalAppName - W10" -ApplicationName "AVI - $internalAppName" -ContentLocation $AppVFilePath -FastNetworkDeploymentMode Download -SlowNetworkDeploymentMode DoNothing -AddRequirement $newRule

        }
    If($AppType -eq 'MSI') {
        New-CMApplication -Name "ALO - $internalAppName" -Publisher $Vendor -SoftwareVersion $AppVersion -SupportContact "itservicedesk" -LocalizedName $internalAppName
        Add-CMDeploymentType -DeploymentTypeName "$internalAppName - W10" -ApplicationName "ALO - $internalAppName" -ContentLocation $SourcePath -ScriptInstaller -InstallationProgram "Deploy-Application.exe" -UninstallProgram "`"Deploy-Application.exe`" -DeploymentType `"Uninstall`"" -AddRequirement $newRule -DetectDeploymentTypeByCustomScript -ScriptType PowerShell -ScriptContent "#Dummy"
        }


    Pop-Location

    }
