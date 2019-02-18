$applist = @(
"ALO - Adobe - FlashPlayer - 28.0.0.161 (1.0)",
"ALO - Citrix - CitrixReceiver - 4.6 (1.0)",
"ALO - ContinuumAnalytics - Python - 3.5 (1.0)",
"ALO - Crestron - Airmedia - 3.2.1.16 (2.0)",
"ALO - Microsoft - OfficeOneDrive - 2018 (1.0)",
"ALO - Microsoft - OfficeProjectProfessional - 2010 (1.0)",
"ALO - Microsoft App-V Client 5.0-SP3",
"ALO - NowMicro - RightClickTools - 3.0.6485 (1.0)",
"ALO - Salesforce - SalesforceForOutlook - 3.4.1.25 (1.0)",
"ALO - Skyline - DataMiner - 9.0.1611.2 (1.0)",
"AVI - C - Ayera - TeraTermPro - 2.3 (1.0)",
"AVI - C - CheckPoint - SmartConsole - R62 (1.0)",
"AVI - C - Eclipse - JavaTesters - 4.3 (1.0)",
"AVI - C - Garmin - Express - 4.1.17.0 (1.0)",
"AVI - C - Google - Earth - 7.1.5.1557",
"AVI - C - IBM - CognosForOffice - 10.1.1 (2.0)",
"AVI - C - Microsoft - Access - 2010SP2 (3.0)",
"AVI - C - Putty - Putty - 0.60 (1.0)",
"AVI - C - SAP - Business Objects Client - 4.1 SP6 (1.0)",
"AVI - C - SourceForge - Greenshot - 1.2.9.104 (1.0)",
"AVI - C - Symantec - EnterpriseVaultClient - 10.0.3.1189 (2.0)",
"AVI - C - XMind - XMind - 3.6.51 (1.0)",
"Codec Pack",
"Configure Wireless Interfaces",
"Dataminer CleanCABFiles",
"Dreamweaver",
"EasyRoute",
"GhostGum",
"HeadEndMetingen",
"IMEICollector",
"Internet Explorer",
"IOLibrariesSuite",
"Java JRE",
"Lotus Notes SQL Driver",
"Microsoft - OfficeVisioProfessionalRepair",
"NSM Etsi",
"Opera",
"Powerdesigner",
"PRD - OSD - Microsoft - Silverlight",
"Reboot - Reboot Pending",
"Reporting Tool",
"Salesforce for Outlook",
"SnapshotViewer",
"TweetDeck",
"VirtualBox",
"WinpCap",
"X-server for Windows"
)

$grups = Get-ADGroup -SearchBase "OU=Auto,OU=Computers,OU=Software Vista,OU=IT,DC=prod,DC=telenet,DC=be" -Filter * | select Name

ForEach($app in $applist) {
  If($app -like "ALO*") {
    $app = $app.Split('-')[2].Trim()
  }
  elseIf($app -like "AVI*") {
    $app = $app.Split('-')[3].Trim()
  }
  elseIf($app -match '\s') {
    $app = $app.Split(' ')[-1].Trim()
  }
  
  $ADfilter = "Name -like ""$app"""
  $abc = $grups | where Name -like "*$app*"
  
}

$abc | export-