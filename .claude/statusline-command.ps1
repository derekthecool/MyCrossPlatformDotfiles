# Claude Code status line (PowerShell version)

$data = $input | ConvertFrom-Json

$cwd = if ($data.workspace.current_dir) { $data.workspace.current_dir } elseif ($data.cwd) { $data.cwd } else { '' }
$model = if ($data.model.display_name) { $data.model.display_name } else { '' }
$used = $data.context_window.used_percentage
$git_worktree = if ($data.workspace.git_worktree) { $data.workspace.git_worktree } else { '' }

# Show only the last path segment (folder name)
$short_cwd = if ($cwd) { Split-Path $cwd -Leaf } else { '' }

# Git branch and status
$git_info = ''
if ($cwd -and (git -C $cwd rev-parse --git-dir 2>$null)) {
    $branch = git -C $cwd --no-optional-locks symbolic-ref --short HEAD 2>$null
    if (-not $branch) {
        $branch = git -C $cwd --no-optional-locks rev-parse --short HEAD 2>$null
    }
    if ($branch) {
        $git_flags = ''
        git -C $cwd --no-optional-locks diff --quiet 2>$null
        if ($LASTEXITCODE -ne 0) { $git_flags += 'M' }
        git -C $cwd --no-optional-locks diff --cached --quiet 2>$null
        if ($LASTEXITCODE -ne 0) { $git_flags += '+' }
        $untracked = git -C $cwd --no-optional-locks ls-files --others --exclude-standard 2>$null
        if ($untracked) { $git_flags += '?' }

        if ($git_flags) {
            $git_info = " [$branch $git_flags]"
        } else {
            $git_info = " [$branch]"
        }
        if ($git_worktree) {
            $git_info += " {$git_worktree}"
        }
    }
}

# Context usage indicator
$ctx_info = ''
if ($null -ne $used -and "$used" -ne '') {
    $ctx_used = [math]::Round([double]$used)
    $ctx_info = " ctx:${ctx_used}%"
}

# Session cost
$cost_info = ''
$session_cost = $data.cost.total_cost_usd
if ($null -ne $session_cost -and "$session_cost" -ne '') {
    $cost_formatted = '$' + ([math]::Round([double]$session_cost, 2)).ToString('F2')
    $cost_info = " $cost_formatted"
}

# Model info
$model_info = ''
if ($model) {
    $model_info = " | $model"
}

Write-Host -NoNewline "${short_cwd}${git_info}${ctx_info}${cost_info}${model_info}"