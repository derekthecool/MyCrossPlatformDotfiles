Set-Location $PSScriptRoot

# Delete existing repo, clone new, and delete .git directory
Remove-Item -Recurse -Force ./awesome-wm-widgets
git clone https://github.com/streetturtle/awesome-wm-widgets.git
Remove-Item -Recurse -Force ./awesome-wm-widgets/.git
