# script to download google chrome enterprise 64 bit and create appV

param(
[string]$downloadFolder,
[string]$AppVLocation
)

$chromeURI = "https://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi"

Invoke-WebRequest -Uri $chromeURI -OutFile "$downloadFolder\Chrome\GoogleChromeStandaloneEnterprise64.msi"

Function Get-FileMetaData 
{ 
 Param([string[]]$folder) 
 foreach($sFolder in $folder) 
  { 
   $a = 0 
   $objShell = New-Object -ComObject Shell.Application 
   $objFolder = $objShell.namespace($sFolder) 
 
   foreach ($File in $objFolder.items()) 
    {  
     $FileMetaData = New-Object PSOBJECT 
      for ($a ; $a  -le 266; $a++) 
       {  
         if($objFolder.getDetailsOf($File, $a)) 
           { 
             $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  = 
                   $($objFolder.getDetailsOf($File, $a)) } 
            $FileMetaData | Add-Member $hash 
            $hash.clear()  
           } #end if 
       } #end for  
     $a=0 
     $FileMetaData 
    } #end foreach $file 
  } #end foreach $sfolder
  }

$name = Get-FileMetaData -folder "$downloadFolder\Chrome"

if ($name[0].Comments -match  '[^\s]+') {
$ver = $Matches[0]
}

Set-Location C:\workingDir\g

New-AppvSequencerPackage  -Name "Google - Chrome - $ver (1.0)" -Installer "$downloadFolder\Chrome\GoogleChromeStandaloneEnterprise64.msi" -Path $AppVLocation

