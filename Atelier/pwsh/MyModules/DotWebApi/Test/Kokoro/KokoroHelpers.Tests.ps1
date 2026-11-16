BeforeAll {
    Import-Module $PSScriptRoot/../../DotWebApi.psd1 -Force
}

Describe 'Start-KokoroRead' {

    It 'is exported by the manifest' {
        Get-Command Start-KokoroRead -Module DotWebApi | Should -Not -BeNullOrEmpty
    }

    It 'sends a single pipeline string as one request' {
        InModuleScope DotWebApi {
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            'test test yo-yo' | Start-KokoroRead

            Should -Invoke New-KokoroSpeech -Times 1 -Exactly
            Should -Invoke New-KokoroSpeech -ParameterFilter {
                $InputText -eq 'test test yo-yo'
            }
        }
    }

    It 'joins a piped string[] into one request instead of one call per line' {
        InModuleScope DotWebApi {
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            @('alpha', '', 'bravo') | Start-KokoroRead

            Should -Invoke New-KokoroSpeech -Times 1 -Exactly
            Should -Invoke New-KokoroSpeech -ParameterFilter {
                $InputText -eq ('alpha', '', 'bravo' -join [Environment]::NewLine)
            }
        }
    }

    It 'accepts a string[] by parameter as well as by pipeline' {
        InModuleScope DotWebApi {
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            Start-KokoroRead -OtherText @('alpha', 'bravo')

            Should -Invoke New-KokoroSpeech -Times 1 -Exactly
            Should -Invoke New-KokoroSpeech -ParameterFilter {
                $InputText -eq ('alpha', 'bravo' -join [Environment]::NewLine)
            }
        }
    }

    It 'defaults to the clipboard when given no text at all' {
        InModuleScope DotWebApi {
            Mock Get-Clipboard { "line one`nline two" }
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            Start-KokoroRead

            Should -Invoke Get-Clipboard -Times 1 -Exactly
            Should -Invoke New-KokoroSpeech -Times 1 -Exactly
        }
    }

    It 'still prefers piped text over the clipboard' {
        InModuleScope DotWebApi {
            Mock Get-Clipboard { 'clipboard content' }
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            'piped content' | Start-KokoroRead

            Should -Invoke Get-Clipboard -Times 0 -Exactly
            Should -Invoke New-KokoroSpeech -ParameterFilter {
                $InputText -eq 'piped content'
            }
        }
    }

    It 'logs the chosen source and the join to the verbose stream' {
        InModuleScope DotWebApi {
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            $verbose = @('alpha', 'bravo') | Start-KokoroRead -Verbose 4>&1 |
                Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } |
                ForEach-Object { $_.Message }

            $verbose -join "`n" | Should -BeLike "*Parameter set 'Text' selected*"
            $verbose -join "`n" | Should -BeLike '*Joined 2 supplied line(s)*'
            $verbose -join "`n" | Should -BeLike '*No -Voice supplied*'
        }
    }

    It 'reads the clipboard with -Raw so it is never split per line' {
        InModuleScope DotWebApi {
            Mock Get-Clipboard { "line one`nline two" }
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            Start-KokoroRead -FromClipboard

            Should -Invoke Get-Clipboard -ParameterFilter { $Raw -eq $true }
            Should -Invoke New-KokoroSpeech -Times 1 -Exactly
        }
    }

    It 'throws a clear error instead of an HTTP 400 when nothing is speakable' {
        InModuleScope DotWebApi {
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            { @('', '   |   ~~~~~~~~') | Start-KokoroRead } |
                Should -Throw '*No speakable text*'

            Should -Invoke New-KokoroSpeech -Times 0 -Exactly
        }
    }

    It 'plays the synthesized audio and returns it only with -PassThru' {
        InModuleScope DotWebApi {
            Mock New-KokoroSpeech { [System.IO.FileInfo]'fake.mp3' }
            Mock Start-KokoroPlayback { }

            $quiet = 'hello' | Start-KokoroRead
            $loud = 'hello' | Start-KokoroRead -PassThru

            Should -Invoke Start-KokoroPlayback -Times 2 -Exactly
            $quiet | Should -BeNullOrEmpty
            $loud.Name | Should -Be 'fake.mp3'
        }
    }
}
