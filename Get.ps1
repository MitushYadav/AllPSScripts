
#Get all active deployments
$reqDep = get-cmdeployment | where-object { $_.FeatureType -in 1,2 -and $_.NumberTargeted -gt 0 }

$final = @()

$allDeviceColl = Get-CMDeviceCollection

$allDeviceCollName = $allDeviceColl | select Name

foreach($dep in $reqDep) {
    if ($dep.FeatureType -eq 1) {
        #Application

        #if deployment is to a device collection
        if($dep.CollectionName -in $allDeviceCollName)


        $applications = Get-CMApplication -Name $dep.SoftwareName
        $details = @{}

        #Since there can be multiple deployments for the same software name
        foreach($app in $applications) {
            $details.PackageId = $app.PackageId
            $details.Name = $app.LocalizedDisplayName
            $details.Manufacturer = $app.Manufacturer
            $details.Type = 'Application'
            $details.Location = (([xml](Get-CMApplication -name $($app.LocalizedDisplayName)).SDMPackageXML).AppMgmtDigest).DeploymentType.Installer.contents.content.location
            $details.Version = $app.SoftwareVersion
            $final += [PSCustomObject]$details
            }
        }
    else {
        #Package
        $packages = Get-CMPackage -Name $($dep.SoftwareName).Substring(0,$($dep.SoftwareName).Length - 10)
        
        $details = @{}

        foreach($pack in $packages) {

            $details.PackageId = $pack.PackageId
            $details.Name = $pack.Name
            $details.Manufacturer = $pack.Manufacturer
            $details.Type = 'Package'
            $details.Location = $pack.PkgSourcePath
            $details.Version = $pack.Version
            $final += [PSCustomObject]$details
            }
        }
    }

#ExportToCSV
$final | select * | Export-Csv C:\workingDir\AllActiveDepList.csv -NoTypeInformation