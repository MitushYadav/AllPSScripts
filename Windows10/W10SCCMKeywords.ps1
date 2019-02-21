$sitecode = 'CMC'
Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Push-Location -Path $($sitecode + ':')
$allSCCMApps = Get-CMApplication
Pop-Location
$keywordInfo = @()

ForEach($app in $allSCCMApps)
{
    $keywordInfo += [PSCustomObject]@{
        Application = $app.LocalizedDisplayName
        Keywords = ([XML]($app.SDMPackageXML)).AppMgmtDigest.Application.DisplayInfo.Info.Tags.Tag
    }
}

$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #6495ED;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@
$keywordInfo | ConvertTo-Html -Property Application,Keywords -Head $Header | Out-File -FilePath C:\workingDir\keywordReportW10.html