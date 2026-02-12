function ConvertFrom-Base64
{
    [Alias('ConvertFrom-64')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidatePattern('^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$')]
        [string[]]$Base64String,
        [switch]$AsText
    )
    process
    {
        foreach ($b64 in $Base64String)
        {
            if ($AsText)
            {
                [System.Text.Encoding]::UTF8.GetString([convert]::FromBase64String($b64))
            } else
            {
                [convert]::FromBase64String($b64)
            }
        }
    }
}

function ConvertTo-Base64
{
    [Alias('ConvertTo-64')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Path")]
        [System.IO.FileInfo[]]$Path,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "String")]
        [string[]]$String,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "ByteArray")]
        [byte[]]$Bytes
    )
    begin
    {
        Write-Verbose "Parameters received: $($PSBoundParameters | Out-String)"
        Write-Verbose "Using parameter set $($PSCmdlet.ParameterSetName)"
        $AllBytes = New-Object System.Collections.Generic.List[byte]
    }
    process
    {
        Write-Verbose "Value of Path: $($Path | Out-String)"
        Write-Verbose "Value of String: $($String | Out-String)"
        Write-Verbose "Value of Bytes: $($Bytes | Out-String)"
        if ($Path)
        {
            foreach ($pathItem in $Path)
            {
                $fileBytes = [IO.File]::ReadAllBytes($pathItem)
                $AllBytes.AddRange($fileBytes)
            }
        }

        if ($String)
        {
            foreach ($stringItem in $String)
            {
                foreach ($textByte in [System.Text.Encoding]::UTF8.GetBytes($stringItem))
                {
                    $AllBytes.Add($textByte)
                }
            }
        }

        if ($Bytes)
        {
            # $AllBytes.AddRange($Byte)
            foreach ($byteItem in $Bytes)
            {
                $AllBytes.Add($byteItem)
            }
        }
    }
    end
    {
        [convert]::ToBase64String($AllBytes)
    }
}

function Edit-Content
{
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High')]
    [Alias('psed')]
    [Alias('ec')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Path,
        [Parameter( Mandatory, Position = 0)]
        [regex]$Pattern,
        [Parameter( Mandatory, Position = 1)]
        [string]$Replacement
    )
    process
    {
        Write-Verbose "Processing file $($_.Name)"
        $rawContent = Get-Content -Raw -Path $_
        $matchesFound = [regex]::Matches($rawContent, $Pattern)
        if ($PSCmdlet.ShouldProcess("Replacing $(($matchesFound | Measure-Object).Count) occurrances in file $($_.Name) $($matchesFound | Out-String)"))
        {
            $updatedContent = $rawContent -replace $Pattern, $Replacement
            Set-Content -NoNewline -Path $_ -Value $updatedContent
        } else
        {
            Write-Output "Would replace $(($matchesFound | Measure-Object).Count) occurrances in file $($_.Name) $($matchesFound | Out-String)"
        }
    }
}
