BeforeAll {
    Import-Module $PSScriptRoot/../*.psd1 -Force
}

Describe 'DotClipboard tests' {
    It 'Function Get-ClipboardAsArray works with <Length> input items' -TestCases @(
        @{
            Length    = 5
            ClipBoard = (1 .. 5) -join "`n"
        }
        @{
            Length    = 1000
            ClipBoard = (1 .. 1000) -join "`n"
        }
        @{
            Length    = 6
            ClipBoard = (1 .. 6) -join ","
        }
        @{
            Length    = 1001
            ClipBoard = (1 .. 1001) -join ","
        }
        @{
            Length    = 50
            ClipBoard = (1 .. 50 | ForEach-Object { Get-Random }) -join ","
        }
        @{
            Length    = 5
            ClipBoard = "hello`nworld`tthis, should       work"
        }
        # Stripping empty white space items
        @{
            Length    = 2
            ClipBoard = "1,,,,5"
        }
    ) {
        $ClipBoard | Set-Clipboard
        Get-ClipboardAsArray | Should -HaveCount $Length
    }

    It 'Function Get-ClipboardAsArray works with <Length> input items and MatchFilter works as expected' -TestCases @(
        @{
            Length      = 3
            ClipBoard   = (1 .. 5) -join "`n"
            MatchFilter = "[135]"
        }
        @{
            Length      = 10
            ClipBoard   = (1 .. 1000) -join "`n"
            MatchFilter = "\d00"
        }
        @{
            Length      = 6
            ClipBoard   = (1 .. 6) -join ","
            MatchFilter = ".*"
        }
    ) {
        $ClipBoard | Set-Clipboard
        Get-ClipboardAsArray -MatchFilter $MatchFilter | Should -HaveCount $Length
    }

    It 'Json format works' {
        '1,2, 3, 4, 5' | Set-Clipboard
        Get-ClipboardAsArray -Json | Should -Be '["1","2","3","4","5"]'
    }

    It 'AsSqlQueryList works' {
        '1,2, 3, 4, 5' | Set-Clipboard
        Get-ClipboardAsArray -AsSqlQueryList | Should -Be '"1","2","3","4","5"'
    }

    It 'AsSqlInsert works' {
        '1,2, 3, 4, 5' | Set-Clipboard
        Get-ClipboardAsArray -AsSqlInsert | Should -Be '("1"),("2"),("3"),("4"),("5")'
    }
}
