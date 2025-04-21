function Set-WindowsRegistrySettings {
    if($IsWindows)
    {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    }
}
