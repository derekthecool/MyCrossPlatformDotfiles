using module PwshSpectreConsole
using namespace Spectre.Console

function Show-ChristmasTree
{
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

                    # --- Detect resize ---
                    $winHeight = [Console]::WindowHeight
                    $winWidth = [Console]::WindowWidth

                    $resized = ($winHeight -ne $lastHeight -or $winWidth -ne $lastWidth)
                    if ($resized)
                    {
                        $lastHeight = $winHeight
                        $lastWidth = $winWidth
                    }

                    # --- Use full available height ---
                    $height = [Math]::Max(
                        6,
                        $winHeight - 6
                    )

                    $lines = @()

                    # Star
                    $lines += (" " * ($height - 1)) + "[yellow]★[/]"

                    # Tree
                    for ($i = 1; $i -le $height; $i++)
                    {
                        $spaces = " " * ($height - $i)
                        $row = ""

                        for ($j = 1; $j -le (2 * $i - 1); $j++)
                        {
                            if ((Get-Random -Max 6) -eq 0)
                            {
                                $row += ($ornaments | Get-Random)
                            } else
                            {
                                $row += "[green]^[/]"
                            }
                        }

                        # Clip line to window width (prevents wrap glitches)
                        if ($row.Length -gt ($winWidth - $spaces.Length - 4))
                        {
                            $row = $row.Substring(0, [Math]::Max(0, $winWidth - $spaces.Length - 4))
                        }

                        $lines += "$spaces$row"
                    }

                    # Trunk
                    $lines += (" " * ($height - 2)) + "[red]|||[/]"
                    $lines += ""
                    $lines += "[yellow]Merry Christmas!  (Press Q to quit)[/]"

                    # --- Force re-layout on resize ---
                    if ($resized)
                    {
                        $panel = [Spectre.Console.Panel]::new($lines -join "`n")
                    } else
                    {
                        $panel = [Spectre.Console.Panel]::new($lines -join "`n")
                    }

                    $panel.Border = [Spectre.Console.BoxBorder]::Rounded
                    $panel.Padding = [Spectre.Console.Padding]::new(1, 0, 1, 0)
                    $panel.Header = [Spectre.Console.PanelHeader]::new(
                        "[green]🎄 Christmas Tree 🎄[/]",
                        [Spectre.Console.Justify]::Center
                    )

                    $ctx.UpdateTarget($panel)

                    # Exit on Q
                    if ([Console]::KeyAvailable -and
                        [Console]::ReadKey($true).Key -eq 'Q')
                    {
                        break
                    }

                    Start-Sleep -Milliseconds 100
                }
            })
    } finally
    {
        [Console]::CursorVisible = $true
    }
}

New-Alias -Name 'sct' -Value Show-ChristmasTree
