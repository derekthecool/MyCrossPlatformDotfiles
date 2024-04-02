BeforeAll {
    # Explicitly importing the powershellget module prevents errors
    Import-Module PowerShellGet -ErrorAction Stop
    . $PSScriptRoot/../Configure-PSReadLine.ps1
}

Describe 'Setup-PSReadLineAndEditor Function Tests' {

    Context 'Module Presence and Installation' {
        It 'Checks if PSReadLine module is installed' {
            Mock Get-Module { return $null }
            Mock Install-Module {}
            Mock Import-Module {}

            Setup-PSReadLineAndEditor

            Assert-MockCalled Get-Module -Times 1 -ParameterFilter { $Name -eq 'PSReadLine' }
        }

        It 'Installs PSReadLine module if not present' {
            Mock Get-Module { return $null }
            Mock Install-Module {}
            Mock Import-Module {}

            Setup-PSReadLineAndEditor

            Assert-MockCalled Install-Module -Times 1 -ParameterFilter { $Name -eq 'PSReadLine' }
            Assert-MockCalled Import-Module -Times 1 -ParameterFilter { $Name -eq 'PSReadLine' }
        }

        It 'Does not attempt to install PSReadLine if it is already installed' {
            Mock Get-Module { return @(@{Name = 'PSReadLine'}) } # Mock returning module info
            Mock Install-Module {}

            Setup-PSReadLineAndEditor

            Assert-MockCalled Install-Module -Times 0
        }
    }

    Context 'PSReadLine Configuration' {
        It 'Sets PSReadLine options' {
            Mock Set-PSReadLineOption {}

            Setup-PSReadLineAndEditor

            Assert-MockCalled Set-PSReadLineOption -Times 4
        }
    }

    Context 'Environment Variables' {
        It 'Sets EDITOR and VISUAL environment variables to nvim' {
            Setup-PSReadLineAndEditor

            $env:EDITOR | Should -BeExactly 'nvim'
            $env:VISUAL | Should -BeExactly 'nvim'
        }
    }
}
