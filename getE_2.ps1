#Get all active deployments
$reqDep = get-cmdeployment | where-object { $_.FeatureType -in 1,2 -and $_.NumberTargeted -gt 0 }

$final = @()

foreach($dep in $reqDep) {
    if ($dep.FeatureType -eq 1) {
        #Application
        $applications = Get-CMApplication -ID $dep.CI_ID
        $details = @{}

        #Since there can be multiple deployments for the same software name
        
            $details.NumberInstalled = $dep.NumberSuccess 
            $details.PackageId = $app.PackageId
            $details.Name = $app.LocalizedDisplayName
            $details.Manufacturer = $app.Manufacturer
            $details.Type = 'Application'
            $details.Location = ([xml]($app.SDMPackageXML).AppMgmtDigest).DeploymentType.Installer.contents.content.location
            $details.Version = $app.SoftwareVersion
            If($app.LocalizedDisplayName -like "ALO*") { $details.Type = 'Scripted' }
            If($app.LocalizedDisplayName -like "AVI*") { $details.Type = 'App-V' }
            $details.SCCMType = 'Application'
            $final += [PSCustomObject]$details
            
        }
    else {
        #Package
        $packages = Get-CMPackage -ID $app.PackageID
        
        $details = @{}

        
            $details.NumberInstalled = $dep.NumberSuccess
            $details.PackageId = $pack.PackageId
            $details.Name = $pack.Name
            $details.Manufacturer = $pack.Manufacturer
            $details.Location = $pack.PkgSourcePath
            $details.Version = $pack.Version
            $details.Type = 'Scripted'
            $details.SCCMType = 'Package'
            $final += [PSCustomObject]$details
            
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
