# $reg64 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
# $reg32 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

Function Get-UninstallString {

# defining parameters

    Param(
    [string]$appName
        )

    
    $item = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Name

    ForEach ($guid in $item) {
  
  # Insert logic here to test the presence of DisplayName value to prevent errors      
  # Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid"

        $names = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid" -Name DisplayName).DisplayName

        ForEach ($name in $names) {
            If ($appName -match $name) {
                # to get the corresponding UninstallString value
                (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$guid" -Name UninstallString).UninstallString
                }
            }
        }
    }
    
#    Get-ChildItem $item[0]
    
#    Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"($item[0])

#    $item | ForEach-Object -Process {$_.DisplayName}

 #   $app64 =  Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | ForEach-Object { $_.DisplayName }


Get-UninstallString -appName "Microsoft"