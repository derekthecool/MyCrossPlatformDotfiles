function Show-ChristmasTree
{
    [Alias('sct')]
    param (
        [Parameter()]
        [string]$AnimationDelayMilliseconds = 190,
        [string]$TreeBaseChar = '^'

    )

    # Helper function: safely crop lines with markup
    function CropMarkupLine
    {
        param($line, $maxWidth)

        $plainLength = ($line -replace '\[.*?\]', '').Length
        if ($plainLength -le $maxWidth) { return $line }

        $cropped = ""
        $count = 0
        $regex = [regex]'\[.*?\]|.'
        foreach ($match in $regex.Matches($line))
        {
            $text = $match.Value
            if ($text -match '^\[.*\]$')
            {
                # Keep markup tags intact
                $cropped += $text
            } else
            {
                if ($count -ge $maxWidth) { break }
                $cropped += $text
                $count++
            }
        }
        return $cropped
    }

    [Console]::CursorVisible = $false

    try
    {
        $ornaments = @(
            "[red]●[/]",
            "[yellow]●[/]",
            "[blue]●[/]"
        )

        $lastHeight = -1
        $lastWidth = -1

        $panel = [Spectre.Console.Panel]::new("")
        $live = [Spectre.Console.AnsiConsole]::Live($panel)

        $live.Start({
                param ($ctx)

                while ($true)
                {

                    $winHeight = [Console]::WindowHeight
                    $winWidth = [Console]::WindowWidth

                    $resized = ($winHeight -ne $lastHeight -or $winWidth -ne $lastWidth)
                    if ($resized)
                    {
                        $lastHeight = $winHeight
                        $lastWidth = $winWidth
                    }

                    # Full-height tree
                    $height = [Math]::Max(8, $winHeight - 3)

                    $lines = @()

                    # Star
                    $starRow = "[yellow]★[/]"
                    $starPadding = " " * ([Math]::Floor(($winWidth - 1) / 2))
                    $lines += "$starPadding$starRow"

                    # Tree body
                    for ($i = 1; $i -le $height; $i++)
                    {
                        $treeWidth = 2 * $i - 1
                        $row = ""
                        for ($j = 1; $j -le $treeWidth; $j++)
                        {
                            if ((Get-Random -Max 6) -eq 0)
                            {
                                $row += ($ornaments | Get-Random)
                            } else
                            {
                                $row += "[green]$TreeBaseChar[/]"
                            }
                        }

                        # Center row horizontally
                        $paddingSize = [Math]::Floor(($winWidth - $treeWidth) / 2)
                        $paddingSize = [Math]::Max(0, $paddingSize)
                        $row = (" " * $paddingSize) + $row

                        # Clip safely
                        $maxWidth = $winWidth - $paddingSize
                        $row = CropMarkupLine $row $maxWidth

                        $lines += $row
                    }

                    # Trunk (2 rows) centered
                    $trunk = "[red]|||[/]"
                    $trunkPadding = [Math]::Floor(($winWidth - 3) / 2)
                    $lines += (" " * $trunkPadding) + $trunk
                    $lines += (" " * $trunkPadding) + $trunk

                    # Build panel with NO border
                    $panel = [Spectre.Console.Panel]::new($lines -join "`n")
                    $panel.Border = [Spectre.Console.BoxBorder]::None
                    $panel.Padding = [Spectre.Console.Padding]::new(0, 0, 0, 0)

                    $ctx.UpdateTarget($panel)

                    # Quit on Q
                    if ([Console]::KeyAvailable -and
                        [Console]::ReadKey($true).Key -eq 'Q')
                    {
                        break
                    }

                    Start-Sleep -Milliseconds $AnimationDelayMilliseconds
                }
            })
    } finally
    {
        [Console]::CursorVisible = $true
    }
}
