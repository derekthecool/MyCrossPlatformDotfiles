function Setup-PSReadLineAndEditor {
    # Check if PSReadLine module is installed
    $psReadLineModule = Get-Module -ListAvailable -Name PSReadLine

    if (-not $psReadLineModule) {
        Write-Host 'PSReadLine module not found. Attempting to install it...'
        try {
            Install-Module -Name PSReadLine -Force -Scope CurrentUser
            Import-Module PSReadLine
            Write-Host 'PSReadLine module installed successfully.'
        } catch {
            Write-Host "Failed to install PSReadLine module. Error: $_"
            return
        }
    }

    # Configure PSReadLine
    try {
        Set-PSReadLineOption -EditMode vi
        Set-PSReadLineOption -ViModeIndicator Prompt
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
        Write-Host "Failed to configure PSReadLine. Error: $_"
    }

    # Set editor environment variables
    $env:EDITOR = 'nvim'
    $env:VISUAL = 'nvim'
}
