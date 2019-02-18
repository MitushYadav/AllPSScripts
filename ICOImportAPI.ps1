# "https://contextualwebsearch-websearch-v1.p.rapidapi.com/api/Search/ImageSearchAPI?count=10&q=xmind&autoCorrect=false"

$headers = @{
  'X-RapidAPI-Key' = '21a673c803mshf978edf05dd0532p15dbf8jsn26867699b5d4'
  }

$packagesBasePath = "\\prod.telenet.be\adm\wsaas\software deployment\Packages"

$vendors = Get-ChildItem $packagesBasePath

ForEach($vendor in $vendors) {
  $apps = Get-ChildItem $vendor.FullName
  ForEach($app in $apps) {
    If(-not (Test-Path "$($app.FullName)\1.DOC\ICO\*")) {
      #icon file doesn't exist
      ConvertTo-Json -InputObject $(Invoke-RestMethod -Uri "https://contextualwebsearch-websearch-v1.p.rapidapi.com/api/Search/ImageSearchAPI?count=10&q=$($app.Name)&autoCorrect=false" -Headers $headers) | Out-File "C:\workingDir\IconAPI\$($vendor.Name)_$($app)ICO.json" -Force
      }
    }
  }
