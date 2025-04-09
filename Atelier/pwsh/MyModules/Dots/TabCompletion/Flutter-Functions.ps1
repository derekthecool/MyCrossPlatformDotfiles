function Get-FlutterGlobalOptions
{
    $helpOutput = flutter --help
    $helpOutput
    | Where-Object { -not ([string]::IsNullOrEmpty($_)) }
    | ConvertFrom-Text -NoProgress '(?<GlobalOption>--\S+\b)'
    | Sort-Object -Property GlobalOption -Unique
}

function Get-FlutterCommandsAndNonGlobalOptions
{
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$FlutterCommand
    )

    process
    {
        $helpOutput = Invoke-Expression "$FlutterCommand --help"
        $helpOutput
        | Where-Object { -not ([string]::IsNullOrEmpty($_)) }
        | ConvertFrom-Text -NoProgress '(?<CommandOrHelp>(^  [a-z0-9-]+|--[a-z0-9-]+))'
        | Sort-Object -Property CommandOrHelp -Unique
    }
}
