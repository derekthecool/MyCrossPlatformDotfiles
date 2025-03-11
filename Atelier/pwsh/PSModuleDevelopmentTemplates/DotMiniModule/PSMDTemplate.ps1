@{
    TemplateName         = "DotMiniModule"
    Version              = "1.0.0.0"
    AutoIncrementVersion = $true
    Tags                 = 'module', 'dots'
    Author               = 'Derek Lomax'
    Description          = 'Tiny powershell module fit for lazy loading in this repo MyCrossPlatformDotfiles'
    Exclusions           = @("PSMDInvoke.ps1")
    Scripts              = @{
        guid = {
            [System.Guid]::NewGuid().ToString()
        }
    }
}
