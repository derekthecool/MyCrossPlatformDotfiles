function Update-AndroidApplications
{
    <#
    .SYNOPSIS
    Return the full link to all website links on page

    .DESCRIPTION
    Returns the full link to all links found on page

    .PARAMETER Name
    $Website is the website to search

    .EXAMPLE
    PS> Get-WebsiteLinks -Website 'https://auroraoss.com/downloads/AuroraStore/Release/'
#>
    function Get-WebsiteLinks
    {
        param (
            [Parameter()]
            [string]$Website
        )

        $SavedErrorAction = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'

        # Convert the string to a URI object
        $uri = [System.Uri]::new($Website).GetLeftPart([System.UriPartial]::Authority)

        Invoke-WebRequest $Website -UseBasicParsing
        | Select-Object -ExpandProperty Links
        | Select-Object -ExpandProperty href
        | Where-Object { $_ -cmatch 'apk$' }
        | ForEach-Object { "$uri/{0}" -f "$_" }

        $SavedErrorAction = $ErrorActionPreference
    }


    # Add GitHub releases to download with gh here
    $GitHubShortRepositoryNamesForGHDownload = @(
        'TeamNewPipe/NewPipe'
    )

    # Other apk downloads here
    $DownloadFiles = @(
        'https://f-droid.org/F-Droid.apk'
        # Find latest somehow
        # 'https://f-droid.org/repo/org.videolan.vlc_13050408.apk',
        # 'https://auroraoss.com/AuroraStore/Stable/AuroraStore_4.3.0.apk'
    )

    $AuroraStore = Get-WebsiteLinks -Website 'https://auroraoss.com/downloads/AuroraStore/Release/' | Select-Object -Last 1
    $DownloadFiles += $AuroraStore

    $VLC = Get-WebsiteLinks -Website 'https://f-droid.org/en/packages/org.videolan.vlc/'
    | Select-Object -Skip 1 -First 1
    $DownloadFiles += $VLC

    # $GitHubShortRepositoryNamesForGHDownload | ForEach-Object {
    #     $downloadURL = gh release --repo $_ view --json tagName,assets
    #     | ConvertFrom-Json
    #     | Select-Object -ExpandProperty assets
    #     | Select-Object -ExpandProperty url
    #
    #     $DownloadFiles += $downloadURL
    # }

    $DownloadFiles

    # $DownloadFiles = "$PSScriptRoot/apks"
    # mkdir $DownloadFiles -ErrorAction SilentlyContinue
    # Set-Location $DownloadFiles

    # $DownloadFiles | ForEach-Object -ThrottleLimit 10 -Parallel {
    #     $output_name = $_ -split '/' | Select-Object -Last 1
    #     Invoke-WebRequest $_ -OutFile $output_name
    # }

    # Set-Location ..
}
