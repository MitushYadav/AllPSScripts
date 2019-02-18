$ComputerName = Get-Content "C:\workingDir\cfm.txt"


     foreach ($comp in $ComputerName)
     {
     If(Test-Connection $comp -Quiet) {
         $output = @{ 'ComputerName' = $comp }
         $output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName
         [PSCustomObject]$output
         }
     }
