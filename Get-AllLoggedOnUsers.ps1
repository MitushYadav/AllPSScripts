Function Get-AllLoggedOnUsers {

  $query = query user
  $query = $query[1..($query.Length-1)]

  $LoggedOnUser = @{}

  $ListAllUsers = @()

  ForEach($user in $query) {

    $splitUser = $user.Trim() -Split '\s+'
    Write-Host $splitUser

    $LoggedOnUser.UserName =  $splitUser[0].Replace(">", "")
    $LoggedOnUser.SessionName = $splitUser[1]
    $LoggedOnUser.ID = $splitUser[2]
    $LoggedOnUser.State = $splitUser[3]
    $LoggedOnUser.IdleTime = $splitUser[4]
    $LoggedOnUser.LogonTime = $splitUser[5] + " " + $splitUser[6]

    $ListAllUsers += [PSCustomObject]$LoggedOnUser

  }

  Return $ListAllUsers
  
}