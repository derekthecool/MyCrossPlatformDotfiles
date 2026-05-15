<#
.SYNOPSIS
    Gets window manager configuration.

.DESCRIPTION
    Retrieves window manager configuration from workspace and filter JSON files.
    Can return all workspaces, specific workspaces, filters only, or raw JSON objects.

.PARAMETER Workspace
    The workspace number(s) to retrieve (1-9). If not specified, returns all workspaces.

.PARAMETER Filters
    If specified, returns filters configuration instead of workspaces.

.PARAMETER Raw
    If specified, returns raw JSON objects instead of formatted output.

.EXAMPLE
    Get-WM
    Returns all workspaces with formatted output

.EXAMPLE
    Get-WM -Workspace 1,2,3
    Returns workspaces 1, 2, and 3

.EXAMPLE
    Get-WM -Filters
    Returns filters configuration

.EXAMPLE
    Get-WM -Workspace 1 -Raw
    Returns raw JSON for workspace 1
#>
function Get-WM
{
    [CmdletBinding(DefaultParameterSetName = 'Workspace')]
    param(
        [Parameter(ParameterSetName = 'Workspace', Position = 0)]
        [ValidateRange(1, 9)]
        [int[]]$Workspace,

        [Parameter(ParameterSetName = 'Filters', Mandatory = $false)]
        [switch]$Filters,

        [Parameter(ParameterSetName = 'Workspace')]
        [Parameter(ParameterSetName = 'Filters')]
        [switch]$Raw
    )

    # Return filters if requested
    if ($Filters)
    {
        $filtersData = Get-FiltersConfiguration

        if ($Raw)
        {
            return $filtersData
        }

        $output = foreach ($filter in $filtersData)
        {
            [PSCustomObject]@{
                App  = $filter.app
                Type = $filter.type
            }
        }

        return $output
    }

    # Determine which workspaces to retrieve
    if ($PSBoundParameters.ContainsKey('Workspace'))
    {
        $workspaces = $Workspace
    } else
    {
        $workspaces = 1..9
    }

    # Retrieve workspaces
    $results = @()

    foreach ($ws in $workspaces)
    {
        $routes = Get-WorkspaceConfiguration -Workspace $ws

        if ($Raw)
        {
            $results += [PSCustomObject]@{
                Workspace = $ws
                Routes    = $routes
            }
        } else
        {
            foreach ($route in $routes)
            {
                $results += [PSCustomObject]@{
                    Workspace = $ws
                    App       = $route.app
                    Type      = $route.type
                }
            }
        }
    }

    return $results
}
