Import-Module -Name UniversalDashboard.Community
  
  #,"Approval","Processing","UAT","InProduction"
$MyDashboard = New-UDDashboard -Title "Automated Packaging Status Report" -Content {
    New-UDRow -Columns {
      New-UDColumn -Size 12 {
        New-UDCard -Title "Hello" -Text { Please click on the relevant request to get the status }
      }
    }
  

    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCollapsible -Items {
        New-UDCollapsibleItem -Title "Mozilla Firefox" -Content {
          New-UDTable -Title "Status" -Headers @("Intake") -FontColor "black" -Style bordered -Endpoint {
            [PSCustomObject]@{Intake='OK'} | Out-UDTableData -Property @("Intake")
            }
        }
      }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe1!" }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe2!" }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe3!" }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe4!" }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe5!" }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe6!" }
    }
  }
    New-UDRow -Columns {
    New-UDColumn -Size 6 {
      New-UDCard -Title "Hello" -Text { "Hey Universe7!" }
    }
  }
}


Start-UDDashboard -Port 1000 -Dashboard $MyDashboard -AutoReload