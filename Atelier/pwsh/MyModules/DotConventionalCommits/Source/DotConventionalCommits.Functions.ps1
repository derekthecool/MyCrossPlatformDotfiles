<#
    .SYNOPSIS
    Get all conventional commit actions

    .DESCRIPTION
    Return the list of call actions e.g. fix, revert etc.
    Actions taken from here: https://github.com/conventional-changelog/commitlint/tree/master/%40commitlint/config-conventional

    .EXAMPLE
    PS> Get-ConventionalCommitValues
#>
function Get-ConventionalCommitValues
{
    'build', 'chore', 'ci', 'docs', 'feat', 'fix', 'perf', 'refactor', 'revert', 'style', 'test'
}

function Select-ConventionalCommitValue
{
    Get-ConventionalCommitValues | Invoke-Fzf
}

<#
    .SYNOPSIS
    Select a git file for the scope of a conventional commit

    .DESCRIPTION
    This function uses git ls-tree to list all source controlled files
    to help select a commit scope

    .PARAMETER Name
    Specifies the file name.

    .EXAMPLE
    PS> Add-Extension -name "File"
#>
function Select-ConventionalCommitFileScope
{
    git diff -r HEAD --name-only | Invoke-Fzf
}
