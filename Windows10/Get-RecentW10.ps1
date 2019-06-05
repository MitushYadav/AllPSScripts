#load the list

Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
$siteCode = 'CMC'

<#
#To get the list dynamically
Push-Location $($siteCode + ":")
Get-CMDevice -Name "PPC*" -Fast
#>

$w10ppc  = Get-Content C:\workingDir\w10_active.txt

$recentW10 = @()

ForEach($ppc in $w10ppc)
{
    If(Test-Connection -ComputerName $ppc -Quiet -Count 1)
    {
        $os = Get-WmiObject -Class win32_operatingsystem
        $installdate = $os.ConvertToDateTime($os.InstallDate)
        if($installdate -gt $installdate.AddMonths(-2))
        {
            $recentW10 += $ppc
        } 
    }
}

$recentW10 | Out-File C:\workingDir\recentw10ppc.txt