[CmdletBinding()]
param 
(
    [string]$commandEntry
)
Function Get-SS64Help
{
    [CmdletBinding()]
    param 
    (
        [string]$commandEntry
    )
    if($verbose)
    {
        $verbosePreference = SilentlyContinue
    }
    $baseUrl = "https://ss64.com/ps"
    $fullUrl = "$baseUrl/$commandEntry.html"
    Write-Verbose "$fullUrl"
    try
    {
        $resp = Invoke-WebRequest -Uri $fullUrl -ErrorAction Stop
        Write-Verbose $resp
    }
    catch
    {
        Write-Host "Invoke-WebRequest: Error contacting $fullUrl"
        Write-Verbose $_
    }
    $overview = $resp.AllElements | Where {$_.TagName -eq "PRE"}
    $syntax = $overview.innerText
    $examplesOverview = $resp.AllElements | Where {$_.TagName -eq "P" -and $_.Class -match "code"}
    $examples = $examplesOverview.innerText #examples not working atm
    $returnObj = @{
        Syntax = $syntax
        Examples = $examples
    }
    return $returnObj
}
Get-SS64Help -commandEntry $commandEntry