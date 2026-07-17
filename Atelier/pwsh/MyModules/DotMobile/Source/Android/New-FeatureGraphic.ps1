function New-FeatureGraphic
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$ScreenshotPath,

        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter()]
        [string]$Subtitle,

        [Parameter()]
        [ValidateSet('vertical', 'horizontal')]
        [string]$GradientDirection = 'vertical',

        [Parameter()]
        [string[]]$GradientColors,

        [Parameter()]
        [string]$BackgroundColor = '#1a1a2e',

        [Parameter()]
        [string]$TitleColor = '#ffffff',

        [Parameter()]
        [string]$SubtitleColor = '#cccccc',

        [Parameter()]
        [int]$TitlePointSize = 60,

        [Parameter()]
        [int]$SubtitlePointSize = 24,

        [Parameter()]
        [string]$Font,

        [Parameter()]
        [string]$OutputPath = (Join-Path (Get-Location) 'feature-graphic.png')
    )

    if (-not (Get-Command magick -ErrorAction SilentlyContinue))
    {
        throw 'magick (ImageMagick v7) not found on PATH. Install ImageMagick.'
    }

    if (-not (Test-Path $ScreenshotPath))
    {
        throw "Screenshot not found: $ScreenshotPath"
    }

    if (-not $PSCmdlet.ShouldProcess($OutputPath, "Compose 1024x500 Play Store feature graphic"))
    {
        return
    }

    $outDir = Split-Path $OutputPath -Parent
    if ($outDir -and -not (Test-Path $outDir))
    {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $tmpBase = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-feature-$([guid]::NewGuid())"
    $tmpCanvas = "$tmpBase-canvas.png"
    $tmpShotResized = "$tmpBase-shot-256.png"
    $tmpWithShot = "$tmpBase-shot.png"
    $tmpWithText = "$tmpBase-text.png"

    try
    {
        # Step 1: canvas with background — gradient if GradientColors set, else solid.
        if ($GradientColors -and $GradientColors.Count -ge 2)
        {
            # ImageMagick gradient angle: 90 = top-to-bottom (vertical), 270 = left-to-right (horizontal).
            $angle = if ($GradientDirection -eq 'horizontal') { 270 } else { 90 }
            $canvasArgs = @(
                '-size', '1024x500',
                '-define', "gradient:angle=$angle",
                "gradient:$($GradientColors[0])-$($GradientColors[1])",
                $tmpCanvas
            )
        } else
        {
            $canvasArgs = @(
                '-size', '1024x500',
                "xc:$BackgroundColor",
                $tmpCanvas
            )
        }
        & magick @canvasArgs *> $null
        if ($LASTEXITCODE -ne 0) { throw "Canvas creation failed (exit $LASTEXITCODE)." }

        # Step 2a: resize the screenshot to 1/4 of canvas width (256px), preserving aspect.
        # Split into its own step because inline `-resize 256x` between two images in a
        # single magick call ends up scaling the whole composite in IM7 — see step 2b.
        $resizeArgs = @(
            $ScreenshotPath, '-resize', '256x',
            $tmpShotResized
        )
        & magick @resizeArgs *> $null
        if ($LASTEXITCODE -ne 0) { throw "Screenshot resize failed (exit $LASTEXITCODE)." }

        # Step 2b: composite the resized screenshot onto the canvas, centered in the
        # right 1/3 column. -gravity east right-aligns AND vertically centers;
        # -geometry +43+0 keeps the right edge 43px from canvas edge so the shot
        # sits in the right 1/3 (centered around x=853).
        $compArgs = @(
            $tmpCanvas,
            $tmpShotResized,
            '-gravity', 'east', '-geometry', '+43+0',
            '-compose', 'over', '-composite',
            $tmpWithShot
        )
        & magick @compArgs *> $null
        if ($LASTEXITCODE -ne 0) { throw "Screenshot composite failed (exit $LASTEXITCODE)." }

        # Step 3: render title (and subtitle if provided) at the configured positions.
        $textArgs = @($tmpWithShot)
        if ($Font) { $textArgs += @('-font', $Font) }
        $textArgs += @(
            '-pointsize', $TitlePointSize,
            '-fill', $TitleColor,
            '-gravity', 'northwest', '-annotate', '+82+180', $Title
        )
        if ($Subtitle)
        {
            $textArgs += @(
                '-pointsize', $SubtitlePointSize,
                '-fill', $SubtitleColor,
                '-gravity', 'northwest', '-annotate', '+82+260', $Subtitle
            )
        }
        $textArgs += $tmpWithText
        & magick @textArgs *> $null
        if ($LASTEXITCODE -ne 0) { throw "Text render failed (exit $LASTEXITCODE)." }

        # Step 4: flatten alpha onto background and write 24-bit PNG (no alpha
        # per Play Store spec). png:color-type=2 = truecolor RGB, no alpha.
        $flattenArgs = @(
            $tmpWithText,
            '-background', $BackgroundColor, '-alpha', 'remove', '-alpha', 'off',
            '-define', 'png:color-type=2',
            $OutputPath
        )
        & magick @flattenArgs *> $null
        if ($LASTEXITCODE -ne 0) { throw "Flatten/save failed (exit $LASTEXITCODE)." }
    } finally
    {
        Remove-Item $tmpCanvas, $tmpShotResized, $tmpWithShot, $tmpWithText -Force -ErrorAction SilentlyContinue
    }

    return (Get-Item $OutputPath)
}
