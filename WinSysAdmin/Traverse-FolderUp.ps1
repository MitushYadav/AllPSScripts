Function Traverse-FolderUp {
    <#
    .Description
    Traverses N number to folders up
    #>

    param(
        [string]$path,
        [int]$levels
    )

    do {
        $path = [io.path]::GetDirectoryName($path)
        $levels = $levels - 1      
    } while ($levels -gt 0)

    return $path
}