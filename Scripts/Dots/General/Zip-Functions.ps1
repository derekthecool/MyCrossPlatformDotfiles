<#
    .SYNOPSIS
    Takes a zip archive and creates a new directory for it to be unzipped to

    .DESCRIPTION
    Creating a new directory manually gets tiring, this will help

    .PARAMETER ZipArchive
    The path to the zip archive

    .EXAMPLE
    # Would create a new directory named test with the contents of test.zip put
    # inside.
    better-unzip test.zip
#>
function better-unzip
{
    param (
        [Parameter()]
        [ValidatePattern('.*\.zip')]
        [string]$ZipArchive
    )

    $details = Get-ChildItem $ZipArchive
    if($details.Extension -ne '.zip')
    {
        Write-Error "Expected a .zip file extension for the input file $ZipArchive"
    }

    $newDirectory = $details.BaseName
    New-Item -ItemType Directory -ErrorAction SilentlyContinue $newDirectory
    Expand-Archive -Path $ZipArchive -DestinationPath $newDirectory
}
