function Set-WindowsRegistrySettings
{
    if ($IsWindows)
    {
        # Show file extension in explorer
        Write-Host "Set file explorer extension to be visible" -ForegroundColor Green
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -PassThru

        # Add registry value to enable Developer Mode
        # Create AppModelUnlock if it doesn't exist, required for enabling Developer Mode
        # Stackover flow on how New-Item -ItemType SymbolicLink requires admin and setting developer mode can fix: https://stackoverflow.com/a/34905638
        # Stackover flow on how to set registry to enable developer mode: https://stackoverflow.com/questions/40033608/enable-windows-10-developer-mode-programmatically
        Write-Host "Enable developer mode (useful to be able to create symbolic links without admin access)" -ForegroundColor Green
        $RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
        if (-not(Test-Path -Path $RegistryKeyPath))
        {
            New-Item -Path $RegistryKeyPath -ItemType Directory -Force
        }
        New-ItemProperty -Path $RegistryKeyPath -Name AllowDevelopmentWithoutDevLicense -PropertyType DWORD -Value 1 -ErrorAction Continue
        if (-not $?)
        {
            Write-Error "Setting the developer mode registry item requires admin access"
        }
    }
}
