function Get-AdventOfCodeData
{
    param(
        [int]$Year,
        [int]$Day
    )

    # Define the base URL for AdventOfCode input files
    $baseUrl = "https://adventofcode.com/$Year/day/$Day/input"

    # Get the session cookie from environment variables
    $cookie = $env:AdventOfCodeCookie
    if (-not $cookie)
    {
        Write-Error "AdventOfCodeCookie environment variable is missing."
        return
    }

    # Define the local file path where input data will be saved
    $localFilePath = Join-Path -Path $HOME -ChildPath "AdventOfCode/inputs/$Year/$Day.txt"

    # Check if the directory exists, if not, create it
    $directory = [System.IO.Path]::GetDirectoryName($localFilePath)
    if (-not (Test-Path -Path $directory))
    {
        Write-Host "Creating directory: $directory"
        New-Item -ItemType Directory -Force -Path $directory
    }

    # If file exists, return the content, otherwise download the input
    if (Test-Path -Path $localFilePath)
    {
        Write-Host "Reading input data from local file: $localFilePath"
        return Get-Content -Path $localFilePath
    } else
    {
        Write-Host "Downloading input data from: $baseUrl to $localFilePath"
        try
        {
            # Make the web request to download the file
            $response = Invoke-RestMethod -Uri $baseUrl -Headers @{ Cookie = "session=$cookie" }

            # Save the content to the local file
            $response | Out-File -FilePath $localFilePath -Force

            Write-Host "File downloaded successfully to: $localFilePath"
            return $response
        } catch
        {
            Write-Error "Failed to download the file. Error: $_"
        }
    }
}

New-Alias -Name 'aoc' -Value Get-AdventOfCodeData
