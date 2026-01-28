$config = New-PesterConfiguration -Hashtable @{
    Run      = @{
        PassThru = $true
        Path     = './Atelier/pwsh/MyModules'
    }
    Debug    = @{
        WriteDebugMessages = $true
    }
    Output   = @{Verbosity = 'Detailed' }
    PassThru = $true
}
$results = Invoke-Pester -Configuration $config
$results
if ($results.Failed -gt 0)
{
    $results.Failed | Select-Object Name, Block, ErrorRecord | Format-List | Out-Host
    exit 1
}
exit 0
