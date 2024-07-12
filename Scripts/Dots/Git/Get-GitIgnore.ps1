# Get all available templates
# Invoke-WebRequest https://www.toptal.com/developers/gitignore/api/list?format=json
# $params = ($list | ForEach-Object { [uri]::EscapeDataString($_) }) -join ","
function Get-GitIgnore
{
    param (
        [Parameter()]
        [switch]$Write
    )

    $AllTemplates = (Invoke-RestMethod https://www.toptal.com/developers/gitignore/api/list) -split ','
    $selected = $AllTemplates | Invoke-Fzf -Prompt 'Choose gitignore file'

    Write-Host "Selected gitignore: $selected"
    $gitignoreContent = Invoke-RestMethod -Uri "https://www.toptal.com/developers/gitignore/api/$selected"

    if($Write)
    {
        Write-Host ".gitignore written"
        $gitignoreContent | Out-File -FilePath $(Join-Path -path $pwd -ChildPath ".gitignore") -Encoding ascii
    } else
    {
        $gitignoreContent
    }
}
