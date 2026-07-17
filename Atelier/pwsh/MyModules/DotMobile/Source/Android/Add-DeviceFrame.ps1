function Add-DeviceFrame
{
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(ValueFromPipeline, ParameterSetName = 'ByPipeline')]
        [System.IO.FileInfo]$InputObject,

        [Parameter()]
        [string]$Path = (Join-Path (Get-Location) 'screenshots' 'raw'),

        [Parameter()]
        [string]$DestinationPath = (Join-Path (Get-Location) 'screenshots' 'framed'),

        [Parameter()]
        [string]$FramePath = (Join-Path $PSScriptRoot '..' '..' 'Assets' 'Android' 'Pixel9ProXL' 'frame.png'),

        [Parameter()]
        [string]$MaskPath = (Join-Path $PSScriptRoot '..' '..' 'Assets' 'Android' 'Pixel9ProXL' 'mask.png'),

        [Parameter()][int]$ViewportX = 170,
        [Parameter()][int]$ViewportY = 140,
        [Parameter()][int]$ViewportW = 1344,
        [Parameter()][int]$ViewportH = 2991
    )

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByPipeline')
        {
            # Derive Name + Path from the piped FileInfo; default DestinationPath
            # to a sibling 'framed' dir next to the raw dir. Explicit
            # -DestinationPath overrides this derivation.
            $Name = [IO.Path]::GetFileNameWithoutExtension($InputObject.Name)
            $Path = $InputObject.DirectoryName
            if (-not $PSBoundParameters.ContainsKey('DestinationPath'))
            {
                $DestinationPath = Join-Path (Split-Path $Path -Parent) 'framed'
            }
        }

        if (-not (Get-Command magick -ErrorAction SilentlyContinue))
        {
            throw 'magick (ImageMagick v7) not found on PATH. Install ImageMagick.'
        }

        # Sanitize Name: drop .png suffix if present, strip path separators.
        $safeName = $Name
        if ($safeName.EndsWith('.png')) { $safeName = $safeName.Substring(0, $safeName.Length - 4) }
        $safeName = $safeName -replace '[/\\]', '_'

        $inputPath  = Join-Path $Path            "$safeName.png"
        $outputPath = Join-Path $DestinationPath "$safeName.png"

        if (-not (Test-Path $inputPath)) { throw "Input screenshot not found: $inputPath" }
        if (-not (Test-Path $FramePath)) { throw "Frame asset not found: $FramePath" }
        if (-not (Test-Path $MaskPath))  { throw "Mask asset not found: $MaskPath" }

        if (-not $PSCmdlet.ShouldProcess($inputPath, "Apply device frame -> $outputPath")) { return }

        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

        $tmpBase    = Join-Path ([IO.Path]::GetTempPath()) "DotMobile-frame-$safeName"
        $tmpMaskVp  = "$tmpBase-mask-vp.png"
        $tmpResized = "$tmpBase-resized.png"
        $tmpMasked  = "$tmpBase-masked.png"

        try
        {
            # Step 1: crop the frame-sized mask down to the viewport rect.
            $step1 = @(
                $MaskPath,
                '-crop', "${ViewportW}x${ViewportH}+${ViewportX}+${ViewportY}",
                '+repage',
                $tmpMaskVp
            )
            & magick @step1 *> $null
            if ($LASTEXITCODE -ne 0) { throw "Mask crop failed (exit $LASTEXITCODE)." }

            # Step 2: resize the raw screenshot to exactly viewport size (cover + center-crop).
            $step2 = @(
                $inputPath,
                '-resize', "${ViewportW}x${ViewportH}^",
                '-gravity', 'center',
                '-extent', "${ViewportW}x${ViewportH}",
                $tmpResized
            )
            & magick @step2 *> $null
            if ($LASTEXITCODE -ne 0) { throw "Resize failed (exit $LASTEXITCODE)." }

            # Step 3: apply the cropped mask as the alpha channel — rounds the
            # screenshot's corners to match the phone's screen shape.
            $step3 = @(
                $tmpResized,
                $tmpMaskVp,
                '-compose', 'copyopacity',
                '-composite',
                $tmpMasked
            )
            & magick @step3 *> $null
            if ($LASTEXITCODE -ne 0) { throw "Mask apply failed (exit $LASTEXITCODE)." }

            # Step 4: composite the masked screenshot onto the frame at the viewport offset.
            $step4 = @(
                $FramePath,
                $tmpMasked,
                '-gravity', 'northwest',
                '-geometry', "+${ViewportX}+${ViewportY}",
                '-compose', 'over',
                '-composite',
                $outputPath
            )
            & magick @step4 *> $null
            if ($LASTEXITCODE -ne 0) { throw "Composite failed (exit $LASTEXITCODE)." }
        }
        finally
        {
            Remove-Item $tmpMaskVp, $tmpResized, $tmpMasked -Force -ErrorAction SilentlyContinue
        }

        return (Get-Item $outputPath)
    }
}
