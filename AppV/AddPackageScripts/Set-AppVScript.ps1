<#
.DESCRIPTION
Script to add a particular script as a machine or user script and/or add a file to the Scripts folder
.NOTES
Currently supports AddPackage, RemovePackage, PublishPackage Global, UnpublishPackage Global, StartVE and TerminateVE for Script based
& supports ddPackage, RemovePackage, PublishPackage User and UnpublishPackage User for Inline based
Mitush Yadav, 26/2/2021
#>
[CmdletBinding()]
param (
    # Full path to the AppV file
    [Parameter(ParameterSetName='Script', Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName='Inline', Mandatory=$true, Position=0)]
    [ValidateScript({Test-Path $PSItem})]
    [string]
    $AppVFullPath,
    # TweakAppv EXE Path
    [Parameter(ParameterSetName='Script', Mandatory=$false)]
    [Parameter(ParameterSetName='Inline', Mandatory=$false)]
    [ValidateScript({Test-Path $PSItem})]
    [string]
    $TweakAppVPath = "C:\Program Files (x86)\Caphyon\TweakAppV\TweakAppV.exe",
    # Script to add => parameter set mandatory property
    [Parameter(ParameterSetName='Script', Mandatory=$true)]
    [ValidateScript({Test-Path $PSItem -PathType Container})]
    [string]
    $ScriptsWorkingDirectory,
    # File\Files to add. Should point to a file or a folder. If folder, all files will be added recursively
    [Parameter(ParameterSetName='Script', Mandatory=$false)]
    [ValidateScript({Test-Path $PSItem})]
    [string]
    $FilesToAdd,
    # delete existing scriptFile
    [Parameter(ParameterSetName='Script', Mandatory=$false)]
    [switch]
    $DeleteExistingScriptFile,
    # Inline Script Block
    [Parameter(ParameterSetName='Inline', Mandatory=$false)]
    [string]
    $AddPackageScript,
    # Inline Script Block
    [Parameter(ParameterSetName='Inline', Mandatory=$false)]
    [string]
    $RemovePackageScript,
    # Inline Script Block
    [Parameter(ParameterSetName='Inline', Mandatory=$false)]
    [string]
    $PublishPackageUserScript,
    # Inline Script Block
    [Parameter(ParameterSetName='Inline', Mandatory=$false)]
    [string]
    $UnpublishPackageUserScript
)

#files to add to Scripts folder
if($FilesToAdd) {
    if (-not(Test-Path -Path $FilesToAdd)) {
        Write-Host "Files to add to Scripts not found."
    }
    else {
        #if single file
        if (Test-Path -Path $FilesToAdd -PathType Leaf) {
            $fToAdd = $FilesToAdd
        }
        # folder
        else {
            $fToAdd = (Get-ChildItem -Path $FilesToAdd -Recurse).FullName
        }
    }
    Write-Host "The files to add are $fToAdd"
}
if($ScriptsWorkingDirectory) {
    $packageScripts = Get-ChildItem -Path $ScriptsWorkingDirectory -Filter "*.ps1"

#NOTE: ScriptsWorkingDirectory should be declared before this here-string
$ScriptText = @"
add-Scriptfile "$ScriptsWorkingDirectory\ACTION.ps1"
New-Element AppxManifest.xml -elementname "appv:CONTEXT" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT" -elementname "appv:ACTION" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -elementname "appv:Path" -elementtext "powershell.exe" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -elementname "appv:Arguments" -elementtext "-NoProfile -NoLogo -WindowStyle Hidden -Noninteractive -ExecutionPolicy Bypass -File ACTION.ps1" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -elementname "appv:Wait" -elementtext " " -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
Set-ElementAttribute AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION/appv:Wait" -attributename "RollbackOnError" -attributevalue "true"
Set-ElementAttribute AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION/appv:Wait" -attributename "Timeout" -attributevalue "60"
"@

    $batchScriptFileName = "batchScripts"
    $batchScriptFilePath = "$ScriptsWorkingDirectory\$batchScriptFileName.txt"
    if(Test-Path $batchScriptFilePath) {
        Write-Host "A ScriptFile already exists at $batchScriptFilePath"
        if($DeleteExistingScriptFile) {
            Write-Host "Option set to delete existing Script File. Deleting"
            Remove-Item -Path $batchScriptFilePath -Force
        }
    }
    # checking again to verify file is deleted. Also, to avoid using multiple if-else
    if(-not(Test-Path $batchScriptFilePath)) {
        Write-Host "ScriptFile does not exist. Creating new"
        Set-Content -Path $batchScriptFilePath -Value ";twc"

        #inserting files into Scripts folder
        foreach ($file in $fToAdd) {
            Add-Content -Path $batchScriptFilePath -Value "add-Scriptfile `"$file`""
        }

        switch ($packageScripts.Name)
        {
            'AddPackage.ps1' {
                Write-Host "Adding AddPackage Machine Script"
                $ScriptText -replace "ACTION", "AddPackage" `
                -replace "CONTEXT", "MachineScripts" | Add-Content -Path $batchScriptFilePath
                }
            'RemovePackage.ps1' {
                Write-Host "Adding RemovePackage Machine Script"
                $ScriptText -replace "ACTION", "RemovePackage" `
                -replace "CONTEXT", "MachineScripts" | Add-Content -Path $batchScriptFilePath
            }
            'PublishPackage.ps1' {
                Write-Host "Adding PublishPackage Machine Script"
                $ScriptText -replace "ACTION", "PublishPackage" `
                -replace "CONTEXT", "MachineScripts" | Add-Content -Path $batchScriptFilePath
            }
            'UnpublishPackage.ps1' {
                Write-Host "Adding UnpublishPackage Machine Script"
                $ScriptText -replace "ACTION", "UnpublishPackage" `
                -replace "CONTEXT", "MachineScripts" | Add-Content -Path $batchScriptFilePath
            }
            'StartVirtualEnvironment.ps1' {
                Write-Host "Adding StartVirtualEnvironment User Script"
                $newScriptText = $ScriptText -split '\r?\n'
                $TextToAdd = 'Set-ElementAttribute AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -attributename "RunInVirtualEnvironment" -attributevalue "false"' # adding since StartVE uses RunInVE attribute
                #insert extra line into the script
                $startVEText = New-Object 'System.Collections.Generic.List[System.String]'
                for ($i = 0; $i -lt $newScriptText.Count; $i++) {
                    $startVEText.Add($newScriptText[$i])
                    if($i -eq 2) {
                        $startVEText.Add($TextToAdd)
                    }
                }
                $startVEText -replace "ACTION", "StartVirtualEnvironment" `
                -replace "CONTEXT", "UserScripts" | Add-Content -Path $batchScriptFilePath
            }
            'TerminateVirtualEnvironment.ps1' {
                Write-Host "Adding TerminateVirtualEnvironment User Script"
                $ScriptText -replace "ACTION", "TerminateVirtualEnvironment" `
                -replace "CONTEXT", "UserScripts" | Add-Content -Path $batchScriptFilePath
            }
        }
    }
}

if($AddPackageScript -or $RemovePackageScript -or $PublishPackageUserScript -or $UnpublishPackageUserScript) {
    $batchScriptFileName = "InlineBatchScripts"
    $ScriptsWorkingDirectory = $PSScriptRoot
    $batchScriptFilePath = "$ScriptsWorkingDirectory\$batchScriptFileName.txt"
    if(Test-Path $batchScriptFilePath) {
        Write-Host "Deleting existing Script File"
        Remove-Item -Path $batchScriptFilePath -Force
    }
    Set-Content -Path $batchScriptFilePath -Value ";twc"
    
$simpleScript = @"
New-Element AppxManifest.xml -elementname "appv:CONTEXT" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT" -elementname "appv:ACTION" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -elementname "appv:Path" -elementtext "ScriptRunner.exe" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -elementname "appv:Arguments" -elementtext "SR_ARGS" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
New-Element AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION" -elementname "appv:Wait" -elementtext "" -namespaceURI "http://schemas.microsoft.com/appv/2010/manifest" -createifnotexist
Set-ElementAttribute AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION/appv:Wait" -attributename "RollbackOnError" -attributevalue "true"
Set-ElementAttribute AppxManifest.xml -xpath "appv:CONTEXT/appv:ACTION/appv:Wait" -attributename "Timeout" -attributevalue "60"
"@
    if($AddPackageScript) {
        Write-Host "Adding AddPackage Machine Script"
        foreach($CommandToInsert in $AddPackageScript) {
            $srArgs += "-AppVScript $CommandToInsert -appvscriptrunnerparameters -wait " #trailing whitespace requried
        }
        $simpleScript -replace "ACTION", "AddPackage" `
        -replace "CONTEXT", "MachineScripts" `
        -replace "SR_ARGS", $srArgs | Add-Content -Path $batchScriptFilePath
    }
    if($RemovePackageScript) {
        Write-Host "Adding RemovePackage Machine Script"
        foreach($CommandToInsert in $RemovePackageScript) {
            $srArgs += "-AppVScript $CommandToInsert -appvscriptrunnerparameters -wait " #trailing whitespace requried
        }
        $ScriptText -replace "ACTION", "RemovePackage" `
        -replace "CONTEXT", "MachineScripts" `
        -replace "SR_ARGS", $srArgs | Add-Content -Path $batchScriptFilePath
    }
    if($PublishPackageUserScript) {
        Write-Host "Adding PublishPackage User Script"
        foreach($CommandToInsert in $PublishPackageUserScript) {
            $srArgs += "-AppVScript $CommandToInsert -appvscriptrunnerparameters -wait " #trailing whitespace requried
        }
        $ScriptText -replace "ACTION", "PublishPackage" `
        -replace "CONTEXT", "UserScripts" `
        -replace "SR_ARGS", $srArgs | Add-Content -Path $batchScriptFilePath
    }
    if($UnpublishPackageUserScript) {
        Write-Host "Adding UnpublishPackage User Script"
        foreach($CommandToInsert in $PublishPackageUserScript) {
            $srArgs += "-AppVScript $CommandToInsert -appvscriptrunnerparameters -wait " #trailing whitespace requried
        }
        $ScriptText -replace "ACTION", "UnpublishPackage" `
        -replace "CONTEXT", "UserScripts" `
        -replace "SR_ARGS", $srArgs | Add-Content -Path $batchScriptFilePath
    }
}

& $tweakAppVPath /batchfileupdate $AppVFullPath $batchScriptFilePath | Tee-Object -Variable procOutput

if($procOutput[-1] -eq "Package updated successfully") {
    Write-Host "AppV package updated successfully" -ForegroundColor Green
}