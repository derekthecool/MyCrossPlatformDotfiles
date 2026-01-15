function Format-PowershellScriptFile
{
    [CmdletBinding()]
    [Alias("taco")]
    param (
        [string]$Path = ($PWD.Path),
        [string]$Settings = "$HOME/Atelier/pwsh/PSScriptAnalyzerSettings.psd1"
    )

    Get-ChildItem $Path -Recurse -Include *ps1, *psm1, *psd1 | ForEach-Object {
        Write-Verbose "Formatting file: $_"
        $content = Get-Content $_ -Raw
        $newContent = Invoke-Formatter -ScriptDefinition $content -Settings $Settings
        $newContent | Set-Content -Path $_
    }
}

New-Alias -Name 'fps' -Value Format-PowershellScriptFile

function Get-PowershellScriptFileAstDetails
{
    
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path
    )
    process
    {
        foreach ($File in $Path)
        {
            $functions = @()
            $aliases = @()

            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)

            # --- FUNCTIONS ---
            $functions += $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true) | ForEach-Object { $_.Name }

            # --- ALIASES (Set-Alias or New-Alias, positional or named args) ---
            $aliases += $ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    @('Set-Alias', 'New-Alias') -contains $node.GetCommandName()
                }, $true) | ForEach-Object {
                $name = $null
                # Look through all command elements for -Name or positional arg
                for ($i = 1; $i -lt $_.CommandElements.Count; $i++)
                {
                    $elem = $_.CommandElements[$i]
                    if ($elem -is [System.Management.Automation.Language.CommandParameterAst])
                    {
                        if ($elem.ParameterName -eq 'Name' -and $i + 1 -lt $_.CommandElements.Count)
                        {
                            $next = $_.CommandElements[$i + 1]
                            if ($next -is [System.Management.Automation.Language.StringConstantExpressionAst])
                            {
                                $name = $next.Value
                            }
                        }
                    } elseif (-not $name -and $elem -is [System.Management.Automation.Language.StringConstantExpressionAst])
                    {
                        # Fallback for positional arg
                        $name = $elem.Value
                    }
                }
                $name
            }

            $functions = $functions | Sort-Object -Unique
            $aliases = $aliases | Sort-Object -Unique

            Write-Verbose "Exporting functions: $($functions -join ', ')"
            Write-Verbose "Exporting aliases: $($aliases -join ', ')"

            [PSCustomObject]@{
                Aliases   = $aliases
                Functions = $functions
            }
        }
    }
}


function Get-PowershellAst
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Path
    )
    process
    {
        foreach ($File in $Path)
        {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
        }
    }
}
