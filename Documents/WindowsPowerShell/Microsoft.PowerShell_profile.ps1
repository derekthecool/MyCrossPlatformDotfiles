# Config for powershell 5.0 Windows only, keep this very basic
# Do not use PSREADLINE as it causes issues with terminal applications

Set-Alias 'v' 'nvim'

# Set Starship prompt
$ENV:STARSHIP_CONFIG = "$HOME\.starship\config.toml"
Invoke-Expression (&starship init powershell)
