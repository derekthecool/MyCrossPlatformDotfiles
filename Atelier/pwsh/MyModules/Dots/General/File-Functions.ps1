# Function to read a file and return the raw bytes as a hex string
function Convert-FileToHexString
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath, # The file path as a named parameter

        [switch]$WithSpaces  # Optional switch to add spaces between hex bytes
    )

    # Check if the file exists
    if (-not (Test-Path -Path $FilePath))
    {
        Write-Error "The file at '$FilePath' does not exist."
        return
    }

    try
    {
        # Read the file as a byte array
        $bytes = Get-Content -Path $FilePath -AsByteStream
        if ($bytes.Count -eq 0)
        {
            Write-Error "The file is empty."
            return
        }

        # Convert the byte array to a hex string
        $hexString = $bytes | ForEach-Object { $_.ToString("X2") }

        # Join hex values with or without spaces, based on the parameter
        if ($WithSpaces)
        {
            $hexString = $hexString -join ' '
        } else
        {
            $hexString = $hexString -join ''
        }

        return $hexString
    } catch
    {
        Write-Error "An error occurred while processing the file: $_"
    }
}
