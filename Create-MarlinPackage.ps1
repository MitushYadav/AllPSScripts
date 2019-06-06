<#
.SYNOPSIS
    Accepts the ZIP file for the Marlin package and creates an SCCM application from it
.DESCRIPTION
    Long description
.EXAMPLE
    Example of how to use this cmdlet
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    The functionality that best describes this cmdlet
#>

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip-Archive {
    param(
        # zipfile
        [Parameter(Mandatory=$true)]
        [string]
        $ZipFilePath,
        [Parameter(Mandatory=$true)]
        [string]
        $OutPath
    )

    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath,$OutPath)

}
function Create-MarlinPackage {
    [CmdletBinding(DefaultParameterSetName='Default')]
    Param (
        #Complete path to Marlin archive file
        [Parameter(Mandatory=$true,
        ParameterSetName="Archive")]
        [string]
        $ArchivePath,
        
        #Version number
        [Parameter(Mandatory=$true,
        ParameterSetName="Archive")]
        [string]
        $Version,

        #Sharepoint page URL
        [Parameter(Mandatory=$true,
        ParameterSetName="Sharepoint")]
        [string]
        $SharepointFormURL,
        
        #SCCM site code
        [Parameter(Mandatory=$true)]
        [ValidateSet("PRD","CMC")]
        [String]
        $SCCMSiteCode,

        #Windows or Server target
        [Parameter(Mandatory=$true)]
        [ValidateSet("WKX","WX")]
        [string]
        $TargetOS
    )
    
    begin {
        Write-Host "Packaging Marlin client $Version and distributing to $SCCMSiteCode SCCM"
        $PRDPackageShare = '\\prod.telenet.be\adm\PackageSources\SCCM\W7\x64'
        $CMCPackageShare = '\\prod.telenet.be\adm\wsaas\software deployment\Packages'
        $TempDir = 'C:\workingDir'
        If($TargetOS -eq "WKX") {
            $PSADTLocation = "\\prod.telenet.be\adm\DSLMpublic\Mitush\Marlin_Template_WKX"
        }
        else {
            $PSADTLocation = "\\prod.telenet.be\adm\DSLMpublic\Mitush\Marlin_Template_WX"
        }
        . .\Windows10\W10AppImportv2.ps1
    }
    
    process {

        If($SharepointFormURL) {
        #sharepoint page handling
            $formData = Invoke-WebRequest -Uri $SharepointFormURL
            $appVendor = $($formData.InputFields | where title -eq "Application vendor").Value
            $appName = $($formData.InputFields | where title -eq "Application name").Value
            $appVersion = $($formData.InputFields | where title -eq "Application version").Value
            $ArchivePath = $($formData.InputFields | where title -eq "Application installation sources").Value
        }

        try{
            Test-Path -Path $ArchivePath -ErrorAction Stop
            Write-host "File found. Proceeding"
        }
        catch{
            Write-Host "File not found. Aborting"
        }

        Copy-Item -Path $ArchivePath -Destination $TempDir

        $ArchiveName = $ArchivePath.Replace('\\','\').Split('\')[-1].Replace('.zip','')

        try{
            If(Test-Path "$TempDir\$ArchiveName" -ErrorAction Stop) {
                Remove-Item -Path "$TempDir\$ArchiveName" -Recurse
            }
        }
        catch{
            Write-Host "already exists"
        }
        

        $MarlinDir = $("Marlin_" + $version + "_PHY")
        New-Item -Path "$TempDir\$MarlinDir" -ItemType Directory
        Copy-Item -Path "$PSADTLocation\*" -Destination "$TempDir\$MarlinDir" -Recurse

        Unzip-Archive -ZipFilePath "$TempDir\$ArchiveName.zip" -OutPath "$TempDir\$MarlinDir\Files"

        Start-Process -FilePath "C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell_ise.exe" -ArgumentList "$TempDir\$MarlinDir\Deploy-Application.ps1" -Wait

        #copy the package to fileshare
        If($SCCMSiteCode -eq 'PRD') {
            New-Item -Path "$PRDPackageShare\Merkator\Marlin\$Version\1.0\5.PKG" -ItemType Directory
            Copy-Item -Path "$TempDir\$MarlinDir\*" -Destination "$PRDPackageShare\Merkator\Marlin\$Version\1.0\5.PKG" -Recurse
            #import into SCCM
            <#
            Invoke-Command -ComputerName PROD425.prod.telenet.be -ScriptBlock {
                Import-Module 
            }
            #>
        }
        else {
            New-Item -Path "$CMCPackageShare\Merkator\Marlin\3.PKG\$Version\1.0\MSI" -ItemType Directory
            Copy-Item -Path "$TempDir\$MarlinDir\*" -Destination "$CMCPackageShare\Merkator\Marlin\3.PKG\$Version\1.0\MSI" -Recurse
            #import into SCCM
            New-MYApplication -SourcePath "$CMCPackageShare\Merkator\Marlin\3.PKG\$Version\1.0\MSI"
        }
    }
    
    end {
    }
}