# This file is meant to make meaningful helpers of the Kokoro generated source
# without trying to over complicate the generator

function Start-KokoroPlayback
{
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [System.IO.FileInfo]$Path
    )
    if (Test-Path $Path)
    {
        if ($(Get-Command mpv -ErrorAction SilentlyContinue))
        {
            Write-Verbose "Playing '$Path' with mpv."
            mpv $Path
        } else
        {
            Write-Verbose "mpv was not found; handing '$Path' to the shell default."
            Start-Process $Path
        }
    } else
    {
        Write-Verbose "'$Path' does not exist; nothing to play."
    }
}

function Start-KokoroRead
{
    <#
    .SYNOPSIS
    Speak text aloud through Kokoro.

    .DESCRIPTION
    Reads the clipboard by default. Any text supplied by pipeline or parameter is
    collected and joined into a single request instead. Joining matters:
    New-KokoroSpeech has a process block, so piping a string[] straight into it
    fires one API call per element and any line without a word (blank lines, rule
    lines, box drawing) fails with HTTP 400.

    .PARAMETER FromClipboard
    Explicitly select the clipboard as the source. The clipboard is already the
    default, so this is only needed for readability at a call site.

    .PARAMETER OtherText
    Text to speak. Accepts a single string or a string[], by pipeline or by parameter.

    .PARAMETER Voice
    Voice name passed through to New-KokoroSpeech.

    .PARAMETER Speed
    Playback rate passed through to New-KokoroSpeech.

    .PARAMETER PassThru
    Emit the synthesized audio file after playing it.

    .EXAMPLE
    Start-KokoroRead

    .EXAMPLE
    'test test yo-yo' | Start-KokoroRead

    .EXAMPLE
    Get-Content ./review.md | Start-KokoroRead -Voice af_heart -Verbose
    #>
    [CmdletBinding(DefaultParameterSetName = 'Clipboard')]
    param (
        [Parameter(ParameterSetName = 'Clipboard')]
        [switch]$FromClipboard,

        [Parameter(ValueFromPipeline, Position = 0, ParameterSetName = 'Text')]
        [Alias('Text')]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$OtherText,

        [Parameter()]
        [string]$Voice,

        [Parameter()]
        [ValidateRange(0.25, 4)]
        [double]$Speed,

        [Parameter()]
        [switch]$PassThru
    )
    begin
    {
        $lines = [System.Collections.Generic.List[string]]::new()
        Write-Verbose "Parameter set '$($PSCmdlet.ParameterSetName)' selected."
    }
    process
    {
        foreach ($line in $OtherText)
        {
            $lines.Add($line)
        }
    }
    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'Clipboard')
        {
            if (-not (Get-Command Get-Clipboard -ErrorAction SilentlyContinue))
            {
                Write-Verbose 'Get-Clipboard was not found on this platform.'
                throw 'Get-Clipboard is not available on this platform; pipe the text in instead.'
            }

            # -Raw keeps the clipboard as one string. Without it Get-Clipboard emits
            # one array element per line, which is the per-line HTTP 400 trap.
            $text = Get-Clipboard -Raw
            Write-Verbose "Read $($text.Length) characters from the clipboard with -Raw."
        } else
        {
            $text = $lines -join [Environment]::NewLine
            Write-Verbose "Joined $($lines.Count) supplied line(s) into $($text.Length) characters for a single request."
        }

        if ($text -notmatch '\w')
        {
            Write-Verbose 'Input held no word characters, so no request was sent.'
            throw 'No speakable text was supplied.'
        }

        $speechArgs = @{ InputText = $text }
        foreach ($passThrough in 'Voice', 'Speed')
        {
            if ($PSBoundParameters.ContainsKey($passThrough))
            {
                $speechArgs[$passThrough] = $PSBoundParameters[$passThrough]
                Write-Verbose "Passing -$passThrough '$($PSBoundParameters[$passThrough])' through to New-KokoroSpeech."
            } else
            {
                Write-Verbose "No -$passThrough supplied; leaving the server default in place."
            }
        }

        Write-Verbose 'Requesting synthesis from New-KokoroSpeech.'
        $audio = New-KokoroSpeech @speechArgs
        Write-Verbose "Synthesized '$($audio.FullName)'."

        $audio | Start-KokoroPlayback

        if ($PassThru)
        {
            Write-Verbose 'Emitting the audio file because -PassThru was supplied.'
            $audio
        } else
        {
            Write-Verbose 'Discarding the audio file; supply -PassThru to receive it.'
        }
    }
}
