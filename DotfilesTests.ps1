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
Invoke-Pester -Configuration $config
