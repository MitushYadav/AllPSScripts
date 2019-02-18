#new directory structure
# \\prod.telenet.be\adm\WSAAS\Software Deployment\Packages\<Vendor>\<Software>\3.PKG\<version>\<build>\<APPV or MSI>\<actual files>

#Create new SCCM AppV Application using the current path

#Set-ExecutionPolicy, needed to be able to load variables from 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\SCCMVariables\, otherwise message "script is not signed"
Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope Process -Confirm:$false -Force 
Set-ExecutionPolicy -ExecutionPolicy 'RemoteSigned' -Scope CurrentUser -Confirm:$false -Force

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


######################################### SCCM VARIABLES ######################3

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
  $Global:Time = Get-Date -Format 'hh:mm'
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
  $Global:Publisher, $Global:AppName, $Global:AppVersion, $Global:PackageVersionOnDFS = $share.Split('\')[$AppVSharePublisherAppNameAppVersionPackageVersion]
  
  Write-Host -Object "Variables used are:  $Publisher, $AppName, $AppVersion, $PackageVersionOnDFS" 
}



##################### MY WORK #######################################333 

#SCCM Application metadata, eg Category, Comments, etc

$MYAppCatInfo = ([xml](Get-CMApplication -name "Test Application").SDMPackageXML).AppMgmtDigest.Application.DisplayInfo.Info


# Create a Device collection with query to discover devices with previous versions installed

# query to get Appv packages through WQL :  select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_APPV_CLIENT_PACKAGE on SMS_G_System_APPV_CLIENT_PACKAGE.ResourceId = SMS_R_System.ResourceId where SMS_G_System_APPV_CLIENT_PACKAGE.Name LIKE "Allround - PLSQLDeveloper%"

New-CMCollection -CollectionType Device -LimitingCollectionName "PRD - DCO - W7 - All" -Name "$Vendor - $Application - INSTALLED"

#adding the WQL collection rule
Add-CMCollectionQueryMembershipRule -CollectionName "$Vendor - $Application - INSTALLED" -RuleName "Installed" -QueryExpression = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_APPV_CLIENT_PACKAGE on SMS_G_System_APPV_CLIENT_PACKAGE.ResourceId = SMS_R_System.ResourceId where SMS_G_System_APPV_CLIENT_PACKAGE.Name LIKE `"$Vendor - Application%`""


# Check if previous versions exist. If previous version < current version, set supersedence with uninstall. (Uninstall/unpublish for all users)

$AllApps = Get-CMApplication -Name "AVI - C - $Vendor - $Application*"

if($AllApps.Count -gt 1) {
  $maxVersion = $AllApps | Measure-Object -Property SoftwareVersion -Maximum
  }
  
  #check if current version is same as max version, If yes, set supersedence.


#Create a mandatory deployment for the created previous versions installed collection to upgrade to newer version 