[CmdletBinding()]

param(
    # Full path to the zip file
    [Parameter(Mandatory=$false)]
    [string]
    $ZIPPath,
    [Parameter(Mandatory=$true)]
    [string]
    $MarlinVersion,
    [Parameter(Mandatory=$false)]
    [string]
    $ArcGISProVersion
)

#variable declaration
$W7PackagePath = "\\prod.telenet.be\adm\PackageSources\SCCM\W7\x64"
$Vendor = "Merkator"
$ApplicationName = "Marlin"
$SCCMSiteCode = "PRD"
$SCCMSiteServer = "PROD425.prod.telenet.be"
$PackageTemplatePath = "C:\Tools\PSADT_Marlin"
$TempFolderPath = "C:\workingDir\Marlin"
$TempFolderName = "Marlin" + "_" + $MarlinVersion

$MarlinPkg = @{
    Version = $MarlinVersion
    Date = Get-Date -Format "dd/MM/yyyy"
}

#copy over sample PSADT to temp folder and replace revelant parts
Copy-Item -Path $PackageTemplatePath -Destination $($TempFolderPath + $TempFolderName) -Recurse
$DeployApp = Get-Content -Path $($TempFolderPath + $TempFolderName + "\Deploy-Application.ps1")
$DeployApp | ForEach-Object -Process {
    $PSItem -replace "{VERSION}","$($MarlinPkg.Version)" `
            -replace "{DATE}","$($MarlinPkg.Date)"
} | Set-Content -Path $($TempFolderPath + $TempFolderName + "\Deploy-Application.ps1") -Force

#create SCCM Application and deploy to Test collection
Invoke-Command -ComputerName $SCCMSiteServer -ScriptBlock {
    Import-Module -Name "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
    Set-Location -Path $($SCCMSiteCode + ":")
    

}