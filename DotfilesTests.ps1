$config = New-PesterConfiguration -Hashtable @{
    Run          = @{
        PassThru    = $true
        Path        = './Atelier/pwsh/MyModules'
        # Kroger integration tests require live API credentials via
        # Microsoft.Powershell.SecretStore, which prompts for a vault password
        # in fresh sessions (CI, clean shells) and blocks the suite. Exclude
        # the whole folder until these tests mock the secret lookup or the
        # vault is unlocked in CI.
        ExcludePath = '*/DotWebApi/Test/Kroger/*'
    }
    Debug        = @{
        WriteDebugMessages = $true
    }
    CodeCoverage = @{
        Enabled = $true
        Path    = './Atelier/pwsh/MyModules'
    }
    Output       = @{Verbosity = 'Detailed' }
    PassThru     = $true
}
$results = Invoke-Pester -Configuration $config
$results
if (@($results.Failed).Length -gt 0)
{
    $results.Failed | Select-Object Name, Block, ErrorRecord | Format-List | Out-Host
    exit 1
}
exit 0
