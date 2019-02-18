#pull data from Erik's list
$elist = Get-Content C:\workingDir\eriklist.txt

$complete = @()

$details = New-Object PSCustomObject

#$allcoll = Get-CMCollection
#$allDevColl = Get-CMDeviceCollection

foreach($coll in $allDevColl) {
    $collQuery = (Get-CMCollectionQueryMembershipRule -CollectionName $coll.Name).QueryExpression
    $collQuery -match 'PROD\\\\(.*)[^"]' | Out-Null
    $adgroup = $Matches[0].Substring(6)
    If($adgroup.StartsWith('APPV')) {
        #AppV
        $usable = $adgroup.Substring(11)
        }
    else {
        #Application/Package
        $usable = $adgroup.Substring(10)
        }

    If ($elist -contains $usable) {
        $dep = Get-CMDeployment -CollectionName $coll.Name
        If($dep.Count -gt 1) { $dep = $dep[0] }
        If($dep.FeatureType -eq 1) {
            #means Application
            $app = Get-CMApplication -Name $dep.SoftwareName

            $details = @{}

            #get the application data
            $details.PackageId = $app.PackageId
            $details.Name = $app.LocalizedDisplayName
            $details.Manufacturer = $app.Manufacturer
           # $details.Version = #get from location
            $details.Type = 'Application'
            $details.Location = (([xml](Get-CMApplication -name $($app.LocalizedDisplayName)).SDMPackageXML).AppMgmtDigest).DeploymentType.Installer.contents.content.location
            }
        If($dep.FeatureType -eq 2) {
            #Package
            #$len = ($dep.softwareName).length

            $details = @{}
            $pack = (Get-CMPackage -Name $($dep.SoftwareName).Substring(0,$($dep.SoftwareName).Length - 10))
            
            #get package data
            $details.PackageId = $pack.PackageId
            $details.Name = $pack.Name
            $details.Manufacturer = $pack.Manufacturer
            
            $details.Type = 'Package'
            $details.Location = (Get-CMPackage -Name $($pack.Name)).PkgSourcePath
           #  $details.Version = 
            }
          $complete += [PSCustomObject]$details         
    }
}

#write all data into a file