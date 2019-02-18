#Get all active deployments
$reqDep = get-cmdeployment | where-object { $_.FeatureType -in 1,2 -and $_.NumberTargeted -gt 0 }

$finalLoc = @()

foreach($dep in $reqDep) {
    if ($dep.FeatureType -eq 1) {
        #Application
        $details = @{}
            
            #get the Location from the Application Deployment Type
            $ALocation = (([xml](Get-CMApplication -name $($dep.SoftwareName)).SDMPackageXML).AppMgmtDigest).DeploymentType.Installer.contents.content.location
            #Split the resultant location, fe \\prod.telenet.be\adm\PackageSources\SCCM\W7\x64\Oracle\InstantClient64bit\12.2.0.1.0\1.0\5.PKG for Applications and \\prod.telenet.be\adm\PackageSources\AppV\X64\Oracle\ASAPOCAClient\5.2.4\4.0\5.PKG for AppV
            If($ALocation.Split('\')[5] -eq 'SCCM') {
                #Application - Scripted
                $details.Vendor = $ALocation.Split('\')[8]
                $details.ApplicationName = $ALocation.Split('\')[9]
                $details.ApplicationVersion = $ALocation.Split('\')[10]
                $details.PackageBuild = $ALocation.Split('\')[11]
                $details.Type = 'Scripted'
            }
            If($ALocation.Split('\')[5] -eq 'AppV') {
                #App-V
                $details.Vendor = $ALocation.Split('\')[7]
                $details.ApplicationName = $ALocation.Split('\')[8]
                $details.ApplicationVersion = $ALocation.Split('\')[9]
                $details.PackageBuild = $ALocation.Split('\')[10]
                $details.Type = 'App-V'
            }
        $finalLoc += [PSCustomObject]$details
        }
    else {
        #Package
        $packages = Get-CMPackage -Name $($dep.SoftwareName).Substring(0,$($dep.SoftwareName).Length - 10)
        
        $details = @{}

            #Package
            #get Package location from the CM Package object
            $PLocation = $packages.PkgSourcePath
            
            #Split the location. Same as application
            $details.Vendor = $PLocation.Split('\')[8]
            $details.ApplicationName = $PLocation.Split('\')[9]
            $details.ApplicationVersion = $PLocation.Split('\')[10]
            $details.PackageBuild = $PLocation.Split('\')[11]
            $details.Type = 'Scripted'
            $finalLoc += [PSCustomObject]$details
            }
        
    }

#temporary object.
#$finalLocTemp = $finalLoc


$finalAppList = $finalLoc | select * -unique

#export unique values to a CSV
$finalAppList | Export-Csv C:\workingDir\ActiveList.csv -NoTypeInformation

$UNselFinalAppList = $finalAppList | select ApplicationName,Vendor,ApplicationVersion -unique

# $UNselFinalAppList = $selFinalAppList | select *
#kinda unnecessary code to remove the duplicate values

$SuperFinal = @()

foreach($something in $UNselFinalAppList) {
    #go through each app in unique list
    foreach($value in $finalAppList) {
        if($something.ApplicationName -eq $value.ApplicationName -and $something.Vendor -eq $value.Vendor -and $something.ApplicationVersion -eq $value.ApplicationVersion) {
            $SuperFinal += $value
            break }
            }
        }
            


$usrContinue = Read-Host "Application List created. Continue with copying over the source files?(y/n)"

If($usrContinue -eq 'y') {
    #Copy over!
    foreach($app in $SuperFinal) {

        #create necessary folders

            If(!(Test-Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$app.Vendor")) {
                #create Vendor folder
                New-Item -Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$($app.Vendor)" -ItemType Directory }

            If(!(Test-Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$app.Vendor\$app.ApplicationName")) {
                New-Item -Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$($app.Vendor)\$($app.ApplicationName)" -ItemType Directory }

            If(!(Test-Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$app.Vendor\$app.ApplicationName\$app.ApplicationVersion")) {
                New-Item -Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$($app.Vendor)\$($app.ApplicationName)\$($app.ApplicationVersion)" -ItemType Directory }

            #If(!(Test-Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$app.Vendor\$app.ApplicationName\$app.ApplicationVersion\2.SRC")) {
             #   New-Item -Path "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$($app.Vendor)\$($app.ApplicationName)\$($app.ApplicationVersion)\2.SRC" -ItemType Directory }

        If($app.Type -eq 'Scripted') {
          
            #copy from \\prod.telenet.be\adm\PackageSources\SCCM\W7\x64\<Vendor>\<AppName>\<version>\1.0\2.SRC
            Copy-Item "\\prod.telenet.be\adm\PackageSources\SCCM\W7\x64\$($app.Vendor)\$($app.ApplicationName)\$($app.ApplicationVersion)\$($app.PackageBuild)\2.SRC" "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$($app.Vendor)\$($app.ApplicationName)\$($app.ApplicationVersion)" -Recurse -Verbose

            }
            else {
                #AppV
                Copy-Item "\\prod.telenet.be\adm\PackageSources\AppV\X64\$($app.Vendor)\$($app.ApplicationName)\$($app.ApplicationVersion)\$($app.PackageBuild)\2.SRC" "\\prod.telenet.be\ADM\WSAAS\Software Deployment\Packages\$($app.Vendor)\$($app.ApplicationName)\$($app.ApplicationVersion)" -Recurse -Verbose
                }
           }
        }

    