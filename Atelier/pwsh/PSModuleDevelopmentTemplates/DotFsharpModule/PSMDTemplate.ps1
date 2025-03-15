@{
    TemplateName = "DotFsharpModule"
    Version = "1.0.0.0"
    AutoIncrementVersion = $true
    Tags = 'module','dots','binary_module'
    Author = 'Derek Lomax'
    Description = 'Tiny binary F# powershell module fit for lazy loading in this repo MyCrossPlatformDotfiles'
    Exclusions = @("PSMDInvoke.ps1", "bin", "obj")
    Scripts = @{
        guid = {
            [System.Guid]::NewGuid().ToString()
        }
    }
}
