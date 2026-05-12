<#
.SYNOPSIS
    Gets the path to a workspace configuration file.

.DESCRIPTION
    Returns the full path to a workspace JSON file based on the workspace number.

.PARAMETER Workspace
    The workspace number (1-9).

.EXAMPLE
    Get-WorkspaceConfigPath -Workspace 1
    Returns /home/derek/Atelier/workspaces/1.json
#>
function Get-WorkspaceConfigPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, 9)]
        [int]$Workspace
    )

    Join-Path $HOME Atelier workspaces "$Workspace.json"
}

<#
.SYNOPSIS
    Gets the path to the filters configuration file.

.DESCRIPTION
    Returns the full path to the filters JSON file.

.EXAMPLE
    Get-FiltersConfigPath
    Returns /home/derek/Atelier/workspaces/filters.json
#>
function Get-FiltersConfigPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param()

    Join-Path $HOME Atelier workspaces filters.json
}

<#
.SYNOPSIS
    Validates a workspace number.

.DESCRIPTION
    Tests if a workspace number is within the valid range (1-9).

.PARAMETER Workspace
    The workspace number to validate.

.EXAMPLE
    Test-WorkspaceConfigValid -Workspace 5
    Returns $true

.EXAMPLE
    Test-WorkspaceConfigValid -Workspace 10
    Returns $false
#>
function Test-WorkspaceConfigValid
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [int]$Workspace
    )

    $Workspace -ge 1 -and $Workspace -le 9
}

<#
.SYNOPSIS
    Creates a new workspace configuration array.

.DESCRIPTION
    Returns an empty array for a new workspace configuration.

.EXAMPLE
    New-WorkspaceConfig
    Returns @()
#>
function New-WorkspaceConfig
{
    [CmdletBinding()]
    [OutputType([array])]
    param()

    @()
}

<#
.SYNOPSIS
    Converts input to a route object.

.DESCRIPTION
    Converts a string, hashtable, or PSCustomObject to a standardized route object
    with 'app' and 'type' properties.

.PARAMETER InputObject
    The input object to convert. Can be a string (app name), hashtable, or PSCustomObject.

.PARAMETER DefaultType
    The default type to use if not specified (default: 'process').

.EXAMPLE
    ConvertTo-RouteObject -InputObject 'firefox'
    Returns @{ app = 'firefox'; type = 'process' }

.EXAMPLE
    ConvertTo-RouteObject -InputObject @{ Name = 'Alacritty'; Type = 'class' }
    Returns @{ app = 'Alacritty'; type = 'class' }

.EXAMPLE
    'firefox', 'brave' | ConvertTo-RouteObject
    Returns multiple route objects
#>
function ConvertTo-RouteObject
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object]$InputObject,

        [Parameter(Position = 1)]
        [ValidateSet('process', 'class', 'title', 'instance', 'role')]
        [string]$DefaultType = 'process'
    )

    process
    {
        if ($null -eq $InputObject)
        {
            return
        }

        # If it's already a route object (hashtable with app and type), return it
        if ($InputObject -is [hashtable] -and $InputObject.ContainsKey('app') -and $InputObject.ContainsKey('type'))
        {
            return $InputObject
        }

        # If it's a PSCustomObject, convert to hashtable
        if ($InputObject -is [PSCustomObject])
        {
            $hash = @{}
            foreach ($prop in $InputObject.PSObject.Properties)
            {
                $hash[$prop.Name.ToLower()] = $prop.Value
            }

            # Normalize property names
            if ($hash.ContainsKey('name') -and -not $hash.ContainsKey('app'))
            {
                $hash['app'] = $hash['name']
                $hash.Remove('name') | Out-Null
            }

            if (-not $hash.ContainsKey('type'))
            {
                $hash['type'] = $DefaultType
            }

            return $hash
        }

        # If it's a hashtable with 'Name' key, normalize it
        if ($InputObject -is [hashtable])
        {
            $hash = @{}

            # Normalize all keys to lowercase
            foreach ($key in $InputObject.Keys)
            {
                $hash[$key.ToLower()] = $InputObject[$key]
            }

            # Normalize property names
            if ($hash.ContainsKey('name') -and -not $hash.ContainsKey('app'))
            {
                $hash['app'] = $hash['name']
                $hash.Remove('name') | Out-Null
            }

            if (-not $hash.ContainsKey('type'))
            {
                $hash['type'] = $DefaultType
            }

            return $hash
        }

        # If it's a string, create a route object
        if ($InputObject -is [string])
        {
            return @{
                app  = $InputObject
                type = $DefaultType
            }
        }

        # Unsupported type
        Write-Error "Unsupported input type: $($InputObject.GetType().Name)"
    }
}

<#
.SYNOPSIS
    Tests if a route already exists in a configuration.

.DESCRIPTION
    Checks if a route with the same app name and type already exists in the configuration.

.PARAMETER Routes
    The existing routes array.

.PARAMETER Route
    The route to check for duplicates.

.EXAMPLE
    $routes = @(@{app='firefox'; type='process'})
    Test-DuplicateRoute -Routes $routes -Route @{app='firefox'; type='process'}
    Returns $true
#>
function Test-DuplicateRoute
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Position = 0)]
        [object[]]$Routes,

        [Parameter(Mandatory, Position = 1)]
        [hashtable]$Route
    )

    # Handle null or empty routes
    if ($null -eq $Routes -or $Routes.Count -eq 0)
    {
        return $false
    }

    foreach ($existingRoute in $Routes)
    {
        if ($existingRoute.app -eq $Route.app -and $existingRoute.type -eq $Route.type)
        {
            return $true
        }
    }

    return $false
}

<#
.SYNOPSIS
    Loads a workspace configuration from file.

.DESCRIPTION
    Reads and parses a workspace JSON file. Creates a new empty configuration if the file doesn't exist.

.PARAMETER Workspace
    The workspace number (1-9).

.EXAMPLE
    Get-WorkspaceConfiguration -Workspace 1
#>
function Get-WorkspaceConfiguration
{
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, 9)]
        [int]$Workspace
    )

    $path = Get-WorkspaceConfigPath -Workspace $Workspace

    if (-not (Test-Path $path))
    {
        Write-Verbose "Workspace configuration file not found at $path. Creating new empty configuration."
        return New-WorkspaceConfig
    }

    try
    {
        $content = Get-Content $path -Raw | ConvertFrom-Json

        # Handle null or empty content
        if ($null -eq $content)
        {
            return New-WorkspaceConfig
        }

        # Convert to array if it's not already
        if ($content -is [array])
        {
            return , $content
        }
        else
        {
            return @($content)
        }
    }
    catch
    {
        Write-Error "Failed to parse workspace configuration from $path : $_"
        return New-WorkspaceConfig
    }
}

<#
.SYNOPSIS
    Saves a workspace configuration to file.

.DESCRIPTION
    Writes a workspace configuration array to a JSON file.

.PARAMETER Workspace
    The workspace number (1-9).

.PARAMETER Routes
    The routes array to save.

.EXAMPLE
    Save-WorkspaceConfiguration -Workspace 1 -Routes $routes
#>
function Save-WorkspaceConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, 9)]
        [int]$Workspace,

        [Parameter(Mandatory, Position = 1)]
        [array]$Routes
    )

    $path = Get-WorkspaceConfigPath -Workspace $Workspace

    try
    {
        $Routes | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
        Write-Verbose "Saved workspace configuration to $path"
    }
    catch
    {
        Write-Error "Failed to save workspace configuration to $path : $_"
    }
}

<#
.SYNOPSIS
    Loads the filters configuration from file.

.DESCRIPTION
    Reads and parses the filters JSON file. Creates a new empty configuration if the file doesn't exist.

.EXAMPLE
    Get-FiltersConfiguration
#>
function Get-FiltersConfiguration
{
    [CmdletBinding()]
    [OutputType([array])]
    param()

    $path = Get-FiltersConfigPath

    if (-not (Test-Path $path))
    {
        Write-Verbose "Filters configuration file not found at $path. Creating new empty configuration."
        return New-WorkspaceConfig
    }

    try
    {
        $content = Get-Content $path -Raw | ConvertFrom-Json

        # Handle null or empty content
        if ($null -eq $content)
        {
            return New-WorkspaceConfig
        }

        # Convert to array if it's not already
        if ($content -is [array])
        {
            return , $content
        }
        else
        {
            return @($content)
        }
    }
    catch
    {
        Write-Error "Failed to parse filters configuration from $path : $_"
        return New-WorkspaceConfig
    }
}

<#
.SYNOPSIS
    Saves the filters configuration to file.

.DESCRIPTION
    Writes a filters configuration array to a JSON file.

.PARAMETER Filters
    The filters array to save.

.EXAMPLE
    Save-FiltersConfiguration -Filters $filters
#>
function Save-FiltersConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [array]$Filters
    )

    $path = Get-FiltersConfigPath

    try
    {
        $Filters | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
        Write-Verbose "Saved filters configuration to $path"
    }
    catch
    {
        Write-Error "Failed to save filters configuration to $path : $_"
    }
}

<#
.SYNOPSIS
    Validates that an application name doesn't contain .exe suffix.

.DESCRIPTION
    Ensures application names are cross-platform compatible by rejecting .exe suffixes.

.PARAMETER AppName
    The application name to validate.

.EXAMPLE
    Test-ApplicationNameValid -AppName 'firefox'
    Returns $true

.EXAMPLE
    Test-ApplicationNameValid -AppName 'firefox.exe'
    Returns $false and writes an error
#>
function Test-ApplicationNameValid
{
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$AppName
    )

    if ($AppName -match '\.exe$')
    {
        Write-Error "Application name '$AppName' should not contain .exe suffix. Whim will add it automatically."
        return $false
    }

    return $true
}
