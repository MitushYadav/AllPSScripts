#Boxstarter

#Uninstall SCCM Client
Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -Wait
Start-Sleep -Seconds 30
Remove-Item -Path "C:\Windows\ccmsetup" -Recurse -Force
Remove-Item -Path "C:\Windows\CCM" -Recurse -Force
New-Item -Path "C:\Windows\ccmsetup" -ItemType File
New-Item -Path "C:\Windows\CCM" -ItemType File

#Disable Windows Updates and Search
Stop-Service -Name 'wuauserv' -Force | Set-Service -StartupType Disabled
Stop-Service -Name 'WSearch' -Force | Set-Service -StartupType Disabled


#Uninstall PaloAlto GlobalProtect
Start-Process -FilePath msiexec -ArgumentList "/x {24D4233F-C473-4C50-8243-53FB6DFF2581} /qn" -Wait


#Create Local User and add to admin account
$ASpass = ConvertTo-SecureString 'adminstudioprep' -AsPlainText -Force
New-LocalUser -AccountNeverExpires -Name 'adminstudioprep' -Password $ASpass -PasswordNeverExpires
Add-LocalGroupMember -Group 'Administrators' -Member 'adminstudioprep'

#Copy and install VMCfg
New-Item C:\Temp\VMCfg -ItemType Directory
Copy-Item -Path "\\prod.telenet.be\adm\DSLMpublic\Mitush\VMCfg\VMCfg.exe" -Destination C:\Temp\VMCfg
Copy-Item -Path "\\prod.telenet.be\adm\DSLMpublic\Mitush\VMCfg\setup.iss" -Destination C:\Temp\VMCfg
Start-Process -FilePath "C:\Temp\VMCfg\VMCfg.exe" -ArgumentList "/s /f1`"C:\Temp\VMCfg\setup.iss`"" -Wait