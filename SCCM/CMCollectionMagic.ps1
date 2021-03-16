 #region variables
  $PrimarySiteServer = "SCCM.contoso.net"
  $ServerCIMSession = New-CimSession -ComputerName $PrimarySiteServer -Credential $script:Credentials -Name "ServerCIMSession"
  $SiteCode = (Get-CimInstance -CimSession $ServerCIMSession -Namespace "root\sms" -ClassName "__Namespace").Name.Substring(5, 3)
  $NameSpace = "root\sms\site_$SiteCode"
  $Collections = @()
  #endregion variables
  
  #region CIM Objects for comparison later
  $AllCollections = Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_Collection -Namespace $NameSpace -Filter "CollectionType='2' and IsBuiltIn=0"
  $CollectionsUsedAsExcludes = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='3'").SourceCollectionID | Sort-Object -Unique
  $CollectionHasExcludes = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='3'").DependentCollectionID | Sort-Object -Unique
  $CollectionsUsedAsIncludes = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='2'").SourceCollectionID | Sort-Object -Unique
  $CollectionHasIncludes = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='2'").DependentCollectionID | Sort-Object -Unique
  $LimitingCollections = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='1'").SourceCollectionID | Sort-Object -Unique
  $CollectionsWithClientSettings = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_ClientSettingsAssignment -Namespace $NameSpace -Property CollectionID).CollectionID | Sort-Object -Unique
  $CollectionsWithDeployments = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_DeploymentInfo -Namespace $NameSpace -Property CollectionID).CollectionID | Sort-Object -Unique
  #endregion CIM Objects for comparison later
  
  foreach ($collection in $AllCollections)
  {
  	#Some properties are LAZY so we need to actually initiate a CimInstance per-object.
  	$collection = $collection | Get-CimInstance -CimSession $ServerCIMSession
  	
  	#region set defaults per collection
  	$HasIncludes = $false
  	$Includes = $null
  	$HasExcludes = $false
  	$Excludes = $null
  	$HasPolicyDeployed = $false
  	$HasDeployment = $false
  	$UsedAsExcludeCollection = $false
  	$CollectionsThatExclude = $null
  	$UsedAsIncludeCollection = $false
  	$CollectionsThatInclude = $null
  	$UsedAsLimitingCollection = $false
  	$CollectionsItLimits = $null
  	$CollectionID = $collection.CollectionID
  	#region set defaults per collection
  	
  	#determine collection refresh type
  	if ($collection.RefreshType -eq "1")
  	{ $RefreshType = "Manual Update only" }
  	elseif ($collection.RefreshType -eq "2")
  	{ $RefreshType = "Periodic Updates only" }
  	elseif ($collection.RefreshType -eq "4")
  	{ $RefreshType = "Incremental Updates Only" }
  	elseif ($collection.RefreshType -eq "6")
  	{ $RefreshType = "Incremental and Periodic Updates" }
  	
  	if ($CollectionHasExcludes -contains $CollectionID)
  	{
  		$HasExcludes = $true
  		$Excludes = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='3' and DependentCollectionID='$CollectionID'").SourceCollectionID | Sort-Object -Unique
  	}
  	
  	if ($CollectionHasIncludes -contains $CollectionID)
  	{
  		$HasIncludes = $true
  		$Includes = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='2' and DependentCollectionID='$CollectionID'").SourceCollectionID | Sort-Object -Unique
  	}
  	
  	if ($CollectionsWithClientSettings -contains $CollectionID)
  	{
  		$HasPolicyDeployed = $true
  	}
  	
  	if ($CollectionsWithDeployments -contains $CollectionID)
  	{
  		$HasDeployment = $true
  	}
  	
  	if ($CollectionsUsedAsExcludes -contains $CollectionID)
  	{
  		$UsedAsExcludeCollection = $true
  		$CollectionsThatExclude = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='3' and SourceCollectionID='$CollectionID'").DependentCollectionID | Sort-Object -Unique
  	}
  	
  	if ($CollectionsUsedAsIncludes -contains $CollectionID)
  	{
  		$UsedAsIncludeCollection = $true
  		$CollectionsThatInclude = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='2' and SourceCollectionID='$CollectionID'").DependentCollectionID | Sort-Object -Unique
  	}
  	
  	if ($LimitingCollections -contains $CollectionID)
  	{
  		$UsedAsLimitingCollection = $true
  		$CollectionsItLimits = (Get-CimInstance -CimSession $ServerCIMSession -ClassName SMS_CollectionDependencies -Namespace $NameSpace -Filter "RelationshipType='1' and SourceCollectionID='$CollectionID'").DependentCollectionID | Sort-Object -Unique
  	}
  	
  	#create the actual pscustomobject and add it into our collections array
  	$Collections += [pscustomobject] @{
  		"CollectionName"   = $collection.Name;
  		"CollectionID"	   = $collection.CollectionID;
  		"MemberCount"	   = $collection.LocalMemberCount;
  		"RefreshType"	   = $RefreshType;
  		"LimitingCollection" = $collection.LimitToCollectionName;
  		"DaySpan"		   = $collection.RefreshSchedule.DaySpan;
  		"StartTime"	       = $collection.RefreshSchedule.StartTime;
  		"DayOfWeek"	       = $collection.RefreshSchedule.StartTime.DayOfWeek;
  		"HasExcludes"	    = $HasExcludes;
  		"Excludes"		    = $Excludes;
  		"HasIncludes"	    = $HasIncludes;
  		"Includes"		    = $Includes;
  		"HasDeployment"    = $HasDeployment;
  		"HasPolicyDeployed" = $HasPolicyDeployed;
  		"UsedAsExcludeCollection" = $UsedAsExcludeCollection;
  		"CollectionsThatExclude" = $CollectionsThatExclude;
  		"UsedAsIncludeCollection" = $UsedAsIncludeCollection;
  		"CollectionsThatInclude" = $CollectionsThatInclude;
  		"UsedAsLimitingCollection" = $UsedAsLimitingCollection;
  		"CollectionsItLimits" = $CollectionsItLimits;
  		"LastMembershipChangeTime" = $collection.LastMemberChangeTime;
  	}
  }
  $ServerCIMSession.Close() #gotta close those cimsessions!!
  $Collections | Out-GridView
