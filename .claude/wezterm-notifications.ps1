# Claude Code hook -> WezTerm bridge (PowerShell 7+, works on Windows and WSL)
#
# Hooks run without a controlling terminal, so this script cannot write escape sequences itself.
# Instead it prints {"terminalSequence": "..."} and Claude Code writes the sequence to the real terminal.
# Claude Code only accepts OSC 0/1/2/9/99/777 and BEL there. OSC 1337 (SetUserVar) is not allowed.
#
# Emits for "needs attention" events:
#   - OSC 777 notify  -> WezTerm toast notification
#   - BEL             -> WezTerm `bell` event (the Lua side highlights the tab)
#
# Hook wiring (settings.json): Notification and Stop -> pwsh -NoProfile -File ~/.claude/wezterm-notifications.ps1
#
# Manual test, run inside a WezTerm pane (writes the sequence straight to the terminal):
#   ./wezterm-notifications.ps1 -Direct -TestEvent Stop
#   ./wezterm-notifications.ps1 -Direct -TestEvent permission_prompt

[CmdletBinding()]
param(
    # Write the escape sequence directly to the terminal instead of emitting hook JSON
    [switch]$Direct,

    # Simulate an event without stdin: Stop or any Notification notification_type
    [string]$TestEvent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$esc = [char]27
$bel = [char]7

# Strip control characters (incl. ESC, so message text cannot inject sequences) and ';' (OSC 777 field separator)
function Get-SafeText
{
    param([string]$Text, [int]$MaxLength = 80)

    if (-not $Text) { return '' }
    $clean = ($Text -replace '[\x00-\x1F\x7F;]', ' ').Trim()
    if ($clean.Length -gt $MaxLength) { $clean = $clean.Substring(0, $MaxLength - 1) + '…' }
    return $clean
}

# Build the event object either from stdin (real hook) or from -TestEvent
$data = $null
if ($TestEvent)
{
    $data = if ($TestEvent -eq 'Stop')
    {
        [pscustomobject]@{ hook_event_name = 'Stop'; cwd = (Get-Location).Path; stop_hook_active = $false }
    } else
    {
        [pscustomobject]@{ hook_event_name = 'Notification'; notification_type = $TestEvent; cwd = (Get-Location).Path }
    }
} else
{
    # Real hooks pipe JSON in. Reading an interactive terminal would block forever (and ignore Ctrl+C)
    if (-not [Console]::IsInputRedirected)
    {
        Write-Host 'Usage: pipe hook JSON on stdin, or use -TestEvent Stop|permission_prompt|idle_prompt [-Direct]'
        return
    }
    $raw = [Console]::In.ReadToEnd()
    if (-not $raw) { return }
    try { $data = $raw | ConvertFrom-Json } catch { return }
}

function Get-Prop
{
    param($Object, [string]$Name)
    if ($Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $null
}

$eventName = Get-Prop $data 'hook_event_name'
$cwd = Get-Prop $data 'cwd'
$folder = if ($cwd) { Split-Path ([string]$cwd) -Leaf } else { '' }

$body = $null
# The only channel into WezTerm's Lua is the number of BELs: 1 = needs input (red tab), 2 = finished (green tab)
$bells = 1
switch ($eventName)
{
    'Stop'
    {
        # A stop hook re-firing after a blocked stop is not a real finish
        if (Get-Prop $data 'stop_hook_active') { return }
        $body = 'Finished'
        $bells = 2
    }
    'Notification'
    {
        switch (Get-Prop $data 'notification_type')
        {
            'permission_prompt' { $body = 'Needs permission' }
            'elicitation_dialog' { $body = 'Has a question for you' }
            'agent_needs_input' { $body = 'Needs your input' }
            'idle_prompt' { $body = 'Waiting for you' }
            default { return } # auth_success, quota_* etc. are not worth interrupting for
        }
    }
    default { return }
}

$title = Get-SafeText ("Claude Code" + $(if ($folder) { " - $folder" } else { '' })) 60
$sequence = "$esc]777;notify;$title;$(Get-SafeText $body)$bel$($bel.ToString() * $bells)"

if ($Direct)
{
    [Console]::Out.Write($sequence)
    return
}

@{ terminalSequence = $sequence } | ConvertTo-Json -Compress
