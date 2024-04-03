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

Describe 'Using git as a diff tool tests' {
    It 'Can run function' {
        { Invoke-GitDiff 2> $null } | Should -Not -Throw
    }

    It 'Calls git with any arguments' {
        Mock git {}
        Invoke-GitDiff 2> $null
        Assert-MockCalled git -Exactly 1 -Scope It
    }

}
