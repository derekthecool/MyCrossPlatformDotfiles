<#
    .SYNOPSIS
    Get detailed PDF metadata using pdfinfo

    .DESCRIPTION
    Collect results from command pdfinfo command line utility

    .PARAMETER Path
    PDFs to process

    .EXAMPLE
    Get-ChildItem *.pdf | Get-PdfInfo

    .EXAMPLE
    Get-PdfInfo -Path file1.pdf, file2.pdf
#>
function Get-PdfInfo
{
    [CmdletBinding()]
    [Alias('gpi')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string[]]$Path
    )

    process
    {
        # Handle both direct call and pipeline
        foreach ($p in $Path)
        {
            # Detect whether we're getting FileInfo or string
            if ($p -is [System.IO.FileInfo])
            {
                $file = $p.FullName
            } else
            {
                $file = $p
            }

            $props = @{ Path = $file }

            pdfinfo $file | ForEach-Object {
                if ($_ -match '^\s*(.+?):\s*(.+)$')
                {
                    $props[($matches[1] -replace '\s+', '_')] = $matches[2].Trim()
                }
            }

            [PSCustomObject]$props
        }
    }
}
