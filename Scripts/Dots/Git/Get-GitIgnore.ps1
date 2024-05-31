# Get all available templates
# Invoke-WebRequest https://www.toptal.com/developers/gitignore/api/list?format=json
# $params = ($list | ForEach-Object { [uri]::EscapeDataString($_) }) -join ","
function Get-GitIgnore
{
    $AllTemplates = Invoke-WebRequest 'https://www.toptal.com/developers/gitignore/api/list?format=json' | ConvertFrom-Json

    # Loop through each property
    foreach ($property in $AllTemplates.PSObject.Properties)
    {
        $propertyName = $property.Name
        $propertyValue = $property.Value
        Write-Output "$propertyName : $propertyValue"
    }
}
