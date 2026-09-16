# Build module with 'dotnet publish` only as needed
$BuildExists = Test-Path $PSScriptRoot/bin -ErrorAction SilentlyContinue

Set-Variable -Name Lang -Option ReadOnly -Value 'C#'

Write-Host "BuildExists: $BuildExists"
Write-Host "env:FORCE_DOT_REBUILD: $env:FORCE_DOT_REBUILD"

if (-not $BuildExists -or $env:FORCE_DOT_REBUILD)
{
    if (-not $(Get-Command dotnet -ErrorAction SilentlyContinue))
    {
        Write-Error "dotnet is installed or found cannot build binary $Lang module $PSScriptRoot"
        return
    }

    Write-Host "Building $Lang binary module $PSScriptRoot"

    dotnet publish $PSScriptRoot/DotNetwork.csproj --verbosity normal
    if (-not $?)
    {
        dotnet --list-sdks
        return
    }
}

Get-ChildItem "$PSScriptRoot/bin/Release/net*.0/publish/*.dll" | ForEach-Object {
    $Module = $_
    Write-Host "Loading $Lang dll: $Module"
    Import-Module $Module
}

# Special multiple ssh function
function Invoke-ssh {
    [CmdletBinding()]
    [Alias('Invoke-ssh')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias('Server')]
        [Alias('Servers')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]$Command,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [string]$IdentityFile,

        [Parameter()]
        [int]$Port,

        [Parameter()]
        [string[]]$SshArgs = @(),

        [Parameter()]
        [int]$ConnectTimeout = 10,

        [Parameter()]
        [switch]$Parallel,

        [Parameter()]
        [int]$ThrottleLimit = 8
    )

    begin {
        $sshExe = (Get-Command ssh -ErrorAction Stop).Source

        $baseArgs = [System.Collections.Generic.List[string]]::new()
        $baseArgs.AddRange([string[]]@(
            '-o', 'BatchMode=yes'                      # never prompt for a password — fail fast on key auth failure
            '-o', "ConnectTimeout=$ConnectTimeout"
            '-n'                                        # redirect stdin from null — otherwise ssh inherits the console's stdin and blocks
            '-T'                                        # no pty — we're running a single non-interactive command, not a shell
        ))
        if ($IdentityFile) { $baseArgs.AddRange([string[]]@('-i', $IdentityFile)) }
        if ($Port)         { $baseArgs.AddRange([string[]]@('-p', $Port)) }
        if ($SshArgs)      { $baseArgs.AddRange($SshArgs) }
    }

    process {
        $targets = foreach ($c in $ComputerName) {
            if ($User) { "$User@$c" } else { $c }
        }

        $invoke = {
            param($sshExe, $baseArgs, $target, $Command)
            $argList = @($baseArgs) + @($target, $Command)
            $output = & $sshExe @argList 2>&1
            [pscustomobject]@{
                ComputerName = $target
                ExitCode     = $LASTEXITCODE
                Output       = ($output | Out-String).TrimEnd()
            }
        }

        if ($Parallel) {
            $targets | ForEach-Object -Parallel {
                $sshExe   = $using:sshExe
                $baseArgs = $using:baseArgs
                $Command  = $using:Command
                $argList  = @($baseArgs) + @($_, $Command)
                $output   = & $sshExe @argList 2>&1
                [pscustomobject]@{
                    ComputerName = $_
                    ExitCode     = $LASTEXITCODE
                    Output       = ($output | Out-String).TrimEnd()
                }
            } -ThrottleLimit $ThrottleLimit
        }
        else {
            foreach ($target in $targets) {
                & $invoke $sshExe $baseArgs $target $Command
            }
        }
    }
}
