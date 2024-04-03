BeforeAll {
    $scriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath).Replace('.Tests', '')
    $scriptPath = Get-ChildItem "$HOME/MyCrossPlatformScripts/" -Recurse -Filter "$scriptName.ps1"
    | Where-Object FullName -NotMatch 'Tests'
    | Select-Object -First 1 -ExpandProperty FullName
    if ($scriptPath) {
        . $scriptPath
    } else {
        Write-Error "Expected script not found for: $scriptName"
    }
}

Describe 'Mason tools in path' {
    It 'Should add mason bin path to path environment variable' {
        Add-MasonToolsToPath
        {$env:Path -match 'mason'} | Should -Be $true
    }
}
