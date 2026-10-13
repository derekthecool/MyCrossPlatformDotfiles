BeforeAll {
    $moduleRoot = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent
    Import-Module (Join-Path $moduleRoot 'DotWebApi.psd1') -Force
}

Describe 'Update-ModuleManifestExport' {
    BeforeEach {
        $script:moduleDirectory = Join-Path $TestDrive "Mod$([guid]::NewGuid().ToString('N').Substring(0, 6))"
        $null = New-Item -ItemType Directory -Path $script:moduleDirectory
        Set-Content -LiteralPath (Join-Path $script:moduleDirectory 'MyMod.psm1') -Value ''
        $script:manifest = Join-Path $script:moduleDirectory 'MyMod.psd1'
        $script:original = @"
@{
    RootModule        = 'MyMod.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '11111111-2222-3333-4444-555555555555'
    # Explicit lists keep lazy loading working. Never use *.
    AliasesToExport   = @(
        'hand'
    )
    FunctionsToExport = @(
        # Hand-written functions
        'Get-Hand'
        'Set-Hand'
    )
    PrivateData       = @{ PSData = @{ Tags = @('a') } }
}

"@
        Set-Content -LiteralPath $script:manifest -Value $script:original -NoNewline
    }

    It 'adds a generated region and keeps hand-written entries and comments' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen', 'New-Gen' -Region Gen
        $text = Get-Content -LiteralPath $script:manifest -Raw
        $text | Should -Match '# BEGIN generated: Gen'
        $text | Should -Match '# END generated: Gen'
        $text | Should -Match '# Explicit lists keep lazy loading working'
        $text | Should -Match '# Hand-written functions'
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        $data.FunctionsToExport | Should -Be @('Get-Hand', 'Set-Hand', 'Get-Gen', 'New-Gen')
        $data.AliasesToExport | Should -Be @('hand')
        $data.PrivateData.PSData.Tags | Should -Be @('a')
    }

    It 'is idempotent' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen
        $first = Get-Content -LiteralPath $script:manifest -Raw
        $result = Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen -PassThru
        Get-Content -LiteralPath $script:manifest -Raw | Should -BeExactly $first
        $result.Changed | Should -BeFalse
    }

    It 'replaces only its own region so removed functions drop out' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen', 'Old-Gen' -Region Gen
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        $data.FunctionsToExport | Should -Be @('Get-Hand', 'Set-Hand', 'Get-Gen')
    }

    It 'keeps separate regions for separate APIs' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-A' -Region A
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-B' -Region B
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-A2' -Region A
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        $data.FunctionsToExport | Should -Be @('Get-Hand', 'Set-Hand', 'Get-B', 'Get-A2')
    }

    It 'does not repeat a name that is already listed by hand' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Hand', 'Get-Gen' -Region Gen
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        @($data.FunctionsToExport | Where-Object { $_ -eq 'Get-Hand' }).Count | Should -Be 1
        $data.FunctionsToExport | Should -Contain 'Get-Gen'
    }

    It 'inserts a missing AliasesToExport key' {
        $without = $script:original -replace "(?s)    AliasesToExport.*?\)\r?\n", ''
        Set-Content -LiteralPath $script:manifest -Value $without -NoNewline
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -AliasName 'gen' -Region Gen
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        $data.AliasesToExport | Should -Be @('gen')
        $data.FunctionsToExport | Should -Contain 'Get-Gen'
    }

    It 'preserves CRLF line endings' {
        Set-Content -LiteralPath $script:manifest -Value ($script:original -replace "`n", "`r`n") -NoNewline
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen
        $text = [System.IO.File]::ReadAllText($script:manifest)
        $text | Should -Match "`r`n"
        ($text -replace "`r`n", '').Contains("`n") | Should -BeFalse
    }

    It 'preserves a UTF-8 BOM when the file has one' {
        [System.IO.File]::WriteAllText($script:manifest, $script:original, [System.Text.UTF8Encoding]::new($true))
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen
        $bytes = [System.IO.File]::ReadAllBytes($script:manifest)
        $bytes[0..2] | Should -Be @(0xEF, 0xBB, 0xBF)
    }

    It '-Full replaces both arrays with exactly the given names' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Only-This' -AliasName 'only' -Full
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        $data.FunctionsToExport | Should -Be @('Only-This')
        $data.AliasesToExport | Should -Be @('only')
        (Get-Content -LiteralPath $script:manifest -Raw) | Should -Match '# Explicit lists keep lazy loading working'
    }

    It 'refuses region updates when exports use a wildcard' {
        Set-Content -LiteralPath $script:manifest -Value ($script:original -replace "(?s)FunctionsToExport = @\(.*?\)\r?\n", "FunctionsToExport = '*'`n") -NoNewline
        { Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen } | Should -Throw '*explicit list*'
    }

    Context 'a manifest whose exports a build step wrote as bare lists' {
        BeforeEach {
            # Update-ModuleManifest writes "FunctionsToExport = 'a', 'b'" and "AliasesToExport = 'one'" without @( ).
            $script:bare = "@{`r`nRootModule = 'MyMod.psm1'`r`nModuleVersion = '0.1.0'`r`nFunctionsToExport = 'Get-Hand', 'Get-Gen', `r`n               'Set-Hand'`r`nCmdletsToExport = @()`r`nAliasesToExport = 'hand'`r`n}`r`n"
            [System.IO.File]::WriteAllText($script:manifest, $script:bare, [System.Text.UTF8Encoding]::new($true))
        }

        It 'leaves the file exactly as it is when every generated name is already listed' {
            $result = Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen', 'Get-Hand' -AliasName 'hand' -Region Gen -PassThru
            [System.IO.File]::ReadAllText($script:manifest) | Should -BeExactly $script:bare
            $result.Changed | Should -BeFalse
        }

        It 'adds only the generated names that are missing and keeps the file valid' {
            Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen', 'New-Gen' -AliasName 'gen' -Region Gen
            $data = Import-PowerShellDataFile -LiteralPath $script:manifest
            $data.FunctionsToExport | Should -Be @('Get-Hand', 'Get-Gen', 'Set-Hand', 'New-Gen')
            $data.AliasesToExport | Should -Be @('hand', 'gen')
            (Get-Content -LiteralPath $script:manifest -Raw) | Should -Match '# BEGIN generated: Gen'
        }
    }

    It 'does not touch the file with -WhatIf' {
        Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen -WhatIf
        Get-Content -LiteralPath $script:manifest -Raw | Should -BeExactly $script:original
    }

    It 'works when the RootModule is produced by a later build step (psm1 not present yet)' {
        Remove-Item -LiteralPath (Join-Path $script:moduleDirectory 'MyMod.psm1')
        { Update-ModuleManifestExport -ManifestPath $script:manifest -FunctionName 'Get-Gen' -Region Gen } | Should -Not -Throw
        (Import-PowerShellDataFile -LiteralPath $script:manifest).FunctionsToExport | Should -Contain 'Get-Gen'
    }

    It 'throws for a missing manifest' {
        { Update-ModuleManifestExport -ManifestPath (Join-Path $TestDrive 'nope.psd1') -FunctionName x -Region R } | Should -Throw '*not found*'
    }

    It 'collects names from -SourcePath, skipping private folders' {
        $source = Join-Path $script:moduleDirectory 'Source'
        $null = New-Item -ItemType Directory -Path (Join-Path $source 'private') -Force
        Set-Content -LiteralPath (Join-Path $source 'Pub.ps1') -Value "function Get-Scanned { [CmdletBinding()] [Alias('gscan')] param() function Inner-Helper { } }"
        Set-Content -LiteralPath (Join-Path $source 'private/Priv.ps1') -Value 'function Get-Hidden { }'
        Update-ModuleManifestExport -ManifestPath $script:manifest -SourcePath $source -Region Scan
        $data = Import-PowerShellDataFile -LiteralPath $script:manifest
        $data.FunctionsToExport | Should -Contain 'Get-Scanned'
        $data.FunctionsToExport | Should -Not -Contain 'Get-Hidden'
        $data.FunctionsToExport | Should -Not -Contain 'Inner-Helper'
        $data.AliasesToExport | Should -Contain 'gscan'
    }
}

Describe 'Get-ModuleSourceExport' {
    It 'finds functions, [Alias()] attributes and Set-Alias/New-Alias names' {
        $file = Join-Path $TestDrive 'scan.ps1'
        Set-Content -LiteralPath $file -Value @'
function Get-One { [CmdletBinding()] [Alias('one', 'uno')] param([Alias('notme')][string]$P) }
function Get-Two { }
Set-Alias -Name two -Value Get-Two
New-Alias three Get-Two
'@
        $found = InModuleScope DotWebApi -Parameters @{ File = $file } { Get-ModuleSourceExport -Path $File }
        $found.Function | Should -Be @('Get-One', 'Get-Two')
        $found.Alias | Should -Be @('one', 'three', 'two', 'uno')
    }

    It 'fails clearly for a file that does not parse' {
        $file = Join-Path $TestDrive 'broken.ps1'
        Set-Content -LiteralPath $file -Value 'function Broken { '
        { InModuleScope DotWebApi -Parameters @{ File = $file } { Get-ModuleSourceExport -Path $File } } | Should -Throw '*Cannot scan*'
    }
}
