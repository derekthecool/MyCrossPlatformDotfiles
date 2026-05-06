function Invoke-FlutterBuild
{
    <#
    .SYNOPSIS
    Runs Flutter build/run commands with flavor discovery and selection

    .DESCRIPTION
    Provides enhanced Flutter build functionality with automatic flavor discovery,
    target file detection, and simplified command execution.

    .PARAMETER Flavor
    The build flavor to use (e.g., 'development', 'staging', 'production')
    Automatically discovers available flavors if not specified.

    .PARAMETER Target
    The target entry-point file (defaults to lib/main.dart or flavor-specific)

    .PARAMETER Command
    Flutter command to run (default: 'run', alternatives: 'build', 'test', 'assemble')

    .PARAMETER ProjectRoot
    Path to Flutter project root (default: current directory)

    .PARAMETER ListFlavors
    List available flavors without running build

    .EXAMPLE
    Invoke-FlutterBuild -Flavor development

    .EXAMPLE
    Invoke-FlutterBuild -Flavor production -Command build

    .EXAMPLE
    Invoke-FlutterBuild -ListFlavors
    #>

    param (
        [Parameter()]
        [string]$Flavor,

        [Parameter()]
        [string]$Target,

        [Parameter()]
        [ValidateSet('run', 'build', 'test', 'assemble')]
        [string]$Command = 'run',

        [Parameter()]
        [string]$ProjectRoot = (Get-Location).Path,

        [Parameter()]
        [switch]$ListFlavors
    )

    # Error handling for flutter command
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue))
    {
        throw 'Flutter command not found. Please install Flutter SDK.'
    }

    # Detect if we're in a Flutter project
    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    if (-not (Test-Path $pubspecPath))
    {
        throw "Not a Flutter project. Missing pubspec.yaml at $ProjectRoot"
    }

    # Flavor discovery logic
    $flavors = Get-FlutterFlavors -ProjectRoot $ProjectRoot

    if ($ListFlavors)
    {
        return $flavors
    }

    # Auto-select flavor if not specified
    if ([string]::IsNullOrEmpty($Flavor))
    {
        if ($flavors.Count -eq 0)
        {
            Write-Verbose 'No flavors found, building default'
        }
        elseif ($flavors.Count -eq 1)
        {
            $Flavor = $flavors[0]
            Write-Verbose "Auto-selected flavor: $Flavor"
        }
        else
        {
            Write-Host 'Available flavors:'
            $flavors | ForEach-Object { Write-Host "  - $_" }
            throw 'Please specify a flavor using -Flavor parameter'
        }
    }

    # Auto-detect target file
    if ([string]::IsNullOrEmpty($Target))
    {
        $Target = Get-FlutterTargetFile -ProjectRoot $ProjectRoot -Flavor $Flavor
    }

    # Build flutter command arguments
    $arguments = @($Command)

    if (-not [string]::IsNullOrEmpty($Flavor))
    {
        $arguments += "--flavor", $Flavor
    }

    if (-not [string]::IsNullOrEmpty($Target))
    {
        $arguments += "--target", $Target
    }

    # Execute flutter command
    Write-Host "Running: flutter $($arguments -join ' ')" -ForegroundColor Green
    & flutter $arguments
}

function Get-FlutterFlavors
{
    param (
        [Parameter()]
        [string]$ProjectRoot
    )

    $flavors = [System.Collections.Generic.List[string]]::new()

    # Method 1: Check Android build.gradle for productFlavors
    $buildGradlePath = Join-Path $ProjectRoot 'android/app/build.gradle'
    if (Test-Path $buildGradlePath)
    {
        $buildGradleContent = Get-Content $buildGradlePath -Raw -ErrorAction SilentlyContinue
        if ($buildGradleContent -match 'productFlavors\s*\{([^}]+)\}')
        {
            $flavorBlock = $Matches[1]
            $flavorMatches = [regex]::Matches($flavorBlock, '(\w+)\s*\{')
            foreach ($match in $flavorMatches)
            {
                $flavorName = $match.Groups[1].Value
                if (-not $flavors.Contains($flavorName))
                {
                    $flavors.Add($flavorName) | Out-Null
                }
            }
        }
    }

    # Method 2: Check pubspec.yaml for flutter.flavor configuration
    $pubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
    if (Test-Path $pubspecPath)
    {
        $pubspecContent = Get-Content $pubspecPath -Raw -ErrorAction SilentlyContinue
        if ($pubspecContent -match 'default-flavor:\s*(\w+)')
        {
            $defaultFlavor = $Matches[1]
            if (-not $flavors.Contains($defaultFlavor))
            {
                $flavors.Add($defaultFlavor) | Out-Null
            }
        }
    }

    # Method 3: Check for flavor-specific main files
    $libPath = Join-Path $ProjectRoot 'lib'
    if (Test-Path $libPath)
    {
        $mainFiles = Get-ChildItem $libPath -Filter 'main_*.dart' -ErrorAction SilentlyContinue
        foreach ($file in $mainFiles)
        {
            if ($file.Name -match 'main_(\w+)\.dart')
            {
                $flavorFromName = $Matches[1]
                if (-not $flavors.Contains($flavorFromName))
                {
                    $flavors.Add($flavorFromName) | Out-Null
                }
            }
        }
    }

    return $flavors.ToArray()
}

function Get-FlutterTargetFile
{
    param (
        [Parameter()]
        [string]$ProjectRoot,

        [Parameter()]
        [string]$Flavor
    )

    # If flavor specified, look for flavor-specific main file
    if (-not [string]::IsNullOrEmpty($Flavor))
    {
        $flavorTarget = "lib/main_$Flavor.dart"
        $flavorTargetPath = Join-Path $ProjectRoot $flavorTarget
        if (Test-Path $flavorTargetPath)
        {
            return $flavorTarget
        }
    }

    # Default to lib/main.dart
    $defaultTarget = "lib/main.dart"
    $defaultTargetPath = Join-Path $ProjectRoot $defaultTarget
    if (Test-Path $defaultTargetPath)
    {
        return $defaultTarget
    }

    # Fallback: search for any main.dart in lib
    $libPath = Join-Path $ProjectRoot 'lib'
    if (Test-Path $libPath)
    {
        $mainFiles = Get-ChildItem $libPath -Filter 'main*.dart' -ErrorAction SilentlyContinue
        if ($mainFiles.Count -gt 0)
        {
            return "lib/$($mainFiles[0].Name)"
        }
    }

    return $null
}
