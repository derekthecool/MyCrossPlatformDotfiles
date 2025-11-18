@{
    TemplateName         = "FRModule"
    Version              = "1.0.0.0"
    AutoIncrementVersion = $true
    Tags                 = 'FR'
    Author               = 'Derek Lomax'
    Description          = 'Create FR Module'
    Exclusions           = @("PSMDInvoke.ps1")
    Scripts              = @{
        guid = {
            [System.Guid]::NewGuid().ToString()
        }
    }
}
