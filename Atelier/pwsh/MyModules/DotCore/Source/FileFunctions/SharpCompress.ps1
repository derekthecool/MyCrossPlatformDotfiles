# 7 year old reference for powershell with SharpCompress
# https://learn.microsoft.com/en-us/archive/blogs/lukeb/powershell-sharpcompress-and-untar
# function Expand-Everything
# {
#     [Alias('UnTar')]
#     [Alias('UnZip')]
#     [Alias('UnRar')]
#     [CmdletBinding()]
#     param ([Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)] [string]$Path, 
#         [Parameter(Mandatory = $true, Position = 1)] [string]$Destination)
#
#
#     if (-not (Test-Path -Path $Path))
#     {
#         Write-Error -Message ('{0} File Not Found.' -f $Path)
#         return 
#     } 
#     if (-not (Test-Path -Path $Destination -IsValid))
#     {
#         Write-Error -Message ('{0} Is not a valid target path.' -f $Destination)
#         return 
#     }
#
#     # use the generic ReaderFactory. It will open anything.
#     # if it's a tar.gz, we'll go straight to the Tar file.
#     $filestream = [System.IO.File]::OpenRead($Path)
#     $reader = [SharpCompress.Readers.ReaderFactory]::Open($filestream)
#     while ($reader.MoveToNextEntry())
#     {
#         Write-Verbose -Message $reader.Entry.Key
#         if ($reader.Entry.IsDirectory)
#         {
#             $folder = $reader.Entry.Key
#             $destDir = Join-Path -Path $Destination -ChildPath $folder
#             if (-not (Test-Path -Path $destDir))
#             {
#                 $null = New-Item -Path $destDir -ItemType Directory -Force 
#             }
#         } else
#         {
#             $file = $reader.Entry.Key
#             $filepath = Join-Path -Path $Destination -ChildPath $file
#             if (Test-Path -Path $filepath)
#             {
#                 Remove-Item -Path $filepath -Force -Verbose
#             }
#             $CreateNew = [System.IO.FileMode]::CreateNew
#             $fs = [System.IO.File]::Open($filepath, $CreateNew)
#             $reader.WriteEntryTo($fs)
#             $fs.close()
#         }
#     }
#     $filestream.Close()
# }
#


function Expand-Everything
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('FullName')]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    begin
    {
        if (-not ([AppDomain]::CurrentDomain.GetAssemblies().GetName().Name -contains 'SharpCompress'))
        {
            Add-Type -Path 'C:\libs\SharpCompress\SharpCompress.dll'
        }

        if (-not (Test-Path $Destination))
        {
            New-Item -ItemType Directory -Path $Destination | Out-Null
        }
    }

    process
    {
        if (-not (Test-Path $Path))
        {
            Write-Warning "Path not found: $Path"
            return
        }

        Write-Verbose "Expanding archive: $Path"

        try
        {
            $baseStream = [System.IO.File]::OpenRead($Path)
            $reader = [SharpCompress.Readers.ReaderFactory]::Open($baseStream)

            while ($reader.MoveToNextEntry())
            {
                $entry = $reader.Entry

                if ($entry.IsDirectory)
                {
                    continue
                }

                # Build output path safely
                $relativePath = $entry.Key -replace '^[\\/]+', ''
                $outPath = Join-Path $Destination $relativePath

                # Ensure directory exists
                $outDir = [System.IO.Path]::GetDirectoryName($outPath)
                if ($outDir -and -not (Test-Path $outDir))
                {
                    [System.IO.Directory]::CreateDirectory($outDir) | Out-Null
                }

                # Write entry
                $outStream = [System.IO.File]::Create($outPath)
                $reader.WriteEntryTo($outStream)
                $outStream.Dispose()
            }

            $reader.Dispose()
            $baseStream.Dispose()
        } catch
        {
            Write-Error "Failed to expand '$Path': $_"
        }
    }
}
