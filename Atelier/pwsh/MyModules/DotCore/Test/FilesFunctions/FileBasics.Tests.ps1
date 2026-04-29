BeforeAll {
    Import-Module $PSScriptRoot/../../*.psd1 -Force
}

Describe 'ConvertFrom-Base64' {
    It 'ConvertFrom-Base64 with input <Base64Text> converts to <Expected>' -TestCases @(
        @{
            Base64Text = "SGVsbG8gd29ybGQ="
            Expected   = [System.Text.Encoding]::UTF8.GetBytes("Hello world")
        },
        @{
            Base64Text = "AQIDBAUGBwgJCg=="
            Expected   = [byte[]]@(1 .. 10)
        }
    ) {
        $Base64Text | ConvertFrom-Base64 | Should -BeExactly $Expected
    }

    It 'ConvertFrom-Base64 with input <Base64Text> converts to text <ExpectedText>' -TestCases @(
        @{
            Base64Text   = "SGVsbG8gd29ybGQ="
            ExpectedText = "Hello world"
        },
        @{
            Base64Text   = "REVGR0hJSktMTU5PUA=="
            ExpectedText = "DEFGHIJKLMNOP"
        }
    ) {
        $Base64Text | ConvertFrom-Base64 -AsText | Should -BeExactly $ExpectedText
    }
}

$ConvertToTestCases = @(
    @{
        InputBytes           = [byte[]]@(1 .. 10)
        ExpectedBase64String = 'AQIDBAUGBwgJCg=='
    }
)

Describe 'ConvertTo-Base64' {
    It 'ConvertTo-Base64 with input through pipeline <InputBytes> converts to <ExpectedBase64String>' -TestCases $ConvertToTestCases {
        $InputBytes | ConvertTo-Base64 | Should -BeExactly $ExpectedBase64String
        # Aliased version
        $InputBytes | ConvertTo-64 | Should -BeExactly $ExpectedBase64String
    }
    It 'ConvertTo-Base64 with input as argument <InputBytes> converts to <ExpectedBase64String>' -TestCases $ConvertToTestCases {
        ConvertTo-Base64 -Bytes $InputBytes | Should -BeExactly $ExpectedBase64String
        # Aliased version
        ConvertTo-64 -Bytes $InputBytes | Should -BeExactly $ExpectedBase64String
    }
}

Describe 'Edit-Content' {
    It 'Edit-Count works as expected' -TestCases @(
        @{
            Content                         = 'Hello world'
            ReplacementArgs                 = @{
                Pattern     = 'Hello'
                Replacement = 'Goodbye'
                Confirm     = $false
            }
            ExpectedContentAfterReplacement = 'Goodbye world'
        }
    ) {
        Set-Content -Path ($tempFile = [IO.Path]::GetTempFileName()) -Value $Content -NoNewline
        Get-ChildItem $tempFile | Edit-Content @ReplacementArgs
        Get-Content -Raw $tempFile | Should -BeExactly $ExpectedContentAfterReplacement
        Remove-Item $tempFile
    }
}
