<#
.SYNOPSIS
    Adds application filters to the filters configuration.

.DESCRIPTION
    Adds one or more application filters to the filters configuration file.
    Filters are applications that should not be tiled by the window manager.
    Supports pipeline input for batch operations.

.PARAMETER Application
    The application(s) to add as filters. Can be strings, hashtables, or PSCustomObjects.

.PARAMETER Type
    The type of application identifier (process, class, title, instance, role).
    Default is 'process'.

.EXAMPLE
    'pinentry', 'copyq' | Add-WMFilter
    Adds pinentry and copyq as filters

.EXAMPLE
    @{Name='.*Teams.*'; Type='title'} | Add-WMFilter
    Adds a regex filter for Teams windows

.EXAMPLE
    Add-WMFilter -Application 'arandr' -Type 'class'
    Adds arandr as a class-type filter

.EXAMPLE
    @(
        @{Name='Alacritty'; Type='class'},
        @{Name='Wezterm'; Type='class'}
    ) | Add-WMFilter
    Adds multiple filters with explicit types
#>
function Add-WMFilter
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [object[]]$Application,

        [Parameter(Position = 1)]
        [ValidateSet('process', 'class', 'title', 'instance', 'role')]
        [string]$Type = 'process'
    )

    begin
    {
        # Load existing configuration
        $existingFilters = Get-FiltersConfiguration
        $newFilters = [System.Collections.ArrayList]::new()
        $duplicateCount = 0
    }

    process
    {
        foreach ($app in $Application)
        {
            # Convert to route object
            $filter = ConvertTo-RouteObject -InputObject $app -DefaultType $Type

            if ($null -eq $filter)
            {
                continue
            }

            # Validate application name
            if (-not (Test-ApplicationNameValid -AppName $filter.app))
            {
                continue
            }

            # Check for duplicates
            if (Test-DuplicateRoute -Routes $existingFilters -Route $filter)
            {
                Write-Warning "Duplicate filter detected: $($filter.app) (type: $($filter.type))"
                $duplicateCount++
                continue
            }

            # Also check against new filters in this batch
            if (Test-DuplicateRoute -Routes $newFilters -Route $filter)
            {
                Write-Warning "Duplicate filter in batch: $($filter.app) (type: $($filter.type))"
                $duplicateCount++
                continue
            }

            # Add to new filters
            $newFilters.Add($filter)
            Write-Verbose "Adding filter: $($filter.app) (type: $($filter.type))"
        }
    }

    end
    {
        # If no new filters to add, return
        if ($newFilters.Count -eq 0)
        {
            Write-Verbose "No new filters to add"
            return
        }

        # Merge with existing filters
        $allFilters = [System.Collections.ArrayList]::new()

        # Add existing filters if any
        if ($null -ne $existingFilters -and $existingFilters.Count -gt 0)
        {
            foreach ($filter in $existingFilters)
            {
                $allFilters.Add($filter) | Out-Null
            }
        }

        # Add new filters
        foreach ($filter in $newFilters)
        {
            $allFilters.Add($filter) | Out-Null
        }

        # Save configuration
        if ($PSCmdlet.ShouldProcess("Filters configuration", "Add $($newFilters.Count) filter(s)"))
        {
            Save-FiltersConfiguration -Filters $allFilters.ToArray()

            # Output summary
            Write-Host "Added $($newFilters.Count) filter(s)"
            if ($duplicateCount -gt 0)
            {
                Write-Host "Skipped $duplicateCount duplicate filter(s)" -ForegroundColor Yellow
            }
        }
    }
}
