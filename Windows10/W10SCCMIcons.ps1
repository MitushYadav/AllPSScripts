
Function Check-CMAppIcons {
    
    <#
    .Description
    Check if the CM icons exist and if not, import them
    #>

    param(
        [switch]$PRDOnly,
        [switch]$ImportIcons
    )

    # functions definitions
    Function Traverse-Folder {
        <#
        .Description
        Traverses N number to folders up
        #>
    
        param(
            [string]$path,
            [int]$levels
        )
    
        do {
            $path = [io.path]::GetDirectoryName($path)
            $levels = $levels - 1      
        } while ($levels -gt 0)
    
        return $path
    }

    $sitecode = 'CMC'
    Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
    $PackageShare = '\\Prod.telenet.be\adm\WSAAS\software deployment\Packages'

    If($PRDOnly){

        $FolderName = 'PRD'
        $SMSSiteCode = 'CMC'
        $SMSSiteServer = 'EWP001704.prod.telenet.be'
        
        $FolderID = (Get-WMIObject -Namespace "ROOT\SMS\Site_$SMSSiteCode" -ComputerName $SMSSiteServer -Query "SELECT ContainerNodeID FROM SMS_ObjectContainerNode WHERE Name LIKE '$FolderName' AND ObjectType='6000'").ContainerNodeID
        $Instancekeys = (Get-WmiObject -Namespace "ROOT\SMS\Site_$SMSSiteCode" -ComputerName $SMSSiteServer -query "select InstanceKey from SMS_ObjectContainerItem where ObjectType='6000' and ContainerNodeID='$FolderID'").instanceKey
        
        $allSCCMApps = @()
        foreach ($key in $Instancekeys)
        {
            Push-Location -Path $($sitecode + ':')
            $allSCCMApps += Get-CMApplication -Name $((Get-WmiObject -Namespace "ROOT\SMS\Site_$SMSSiteCode" -ComputerName $SMSSiteServer -Query "select LocalizedDisplayName from SMS_Applicationlatest where ModelName = '$key'").LocalizedDisplayName)
            Pop-Location
        }
    }
    else {
        Push-Location -Path $($sitecode + ':')
        $allSCCMApps = Get-CMApplication
        Pop-Location
    }
        
    $IconInfo = @()

    ForEach($app in $allSCCMApps)
    {
        #incorrect as Flexera auto packaged apps point to another source location
        $iconFolder = "$(Traverse-Folder -path "$(([xml]$app.SDMPackageXML).AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location)" -levels 4)\1.DOC\ICO"
        #$app.LocalizedDisplayName.Split(' - ')
        $IconInfo += [PSCustomObject]@{
            Application = $app.LocalizedDisplayName
            SCCMIcon = if(([xml]$app.SDMPackageXML).AppMgmtDigest.Application.DisplayInfo.Info.Icon) {
                'Yes'
            }
            else {
                $null
            }
            IconFile = If(Test-Path $iconFolder) {
                (Get-ChildItem $iconFolder).FullName
            }
            else {
                $null
            }
        }

        If($ImportIcons) {
            If($IconInfo.SCCMIcon -ne 'Yes') {
            ..\Set-CMApplicationIcon.ps1 -SiteServer 'EWP001704.prod.telenet.be' -SiteCode 'CMC' -ApplicationName $($app.LocalizedDisplayName) -IconSize 400 -IconFolder $iconFolder
            }
        }
    }

    $Header = @"
    <style>
    TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
    TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
    TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
    </style>
"@
    $IconInfo | ConvertTo-Html -Property Application,SCCMIcon,IconFile -Head $Header | Out-File -FilePath C:\workingDir\iconReportW10.html

}
