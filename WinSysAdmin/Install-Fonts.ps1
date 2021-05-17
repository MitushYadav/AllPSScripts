# Create ComObject
$obj = New-Object -ComObject Shell.Application
# Get Fonts Windows Special Folder: https://richardspowershellblog.wordpress.com/2008/03/20/special-folders/
$dest = $obj.Namespace(0x14)

$sourceDir = ""

#Copy and Install Fonts, currently only OTF and TTF
Get-ChildItem -Path "$sourceDir\*" -Include "*.otf,*.ttf" | ForEach-Object { $dest.CopyHere($PSItem.FullName,0x10) }
