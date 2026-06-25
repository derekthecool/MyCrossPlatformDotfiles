<#
    .SYNOPSIS
    Extract metadata from image and video files using exiftool

    .DESCRIPTION
    Reads EXIF, IPTC, XMP, and other metadata from image and video files using exiftool.
    Supports 200+ file formats including JPEG, TIFF, PNG, GIF, WebP, RAW, video, and more.

    .PARAMETER Path
    Image or video files to process. Accepts pipeline input from Get-ChildItem.

    .PARAMETER SkipUnsupported
    If specified, files without metadata are silently skipped. Otherwise, a warning is issued.

    .EXAMPLE
    Get-ImageMetaData -Path photo.jpg

    .EXAMPLE
    Get-ChildItem *.jpg | Get-ImageMetaData | Where-Object HasGPS

    .EXAMPLE
    Get-ImageMetaData -Path video.mp4 | Select-Object FileName, Width, Height, Duration
#>
function Get-ImageMetaData
{
    [CmdletBinding()]
    [Alias('gim')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [string[]]$Path,

        [switch]$SkipUnsupported
    )

    begin
    {
        # Check if exiftool is available
        if (-not (Get-Command exiftool -ErrorAction SilentlyContinue))
        {
            throw "exiftool not found. Please install exiftool (perl-image-exiftool on Arch, brew install exiftool on macOS)"
        }
    }

    process
    {
        foreach ($p in $Path)
        {
            # Handle both FileInfo objects from pipeline and string paths
            if ($p -is [System.IO.FileInfo])
            {
                $file = $p.FullName
            } else
            {
                $file = $p
            }

            # Validate file exists
            if (-not (Test-Path -Path $file -PathType Leaf))
            {
                Write-Warning "File not found: $file"
                continue
            }

            try
            {
                # Run exiftool with JSON output
                # -json: structured output for easy parsing
                # -coordFormat "%.8f": force GPS to decimal degrees
                # -n: prevent value conversion (keeps raw numbers)
                # -FileSize -MimeType: include file info
                $output = & exiftool -json -coordFormat "%.8f" -n -FileSize -MimeType $file 2>&1

                # Check if exiftool returned an error
                if ($LASTEXITCODE -ne 0 -and $output -match 'Error:')
                {
                    if (-not $SkipUnsupported)
                    {
                        Write-Warning "No metadata found for: $file"
                    }
                    continue
                }

                # Parse JSON output
                $jsonData = $output | ConvertFrom-Json

                # exiftool returns an array, get first element
                $data = if ($jsonData -is [array]) { $jsonData[0] } else { $jsonData }

                if ($null -eq $data -or $data.PSObject.Properties.Count -eq 0)
                {
                    if (-not $SkipUnsupported)
                    {
                        Write-Verbose "No metadata found in: $file"
                    }
                    continue
                }

                # Build result object with common properties at top level
                $result = [PSCustomObject]@{
                    Path             = $file
                    FileName         = if ($data.FileName) { $data.FileName } else { [IO.Path]::GetFileName($file) }
                    Extension        = [IO.Path]::GetExtension($file)
                    Width            = $data.ImageWidth ?? $data.VideoWidth ?? $null
                    Height           = $data.ImageHeight ?? $data.VideoHeight ?? $null
                    GPSLatitude      = $data.GPSLatitude ?? $null
                    GPSLongitude     = $data.GPSLongitude ?? $null
                    GPSAltitude      = $data.GPSAltitude ?? $null
                    HasGPS           = ($null -ne $data.GPSLatitude -and $null -ne $data.GPSLongitude)
                    CameraMake       = $data.Make ?? $null
                    CameraModel      = $data.Model ?? $null
                    DateTime         = $data.CreateDate ?? $null
                    DateTimeOriginal = $data.DateTimeOriginal ?? $null
                    ISO              = $data.ISO ?? $data.PhotographicSensitivity ?? $null
                    FocalLength      = $data.FocalLength ?? $data.FocalLengthIn35mmFormat ?? $null
                    FNumber          = $data.FNumber ?? $data.Aperture ?? $null
                    ExposureTime     = $data.ExposureTime ?? $null
                    Orientation      = $data.Orientation ?? $null
                    Software         = $data.Software ?? $null
                    MimeType         = $data.MimeType ?? $null
                    FileSize         = $data.FileSize ?? $null
                    Duration         = $data.Duration ?? $null
                    FileType         = $data.FileType ?? $null
                }

                # Add all raw properties as nested object
                $rawProps = [ordered]@{}
                foreach ($prop in $data.PSObject.Properties)
                {
                    $propName = $prop.Name
                    $propValue = $prop.Value
                    $rawProps[$propName] = $propValue
                }
                $result | Add-Member -NotePropertyName RawProperties -NotePropertyValue ([PSCustomObject]$rawProps)

                # Add type name for display formatting
                $result.PSTypeNames.Insert(0, 'DotImages.ImageMetadata')
                $result
            } catch
            {
                Write-Error "Failed to process '$file': $_"
            }
        }
    }
}
