# Uses EZOut to format as specified here
# Generate by running ../Dots.EzFormat.ps1
# Generated output located ../Dots.format.ps1xml
Write-FormatView `
    -TypeName 'System.Management.Automation.PSDriveInfo' `
    -Name DotsPSDriveInfoView `
    -Property Name, Used, Root, Description `
    -VirtualProperty @{
    Used = {
        if ($_.Used -ne 0)
        {
            "{0}%" -f [Math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 0)
        } else
        {
            0
        }
    }
} `
    -AutoSize
