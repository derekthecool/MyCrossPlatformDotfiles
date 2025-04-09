# This module only includes aliases!

# Linux and Windows included aliases in powershell are different!
# In general my preference is to use the Linux command name e.g. 'ls'
# with the powershell command e.g. Get-ChildItem

# Get-ChildItem is far better than /usr/bin/ls
Set-Alias -Name ls -Value Get-ChildItem -Option AllScope -Force -Description 'DotAlias for Get-ChildItem'
Set-Alias -Name cp -Value Copy-Item -Option AllScope -Force -Description 'DotAlias for Copy-Item'
Set-Alias -Name sort -Value Sort-Object -Option AllScope -Force -Description 'DotAlias for Sort-Object'
Set-Alias -Name sleep -Value Start-Sleep -Option AllScope -Force -Description 'DotAlias for Start-Sleep' -Scope Global
Set-Alias -Name ps -Value Get-Process -Option AllScope -Force -Description 'DotAlias for Get-Process'
Set-Alias -Name rmdir -Value rmdir_function -Option AllScope -Force -Description 'DotAlias for Remove-Item -Recurse -Force'
Set-Alias -Name rm -Value Remove-Item -Option AllScope -Force -Description 'DotAlias for Remove-Item'
Set-Alias -Name kill -Value Stop-Process -Option AllScope -Force -Description 'DotAlias for Stop-Process'
Set-Alias -Name cat -Value Get-Content -Option AllScope -Force -Description 'DotAlias for Get-Content'
Set-Alias -Name clear -Value Clear-Host -Option AllScope -Force -Description 'DotAlias for Clear-Host'
Set-Alias -Name mv -Value Move-Item -Option AllScope -Force -Description 'DotAlias for Move-Item'
Set-Alias -Name tee -Value Tee-Object -Option AllScope -Force -Description 'DotAlias for Tee-Object'

# Naughty! Creating a function then setting a alias to the function does not lazy load as expected
# backup plan is to use functions as they seem to have connect lazy loading behavior
function rmdir { Remove-Item -Recurse -Force $args }
function diff { git diff --no-index $args }
