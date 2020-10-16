$destinations = "127.0.0.1","8.8.8.8"
$ports = "22","23"#"80","8080","443","21100","31100","41100"

$results = @()
foreach($destination in $destinations) {
    $result = [PSCustomObject]@{
        LocalComputer = $env:COMPUTERNAME
        RemoteComputer = $destination
    }
    foreach($port in $ports) {
        $portcheck = $(Test-NetConnection -ComputerName $destination -Port $port).TcpTestSucceeded
        If($PortCheck -notmatch "True|False"){$PortCheck = "ERROR"}
        $result | Add-Member -MemberType NoteProperty -Name "$("Port " + "$port")" -Value "$($portcheck)"
    }
    $results += $result
}

