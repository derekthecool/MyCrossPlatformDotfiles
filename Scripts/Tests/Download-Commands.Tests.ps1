BeforeAll {
    # Extract just the filename without extension and replace '.Tests' with nothing, assuming the test script ends with '.Tests.ps1'
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    $scriptName = $fileNameWithoutExtension -replace '\.Tests$', ''
    $scriptFileName = "$scriptName.ps1"
    $scriptBase = ([regex]::Match($PSCommandPath, '(.*[/\\]Scripts)')).Groups[1].Value

    # Search for the script within the base directory, excluding any paths that still include 'Tests'
    $scriptPath = Get-ChildItem -Path $scriptBase -Recurse -Filter $scriptFileName |
        Where-Object { $_.FullName -notmatch 'Tests' } |
        Select-Object -First 1 -ExpandProperty FullName

    if ($scriptPath)
{
        . $scriptPath
    } else
                     {
        Write-Error "Expected script not found for: $scriptFileName"
        Write-Error "Script base: $scriptBase"
    }
}

Describe 'ISO Functions' {
    It 'Get-ISOFilename <InputURL> should return <Output>' -TestCases @(
        @{ Input = 'http://old-releases.ubuntu.com/releases/trusty/ubuntu-14.04.1-desktop-amd64.iso'; Output = 'ubuntu-14.04.1-desktop-amd64.iso'; }
    ) {
        param (
            [string]$InputURL,
            [string]$Output
        )

        Get-ISOFilename -Filename $InputURL | Should -Be $Output
    }

    It 'Get-ISOFilename <InputURL> should return throw exception' -TestCases @(
        @{ Input = 'test'; Output = 'test'; }
    ) {
        param (
            [string]$InputURL,
            [string]$Output
        )

        { Get-ISOFilename -Filename $InputURL | Should -Throw }
    }
}
