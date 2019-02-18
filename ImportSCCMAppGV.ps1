Globalvariables


#GENERAL
$Global:Company = "Telenet"
$Global:Organization = "Telenet"
$Global:EmailSuffix = "@TelenetGroup.be"
$Global:DomainFQDN = $env:USERDNSDOMAINd
$Global:SCCMSiteCode01 = "PRD"
$Global:SCCMSiteCode02 = 'CMC'
$Global:MailFromAddress = "noreply$EmailSuffix"
$Global:MailToAddressDeploySoftware = "steven.baert$EmailSuffix"
$Global:MailAddressWorkPlaceEngineering = "F_IT.Workplace.Engineering$EmailSuffix"
#SERVERS
$Global:SCCMSiteServer01 = 'PROD425'
$Global:PublicSMTPServer01 = 'SMTP' #SMTP server which does not need authentication
$Global:ConnectionBroker01 = 'PROD467'
$Global:ConnectionBroker02 = 'PROD481'
$Global:ConnectionBroker03 = 'PROD482'
$Global:RemoteAppServer01 = 'EWP001069'
$Global:RemoteAppServer02 = 'EWP001070'
$Global:PictureServer01 = 'PROD465'
$Global:ReportingServer01 = 'PROD479'
$Global:ExchangeServer01 = 'EWP000923'
$Global:RDS02 = 'RDS2'
$Global:RDS03 = 'RDS3'
$Global:SQLReportingServer01 = 'PROD450'
$Global:Reporting01ServerAlias = 'reportingserver'
$Global:ViServer01 = 'prod203'
#RDS
$Global:CollectionRemoteAppRDS03 = 'RA Universal PRD'
#SOFTWARE GENERAL
$Global:PackageSourcesShare = "\\$DomainFQDN\ADM\PackageSources\"
#SOFTWARE PER TECHNOLOGY
$Global:AppVPackagesShare = "\\$DomainFQDN\ADM\PackageSources\AppV\X64\"
$Global:ApplicationsShare = "\\$DomainFQDN\ADM\PackageSources\SCCM\W7\x64\"
$Global:PackagesShare = "\\$DomainFQDN\ADM\PackageSources\SCCM\W7\x64\"
$Global:NetlogonShare = "\\$DomainFQDN\Netlogon"


#Selection of Publisher, AppName, AppVersion,Packageversion on $AppVPackageShare
$Global:AppVSharePublisherAppNameAppVersionPackageVersion01 = @(7,8,9,10)
#If different root share to be used for selection of Publisher, AppName, AppVersion,Packageversion on $AppVPackageShare
$Global:AppVSharePublisherAppNameAppVersionPackageVersion01 = @(7,8,9,10)

#DO THE SAME FOR APPLICATION/PACKAGES
#Selection of Publisher, AppName, AppVersion,Packageversion on $ApplicationsShare
$Global:ApplicationSharePublisherAppNameAppVersionPackageVersion02 = @(5,6,7,8)


$Global:DepartmentDFSFolder = "\\$DomainFQDN\PRD\DEP"

$Global:CMNewApplicationCollectionFolderPath  = "$SCCMSiteCode01\Software\W7-Applications\NEW"
$Global:CMNewApplicationFolderPath = "$SCCMSiteCode01\NEW"

  
#SCCM VARIABLES FOR deployments/queries
$Global:CMDeployPurpose = 'Required' #Available or Required
$Global:CMDeployLogFile = Join-Path  $PackageSourcesShare -childpath 'Deployments.log'
$Global:CMAppVNameComputersPrefix = "AVI - C"
$Global:CMAppVNameUsersPrefix = "AVI - U"
$Global:CMApplicationNamePrefix = "ALO"
$Global:CMDistributionPointGroupName = "$Company DG"
$Global:CMADMainAppVGroupPrefix = "APPV-5-PRD"
$Global:CMADMainApplicationGroupPrefix = 'APP-PRD-C'
$Global:CMDeviceCollectionNamePackagePrefix = 'W7 - PRD'
$Global:CMLimitingCollectionUsers = 'All Users'
#Not in use $Global:CMLimitingCollectionUsersUninstall = 'All RDS Users'
$Global:CMLimitingCollectionW7 = 'PRD - DCO - W7 - All'
$Global:CMOUPathAppV = 'OU=App-V,OU=Software W7,OU=IT,DC=prod,DC=telenet,DC=be'
$Global:CMOUPathComputers = 'OU=Auto,OU=Computers,OU=Software Vista,OU=IT,DC=prod,DC=telenet,DC=be'
$Global:CMSoftwareSupportContact = 'Helpdesk'
$Global:CMDeviceCollectionNamePrefix = "$SCCMSiteCode01 - DCO"
$Global:CMSoftPackageFolder = '5.PKG'
$Global:CMUserCollectionNameAppVPRDUNINSTALL = 'All RDS Users'
$Global:CMDeviceCollectionNameAppVUNINSTALL = 'All Workstations Active'
$Global:DeviceCollectionNameApplicationUNINSTALL = 'All Workstations Active'
$Global:CMDeviceCollectionNameApplicationPrefix = 'ALO'
#SCCM => TO CHECK, DOES NOT WORK SO $AppVPackageWithoutShorCutFolderPath is in DEPLOY-SOFTWARE.PSM1 right now
$Global:AppVPackageWithoutShorCutFolderPath = "PRD:\Application\PRD\RDS-App-V-NOSHORTCUT"

#AD Groups, used in Get-RDSADGroupMembers
$Global:RDSADGroupNames = @{ 
  Cognizant = 'APP PRD U cognizant'
  Cegeka = 'APP PRD U Cegeka'
  Base = 'APP PRD U Base'
  Technicians = 'APP PRD U Field Technicians'
  Agilis = 'APP PRD U Agilis'
  CognizantMS =  '(F) IT Cognizant Infrastructure support Offshore'
  InfoSys = 'APP PRD U InfoSys'
  Mphasis = 'APP PRD U Mphasis'
  NetCracker = 'APP PRD U NetCracker'
  NASEngineering = 'APP PRD U Telenet NAS Engineering'
  WindowsEngineering = 'APP PRD U Windows Engineering'
  HelpDesk = 'APP PRD U Real Dolmen'
  GISXXL =  'APP PRD U RDS GISXXL'
  VMWareSphereClient ='APPR-PRD-VMWare-VSphereClient'
  PackagingTeam = '(F) IT Desktop Software Lifecycle Management'
  ADGroupITEngineeringPrivilged = '(DLG) - IT Windows Engineering Privileged Users'
}
#NETLOGON
#Format for samaccountname.txt => Logon : samaccountname  server dd/MM/YYYY hh:mm:ss  Mac : xx:yy:zz:xx:yy:zz IP : 0.0.0.0
#Format for computername.txt =>  Logon : samaccontname  PCNAME dd/MM/YYYY hh:mm:ss Mac : xx:yy:zz:xx:yy:zz IP : 0.0.0.0
$LogonScriptsLocation = "\\$DomainFQDN\ADM\Logs\LogonScript\"
######################################################


$Global:PowerCLIPS1Path = 'C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1'


#FQDN
$Global:SCCMSiteServer01_FQDN =  ($SCCMSiteServer01 + '.' + $DomainFQDN)
$Global:PublicSMTPServer01_FQDN = ($PublicSMTPServer01 + '.' + $DomainFQDN)
$Global:PictureServer01_FQDN =  ($PictureServer01 + '.' + $DomainFQDN)
$Global:ConnectionBroker01_FQDN = ($ConnectionBroker01 + '.' + $DomainFQDN)
$Global:ConnectionBroker02_FQDN = ($ConnectionBroker02 + '.' + $DomainFQDN)
$Global:ConnectionBroker03_FQDN = ($ConnectionBroker03 + '.' + $DomainFQDN)
$Global:RDS02_FQDN = ($RDS02 + '.' + $DomainFQDN)
$Global:RDS03_FQDN = ($RDS03 + '.' + $DomainFQDN)
$Global:RemoteAppServer01_FQDN = ($RemoteAppServer01 + '.' + $DomainFQDN)
$Global:RemoteAppServer02_FQDN = ($RemoteAppServer02 + '.' + $DomainFQDN)
$Global:ReportingServer01_FQDN = ($ReportingServer01 + '.' + $DomainFQDN)
$Global:SQLReportingServer01_FQDN = ($SQLReportingServer01 + '.' + $DomainFQDN)
$Global:ExchangeServer01_FQDN = ($ExchangeServer01 + '.' + $DomainFQDN)
$Global:ReportingServer01Alias_FQDN = ($Reporting01ServerAlias + '.' + $DomainFQDN)
$Global:ViServer01_FQDN = ($ViServer01 + '.' + $DomainFQDN)

$Global:FileSharePictureUsers = "\\$PictureServer01_FQDN\TGPhoto"

#OTHER
$Global:Reportingserver01_URL =  "http://$ReportingServer01_FQDN"
