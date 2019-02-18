Function Get-AllLoggedOnUsers {

  $query = query user
  $query = $query[1..($query.Length-1)]

  $LoggedOnUser = @{}

  $ListAllUsers = @()

  ForEach($user in $query) {

    $splitUser = $user -Split '\s+'

    $LoggedOnUser.UserName =  $(If($splitUser[0][0] -eq '>') { $splitUser[0].Remove(0,1) })
    $LoggedOnUser.SessionName = $splitUser[1]
    $LoggedOnUser.ID = $splitUser[2]
    $LoggedOnUser.State = $splitUser[3]
    $LoggedOnUser.IdleTime = $splitUser[4]
    $LoggedOnUser.LogonTime = $splitUser[5] + " " + $splitUser[6]

    $ListAllUsers += [PSCustomObject]$LoggedOnUser

  }

  Return $ListAllUsers
  
}