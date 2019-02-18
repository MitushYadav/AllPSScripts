Import-Module -Name UniversalDashboard.Community

$PageHome = New-UDPage -Name "Home" -Content {
    New-UDLayout -Columns 3 -Content {
        New-UDCard -Title "Scheduled" -Content {
            "Links"
        } -Links @(
            New-UDlink -Text "Jobs" -Url "/jobs/"
            New-UDlink -Text "Tasks" -Url "/tasks/"
        )
    }
}

$PageJobList = New-UDPage -Name "Jobs" -Content {
    New-UdGrid -Title "Jobs" -Headers @(
        "Name", "ID", "Enabled"
    ) -Properties @(
        "Name", "Id", "Enabled"
    ) -AutoRefresh -RefreshInterval 60 -Endpoint {
        Get-ScheduledJob | Select-Object -Property Name, Id, Enabled | Out-UDGridData
    }
}

$PageTaskList = New-UDPage -Name "Tasks" -Content {
    New-UdGrid -Title "Tasks" -Headers @(
        "TaskName", "State", "TaskPath"
    ) -Properties @(
        "TaskName", "State", "TaskPath"
    ) -AutoRefresh -RefreshInterval 60 -Endpoint {
        Get-ScheduledTask -TaskPath "\*" |
            Where-Object {$_.TaskPath -notlike "*Microsoft*"} |
            Select-Object -Property TaskName, State, TaskPath | Out-UDGridData
    }
}

$FormLogin = New-UDAuthenticationMethod -Endpoint {
    param([PSCredential]$Credentials)
    Function Test-Credential {
        [OutputType([Bool])]
        
        Param (
            [Parameter(
                Mandatory = $true,
                ValueFromPipeLine = $true,
                ValueFromPipelineByPropertyName = $true
            )]
            [Alias(
                'PSCredential'
            )]
            [ValidateNotNull()]
            [System.Management.Automation.PSCredential]
            [System.Management.Automation.Credential()]
            $Credential,
    
            [Parameter()]
            [String]
            $Domain = $Credential.GetNetworkCredential().Domain
        )
    
        Begin {
            [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") |
                Out-Null
    
            $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext(
                [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Domain
            )
        }
    
        Process {
            foreach ($item in $Credential) {
                $networkCredential = $Credential.GetNetworkCredential()
                
                Write-Output -InputObject $(
                    $principalContext.ValidateCredentials(
                        $networkCredential.UserName, $networkCredential.Password
                    )
                )
            }
        }
        End {
            $principalContext.Dispose()
        }
    }
    if ((Test-Credential -Credential $Credentials)) {
        New-UDAuthenticationResult -Success -UserName $Credentials.UserName
    }
    New-UDAuthenticationResult -ErrorMessage "Invalid Credentials, please try again."
}

$LoginPage = New-UDLoginPage -AuthenticationMethod $FormLogin

$PageArray = @($PageHome, $PageJobs, $PageJobList, $PageTaskList, $PageTasks)

$MyDashboard = New-UDDashboard -Title "Hello, World" -Pages $PageArray -LoginPage $LoginPage

Start-UDDashboard -Port 1000 -Dashboard $MyDashboard -AllowHttpForLogin