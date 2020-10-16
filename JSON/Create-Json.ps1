Function Create-Json {

    param(
        [Parameter(Mandatory=$true)]
        [string]$Vendor,
        [Parameter(Mandatory=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [string]$Version,
        [Parameter(Mandatory=$true)]
        [string]$ApplicationOwner,
        [string]$CatalogDescription,
        [string]$CatalogCategory,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Virtual","Local")]
        [string]$PackageType,
        [Parameter(Mandatory=$true)]
        [string]$InstallFile,
        [Parameter(Mandatory=$true)]
        [string]$UATUsers,
        [Parameter(Mandatory=$true)]
        [string]$OutputLocation
    )
    
    $FullJson = [ordered]@{
                    Application = [ordered]@{
                             "Vendor" = $Vendor;
                             "Name" = $Name;
                             "Version" = "Version";
                              "Application Owner" = $ApplicationOwner;
                              "Description_Catalog" = $CatalogDescription;
                              "Category_Catalog" = $CatalogCategory
                              }
                    Package = [ordered]@{
                                  "Installfile" = $InstallFile;
                                  "PackageType" = $PackageType;
                                  "PackagedBy" = "Automatic";
                                   Date = Get-Date -Format dd-MM-yyyy;
                                   "_comment_packagetype" = "Use Virtual or Local"
                                   }
                    Deployment = @{
                                  "UAT_Users" = $UATUsers
                                  }
                              }

    ConvertTo-Json -InputObject $FullJson | Set-Content $OutputLocation

}