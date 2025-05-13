# Load the ps1xml format data file here because using the -PrependPath
# option can't be done when loaded via the Dots.psd1 module manifest
# With this option my formatviews become the default views!
Update-FormatData -PrependPath $PSScriptRoot/DotBeautiful.format.ps1xml
