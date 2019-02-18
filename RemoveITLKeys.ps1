$path = "HKCU:\SOFTWARE\itl"
$build = "Build"
$exists = $false

if(Test-Path $path) {
    try {
        $value = (Get-ItemProperty -Path $path -Name $build -ErrorAction Stop).$build
        $exists = $true
        }
    catch {
        $exists = $false
        }
        
    }

If(!$exists -or ($value -ne "4.0")) {
    #delete the reg values
    Remove-Item -Path "HKCU:\SOFTWARE\itl" -Recurse -Force
    }
    
    