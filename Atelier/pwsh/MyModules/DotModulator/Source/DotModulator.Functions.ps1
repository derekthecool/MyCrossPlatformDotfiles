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

            # if the code contains syntax errors and is invalid, bail out:
            if ($errors)
            {
                throw [System.InvalidCastException]::new("Submitted text could not be converted to PowerShell because it contains syntax errors: $($errors | Out-String)")
            }
        }
    }
}

# https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree
# TODO: (Derek Lomax) 1/15/2026 4:12:15 PM, modify this function from the website to read from files instead
function Get-PsOneAst
{
    param
    (
        # PowerShell code to examine:
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Code,
    
        # requested Ast type
        # use dynamic argument completion:
        [ArgumentCompleter({
                # receive information about current state:
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    
                # get all ast types
                [PSObject].Assembly.GetTypes().Where{ $_.Name.EndsWith('Ast') }.Name | 
                    Sort-Object |
                    # filter results by word to complete
                    Where-Object { $_.LogName -like "$wordToComplete*" } | 
                    ForEach-Object { 
                        # create completionresult items:
                        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
                    }
            })]
        $AstType = '*',
    
        # when set, do not recurse into nested scriptblocks:
        [Switch]
        $NoRecursion
    )

    begin
    {
        # create the filter predicate by using the submitted $AstType
        # if the user did not specify it is "*" by default, including all:
        $predicate = { param($astObject) $astObject.GetType().Name -like $AstType }
    }  
    # do this for every submitted code:
    process
    {
        # we need to read the errors because we are accepting text which
        # can contain syntax errors:
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Code, [ref]$null, [ref]$errors)
    
        # if the code contains syntax errors and is invalid, bail out:
        if ($errors) { throw [System.InvalidCastException]::new("Submitted text could not be converted to PowerShell because it contains syntax errors: $($errors | Out-String)") }
    
        # search for all requested ast...
        $ast.FindAll($predicate, !$NoRecursion) |
            # and dynamically add a visible property for the ast object type:
            Add-Member -MemberType ScriptProperty -Name Type -Value { $this.GetType().Name } -PassThru
    }
}
