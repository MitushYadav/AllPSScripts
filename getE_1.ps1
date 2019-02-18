#Get all active deployments
$reqDep = get-cmdeployment | where-object { $_.FeatureType -in 1,2 -and $_.NumberTargeted -gt 0 }

$final = @()

foreach($dep in $reqDep) {
    if ($dep.FeatureType -eq 1) {
        #Application
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
            If($app.LocalizedDisplayName -like "ALO*") { $details.Type = 'Scripted' }
            If($app.LocalizedDisplayName -like "AVI*") { $details.Type = 'App-V' }
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
            $details.Type = 'Scripted'
            $final += [PSCustomObject]$details
            }
        }
    }

$finalTemp = $final

$finalNew = $final

#Remove Duplicates

foreach($entry in $final) {
    If($entry.Name -like "ALO*") { 
        $entry.Name = $entry.Name.Substring(6)
        }
    If($entry.Name -like "AVI*") {
        $entry.Name = $entry.Name.Substring(10)
        }
    If($entry.Name -like "*NOSHORTCUT") {
        $entry.Name = $entry.Name.Substring(0,$entry.Name.Length - 13)
        }
    }

$finalList = $final | select * -unique


#ExportToCSV
$finalList | Export-Csv C:\workingDir\AllActiveDepList1.csv -NoTypeInformation 
