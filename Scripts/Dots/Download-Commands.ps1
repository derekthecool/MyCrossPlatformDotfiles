function Get-ISOFilename
{
    param (
        [Parameter()]
        [string]$Filename
    )

    if($Filename -cmatch '([^/]+\.iso)')
    {
        return $Matches[1]
    } else
    {
        throw 'The providing filename did not contain a ISO file match'
    }
}

function Download-ISO
{
    param (
        [ValidatePattern('.*/([^/]+\.iso)')]
        [Parameter(Mandatory=$true)]
        [string]$URL,

        [string]$CheckSumLink,

        # [Parameter(Mandatory=$true)]
        # [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$HashType
    )

    $LocalFilename = Get-ISOFilename -Filename $URL

    if(Test-Path $LocalFilename)
    {
        Write-Host "File: $LocalFilename exists locally, verifying the checksum"
    } else
    {
        Write-Host "Downloading ISO as local file: $LocalFilename"
        Invoke-WebRequest -Uri $URL -OutFile $LocalFilename
    }

    # If a check sum link has been provided use it
    # otherwise try to get it through sneaky approaches
    if($CheckSumLink)
    {
        $CheckSumText = [System.Text.Encoding]::UTF8.GetString($(Invoke-WebRequest -Uri $CheckSumLink | Select-Object -ExpandProperty Content))
    } else
    {
        Write-Error 'Could not download check sum file'
        return
    }

    $fileHash = Get-FileHash -Path $LocalFilename -Algorithm $HashType | Select-Object -ExpandProperty Hash

    if($CheckSumText -match $fileHash)
    {
        Write-Host 'ISO hash matched!' -ForegroundColor Green
    } else
    {
        Write-Host 'ISO hash did not match' -ForegroundColor Red
        Write-Host "Calculated hash: $fileHash"
        Write-Host "Downloaded hash data:`n$CheckSumText"
    }
}
