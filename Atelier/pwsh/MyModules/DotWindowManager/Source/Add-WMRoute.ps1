<#
.SYNOPSIS
    Adds application routes to a workspace.

.DESCRIPTION
    Adds one or more application routes to a workspace configuration file.
    Supports pipeline input for batch operations.

.PARAMETER Workspace
    The workspace number (1-9) to add routes to.

.PARAMETER Applications
    The application(s) to add. Can be strings, hashtables, or PSCustomObjects.

.PARAMETER Type
    The type of application identifier (process, class, title, instance, role).
    Default is 'process'.

.EXAMPLE
    'firefox', 'brave' | Add-WMRoute -Workspace 2
    Adds firefox and brave to workspace 2

.EXAMPLE
    @{Name='Obsidian'; Type='class'} | Add-WMRoute -Workspace 5
    Adds Obsidian as a class type to workspace 5

.EXAMPLE
    Add-WMRoute -Workspace 4 -Applications 'pythonw' -Type 'process'
    Adds pythonw as process type to workspace 4

.EXAMPLE
    @(
        @{Name='Alacritty'; Type='class'},
        @{Name='Wezterm'; Type='class'}
    ) | Add-WMRoute -Workspace 1
    Adds multiple applications with explicit types to workspace 1
#>
function Add-WMRoute
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(1, 9)]
        [int]$Workspace,

        [Parameter(Mandatory, ValueFromPipeline, Position = 1)]
        [object[]]$Applications,

        [Parameter(Position = 2)]
        [ValidateSet('process', 'class', 'title', 'instance', 'role')]
        [string]$Type = 'process'
    )

    begin
    {
        # Load existing configuration
        $existingRoutes = Get-WorkspaceConfiguration -Workspace $Workspace
        $newRoutes = [System.Collections.ArrayList]::new()
        $duplicateCount = 0
    }

    process
    {
        foreach ($app in $Applications)
        {
            # Convert to route object
            $route = ConvertTo-RouteObject -InputObject $app -DefaultType $Type

            if ($null -eq $route)
            {
                continue
            }

            # Validate application name
            if (-not (Test-ApplicationNameValid -AppName $route.app))
            {
                continue
            }

            # Check for duplicates
            if (Test-DuplicateRoute -Routes $existingRoutes -Route $route)
            {
                Write-Warning "Duplicate route detected: $($route.app) (type: $($route.type)) in workspace $Workspace"
                $duplicateCount++
                continue
            }

            # Also check against new routes in this batch
            if (Test-DuplicateRoute -Routes $newRoutes -Route $route)
            {
                Write-Warning "Duplicate route in batch: $($route.app) (type: $($route.type))"
                $duplicateCount++
                continue
            }

            # Add to new routes
            $newRoutes.Add($route)
            Write-Verbose "Adding route: $($route.app) (type: $($route.type)) to workspace $Workspace"
        }
    }

    end
    {
        # If no new routes to add, return
        if ($newRoutes.Count -eq 0)
        {
            Write-Verbose "No new routes to add to workspace $Workspace"
            return
        }

        # Merge with existing routes
        $allRoutes = [System.Collections.ArrayList]::new()

        # Add existing routes if any
        if ($null -ne $existingRoutes -and $existingRoutes.Count -gt 0)
        {
            foreach ($route in $existingRoutes)
            {
                $allRoutes.Add($route) | Out-Null
            }
        }

        # Add new routes
        foreach ($route in $newRoutes)
        {
            $allRoutes.Add($route) | Out-Null
        }

        # Save configuration
        if ($PSCmdlet.ShouldProcess("Workspace $Workspace", "Add $($newRoutes.Count) route(s)"))
        {
            Save-WorkspaceConfiguration -Workspace $Workspace -Routes $allRoutes.ToArray()

            # Output summary
            Write-Host "Added $($newRoutes.Count) route(s) to workspace $Workspace"
            if ($duplicateCount -gt 0)
            {
                Write-Host "Skipped $duplicateCount duplicate route(s)" -ForegroundColor Yellow
            }
        }
    }
}
