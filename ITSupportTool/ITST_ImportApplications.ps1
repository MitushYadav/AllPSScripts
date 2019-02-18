Import-Module -Name 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'

#if (test-path "$PsScriptRoot\Deploy-Software-Variables.ps1") {. "$PsScriptRoot\Deploy-Software-Variables.ps1"}

#. "$PsScriptRoot\Deploy-Software-Functions.ps1"

<#    
    .SYNOPSIS
    
    .DESCRIPTION

    This script enables you to deploy Software to collections by means of SCCM.
   
    .PARAMETER
    
    .EXAMPLE
    Deploy-CMSoftware -SoftwareType AppV -Path \\avppvpackageshare\CheckPoint\SmartConsole\R62\1.0\5.PKG\ -OptionAppV PackagesOnly
    
    .NOTES
    
#>


########################################  EXECUTION POLICY  ####################
#Set-ExecutionPolicy, needed to be able to load variables from 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\SCCMVariables\, otherwise message "script is not signed"
Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope Process -Confirm:$false -Force 
Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope CurrentUser -Confirm:$false -Force
########################################  GENERAL VARIABLES  ####################
#$VerbosePreference = "Continue" = Verbose Logging for all Commands
$VerbosePreference = 'SilentlyContinue'
$CurrentDate = Get-Date
#cmdlet SCCM 2012 issue, thereofre warnings in darkblue (to check)
#-script doesn't work with latest cmdlets, version 5.0.8249.1128-
#$a = (Get-Host).PrivateData
#$a.WarningForegroundColor = 'DarkBlue'

#Load CMDeployLogFile to monitor deployment
#& $CMDeployLogFile
<#Testvariables:
    $Publisher = "Checkpoint"
    $AppName = "SmartConsole"
    $AppVersion = "R70"
    $PackageVersionOnDFS = "1.0"
    Get-SCCMVariables
#>


#TO ADD WRITE-OUTPUT IN EACH FUNCTION SO OUTPUT WILL CONTAIN CORRECT INFO
# $result = add-sbcm...
#THEN YOU CAN HAVE IN PS STUDIO: out-richtextbox $result


#region FUNCTIONS
Write-Host "Loading Functions" -ForegroundColor Green

#region copy AppV to one withoutshortcut

$AppVPackageWithoutShorCutFolderPath = "$($SCCMSiteCode01 + ':')\Application\$SCCMSiteCode01\RDS-App-V-NOSHORTCUT"
Function Get-SCCMApplication($name) {
    $smsApp = Get-CMApplication -Name $name
    $currSDMobj = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($smsapp.SDMPackageXML)
    return $currSDMobj
}

Function Set-SCCMApplication($name, $app) {
    $smsApp = Get-CMApplication -Name $name
    $currSDMXmlNew = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($app)
    #Set all publishing components to False
    $smsApp.SDMPackageXML = $currSDMXmlNew.Replace("Publish=`"true`"","Publish=`"false`"")                                                                            
    Set-CMApplication -InputObject $smsApp | Out-Null
}

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
    
    #Moving the new application to SiteCode\RDS-App-V-NOSHORTCUT folder
    Move-CMObject -InputObject (Get-CMApplication -Name $Destination) -FolderPath $CMNewApplicationFolderPath
  } 
#endregion

########################################  CREATE AD GROUPS ####################
#APP-V
Function New-SBCMADGroupAppVUsers
{
  if (!(Get-ADGroup -filter {Name -eq $ADMainAppVGroup})){
    Write-Output "Creating APPV AD Group Users $ADMainAppVGroup" 
    New-ADGroup -name $ADMainAppVGroup -groupscope Global -path $CMOUPathAppV  
  }
  else {Write-Output "$ADMainAppVGroup already exists"}
}
Function New-SBCMADGroupAppVComputers
{
  Write-Host -Object "Creating AppV AD-Group Computers Tipos $ADAppVGroupTipos" 
  New-ADGroup -name $ADAppVGroupTipos -groupscope Global -path $CMOUPathComputers  
}
#APPLICATION/PACKAGE
Function New-SBCMADGroupApplicationPackage
{
  Write-Host -Object "Creating AD Group Application $ADMainApplicationGroup" -ForegroundColor Magenta
  New-ADGroup $ADMainApplicationGroup -GroupScope Global -Path $OuPathApplication
}
Function Add-SBCMADGroupTiposToAppV
{
  Write-Host -Object "Adding $ADAppVGroupTipos to $ADMainApplicationGroup" -ForegroundColor Magenta
  Add-ADGroupMember $ADAppVGroupTipos $ADMainApplicationGroup -Confirm 
}
######################################## CREATE APP-V PACKAGES ####################
Function New-SBCMAppVUsers 
{ 
  Write-Host -Object "Creating $FullAppVNameUsers" -ForegroundColor Magenta
  New-CMApplication -Name $FullAppVNameUsers -Description $Description -SoftwareVersion $AppVersion -Publisher $Publisher -ReleaseDate $Date -Owner $Owner -SupportContact $CMSoftwareSupportContact -ErrorAction Inquire
}
Function New-SBCMAppVUsersDTWKX 
{ 
  Write-Host -Object "Creating Deployment Type $DeploymentTypeNameWKX" -ForegroundColor Magenta
  Add-CMDeploymentType -ApplicationName $FullAppVNameUsers -DeploymentTypeName $DeploymentTypeNameWKX -AppV5xInstaller -InstallationFileLocation  $InstallFileLocation -AutoIdentifyFromInstallationFile  -ForceForUnknownPublisher $true -AddRequirement $oDTRuleWKX
  # Write-Verbose "Set to App-V Client dependency NO AUTOMATIC INSTALL RDS 'https://support.microsoft.com/en-us/kb/3031717'" 
  #Get-CMDeploymentType -ApplicationName $FullAppVNameUsers -DeploymentTypeName $DeploymentTypeNameWKX |New-CMDeploymentTypeDependencyGroup -GroupName "App-V Client" |Add-CMDeploymentTypeDependency -DeploymentTypeDependency (Get-CMDeploymentType -ApplicationName "ALO - Microsoft App-V Client 5.0-SP3") -IsAutoInstall $false 
  Write-Host -Object "Content Distribution of $FullAppVNameUsers" -ForegroundColor Magenta
  Start-CMContentDistribution -ApplicationName $FullAppVNameUsers -DistributionPointGroupName $CMDistributionPointGroupName 
}
Function New-SBCMAppVComputers
{
  Write-Host -Object "Creating $FullAppVNameComputers" -ForegroundColor Magenta
  New-CMApplication -Name $FullAppVNameComputers -Description $Description -SoftwareVersion $AppVersion -Publisher $Publisher -ReleaseDate $Date -Owner $Owner -SupportContact $CMSoftwareSupportContact 
  
  #Copy to App-V package without shorcut, used by RDS deploys
  Copy-SCCMApplication -Source $FullAppVNameComputers
}
Function New-SBCMAppVComputersDTW7 
{
  Write-Host -Object "Adding Deployment Type $DeploymentTypeNameW7 to $FullAppVNameComputers" -ForegroundColor Magenta
  Add-CMDeploymentType -ApplicationName $FullAppVNameComputers  -DeploymentTypeName $DeploymentTypeNameW7 -AppV5xInstaller -InstallationFileLocation $InstallFileLocation -ForceForUnknownPublisher $true #-AddRequirement $oDTRuleW7

  #Write-Host "Set to AUTOMATICALLY install App-V Client for W7, https://support.microsoft.com/en-us/kb/3031717" -ForegroundColor Magenta
  #Get-CMDeploymentType -ApplicationName $FullAppVNameComputers -DeploymentTypeName $DeploymentTypeNameW7 | New-CMDeploymentTypeDependencyGroup -GroupName "App-V Client" | Add-CMDeploymentTypeDependency -DeploymentTypeDependency (Get-CMDeploymentType -ApplicationName "ALO - Microsoft App-V Client 5.0-SP3") -IsAutoInstall $true
    
  Write-Host -Object "Distributing $FullAppVNameComputers to $CMDistributionPointGroupName"  -ForegroundColor Magenta
  Start-CMContentDistribution -ApplicationName $FullAppVNameComputers -DistributionPointGroupName $CMDistributionPointGroupName 
}
########################################  CREATE APPLICATION ####################
Function New-SBCMApplication 
{
  Write-Host -Object "Creating $FullApplicationName" -ForegroundColor Magenta
  $null = New-CMApplication -Name $FullApplicationName -Description $Description -Publisher $Publisher -ReleaseDate $Date -Owner $Owner -SupportContact $CMSoftwareSupportContact
}
Function Add-SBCMApplicationDeploymentTypeW7 
{ 
  Write-Host -Object "Adding $StandardProgramNameW7 to $FullApplicationName, DETECTION METHOD TO ADAPT SINCE IT IS DUMMY PS SCRIPT BY DEFAULT" -ForegroundColor Magenta
    
  ##Detection method based upon INS framework: $(Get-ItemProperty 'HKLM:\SOFTWARE\ins\Packages\log\Adobe Acrobat Reader 11 EN\1.0').status
  #if (HKLM:\SOFTWARE\ins\Packages\log\ + ($Publisher $AppName $AppVersion)Split(' ')[0..3]\$PackageVersion).status -eq 'installed' {Write-Host "installed" Exit 0 } else {Clear-Host Exit 0}
  #Approach: $ini2 = Get-Content "C:\Program Files (x86)\ImageNow6\imagenow.ini" If ($ini2 -match "image02.xxx.xxx") {Write-Host "installed" Exit 0 } Else {Clear-Host Exit 0} https://www.windows-noob.com/forums/topic/13018-cant-get-powershell-detection-method-to-work/
    
  Add-CMDeploymentType  -ApplicationName $FullApplicationName  -DeploymentTypeName $StandardProgramNameW7  -ScriptInstaller -LogonRequirementType WhereOrNotUserLoggedOn -AdministratorComment $Description -InstallationProgram  'Package.wsf //Job:Install /mode:Silent' -UninstallProgram 'Package.wsf //Job:UnInstall /mode:Silent' -ContentLocation $PackagePath -DetectDeploymentTypeByCustomScript -ScriptType Powershell -ScriptContent 'Dummy' -RunScriptAs32BitProcessOn64BitClient $false -ManualSpecifyDeploymentType -InstallationBehaviorType InstallForSystem -InstallationProgramVisibility $RunType -AddRequirement $oDTRuleW7 
  #To adapt, if $NewDeploymentTypeName -neq $FullApplicantionName then ...
  Set-CMDeploymentType -ApplicationName $FullApplicationName -DeploymentTypeName ' - Script Installer' -NewDeploymentTypeName $StandardProgramNameW7
  Write-Host -Object 'DETECTION METHOD TO ADAPT SINCE IT IS DUMMY PS SCRIPT BY DEFAULT' -ForegroundColor Magenta
}
Function Add-SBCMApplicationDeploymentTypeWKX
{
  Write-Host -Object "Adding $StandardProgramNameWKX to $FullApplicationName, DETECTION METHOD TO ADAPT SINCE IT IS DUMMY PS SCRIPT BY DEFAULT" -ForegroundColor Magenta
  Add-CMDeploymentType -ApplicationName $FullApplicationName -DeploymentTypeName $StandardProgramNameWKX -ScriptInstaller -LogonRequirementType WhereOrNotUserLoggedOn  -AdministratorComment $Description -InstallationProgram  'Package.wsf //Job:Install /mode:Silent' -UninstallProgram 'Package.wsf //Job:UnInstall /mode:Silent' -ContentLocation $PackagePath -DetectDeploymentTypeByCustomScript -ScriptType Powershell -ScriptContent 'Dummy' -RunScriptAs32BitProcessOn64BitClient $false -ManualSpecifyDeploymentType -InstallationBehaviorType InstallForSystem -InstallationProgramVisibility $RunType -AddRequirement $oDTRuleWKX    
  Write-Host -Object 'DETECTION METHOD TO ADAPT SINCE IT IS DUMMY PS SCRIPT BY DEFAULT' -ForegroundColor Magenta
}   
Function Start-SBCMApplicationDistribution
{
  Write-Host -Object "Distributing $FullApplicationName to $CMDistributionPointGroupName" -ForegroundColor Magenta
  Start-CMContentDistribution -ApplicationName $FullApplicationName -DistributionPointGroupName $CMDistributionPointGroupName 
}

####################################### CREATE PACKAGE ####################
#Note: datasource W7 +  requirements W7 is not set
Function New-SBCMPackage
{
  Write-Host -Object "Creating and Distributing $PackageName" -ForegroundColor Magenta
  New-CMPackage -Name $PackageName -Manufacturer $Publisher -Version $AppVersion -Description $Description -Path $PackagePath
  New-CMProgram -PackageName $PackageName -StandardProgramName $StandardProgramName -CommandLine 'Package.wsf //Job:Install /mode:Silent' -UserInteraction $true -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn -RunType $RunType
  Start-CMContentDistribution -PackageName $PackageName -DistributionPointGroupName $CMDistributionPointGroupName
  Write-Host -Object 'DATASOURCE W7 +  REQUIREMENT W7 IS NOT SET BY DEFAULT, ADAPT IF NEEDED' -ForegroundColor Magenta
}
######################################## CREATE COLLECTIONS (AND QUERIES FOR APPLICATIONS/PACKAGES) ####################
Function New-SBCMAppVCollection
{
  Write-Host -Object 'Creating APPV USER Collections' -ForegroundColor Magenta
  New-CMUserCollection -Name $UserCollectionNameAppVPRDINSTALL -LimitingCollectionName $CMLimitingCollectionUsers -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (Get-Date) -RecurInterval Minutes -RecurCount 20) 
  #New-CMUserCollection -Name $UserCollectionNameAppVPRDINSTALLED -LimitingCollectionName $CMLimitingCollectionUsers -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 
  #New-CMUserCollection -Name $CMUserCollectionNameAppVPRDUNINSTALL -LimitingCollectionName $CMLimitingCollectionUsers -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 
  Write-Host -Object 'Creating APPV COMPUTER Collections' -ForegroundColor Magenta
  New-CMDeviceCollection -Name $DeviceCollectionNameAppVINSTALL -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (Get-Date) -RecurInterval Minutes -RecurCount 20) 
  #New-CMDeviceCollection -name $DeviceCollectionNameAppVINSTALLED -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 
  #New-CMDeviceCollection -name $CMDeviceCollectionNameAppVUNINSTALL -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 
}
Function New-SBCMApplicationCollection
{
  Write-Host -Object "Creating Application COMPUTER Collection for $DeviceCollectionNameApplicationINSTALL" -ForegroundColor Magenta
  New-CMDeviceCollection -Name $DeviceCollectionNameApplicationINSTALL -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (Get-Date) -RecurInterval Minutes -RecurCount 20) 
  Write-Host -Object "Add CollectionMembershipRule to COMPUTER $DeviceCollectionNameApplicationINSTALL Collection" -ForegroundColor Magenta
  Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameAD -CollectionName $DeviceCollectionNameApplicationINSTALL -QueryExpression $QueryDevicesApplicationsInstall
  <# INSTALLED/UNINSTALL COLLECTIONS
      Write-Host "Creating Application COMPUTER Collection for $DeviceCollectionNameApplicationINSTALLED" -ForegroundColor Magenta
      New-CMDeviceCollection -name $DeviceCollectionNameApplicationINSTALLED -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 
      Write-Host "Add CollectionMembershipRule to COMPUTER $DeviceCollectionNameApplicationINSTALLED Collection" -ForegroundColor Magenta
      Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameQuery -CollectionName $DeviceCollectionNameApplicationINSTALLED -QueryExpression $QueryDevicesApplicationsInstalled

      Write-Host "Creating Application COMPUTER Collection for $CMDeviceCollectionNameApplicationUNINSTALL" -ForegroundColor Magenta
      New-CMDeviceCollection -name $CMDeviceCollectionNameApplicationUNINSTALL -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 
      Write-Host "Add CollectionMembershipRule to COMPUTER $CMDeviceCollectionNameApplicationUNINSTALL Collection" -ForegroundColor Magenta
      Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $CMDeviceCollectionNameApplicationUNINSTALL  -ExcludeCollectionName $DeviceCollectionNameApplicationINSTALL 
      Add-CMDeviceCollectionIncludeMembershipRule -CollectionName $CMDeviceCollectionNameApplicationUNINSTALL -IncludeCollectionName $DeviceCollectionNameApplicationINSTALLED 
  #>
}
Function New-SBCMPackageCollection
{
  Write-Host -Object "Creating Application COMPUTER Collection for $DeviceCollectionNamePackage" -ForegroundColor Magenta
  New-CMDeviceCollection -Name $DeviceCollectionNamePackage -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (Get-Date) -RecurInterval Minutes -RecurCount 20) 
  Write-Host -Object "Add CollectionMembershipRule to COMPUTER $DeviceCollectionNamePackage Collection" -ForegroundColor Magenta
  Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameAD -CollectionName $DeviceCollectionNamePackage -QueryExpression $QueryDevicesApplications
}
######################################## CREATE (APP-V) QUERIES FOR COLLECTIONS ####################
Function New-SBCMAppVCollectionQueries
{
  [CmdletBinding()] 
  param
  ([Parameter()]$Option
  )      


  # Add-CMDeviceCollectionQueryMembershipRule -RuleName "ComputerNamesEndingOn $ComputerNamesEndingOn" -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[0]'"          

  if ($Option -eq 'ComputersEven')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections FOR EVEN COMPUTERS ONLY' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName EvenComputers -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevicesEvenInstall
    <#Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameQuery -CollectionName $DeviceCollectionNameAppVINSTALLED -QueryExpression $QueryDevicesInstalled  
        Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $CMDeviceCollectionNameAppVUNINSTALL  -ExcludeCollectionName $DeviceCollectionNameAppVINSTALL 
        Add-CMDeviceCollectionIncludeMembershipRule -CollectionName $CMDeviceCollectionNameAppVUNINSTALL -IncludeCollectionName $DeviceCollectionNameAppVINSTALLED
    #>
  }
  if ($Option -eq 'ComputersOdd')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections FOR ODD COMPUTERS ONLY' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName OddComputers -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevicesOddInstall
  }
  if ($Option -eq 'ComputersEndingOn-0')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections for ComputersEndingOn-0' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName ComputersEndingOn-0 -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevices0Install
  }

  if ($Option -eq 'ComputersEndingOn-1-2')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections for ComputersEndingOn-1-2' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName ComputersEndingOn-1-2 -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevices1to2Install
  }
  if ($Option -eq 'ComputersEndingOn-3-5')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections for ComputersEndingOn-3-5' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName ComputersEndingOn-3-5 -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevices3to5Install
  }
  if ($Option -eq 'ComputersEndingOn-6-9')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections for ComputersEndingOn-6-9' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName ComputersEndingOn-6-9 -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevices6to9Install
  }

  if ($Option -eq 'ComputersAll')
  {  
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections ONLY' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameAD -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevicesInstall 
    <#Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameQuery -CollectionName $DeviceCollectionNameAppVINSTALLED -QueryExpression $QueryDevicesInstalled  
        Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $CMDeviceCollectionNameAppVUNINSTALL  -ExcludeCollectionName $DeviceCollectionNameAppVINSTALL 
        Add-CMDeviceCollectionIncludeMembershipRule -CollectionName $CMDeviceCollectionNameAppVUNINSTALL -IncludeCollectionName $DeviceCollectionNameAppVINSTALLED 
    #>
  }
  if ($Option -eq 'UsersAll')
  {  
    Write-Host -Object 'Add CollectionMembershipRules USER Collections ONLY' -ForegroundColor Magenta 
    Add-CMUserCollectionQueryMembershipRule -CollectionName $UserCollectionNameAppVPRDINSTALL -RuleName $RuleNameAD -QueryExpression $QueryUsersInstall 
    <#Add-CMUserCollectionQueryMembershipRule -CollectionName $UserCollectionNameAppVPRDINSTALLED -RuleName $RulenameQuery -QueryExpression $QueryUsersInstalled  
        Add-CMUserCollectionExcludeMembershipRule -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -ExcludeCollectionName $UserCollectionNameAppVPRDINSTALL 
        Add-CMUserCollectionIncludeMembershipRule -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -IncludeCollectionName $UserCollectionNameAppVPRDINSTALLED 
    #>
  }   
  if ($Option -eq 'ComputersAndUsersAll')
  {
    Write-Host -Object 'Add CollectionMembershipRules USER Collections' -ForegroundColor Magenta 
    Add-CMUserCollectionQueryMembershipRule -CollectionName $UserCollectionNameAppVPRDINSTALL -RuleName $RuleNameAD -QueryExpression $QueryUsersInstall 
    <#Add-CMUserCollectionQueryMembershipRule -CollectionName $UserCollectionNameAppVPRDINSTALLED -RuleName $RulenameQuery -QueryExpression $QueryUsersInstalled  
        Add-CMUserCollectionExcludeMembershipRule -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -ExcludeCollectionName $UserCollectionNameAppVPRDINSTALL 
        Add-CMUserCollectionIncludeMembershipRule -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -IncludeCollectionName $UserCollectionNameAppVPRDINSTALLED
    #>
    
    Write-Host -Object 'Add CollectionMembershipRules COMPUTER Collections' -ForegroundColor Magenta
    Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameAD -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression $QueryDevicesInstall 
    <#Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameQuery -CollectionName $DeviceCollectionNameAppVINSTALLED -QueryExpression $QueryDevicesInstalled  
        Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $CMDeviceCollectionNameAppVUNINSTALL  -ExcludeCollectionName $DeviceCollectionNameAppVINSTALL 
        Add-CMDeviceCollectionIncludeMembershipRule -CollectionName $CMDeviceCollectionNameAppVUNINSTALL -IncludeCollectionName $DeviceCollectionNameAppVINSTALLED 
    #>
  }
}#End Function
######################################## CREATE DEPLOYMENTS ####################
Function New-SBCMAppVDeployment 
{
  <#
      .INFO
      ! AvailableDate, AvailableTime, DeadLineDate, DealLineTime is depcrecated and should be changed to AvailableDateTime and DeadLineDateTime
  #>
  Write-Host -Object "Deploy APP-V to users $SCCMSiteCode01 INSTALL"
  #OLD Start-CMApplicationDeployment -CollectionName $UserCollectionNameAppVPRDINSTALL -Name $FullAppVNameUsers -DeployPurpose $CMDeployPurpose -DeployAction Install -UserNotification DisplayAll -DeadlineDate $DeadlineDate -DeadlineTime $DeadlineTime -AvailableDate $AvailableDate -AvailableTime $AvailableTime -TimeBaseOn LocalTime 
  Start-CMApplicationDeployment -CollectionName $UserCollectionNameAppVPRDINSTALL -Name $FullAppVNameUsers -DeployPurpose $CMDeployPurpose -DeployAction Install -UserNotification DisplayAll -DeadlineDateTime  "$DeadlineDate,$DeadlineTime" -AvailableDateTime "$AvailableDate,$AvailableTime" -TimeBaseOn LocalTime

  <#23/11/'17 WE WILL NOT UNINSTALL AUTOMATICALLY ANYMORE
      Write-Host -Object 'Deploy APP-V to users PRD UNINSTALL' -ForegroundColor Magenta
      #OLD Start-CMApplicationDeployment -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -Name $FullAppVNameUsers -DeployPurpose $CMDeployPurpose -DeployAction Uninstall -UserNotification HideAll -DeadlineDate $DeadlineDate -DeadlineTime $DeadlineTime -AvailableDate $AvailableDate -AvailableTime $AvailableTime -TimeBaseOn LocalTime 
      Start-CMApplicationDeployment -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -Name $FullAppVNameUsers -DeployPurpose $CMDeployPurpose -DeployAction Uninstall -UserNotification HideAll -DeadlineDateTime "$DeadlineDate,$DeadlineTime" -AvailableDateTime "$AvailableDate,$AvailableTime" -TimeBaseOn LocalTime
  #>

  Write-Host -Object "Deploy APP-V to COMPUTERS $SCCMSiteCode01 INSTALL" -ForegroundColor Magenta
  Start-CMApplicationDeployment -CollectionName $DeviceCollectionNameAppVINSTALL -Name $FullAppVNameComputers -DeployPurpose $CMDeployPurpose -DeployAction Install -UserNotification DisplayAll -DeadlineDateTime "$DeadlineDate,$DeadlineTime" -AvailableDateTime "$AvailableDate,$AvailableTime" -TimeBaseOn LocalTime

  <# 23/11/'17 WE WILL NOT UNINSTALL AUTOMATICALLY ANYMORE
      Write-Host -Object 'Deploy APP-V ASAP to COMPUTERS SiteCode UNINSTALL' -ForegroundColor Magenta
      Start-CMApplicationDeployment -CollectionName $CMDeviceCollectionNameAppVUNINSTALL -Name $FullAppVNameComputers -DeployPurpose $CMDeployPurpose -DeployAction Uninstall -UserNotification HideAll -DeadlineDateTime "$DeadlineDate,$DeadlineTime" -AvailableDateTime "$AvailableDate,$AvailableTime" -TimeBaseOn LocalTime
  #>
}
<#EXAMPLE: Start-CMApplicationDeployment -CollectionName "All Users" -Name "7zip" -AvaliableDate 2012/10/1 -AvaliableTime 12:45 -Comment "test" -DeadlineDate 2013/10/23 -DeadlineTime 21:12 -DeployAction Uninstall -EnableMom
   Alert $True -FailParameterValue 40 -OverrideServiceWindow $True -PersistOnWriteFilterDevice $False -PostponeDate 2014/2/8 -PostponeTime 11:11 -PreDeploy $True -RaiseMomAlertsOnFailure $True -RebootOutsideServiceWindow $
    True -SendWakeUpPacket $True -SuccessParameterValue 30 -UseMeteredNetwork $True -UserNotification DisplaySoftwareCenterOnly
#>  
Function New-SBCMApplicationDeployment
{
  <#
      .INFO
      ! AvailableDate, AvailableTime, DeadLineDate, DealLineTime is depcrecated and should be changed to AvailableDateTime and DeadLineDateTime
  #>
  Write-Host -Object "Deploy Application $FullApplicationName $SCCMSiteCode01 INSTALL" -ForegroundColor Magenta
  Start-CMApplicationDeployment -CollectionName $DeviceCollectionNameApplicationINSTALL -Name $FullApplicationName -DeployPurpose $CMDeployPurpose -DeployAction Install -UserNotification DisplayAll -DeadlineDateTime  "$DeadlineDate,$DeadlineTime"  -AvailableDateTime "$AvailableDate,$AvailableTime" -TimeBaseOn LocalTime
  #23/11/'17 no uninstalls anymore
  #Start-CMApplicationDeployment -CollectionName $CMDeviceCollectionNameApplicationUNINSTALL -Name $FullApplicationName -DeployPurpose $CMDeployPurpose -DeployAction Uninstall -UserNotification HideAll -DeadlineDateTime  "$DeadlineDate,$DeadlineTime" -AvailableDateTime "$AvailableDate,$AvailableTime" -TimeBaseOn LocalTime
}
######################################## MOVE OBJECTS IN SCCM CONSOLE  ####################
Function Move-SBCMAppVPackages
{
  Write-Host -Object "Moving Packages in SCCM Console to $SCCMSiteCode01\NEW" -ForegroundColor Magenta
  $Application = Get-CMApplication -Name $FullAppVNameUsers
  Move-CMObject  -FolderPath "$($SCCMSiteCode01 + ':')\Application\$CMNewApplicationFolderPath" -ObjectId $Application.ModelName -ErrorAction Ignore
  $Application = Get-CMApplication -Name $FullAppVNameComputers
  Move-CMObject -FolderPath "$($SCCMSiteCode01 + ':')\Application\$CMNewApplicationFolderPath" -ObjectId $Application.ModelName -ErrorAction Ignore
}
Function Move-SBCMAppVCollections
{
  Write-Host -Object 'Moving COMPUTER App-V Collections in SCCM Console' -ForegroundColor Magenta
  $CMCollection = Get-CMDeviceCollection -Name $DeviceCollectionNameAppVINSTALL
  Move-CMObject -FolderPath "$($SCCMSiteCode01 + ':')\DeviceCollection\$CMNewApplicationCollectionFolderPath" -InputObject $CMCollection -ErrorAction Ignore
        
  <# INSTALLED/UNINSTALL COLLECTIONS
      $CMCollection = Get-CMDeviceCollection -Name $DeviceCollectionNameAppVINSTALLED
      Move-CMObject -FolderPath "PRD:\DeviceCollection\PRD\Software\W7-App-V\NEW" -InputObject $CMCollection
      $CMCollection = Get-CMDeviceCollection -Name $CMDeviceCollectionNameAppVUNINSTALL
      Move-CMObject -FolderPath "PRD:\DeviceCollection\PRD\Software\W7-App-V\NEW" -InputObject $CMCollection
  #>
   
  Write-Host -Object "Moving USERS App-V Collections in SCCM Console to $SCCMSiteCode01\NEW" -ForegroundColor Magenta
  $CMCollection = Get-CMUserCollection -Name $UserCollectionNameAppVPRDINSTALL 
  Move-CMObject -FolderPath "$($SCCMSiteCode01 + ':')\UserCollection\$CMNewApplicationCollectionFolderPath" -InputObject $CMCollection -ErrorAction Ignore
  <# INSTALLED/UNINSTALL COLLECTIONS
      $CMCollection = Get-CMUserCollection -Name $UserCollectionNameAppVPRDINSTALLED 
      Move-CMObject -FolderPath "PRD:\UserCollection\PRD\App-V\NEW" -InputObject $CMCollection
      $CMCollection = Get-CMUserCollection -Name $CMUserCollectionNameAppVPRDUNINSTALL 
      Move-CMObject -FolderPath "PRD:\UserCollection\PRD\App-V\NEW" -InputObject $CMCollection
  #>
}
Function Move-SBCMApplicationCollection
{
  Write-Host -Object 'Moving COMPUTER Application Collections in SCCM Console' -ForegroundColor Magenta
  $CMCollection = Get-CMDeviceCollection -Name $DeviceCollectionNameApplicationINSTALL
  
  if (!$CMNewApplicationCollectionFolderPath ) {Write-output 'Variable $CMNewApplicationFolderPath is not defined'}
  Move-CMObject -FolderPath "$($SCCMSiteCode01 + ':')\DeviceCollection\$CMNewApplicationCollectionFolderPath " -InputObject $CMCollection
  <# INSTALLED/UNINSTALL COLLECTION
      $CMCollection = Get-CMDeviceCollection -Name $DeviceCollectionNameApplicationINSTALLED
      Move-CMObject -FolderPath "PRD:\DeviceCollection\PRD\Software\W7-Applications\NEW" -InputObject $CMCollection
      $CMCollection = Get-CMDeviceCollection -Name $CMDeviceCollectionNameApplicationUNINSTALL
      Move-CMObject -FolderPath "PRD:\DeviceCollection\PRD\Software\W7-Applications\NEW" -InputObject $CMCollection
  #>
}
Function Move-SBCMApplication
{
  Write-Host -Object "Moving Application in SCCM Console to $SCCMSiteCode01\NEW"
  $Application = Get-CMApplication -Name $FullApplicationName
  

  if (!$CMNewApplicationFolderPath ) {Write-output 'Variable $CMNewApplicationFolderPath is not defined'}
  
  Move-CMObject -FolderPath "$($SCCMSiteCode01 + ':')\Application\$CMNewApplicationFolderPath " -ObjectId $Application.ModelName
}
######################################## REMOVE ALL APPV ENTRIES ####################
#TO ADD remove-SBCMDeployments
Function Remove-SBCMAppVCollections
{
  <#
      .INFO

  #>
  Write-Host -Object 'AD GROUPS ARE NOT REMOVED BY DEFAULT' -ForegroundColor Magenta


  if ( $(Get-CMCollection -Name $UserCollectionNameAppVPRDINSTALL))
  {
    write-host -Object "Removing Deployment from User Collection $UserCollectionNameAppVPRDINSTALL"
    
    Write-Host -Object "Remove APPV USER Deployments $UserCollectionNameAppVPRDINSTALL"  
    Remove-CMDeployment -CollectionName $UserCollectionNameAppVPRDINSTALL -ApplicationName $FullAppVNameUsers -Force
    <# REMOVE OTHER COLLECTIONS
        Remove-CMDeployment -CollectionName $UserCollectionNameAppVPRDINSTALLED -ApplicationName $FullAppVNameUsers -Force
        Remove-CMDeployment -CollectionName $CMUserCollectionNameAppVPRDUNINSTALL -ApplicationName $FullAppVNameUsers -Force
    #>
        
    #Write-Host -Object "Getting collection IDS from $CollectionIDUserCollectionNameAppVPRDINSTAL"  -ForegroundColor Magenta
    #$CollectionIDUserCollectionNameAppVPRDINSTALL = Get-CMUserCollection -Name $UserCollectionNameAppVPRDINSTALL | Select-Object -Property CollectionID -ExpandProperty CollectionID
    
    Write-Host -Object 'Removing APPV USER COLLECTIONS'   -ForegroundColor Magenta
    Remove-CMUserCollection -Name $UserCollectionNameAppVPRDINSTALL -Force 
    Write-Output -Object "APPV USER COLLECTIONS $UserCollectionNameAppVPRDINSTALL removed"
    
    
  }
  else { write-Output "$UserCollectionNameAppVPRDINSTALL does not exist"}
  
  
  if ( $(Get-CMCollection -Name $DeviceCollectionNameAppVINSTALL))
  {
    Write-Host -Object "Remove APPV COMPUTER Deployments $DeviceCollectionNameAppVINSTALL"  -ForegroundColor Magenta
    Remove-CMDeployment -CollectionName $DeviceCollectionNameAppVINSTALL -ApplicationName $FullAppVNameComputers -Force

    #$CollectionIDDeviceCollectionNameAppVINSTALL = Get-CMDeviceCollection -Name $DeviceCollectionNameAppVINSTALL | Select-Object -Property CollectionID -ExpandProperty CollectionI    
 

    Write-Host -Object 'Removing APPV COMPUTER COLLECTIONS'   -ForegroundColor Magenta
    Remove-CMDeviceCollection -Name $DeviceCollectionNameAppVINSTALL -Force 
    Write-Output "APPV COMPUTER COLLECTIONS $DeviceCollectionNameAppVINSTALL removed"
    

  }
  else { write-output "$DeviceCollectionNameAppVINSTALL does not exist"}
}
Function Remove-SBCMAppVPackages
{

  Write-Host -Object 'AD GROUPS ARE NOT REMOVED BY DEFAULT' -ForegroundColor Magenta

  if (Get-CMApplication -Name $FullAppVNameUsers){
    Write-Host -Object "Removing APPV PACKAGE USERS $FullAppVNameUsers" -ForegroundColor Magenta
    Remove-CMApplication -Name $FullAppVNameUsers -Force 
    Write-Output "$FullAppVNameUsers removed"
  }
  else {write-output "$FullAppVNameUsers does not exist"}
  
  
  if (Get-CMApplication -Name $FullAppVNameComputers){
    Write-Host -Object "Removing APPV PACKAGE COMPUTERS $FullAppVNameComputers" -ForegroundColor Magenta
    Remove-CMApplication -Name $FullAppVNameComputers -Force 
    Write-Output "$FullAppVNameComputers removed"
  }
  else {write-output "$FullAppVNameComputers does not exist"}
  

}

######################################## REMOVE ALL APPLICATION ENTRIES ####################
Function Remove-SBCMApplicationCollections
{
  <#
      .INFO

  #>
  Write-Host -Object 'AD GROUPS ARE NOT REMOVED BY DEFAULT' -ForegroundColor Magenta
    
  if ( $(Get-CMCollection -Name $DeviceCollectionNameApplicationINSTALL))
  {
    Write-Host -Object "Remove Application Deployments from  $DeviceCollectionNameApplicationINSTALL"  -ForegroundColor Magenta
    
    Remove-CMDeployment -CollectionName $DeviceCollectionNameApplicationINSTALL -ApplicationName $FullApplicationName -Force


    Write-Host -Object 'Removing Application COMPUTER COLLECTION $DeviceCollectionNameApplicationINSTALL'   -ForegroundColor Magenta
    Remove-CMDeviceCollection -Name $DeviceCollectionNameApplicationINSTALL -Force  

  }
  else { write-host "$DeviceCollectionNameApplicationINSTALL does not exist"}
}
Function Remove-SBCMApplication
{

  if (Get-CMApplication -Name $FullApplicationName){
    Write-Host -Object "Removing Application $FullApplicationName" -ForegroundColor Magenta
    Remove-CMApplication -Name $FullApplicationName -Force 
  }
  else {write-host "$FullApplicationName does not exist"}
   

}


######################################## REMOVE ALL PACKAGE ENTRIES ####################
Function Remove-SBCMPackageCollections
{
  <#
      .INFO

  #>
  Write-Host -Object 'AD GROUPS ARE NOT REMOVED BY DEFAULT' -ForegroundColor Magenta
    
  if ( $(Get-CMCollection -Name $DeviceCollectionNamePackage))
  {
    
    <# NEEDED TO REMOVE DEPLOYMENTS FOR PACKAGES?
        Write-Host -Object "Remove Application Deployments from  $DeviceCollectionNamePackage"  -ForegroundColor Magenta
    
        #for applications Remove-CMDeployment -CollectionName $DeviceCollectionNamePackage  $PackageName -Force , for packages this is different
        $deploymentid = (Get-CMDeployment -CollectionName $DeviceCollectionNamePackage).DeploymentID
    #>

    Write-Host -Object 'Removing package COMPUTER COLLECTION $DeviceCollectionNamePackage'   -ForegroundColor Magenta
    Remove-CMDeviceCollection -Name $DeviceCollectionNamePackage -Force  

  }
  else { write-host "Device collection $DeviceCollectionNamePackage does not exist"}
}
Function Remove-SBCMPackage
{

  if (Get-CMPackage -Name $PackageName){
    Write-Host -Object "Removing Package $PackageName" -ForegroundColor Magenta
    Remove-CMPackage -Name $PackageName -Force 
  }
  else {write-host "Package $PackageName does not exist"}
   

}

########################################  SCRAP (THINGS TO ADD/CHANGE) ################
<#ADD DeployMENT TYPE $InstallFileLocationCustom, used when name convention is not correctly followed#
    Add-CMDeploymentType -ApplicationName $FullAppVNameUsers  -DeploymentTypeName $DeploymentTypeNameWKX -AppV5xInstaller -InstallationFileLocation $InstallFileLocationCustom -AutoIdentifyFromInstallationFile -ForceForUnknownPublisher $true -AddRequirement $oDTRuleWKX 
    Add-CMDeploymentType -ApplicationName $FullAppVNameComputers  -DeploymentTypeName $DeploymentTypeNameW7 -AppV5xInstaller -InstallationFileLocation $InstallFileLocationCustom -AutoIdentifyFromInstallationFile -ForceForUnknownPublisher $true -AddRequirement $oDTRuleW7 

    #!!!! DEVICE COLLECTION TO CORRECT THE SITUATION IN WHICH PACKAGES WERE DeployED TO COMPUTERS WHEN TS USERS LOGGED ON TO THEM!!!##
    New-CMDeviceCollection -name $DeviceCollectionNameAppVCORRECT -LimitingCollectionName $CMLimitingCollectionW7 -RefreshType Periodic -RefreshSchedule (New-CMSchedule -Start (get-date) -RecurInterval Minutes -RecurCount 20) 

    #!!QUERY CORRECT COLLECTION -TO CORRECT SITUATION IN WHICH TS USERS LOGGED ON TO PC'S AND HAD APP-V PACKAGES Deployed#
    Add-CMDeviceCollectionQueryMembershipRule -RuleName $RuleNameQuery -CollectionName $DeviceCollectionNameAppVCORRECT -QueryExpression $QueryDevicesW7Users 

    #Add DIRECT-mebership to collection, to check: Add-CMUserCollectionDirectMembershipRule -CollectionName -$UserCollectionNameAppVDEV -ResourceId ((Get-CMUser -Name fnccognizant-1).ResourceID)
    Add-CMUserCollectionDirectMembershipRule -CollectionName $UserCollectionNameAppVDEV -ResourceId '2063602239'

    #####Deploy APP-V TO USERS DEV INSTALL#####
    Start-CMApplicationDeployment -CollectionName $UserCollectionNameAppVDEV -Name $FullAppVNameUsers -DeployPurpose $CMDeployPurpose -DeployAction Install -UserNotification DisplayAll -DeadlineDate $DeadlineDate -DeadlineTime $DeadlineTime -AvailableDateTime $AvailableDateTime -AvailableTime $AvailableTime -TimeBaseOn LocalTime 

    #Deploy APP-V  AS AVAILABLE TO "UAT - DCO - ALL PACKAGES AVAILABLE"#
    Start-CMApplicationDeployment -CollectionName "UAT - DCO - ALL PACKAGES AVAILABLE" -Name $FullAppVNameComputers -DeployPurpose Available -DeployAction Install -UserNotification DisplayAll 

    #Deploy PACKAGE AS AVAILABLE TO "UAT - DCO - ALL PACKAGES AVAILABLE"#
    Start-CMPackageDeployment -CollectionName "UAT - DCO - ALL PACKAGES AVAILABLE" -PackageName $PackageName  -StandardProgramName $StandardProgramName  -DeployPurpose Available 

    #Deploy APPLICATION to testcollection AVAILABLE#
    Start-CMApplicationDeployment -CollectionName "TESTCOLLECTION" -Name $FullApplicationName -DeployPurpose $CMDeployPurpose -DeployAction Install -UserNotification DisplayAll 

    #AD UAT PC for testing#
    Add-ADGroupMember $ADMainApplicationGroup -members "ppc05459$"

    #ADD USER GROUPS TO AD GROUP#
    Add-ADGroupMember -Identity $ADMainAppVGroup -Members $ADGroupMembersCognizant 
    Add-ADGroupMember -Identity $ADMainAppVGroup -Members $ADGroupMembersInfoSys 
    Add-ADGroupMember -Identity $ADMainAppVGroup -Members $ADGroupMembersGISXXL 

    #REMOVE USER GROUPS FROM AD GROUP#
    Remove-ADGroupMember -Identity $ADMainAppVGroup -Members $ADGroupMembersCognizant 
    Remove-ADGroupMember -Identity $ADMainAppVGroup -Members $ADGroupMembersInfoSys 
    Remove-ADGroupMember -Identity $ADMainAppVGroup -Members $ADGroupMembersGISXXL 
    #####REMOVE TIPOS APPV AD GROUP TO MAIN APPV AD GROUP#####
    Remove-ADGroupMember -Identity $ADMainAppVGroup -Members $ADAppVGroupTipos 

#>

#endregion

#region FUNCTIONS GETTING VARIABLES
#GENERAL VARIABLES
Function Get-SCCMVariables
{

  $Global:PackageVersion = "($PackageVersionOnDFS)"
    
  <#    
      $Global:ADGroupMembersMultiple = @('APP PRD U Cognizant', 'APP PRD U Infosys') #@("Appv Testusers","APPV-5-PRD-SourceForge-NotepadPlusPlus") #"APP PRD U Cognizant", "APP PRD U Infosys", "APP PRD U RDS GISXXL"
      $Global:ADGroupMembersCognizant = 'APP PRD U Cognizant'
      $Global:ADGroupMembersInfoSys = 'APP PRD U Infosys'
      $Global:ADGroupMembersGISXXL = 'APP PRD U RDS GISXXL'
  #>
  
  
        
  $Global:AppVPackageName = "$Publisher - $AppName - $AppVersion $PackageVersion.appv"
  $Global:Date = Get-Date -Format 'yyyy/MM/dd'
  $Global:Time = Get-Date -Format 'h:mm'
  $Global:AvailableDate = $Date #$Date
  #$Global:AvailableTime = $Time #$Time
  $Global:AvailableTime = '{0:HH:mm}' -f (Get-Date) #$Time
  $Global:DeadlineDate = $Date
  $Global:DeadlineTime = '{0:HH:mm}' -f (Get-Date).AddMinutes(1)
  $Global:Owner = $env:USERNAME
  $Global:Description = "Created automatically via scripting by $Owner on $Date $Time"
             
  $Global:PackageName = $AppName
  $Global:FullAppVNameComputers = "$CMAppVNameComputersPrefix - $Publisher - $AppName - $AppVersion $PackageVersion"
  $Global:FullAppVNameUsers = "$CMAppVNameUsersPrefix - $Publisher - $AppName - $AppVersion $PackageVersion"
  $Global:FullApplicationName = "$CMApplicationNamePrefix - $Publisher - $AppName - $AppVersion $PackageVersion"
  
  $Global:ADMainAppVGroup = "$CMADMainAppVGroupPrefix-$Publisher-$AppName"
  $Global:ADAppVGroupTipos = "$CMADMainApplicationGroupPrefix-$Publisher-$AppName (AppV)"
  $Global:ADMainApplicationGroup = "$CMADMainApplicationGroupPrefix-$Publisher-$AppName"
  $Global:DeploymentTypeNameW7 = "$Publisher - $AppName - $AppVersion $PackageVersion"
  $Global:DeploymentTypeNameWKX = "$Publisher - $AppName - $AppVersion $PackageVersion - WKX"
  $Global:DeviceCollectionNameApplicationINSTALL = "$CMDeviceCollectionNamePrefix - $CMDeviceCollectionNameApplicationPrefix - $Publisher $AppName - INSTALL"

  $Global:DeviceCollectionNamePackage = "$CMDeviceCollectionNamePackagePrefix - $Publisher $AppName"
  $Global:DeviceCollectionNameAppVINSTALL = "$CMDeviceCollectionNamePrefix - App-V - $Publisher - $AppName - INSTALL"

  $Global:DeviceCollectionNameAppVCORRECT = "$CMDeviceCollectionNamePrefix - App-V - $Publisher - $AppName - USERS W7 INSTALLED"
        

  $Global:InstallFileLocation = "$AppVPackagesShare$Publisher\$AppName\$AppVersion\$PackageVersionOnDFS\$CMSoftPackageFolder\$AppVPackageName"
  $Global:PackagePath = "$PackagesShare$Publisher\$AppName\$AppVersion\$PackageVersionOnDFS\$CMSoftPackageFolder\"
  
  
  $Global:OuPathApplication = $CMOUPathComputers

  $Global:UserCollectionNameAppVDEV = "$SCCMSiteCode01 - USR - $Publisher - $AppName"
  $Global:UserCollectionNameAppVPRDINSTALL = "$SCCMSiteCode01 - USR - $Publisher - $AppName - INSTALL"
  #$Global:CMUserCollectionNameAppVPRDUNINSTALL = "$SCCMSiteCode01 - USR - $Publisher - $AppName - UNINSTALL"

  $Global:UserCollectionNameAppVPRDINSTALLED = "$SCCMSiteCode01 - USR - $Publisher - $AppName - INSTALLED"
  $Global:RulenameAD = 'Active Directory'
  $Global:RulenameQuery = 'Query'
  $Global:RunType = 'Hidden'
  $Global:StandardProgramName = "$Publisher - $AppName - $AppVersion"
  $Global:StandardProgramNameW7 = "$Publisher - $AppName - $AppVersion $PackageVersion"
  $Global:StandardProgramNameWKX = "$Publisher - $AppName - $AppVersion $PackageVersion"
  $Global:QueryMachines = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Obsolete = 0 and SMS_R_System.OperatingSystemNameandVersion like 'Microsoft Windows NT Workstation 6.1%' and SMS_R_System.SystemGroupName = 'PROD\\$ADGroup'"
  #PREVIOUSLY GROUPS WERE USED
  $Global:QueryDevicesW7Users = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_AppClientState on SMS_G_System_AppClientState.MachineName = SMS_R_System.Name where SMS_G_System_AppClientState.ComplianceState = 1 and SMS_G_System_AppClientState.AppName = '$FullAppVNameUsers'"
  $Global:QueryUsersGroup = "select SMS_R_USERGROUP.ResourceID,SMS_R_USERGROUP.ResourceType,SMS_R_USERGROUP.Name,SMS_R_USERGROUP.UniqueUsergroupName,SMS_R_USERGROUP.WindowsNTDomain from SMS_R_UserGroup where SMS_R_UserGroup.UsergroupName = $ADGroup'"
  $Global:QueryUsersInstall = "select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User where SMS_R_User.SecurityGroupName = 'PROD\\$ADMainAppVGroup'"
  $Global:QueryUsersInstalled = "select SMS_R_USER.ResourceID,SMS_R_USER.ResourceType,SMS_R_USER.Name,SMS_R_USER.UniqueUserName,SMS_R_USER.WindowsNTDomain from SMS_R_User inner join SMS_G_System_AppClientState on SMS_R_USER.UniqueUserName = SMS_G_System_AppClientState.UserName  where SMS_G_System_AppClientState.AppName = '$FullAppVNameUsers' and   SMS_G_System_AppClientState.ComplianceState = 1"
  $Global:QueryDevicesInstall = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Obsolete = 0  and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
  $Global:QueryDevicesEvenInstall = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[02468]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
        
  $Global:QueryDevices0Install = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[0]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
  $Global:QueryDevices1to2Install = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[12]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
        
  #$Global:QueryDevices0to2Install = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[012]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
  $Global:QueryDevices3to5Install = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[345]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
  $Global:QueryDevices6to9Install = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[6789]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"

        
  $Global:QueryDevicesOddInstall = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[13579]' and SMS_R_System.Obsolete = 0 and SMS_R_System.SystemGroupName = 'PROD\\$ADAppVGroupTipos'"
  $Global:QueryDevicesInstalled = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_AppClientState on SMS_G_System_AppClientState.MachineName = SMS_R_System.Name where SMS_G_System_AppClientState.ComplianceState = 1 and SMS_G_System_AppClientState.AppName = '$FullAppVNameComputers'"
  $Global:QueryDevicesApplicationsInstall = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Obsolete = 0 and SMS_R_System.OperatingSystemNameandVersion like 'Microsoft Windows NT Workstation 6.1%' and SMS_R_System.SystemGroupName = 'PROD\\$ADMainApplicationGroup'"
  $Global:QueryDevicesApplicationsInstalled = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_AppClientState on SMS_G_System_AppClientState.MachineName = SMS_R_System.Name where SMS_G_System_AppClientState.ComplianceState = 1 and SMS_G_System_AppClientState.AppName = '$FullApplicationName'"
        
  #Prereqs W7
  $oOperandsW7 = New-Object -TypeName "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
  $oOperandsW7.Add('Windows/x64_Windows_7_SP1') 
  $oOperatorW7     = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::OneOf
  $oOSExpressionW7 = New-Object -TypeName Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression -ArgumentList $oOperatorW7, $oOperandsW7
  $oAnnotationW7  = New-Object -TypeName Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation     
  $oAnnotationW7.DisplayName = New-Object -TypeName Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString -ArgumentList 'DisplayName', 'Operating system One of {Windows 7 SP1 (64-bit)}', $null
  $oNoncomplianceSeverityW7 = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None
  $Global:oDTRuleW7 = New-Object -TypeName 'Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule' -ArgumentList(('Rule_' + [Guid]::NewGuid().ToString()), 
    $oNoncomplianceSeverityW7, 
    $oAnnotationW7, 
    $oOSExpressionW7
  )

  #Prereqs WKX
  $oOperandsWKX = New-Object -TypeName "Microsoft.ConfigurationManagement.DesiredConfigurationManagement.CustomCollection``1[[Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.RuleExpression]]"
  $oOperandsWKX.Add('Windows/x64_Windows_Server_2008_R2_SP1')
  $oOperandsWKX.Add('Windows/All_x64_Windows_Server_2012_R2')
  $oOperatorWKX     = [Microsoft.ConfigurationManagement.DesiredConfigurationManagement.ExpressionOperators.ExpressionOperator]::OneOf
  $oOSExpressionWKX = New-Object -TypeName Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression `
  -ArgumentList $oOperatorWKX, $oOperandsWKX   
  $oAnnotationWKX             = New-Object -TypeName Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Annotation     
  $oAnnotationWKX.DisplayName = New-Object -TypeName Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.LocalizableString `
  -ArgumentList 'DisplayName', 'Operating system One of {All Windows Server 2012 R2 SP1 (64-bit), All Windows Server 2012 R2 (64-bit)}', $null
  $oNoncomplianceSeverityWKX = [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.NoncomplianceSeverity]::None
  $Global:oDTRuleWKX = New-Object -TypeName 'Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule' -ArgumentList(('Rule_' + [Guid]::NewGuid().ToString()), 
    $oNoncomplianceSeverityWKX, 
    $oAnnotationWKX, 
    $oOSExpressionWKX
  )
}
#APP-V PACKAGE VARIABLES
Function Get-SCCMSoftwareAppVVariables
{ 
  param($Path)
  $share = "$Path.Replace('\\','')"
  #$Publisher,$AppName,$AppVersion,$PackageVersionOnDFS = $Share.Split('\')[7,8,9,10]

  
  if (!$AppVSharePublisherAppNameAppVersionPackageVersion) {Write-Output "AppVSharePublisherAppNameAppVersionPackageVersionvariable not loaded"}
  #$Global:Publisher, $Global:AppName, $Global:AppVersion, $Global:PackageVersionOnDFS = $share.Split('\')[7, 8, 9, 10]
  $Global:Publisher, $Global:AppName, $Global:AppVersion, $Global:PackageVersionOnDFS = $share.Split('\')[7,8,9,10]
  
  Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS" 
}

#APPLICATION/PACKAGE VARIABLES
Function Get-SCCMApplicationPackageSoftwareVariables
{ 

  [Cmdletbinding()]
  Param (
    [Parameter()]
    [String]$Path
    #[Switch]$PSStudio
  )

  $share = $Path.Replace('\\','')
  # 10/08/'17 $Global:Publisher, $Global:AppName, $Global:AppVersion, $Global:PackageVersionOnDFS = $share.Split('\')[8, 9, 10, 11]
  $Global:Publisher, $Global:AppName, $Global:AppVersion, $Global:PackageVersionOnDFS = $share.Split('\')[6,7,8,9]
  #$Global:Publisher, $Global:AppName, $Global:AppVersion, $Global:PackageVersionOnDFS = $share.Split('\')[8, 9, 10, 11]
  Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
    
  <#
      if ($PSStudio){
      Get-SCCMApplicationPackageSoftwareVariables -Path $Path
      Add-RichTextBox -Text "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
      #Get-SCCMVariables
      Add-RichTextBox -text 'Not implemented yet'
  }#>
}
#endregion

#region THE REAL STUFF
<#WATCH OUT WITH END BACKSLASH, F.E.  Get-SCCMSoftwareAppVVariables  -Path '\\prod.telenet.be\adm\PackageSources\AppV\X64\Test\1.0\1.0\5.PKG' WILL GIVE
    S C:\Windows\system32>  Get-SCCMSoftwareAppVVariables  -Path '\\prod.telenet.be\adm\PackageSources\AppV\X64\Test\1.0\1.0\5.PKG'
    Variables used are:  Test, 1.0, 1.0, 5.PKG.Replace('

    ADD \ AT THE END AND IT WORKS FINE  Get-SCCMSoftwareAppVVariables  -Path '\\prod.telenet.be\adm\PackageSources\AppV\X64\Test\1.0\1.0\5.PKG\'
#>
Function Get-TestVariables {
  param($Path,
    [switch]$AppV
  )                                    
  if (! $GlobaVariablesLoaded)  {Get-GlobalVariables}
  Get-SCCMVariables
  
  if (! $AppV) {   Get-SCCMApplicationPackageSoftwareVariables -Path '\\prod.telenet.be\adm\PackageSources\SCCM\W7\x64\Telenet\Test\1.0\1.0\5.PKG\' }
  else {  Get-SCCMSoftwareAppVVariables  -Path '\\prod.telenet.be\adm\PackageSources\AppV\X64\Telenet\Test\1.0\1.0\5.PKG\' }  
}

Function Deploy-SBCMSoftware
{
  <#
      .SYNOPSIS
      This function will Deploy Applications within SCCM 2012:
      *Create Application/Package
      *Create Collections + their queries
      *Create AD Groups
      *Deploy the software

      .DESCRIPTION
       

      .EXAMPLE
      PS C:\> Deploy-CMSoftware -SoftwareType AppV -Path \\$AppvPackageShare\CheckPoint\SmartConsole\R70\1.0\5.PKG
       

      .NOTE
      Application requirements: http://www.laurierhodes.info/?q=node/91 and http://www.laurierhodes.info/?q=node/60
        
      To DO:
      ------
      *supersedence, howto set application detection, howto set automatically in application
      *autocomplete path,
      -if App-V then FullPath = $appvapackageshare + Path
      Path = \SmartConsole\R70\1.0
      -if Application or Package then FullPath = \\domainfqdn\ADM\PackageSources\SCCM\W7\x64 + Path
      *autocomplete partly works with TabExpansion++ module but not fully working => deploy-teletcmsoftware -publisher Microsoft -AppName etc
      *Error handling, logging and notification (mail): now only generic mails, errors should be catched with try catch
      * Applications: ONLY COLLECTION INSTALL IS OK, OTHER COLLECTIONS DO NOT HAVE QUERY OR DEPLOYMENT TO IT
         

      
      Author: sbaert
      Last Modified: 9/11/2015
  #>
  [CmdletBinding()] 
  param
  ([Validateset('AppV','Application','Package')]
    [Parameter(Position = 1,Mandatory = $true)][String]$SoftwareType,
    [Parameter(Position = 2,Mandatory = $true)] $Path,
    [Validateset('Full','PackagesOnly','DeploymentsOnly','CollectionsOnly','ADGroupsOnly','AddCollectionQuery')]
    [Parameter(Position = 3)] $OptionAppV = 'PackagesOnly',
    [Validateset('Full','ApplicationOnly','DeploymentTypeW7Only','DeploymentTypeWKXOnly','DistributionOnly','CollectionOnly','DeploymentOnly','ADGroupOnly')]
    [Parameter(Position = 3)] $OptionApplication = 'ApplicationOnly',
    [Validateset('ComputersEndingOn-0-2','ComputersEndingOn-3-5','ComputersEndingOn-6-9','ComputersEven','ComputersOdd','ComputersAll','UsersAll','ComputersAndUsersAll')]
    [Parameter()]$OptionQuery = 'ComputersEven'
  )      
  Set-Location -Path c:
  Add-Content $CMDeployLogFile -Value "Start executing 'Software Deployment Script' by $env:USERNAME on $CurrentDate"
  Set-Location -Path $($SCCMSiteCode01 + ':')

  if ($SoftwareType -eq 'AppV')
  {
    Get-SCCMSoftwareAppVVariables -Path $Path
    Get-SCCMVariables
    #if ($($PkgAppv.name) -like "$vendor - $Application - $ApplicationVersion ($PackageVersion).appv"){$PkgNameConvention = 'OK'} else {$PkgNameConvention = 'NOK'}
    cd c:
    if (! $(test-path $InstallFileLocation)){Write-Host "$AppVPackageName cannot be found, probably name convention not OK" -ForegroundColor DarkYellow 
      Write-Output "Path not found $InstallFileLocation"    
      [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      [Windows.Forms.MessageBox]::Show("Check if $InstallFileLocation exists ", "!Abort: App-V package not found", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Warning)
    }
          
    else{
      Write-Host -Object "AppVpackageName is $AppVPackageName" -ForegroundColor Magenta
      cd $($SCCMSiteCode01 + ':')
        
      #Deploy-CMSoftware -SoftwareType AppV -Path \\domainfqdn\ADM\PackageSources\AppV\X64\CheckPoint\SmartConsole\R70\1.0\5.PKG
       
      if ($OptionAppV -eq 'DeploymentsOnly')
      {
        $null = New-SBCMAppVDeployment  
        $body += "Deploy-CMSoftware -AppV for ""$AppVPackageName"" with option 'DeploymentsOnly' was executed by $env:USERNAME on $CurrentDate"
      }
      if ($OptionAppV -eq 'CollectionsOnly')
      {
        $null = New-SBCMAppVCollection 
        #New-SBCMAppVCollectionQueries | Out-Null
        $null = Move-SBCMAppVCollections
        $body += "Deploy-CMSoftware -AppV for ""$AppVPackageName"" with option 'CollectionsOnly' was executed by $env:USERNAME on $CurrentDate"
      }
      if ($OptionAppV -eq 'AddCollectionQuery')
      {
        if ($OptionQuery -eq 'ComputersAndUsersAll')
        {
          New-SBCMAppVCollectionQueries -Option ComputersAndUsersAll 
        }
        if ($OptionQuery -eq 'ComputersAll')
        {
          New-SBCMAppVCollectionQueries -Option ComputersAll 
        }
        if ($OptionQuery -eq 'UsersAll')
        {
          New-SBCMAppVCollectionQueries -Option UsersAll 
        }
        if ($OptionQuery -eq 'ComputersEndingOn-0-2')
        {
          New-SBCMAppVCollectionQueries -Option ComputersEndingOn-0-2 
        }
        if ($OptionQuery -eq 'ComputersEndingOn-3-5')
        {
          New-SBCMAppVCollectionQueries -Option ComputersEndingOn-3-5 
        }
        if ($OptionQuery -eq 'ComputersEndingOn-6-9')
        {
          New-SBCMAppVCollectionQueries -Option ComputersEndingOn-6-9 
        }
        if ($OptionQuery -eq 'ComputersEven')
        {
          New-SBCMAppVCollectionQueries -Option ComputersEven 
        }
        if ($OptionQuery -eq 'ComputersOdd')
        {
          New-SBCMAppVCollectionQueries -Option ComputersOdd 
        }

        #Add-CMDeviceCollectionQueryMembershipRule -RuleName "ComputerNamesEndingOn $ComputerNamesEndingOn" -CollectionName "PRD - DCO - App-V - Putty - Putty - INSTALL" -QueryExpression "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[$ComputerNamesEndingOn]'"
        #Add-CMDeviceCollectionQueryMembershipRule -RuleName "ComputerNamesEndingOn $ComputerNamesEndingOn" -CollectionName $DeviceCollectionNameAppVINSTALL -QueryExpression "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Name like '%[$ComputerNamesEndingOn]'"          
        $body += "Deploy-CMSoftware -AppV for ""$AppVPackageName"" with option 'AddCollectionQuery' was executed by $env:USERNAME on $CurrentDate"
      }
      if ($OptionAppV -eq 'ADGroupsOnly')
      {
        $null = New-SBCMADGroupAppVUsers 
        $null = New-SBCMADGroupAppVComputers 
        $body += "Deploy-CMSoftware -AppV for ""$AppVPackageName"" with option 'ADGroupsOnly' was executed by $env:USERNAME on $CurrentDate"
      }
      if ($OptionAppV -eq 'Full')
      {
        $null = New-SBCMAppVUsers 
        $null = New-SBCMAppVComputers
         
        Start-Sleep -Seconds 5 
        $null = New-SBCMAppVUsersDTWKX 
        $null = New-SBCMAppVComputersDTW7
        $null = New-SBCMAppVCollection 
        $null = New-SBCMAppVCollectionQueries -Option ComputersAndUsersAll
        $null = New-SBCMAppVDeployment  
        #$null = Move-CMAppVPackages
        
        $null = New-SBCMADGroupAppVUsers 
        $null = New-SBCMADGroupAppVComputers     
        
        $null = Move-SBCMAppVPackages
        $null = Move-SBCMAppVCollections
        $body += "Deploy-CMSoftware -AppV for ""$AppVPackageName"" with option 'Full' was executed by $env:USERNAME on $CurrentDate"
      }
      elseif ($OptionAppV -eq 'PackagesOnly')
      {
        $null = New-SBCMAppVUsers 
        $null = New-SBCMAppVComputers
     
        Start-Sleep -Seconds 5 
        $null = New-SBCMAppVUsersDTWKX 
        $null = New-SBCMAppVComputersDTW7
        #$null = Move-SBCMAppVPackages 
        $null = Move-SBCMAppVPackages 
        $body += "Deploy-CMSoftware -AppV for ""$AppVPackageName"" with option 'PackagesOnly' was executed by $env:USERNAME on $CurrentDate"
      }
                                   
      $body = $body | Out-String
      Send-MailMessage -From $MailFromAddress -To $MailToAddressDeploySoftware -SmtpServer $PublicSMTPServer01_FQDN -BodyAsHtml -Subject "Deploy Telenet Software by $env:USERNAME, APP-V" -Body $body
      Set-Location -Path c:
      Add-Content $CMDeployLogFile -Value "Deplomyent of $AppVPackageName"
      Write-Host -Object 'Deployment script Finished' -ForegroundColor Magenta
    }
  }
  If ($SoftwareType -eq 'Application')
  {
    Get-SCCMApplicationPackageSoftwareVariables -Path $Path
    Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS" 
    Get-SCCMVariables
    Write-Host -Object "Application is $FullApplicationName" -ForegroundColor Magenta
    Set-Location -Path $($SCCMSiteCode01 + ':')


    if ($OptionApplication -eq 'ApplicationOnly')
    {
      New-SBCMApplication
      Move-SBCMApplication
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'ApplicationOnly' was executed by $env:USERNAME on $CurrentDate"
    }
    if ($OptionApplication -eq 'DeploymentTypeW7Only')
    {
      Add-SBCMApplicationDeploymentTypeW7 
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'DeploymentTypeW7Only' was executed by $env:USERNAME on $CurrentDate"
    }
    if ($OptionApplication -eq 'DeploymentTypeWKXOnly')
    {
      Add-SBCMApplicationDeploymentTypeWKX
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'DeploymentTypeW7Only' was executed by $env:USERNAME on $CurrentDate"
    }
    if ($OptionApplication -eq 'DistributionOnly')
    {
      Start-SBCMApplicationDistribution
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'DistributionOnly' was executed by $env:USERNAME on $CurrentDate"
    }
    if ($OptionApplication -eq 'CollectionOnly')
    {
      New-SBCMApplicationCollection
      Move-SBCMApplicationCollection
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'CollectionOnly' was executed by $env:USERNAME on $CurrentDate"
    }
    if ($OptionApplication -eq 'DeploymentOnly')
    {
      New-SBCMApplicationDeployment
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'DeploymentOnly' was executed by $env:USERNAME on $CurrentDate"
    }
    if ($OptionApplication -eq 'ADGroupOnly')
    {
      New-SBCMADGroupApplicationPackage
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'ADGroupOnly' was executed by $env:USERNAME on $CurrentDate"
    }
    elseif ($OptionApplication -eq 'Full')
    {
      New-SBCMApplication
     

      Add-SBCMApplicationDeploymentTypeW7 
      Add-SBCMApplicationDeploymentTypeWKX

      Start-SBCMApplicationDistribution

      New-SBCMApplicationCollection
     
      New-SBCMApplicationDeployment

      New-SBCMADGroupApplicationPackage
      
      Move-SBCMApplication
      Move-SBCMApplicationCollection
       
      $body += "Deploy-CMSoftware -Application  for Application $FullApplicationName with option 'Full' was executed by $env:USERNAME on $CurrentDate"
    }


    Set-Location -Path c:
    $body = $body | Out-String
    Send-MailMessage -From $MailFromAddress -To $MailToAddressDeploySoftware -SmtpServer $PublicSMTPServer01_FQDN -BodyAsHtml -Subject "Deploy Telenet Software by $env:USERNAME, APPLICATION" -Body $body
    Write-Host -Object 'ONLY COLLECTION INSTALL IS OK, OTHER COLLECTIONS DO NOT HAVE QUERY OR DEPLOYMENT TO IT' -ForegroundColor Magenta
    Set-Location -Path c:
    Add-Content $CMDeployLogFile -Value "Deplomyent of $FullApplicationName"
  }
  If ($SoftwareType -eq 'Package')
  {
    Get-SCCMApplicationPackageSoftwareVariables -Path $Path
    Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS" 
    Get-SCCMVariables
    Write-Host -Object "PackageName is $PackageName" -ForegroundColor Magenta
        
    Set-Location -Path $($SCCMSiteCode01 + ':')
    New-SBCMPackage
    New-SBCMPackageCollection
    New-SBCMADGroupApplicationPackage
    Write-Host -Object 'DEPLOY HAS TO BE DONE MANUALLY!' -ForegroundColor Magenta
    Set-Location -Path c:

    $body += "Package $PackageName deployed by $env:USERNAME on $CurrentDate"
    $body = $body | Out-String
    Send-MailMessage -From $MailFromAddress -To $MailToAddressDeploySoftware -SmtpServer $PublicSMTPServer01_FQDN -BodyAsHtml -Subject "Deploy $Company Software by $env:USERNAME" -Body $body
  }

  Set-Location -Path c:
  Add-Content $CMDeployLogFile -Value "End of executing 'Software Deployment Script' by $env:USERNAME on $CurrentDate"
}
  

#GET-SBCMSoftware NOK, IT IS MADE FOR PS STUDIO ONLY, see AppVQueryResultComputers | out-string -width ...
function Get-SBCMSoftware
{
             
  [CmdletBinding()]
  param
  ([Validateset('AppV', 'Application', 'Package')]
    [Parameter(Position = 1, Mandatory = $true)]
    [String]$SoftwareType,
    [Parameter(Position = 2, Mandatory = $true)]
    $Path
  )
       
  try
  {
    Set-Location -Path $($SCCMSiteCode01 + ':')
             
    if ($SoftwareType -eq 'AppV')
    {
    
      
      Get-SCCMSoftwareAppVVariables -Path $Path
      $VariablesUsed = "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
      Write-Host "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
      Get-SCCMVariables
                    
      
      $Result = @()
      #APPVPACKAGES
      Add-Logs "Getting App-V Package"
      $AppVQueryResultComputers = Get-CMApplication -Name $FullAppVNameComputers | select-object LocalizedDisplayName, DateCreated, LastModifiedBy, CreatedBy | Out-String #| Format-Table -AutoSize #| Out-String -Width $richtextboxOutput.width
      $AppVQueryResultUsers = Get-CMApplication -Name $FullAppVNameUsers | select-object LocalizedDisplayName, DateCreated, LastModifiedBy, CreatedBy | Out-String #| Format-Table -AutoSize #| Out-String -Width $richtextboxOutput.width
      #Add-RichTextBox -text "Current status App-V Computers: `n $AppVQueryResultComputers"
      #Add-RichTextBox -text "Current status App-V Users: `n $AppVQueryResultUsers "
      if ($AppVQueryResultComputers) {$Result += "`n *Status App-V package Computers: `n $AppVQueryResultComputers `n"}
      if ($AppVQueryResultUsers) {$Result += "*Status App-V package Users: `n $AppVQueryResultUsers `n"}
      Write-Host "Status App-V package Computers: `n $AppVQueryResultComputers"
      Write-Host "Status App-V package Users: `n $AppVQueryResultUsers "

      
      #COLLECTIONS
      Add-Logs "Getting Collections"
      $AppVQueryResultComputerCollection = Get-CMCollection -Name $DeviceCollectionNameAppVINSTALL | select-object name, LastChangeTime, CollectionRules | Out-String  #| Format-Table -AutoSize # | Out-String -Width $richtextboxOutput.width
      $AppVQueryResultUserCollection = Get-CMCollection -Name $UserCollectionNameAppVPRDINSTALL | select-object name, LastChangeTime, CollectionRules | Out-String #| Format-Table -AutoSize #| Out-String -Width $richtextboxOutput.width
      #Add-RichTextBox -text "Current status AppV Collection Computers: `n $AppVQueryResultComputerCollection"
      #Add-RichTextBox -text "Current status AppV Collection Users: `n $AppVQueryResultUserCollection"
      if ($AppVQueryResultComputerCollection) {$Result += "*Status App-V Collection Computers: `n $AppVQueryResultComputerCollection `n"}
      if ($AppVQueryResultUserCollection) {$Result += "*Status App-V Collection Users: `n $AppVQueryResultUserCollection `n"}
      Write-Host "Status AppV Collection Computers: `n $AppVQueryResultComputerCollection"
      Write-Host "Status AppV Collection Users: `n $AppVQueryResultUserCollection"

      
      #DEPLOYMENTS
      Add-Logs "Getting Deployments"
      $AppVQueryComputerCollectionDeployment = Get-CMDeployment -CollectionName $DeviceCollectionNameAppVINSTALL | Select-Object SoftwareName, DeploymentTime, EnforcementDeadline, ModificationTime, CreationTime,MemberCount | Out-String #| Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      $AppVQueryUserCollectionDeployment = Get-CMDeployment -CollectionName $UserCollectionNameAppVPRDINSTALL | Select-Object SoftwareName, DeploymentTime, EnforcementDeadline, ModificationTime, CreationTime,MemberCount  | Out-String #| Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      #Add-RichTextBox -text "Current deployment status AppV Collection Computers: `n $AppVQueryComputerCollectionDeployment"
      #Add-RichTextBox -text "Current deployment status AppV Collection Users: `n $AppVQueryUserCollectionDeployment"
      if ($AppVQueryComputerCollectionDeployment) {$Result += "*Deployment status App-V Collection Computers: `n $AppVQueryComputerCollectionDeployment `n"}
      if ($AppVQueryUserCollectionDeployment) {$Result += "*Deployment status App-V Collection Users: `n $AppVQueryUserCollectionDeployment `n"}
      Write-Host "Deployment status AppV Collection Computers: `n $AppVQueryComputerCollectionDeployment"
      Write-Host "Deployment status AppV Collection Users: `n $AppVQueryUserCollectionDeployment"
      Add-Logs "Done"                   
                    
      if (!$Result){
        Add-Richtextbox "No entries found in SCCM for App-V $FullAppVNameComputers `n `n ($VariablesUsed)"
        Write-Host "No entries found in SCCM for $FullAppVNameComputers"
      }
      else { 
        $Result += "`n `n ($VariablesUsed)"
        Add-RichTextBox "$Result" # | Out-String -Width $richtextboxOutput.width)
      }

                    
    }
    If ($SoftwareType -eq 'Application')
    {
      Get-SCCMApplicationPackageSoftwareVariables -Path $Path
      $VariablesUsed = "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
      Get-SCCMVariables
      
      $Result = @()
      Add-logs 'Getting Application'
      $ApplicationQueryResultComputers = Get-CMApplication -Name $FullApplicationName | select-object LocalizedDisplayName, DateCreated, LastModifiedBy, CreatedBy | Out-String  #| Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      if  ($ApplicationQueryResultComputers) { $Result += "*Current status Application $FullApplicationName : `n $ApplicationQueryResultComputers"}
      Write-Host "Current status Application Computers: `n $AppVQueryResultComputers"
                    
      Add-logs 'Getting Collection'
      $ApplicationQueryResultComputerCollection = Get-CMCollection -Name $DeviceCollectionNameApplicationINSTALL | select-object name, LastChangeTime, CollectionRules | Out-String # | Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      if ($ApplicationQueryResultComputerCollection){ $Result += "*Status Application Collection $DeviceCollectionNameApplicationINSTALL : `n $ApplicationQueryResultComputerCollection"}
      Write-Host "Current status Application Collection Computers: `n $AppVQueryResultComputerCollection"
                    
      Add-logs 'Getting Deployment'
      $ApplicationQueryComputerCollectionDeployment = Get-CMDeployment -CollectionName $DeviceCollectionNameApplicationINSTALL | Select-Object SoftwareName, DeploymentTime, EnforcementDeadline, ModificationTime, CreationTime, MemberCount | Out-String # | Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      if ($ApplicationQueryComputerCollectionDeployment) { $Result += "*Status application deployment $DeviceCollectionNameApplicationINSTALL : `n $ApplicationQueryComputerCollectionDeployment"}
      Write-Host "Current status appliation deployment Collection Computers: `n $ApplicationQueryComputerCollectionDeployment "
      Add-Logs 'Done'


      if (!$Result){
        Add-Richtextbox "No entries found in SCCM for Application $FullApplicationName `n `n ($VariablesUsed)"
        Write-Host "No entries found in SCCM for $FullApplicationName"
      }
      else { 
        $Result += "`n `n ($VariablesUsed)"
        Add-RichTextBox "$Result" # | Out-String -Width $richtextboxOutput.width)
      }
      
    }
             
    If ($SoftwareType -eq 'Package')
    {
      Get-SCCMApplicationPackageSoftwareVariables -Path $Path
      $VariablesUsed =  "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
      Get-SCCMVariables
      
      $Result = @()
      
      Add-logs 'Getting Package' 
      $PackageQueryResultComputers = Get-CMPackage -Name $PackageName | select-object Manufacturer, SourceDate, LastRefreshTime, PackageID, Description | Out-String # | Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      if ($PackageQueryResultComputers) { $Result += "*Package $PackageName Computers: `n $PackageQueryResultComputers"}
      Write-Host "Package $PackageName Computers: `n $PackageQueryResultComputers"
                    
      Add-logs 'Getting Collection'
      $PackageQueryResultComputerCollection = Get-CMCollection -Name $DeviceCollectionNamePackage | select-object name, LastChangeTime, CollectionRules | Out-String # | Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      if ($PackageQueryResultComputerCollection) {$Result += "*Status Application Collection $DeviceCollectionNamePackage : `n $PackageQueryResultComputerCollection"}
      Write-Host "Current status Application Collection Computers: `n $PackageQueryResultComputerCollection"
                    
      Add-logs 'Getting Deployment'
      $PackageQueryComputerCollectionDeployment = Get-CMDeployment -CollectionName $DeviceCollectionNamePackage | Select-Object SoftwareName, DeploymentTime, EnforcementDeadline, ModificationTime, CreationTime,NumberTargetted, NumberSuccess | Out-String #  | Format-Table -AutoSize | Out-String -Width $richtextboxOutput.width
      if ($PackageQueryComputerCollectionDeployment) {$Result += "*Status package deployment $DeviceCollectionNamePackage Computers: `n $PackageQueryComputerCollectionDeployment" }
      Write-Host "Current status package deployment Collection Computers: `n $PackageQueryComputerCollectionDeployment "
                    
      if (!$Result){
        Add-Richtextbox "No entries found in SCCM for Package $PackageName `n `n ($VariablesUsed)"
        Write-Host "No entries found in SCCM for $PackageName"
      }
      else { 
        $Result += "`n ($VariablesUsed)"
        Add-RichTextBox "$Result" # | Out-String -Width $richtextboxOutput.width)
      }

    }
             
    Set-Location -Path c:
  }
  catch
  {
    $error[0]
    set-catch
  }
       
}
Function Remove-SBCMSoftware
{
  param
  #([Validateset('AppV','Application','Package')]
  ([Validateset('AppV','Application','Package')]
    [Parameter(Position = 1,Mandatory = $true)][String]$SoftwareType,
    [Parameter(Position = 2,Mandatory = $true)] $Path,
    [Validateset('Full','CollectionsOnly','PackagesOnly')]
    [Parameter(Position = 3)] $Option = 'Full'
  )
    
  Set-Location -Path c:
  Add-Content $CMDeployLogFile -Value "Start executing 'Software REMOVAL by $env:USERNAME on $CurrentDate"
  Set-Location -Path $($SCCMSiteCode01 + ':')

  if ($SoftwareType -eq 'AppV')
  {
    $share = "$Path.Replace('\\','')"
    $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS = $share.Split('\')[$AppVSharePublisherAppNameAppVersionPackageVersion]
    #$Publisher, $AppName, $AppVersion = $share.Split('\')[7, 8, 9]

    Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS"
    #Tried to load variables in a function, in a module or via .\variables but none of them worked
    Get-SCCMVariables
        

    if ($Option -eq 'CollectionsOnly')
    {
      Remove-SBCMAppVCollections
      $body += "App-V package ""$AppVPackageName"" was REMOVED with option 'CollectionsOnly' by $env:USERNAME on $CurrentDate"
    }
    if ($Option -eq 'PackagesOnly')
    {
      Remove-SBCMAppVPackages
      $body += "App-V package ""$AppVPackageName"" was REMOVED with option 'PackagesOnly' by $env:USERNAME on $CurrentDate"
    }
    ElseIf ($Option -eq 'Full')
    {
      Remove-SBCMAppVCollections
      Remove-SBCMAppVPackages
      $body += "App-V package ""$AppVPackageName"" was REMOVED with option 'Full' by $env:USERNAME on $CurrentDate"
    }                 
        
    $body = $body | Out-String
    Send-MailMessage -From $MailFromAddress -To $MailToAddressDeploySoftware -SmtpServer $PublicSMTPServer01_FQDN -BodyAsHtml -Subject 'REMOVE Telenet Software' -Body $body
    Write-Host -Object 'Removal script Finished' -ForegroundColor Magenta
    Set-Location -Path c:
    Add-Content $CMDeployLogFile -Value "End of executing 'Software Deployment Script' for $AppVPackageName by $env:USERNAME on $CurrentDate"
  }
  

  if ($SoftwareType -eq 'Application')
  {
      
    Get-SCCMApplicationPackageSoftwareVariables -Path $Path
    Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS" 
    Get-SCCMVariables
    
    if ($Option -eq 'Full')    
    {
      Remove-SBCMApplicationCollections
      Remove-SBCMApplication
      $body += "App-V package ""$FullApplicationName"" was REMOVED with option 'CollectionsOnly' by $env:USERNAME on $CurrentDate"
    }           
        
    $body = $body | Out-String
    Send-MailMessage -From $MailFromAddress -To $MailToAddressDeploySoftware -SmtpServer $PublicSMTPServer01_FQDN -BodyAsHtml -Subject 'REMOVE Telenet Software' -Body $body
    Write-Host -Object 'Removal script Finished' -ForegroundColor Magenta
    Set-Location -Path c:
    Add-Content $CMDeployLogFile -Value "End of executing 'Software Deployment Script' for $FullApplicationName by $env:USERNAME on $CurrentDate"

  }
  
     if ($SoftwareType -eq 'Package')
     {
      
       Get-SCCMApplicationPackageSoftwareVariables -Path $Path
       Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS" 
       Get-SCCMVariables
     
      if ($Option -eq 'Full') {
        Remove-SBCMPackageCollections
        Remove-SBCMPackages
        $body += "Package ""$PackageName"" was REMOVED with option 'Full' by $env:USERNAME on $CurrentDate"
      }          
        
       $body = $body | Out-String
       Send-MailMessage -From $MailFromAddress -To $MailToAddressDeploySoftware -SmtpServer $PublicSMTPServer01_FQDN -BodyAsHtml -Subject 'REMOVE Telenet Software' -Body $body
       Write-Host -Object 'Removal script Finished' -ForegroundColor Magenta
       Set-Location -Path c:
       Add-Content $CMDeployLogFile -Value "End of executing 'Software Deployment Script' for $PackageName by $env:USERNAME on $CurrentDate"

  





     }
  
 
}
  #! To make only these functions available and hide others, use following line
  #Export-ModuleMember -Function Deploy-CMSoftware, Remove-CMSoftware, Add-SBCMADGroupTiposToAppV, Get-CMSoftware
#endregion



#region TESTING

# get-testvariables or get-testvariables -appv for appv
# then run your tests

#endregion
