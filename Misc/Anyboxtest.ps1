Import-Module AnyBox

# build the AnyBox
$anybox = New-Object AnyBox.AnyBox

$anybox.Prompts = New-AnyBoxPrompt -Name 'name' -Message "what's your name?" -ValidateNotEmpty

$anybox.Buttons = @(
    New-AnyBoxButton -Name 'cancel' -Text 'Cancel' -IsCancel
    New-AnyBoxButton -Name 'submit' -Text 'Submit' -IsDefault
)

# show the AnyBox; collect responses.
$response = $anybox | Show-AnyBox

# act on responses.
if ($response['submit'] -eq $true) {
    $name = $response['name']
    Show-AnyBox -Message "Hello $name!" -Buttons 'OK'
}
else {
    Show-AnyBox -Message "Ouch!" -Buttons 'OK'
}