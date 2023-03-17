local wezterm = require('wezterm')
local act = require('wezterm').action
local mux = wezterm.mux

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    if tab.is_active then
        return {
            { Background = { Color = '#000044' } },
            { Text = ' ' .. tab.active_pane.title .. ' ' },
        }
    end
    return tab.active_pane.title
end)

wezterm.on('update-right-status', function(window, pane)
    -- "Wed Mar 3 08:14"
    local date = wezterm.strftime('%A %b %-d %H:%M ')

    local bat = ''
    for _, b in ipairs(wezterm.battery_info()) do
        bat = '🔋 ' .. string.format('%.0f%%', b.state_of_charge * 100)
    end

    window:set_right_status(wezterm.format({
        { Text = bat .. '   ' .. date },
    }))
end)

-- Build my default set of sessions, tabs, etc.
wezterm.on('gui-startup', function(cmd)
    local args = {}
    if cmd then
        args = cmd.args
    end

    local workspaces = {
        'CommandStation',
        'Development',
    }

    -- Set a workspace for coding on a current project
    -- Top pane is for the editor, bottom pane is for the build tool
    local tab, build_pane, window = mux.spawn_window({
        workspace = workspaces[1],
        cwd = os.getenv('USERPROFILE') .. [[\.config\wezterm]],
        args = args,
    })

    -- Open neovim to wezterm config
    build_pane:send_text('nvim wezterm.lua\r\n')
    tab:set_title('Wezterm')

    -- Neovim tab
    local nvimTab, nvimPane, nvimWindow = window:spawn_tab({ cwd = os.getenv('LOCALAPPDATA') .. [[\nvim]] })
    nvimPane:send_text('nvim init.lua\r\n')
    nvimTab:set_title('Neovim')

    -- Plover
    local ploverTab, ploverPane, ploverWindow = window:spawn_tab({ cwd = os.getenv('LOCALAPPDATA') .. [[\plover]] })
    ploverPane:send_text('nvim plover/programming.md\r\n')
    ploverTab:set_title('Plover')

    -- Example of splitting the window
    -- local editor_pane = build_pane:split {
    --   direction = 'Top',
    --   size = 0.6,
    --   cwd = os.getenv('USERPROFILE') .. [[\.workspacer]],
    -- }

    -- A workspace for interacting with a local machine that
    -- runs some docker containners for home automation

    local tab, pane, window = mux.spawn_window({
        workspace = workspaces[2],
        cwd = os.getenv('USERPROFILE') .. [[\repos]],
        -- args = { 'ntop' },
    })

    local extraTab, extraPane, extraWindow =
        window:spawn_tab({ cwd = [[D:\Wallaby\wearable_post_BelleW_research\PPG_code\2023-01-24_ESP_IDF\i2c_simple\]] })

    mux.set_active_workspace(workspaces[1])
end)

local config = {}

config.font = wezterm.font('JetBrains Mono')
-- Enable ligatures
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- Use the same color scheme as neovim
config.color_scheme = 'Atelier Sulphurpool (base16)'

-- Set different default shell
-- config.default_prog = { 'pwsh' }
-- On windows you can set the default shell with this administrator command
-- [System.Environment]::SetEnvironmentVariable("COMSPEC", 'C:\Users\dlomax\scoop\apps\pwsh\current\pwsh.exe', 'User')

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

config.audible_bell = 'Disabled'
config.visual_bell = {
    fade_in_function = 'EaseIn',
    fade_in_duration_ms = 150,
    fade_out_function = 'EaseOut',
    fade_out_duration_ms = 150,
}
wezterm.on('bell', function(window, pane)
    -- TODO: change highlight of tab if not current like tmux
    wezterm.log_info('the bell was rung in pane ' .. pane:pane_id() .. '!')
end)

config.ssh_domains = {
    {
        -- The name of this specific domain.  Must be unique amongst
        -- all types of domain in the configuration file.
        name = 'device.MQTTBroker',

        -- identifies the host:port pair of the remote server
        -- Can be a DNS name or an IP address with an optional
        -- ":port" on the end.
        remote_address = '192.168.100.35',

        -- Whether agent auth should be disabled.
        -- Set to true to disable it.
        -- no_agent_auth = false,

        -- The username to use for authenticating with the remote host
        username = 'jgarner',

        -- Set to 'None' for ssh hosts that do not have wezterm available
        -- multiplexing = 'None',
        -- Only set the default_prog if using 'None'
        -- default_prog = { 'bash' },
        multiplexing = 'WezTerm',

        -- If true, connect to this domain automatically at startup
        -- connect_automatically = true,

        -- Specify an alternative read timeout
        -- timeout = 60,

        -- The path to the wezterm binary on the remote host.
        -- Primarily useful if it isn't installed in the $PATH
        -- that is configure for ssh.
        remote_wezterm_path = '~/WezTerm-20221119-145034-49b9839f-Ubuntu18.04.AppImage',
    },
}

-- Easy picks for steno keyboard
config.quick_select_alphabet = '1234567890'

-- Slightly translucent background
config.window_background_opacity = 0.92

config.colors = {
    visual_bell = '#202020',
    -- Colors for copy_mode and quick_select
    -- available since: 20220807-113146-c2fee766
    -- In copy_mode, the color of the active text is:
    -- 1. copy_mode_active_highlight_* if additional text was selected using the mouse
    -- 2. selection_* otherwise
    copy_mode_active_highlight_bg = { Color = '#000000' },
    -- use `AnsiColor` to specify one of the ansi color palette values
    -- (index 0-15) using one of the names "Black", "Maroon", "Green",
    --  "Olive", "Navy", "Purple", "Teal", "Silver", "Grey", "Red", "Lime",
    -- "Yellow", "Blue", "Fuchsia", "Aqua" or "White".
    copy_mode_active_highlight_bg = { Color = '#3b009f' },
    copy_mode_active_highlight_fg = { Color = '#ffffff' },
    copy_mode_inactive_highlight_bg = { Color = '#6e00d2' },
    copy_mode_inactive_highlight_fg = { Color = '#fa0046' },

    quick_select_label_bg = { Color = '#00ff00' },
    quick_select_label_fg = { Color = '#222222' },
    quick_select_match_bg = { Color = '#009600' },
    quick_select_match_fg = { Color = '#000000' },
}

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }
config.keys = {
    -- My keymaps
    -- When using steno, shift is not needed. It just seems to be implied because normal keyboard needs a shift
    { key = '|', mods = 'LEADER|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '-', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    -- -- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
    { key = 'a', mods = 'LEADER|CTRL', action = wezterm.action.SendString('\x01') },

    -- Launch specific programs
    {
        key = 't',
        mods = 'LEADER',
        action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain', args = { 'ntop' } }),
    },
    {
        key = 'v',
        mods = 'LEADER',
        action = wezterm.action.SpawnCommandInNewTab({ domain = 'CurrentPaneDomain', args = { 'ntop' } }),
    },
    {
        key = 'w',
        mods = 'LEADER',
        action = wezterm.action.SpawnCommandInNewTab({ domain = 'CurrentPaneDomain', args = { 'pwsh -c ls' } }),
    },

    -- { key = 'T', mods = 'CTRL', action = act.SpawnTab('CurrentPaneDomain') },

    -- { key = '|', mods = 'LEADER|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },

    --[[
    Command launcher
    https://wezfurlong.org/wezterm/config/lua/keyassignment/ShowLauncherArgs.html

    * "FUZZY" - activate in fuzzy-only mode. By default the launcher will allow
      using the number keys to select from the first few items, as well as vi
      movement keys to select items. Pressing / will enter fuzzy filtering mode,
      allowing you to type a search term and reduce the set of matches. When you
      use the "FUZZY" flag, the launcher activates directly in fuzzy filtering mode.
    * "TABS" - include the list of tabs from the current window
    * "LAUNCH_MENU_ITEMS" - include the launch_menu items
    * "DOMAINS" - include multiplexing domains
    * "KEY_ASSIGNMENTS" - include items taken from your key assignments
    * "WORKSPACES" - include workspaces
    * "COMMANDS" - include a number of default commands (Since: 20220408-101518-b908e2dd)
    ]]
    -- { key = '°', action = act.ShowLauncherArgs { flags = 'TABS|FUZZY' }, },
    { key = '°', action = act.ShowLauncher },

    { key = '»', action = act.ActivateTabRelative(1) },
    { key = '«', action = act.ActivateTabRelative(-1) },
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection('Left') },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection('Right') },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection('Down') },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection('Up') },
    -- NOTE: requires a nightly version as of 2023-03-16
    -- { key = 'P', mods = 'CTRL', action = act.ActivateCommandPalette },

    -- Default key maps
    { key = 'X', mods = 'CTRL', action = act.ActivateCopyMode },
    { key = 'X', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
    { key = 'x', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
    { key = 'DownArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection('Down') },
    { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection('Left') },
    { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection('Right') },
    { key = 'UpArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection('Up') },
    { key = '(', mods = 'CTRL', action = act.ActivateTab(-1) },
    { key = '(', mods = 'SHIFT|CTRL', action = act.ActivateTab(-1) },
    { key = '9', mods = 'SHIFT|CTRL', action = act.ActivateTab(-1) },
    { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },
    { key = '!', mods = 'SHIFT|CTRL', action = act.ActivateTab(0) },
    { key = '!', mods = 'CTRL', action = act.ActivateTab(0) },
    { key = '1', mods = 'SHIFT|CTRL', action = act.ActivateTab(0) },
    { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
    { key = '2', mods = 'SHIFT|CTRL', action = act.ActivateTab(1) },
    { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
    { key = '@', mods = 'CTRL', action = act.ActivateTab(1) },
    { key = '@', mods = 'SHIFT|CTRL', action = act.ActivateTab(1) },
    { key = '#', mods = 'CTRL', action = act.ActivateTab(2) },
    { key = '#', mods = 'SHIFT|CTRL', action = act.ActivateTab(2) },
    { key = '3', mods = 'SHIFT|CTRL', action = act.ActivateTab(2) },
    { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
    { key = '$', mods = 'CTRL', action = act.ActivateTab(3) },
    { key = '$', mods = 'SHIFT|CTRL', action = act.ActivateTab(3) },
    { key = '4', mods = 'SHIFT|CTRL', action = act.ActivateTab(3) },
    { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
    { key = '%', mods = 'CTRL', action = act.ActivateTab(4) },
    { key = '%', mods = 'SHIFT|CTRL', action = act.ActivateTab(4) },
    { key = '5', mods = 'SHIFT|CTRL', action = act.ActivateTab(4) },
    { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
    { key = '6', mods = 'SHIFT|CTRL', action = act.ActivateTab(5) },
    { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
    { key = '^', mods = 'CTRL', action = act.ActivateTab(5) },
    { key = '^', mods = 'SHIFT|CTRL', action = act.ActivateTab(5) },
    { key = '&', mods = 'CTRL', action = act.ActivateTab(6) },
    { key = '&', mods = 'SHIFT|CTRL', action = act.ActivateTab(6) },
    { key = '7', mods = 'SHIFT|CTRL', action = act.ActivateTab(6) },
    { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
    { key = '*', mods = 'CTRL', action = act.ActivateTab(7) },
    { key = '*', mods = 'SHIFT|CTRL', action = act.ActivateTab(7) },
    { key = '8', mods = 'SHIFT|CTRL', action = act.ActivateTab(7) },
    { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
    { key = '[', mods = 'SHIFT|SUPER', action = act.ActivateTabRelative(-1) },
    { key = '{', mods = 'SUPER', action = act.ActivateTabRelative(-1) },
    { key = '{', mods = 'SHIFT|SUPER', action = act.ActivateTabRelative(-1) },
    { key = 'PageUp', mods = 'CTRL', action = act.ActivateTabRelative(-1) },
    { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = ']', mods = 'SHIFT|SUPER', action = act.ActivateTabRelative(1) },
    { key = '}', mods = 'SUPER', action = act.ActivateTabRelative(1) },
    { key = '}', mods = 'SHIFT|SUPER', action = act.ActivateTabRelative(1) },
    { key = 'PageDown', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = 'DownArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'LeftArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'RightArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize({ 'Right', 1 }) },
    { key = 'UpArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize({ 'Up', 1 }) },
    {
        key = 'U',
        mods = 'CTRL',
        action = act.CharSelect({ copy_on_select = true, copy_to = 'ClipboardAndPrimarySelection' }),
    },
    {
        key = 'U',
        mods = 'SHIFT|CTRL',
        action = act.CharSelect({ copy_on_select = true, copy_to = 'ClipboardAndPrimarySelection' }),
    },
    {
        key = 'u',
        mods = 'SHIFT|CTRL',
        action = act.CharSelect({ copy_on_select = true, copy_to = 'ClipboardAndPrimarySelection' }),
    },
    { key = 'K', mods = 'CTRL', action = act.ClearScrollback('ScrollbackOnly') },
    { key = 'K', mods = 'SHIFT|CTRL', action = act.ClearScrollback('ScrollbackOnly') },
    { key = 'k', mods = 'SHIFT|CTRL', action = act.ClearScrollback('ScrollbackOnly') },
    { key = 'k', mods = 'SUPER', action = act.ClearScrollback('ScrollbackOnly') },
    { key = 'W', mods = 'CTRL', action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'W', mods = 'SHIFT|CTRL', action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'w', mods = 'SHIFT|CTRL', action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'C', mods = 'CTRL', action = act.CopyTo('Clipboard') },
    { key = 'C', mods = 'SHIFT|CTRL', action = act.CopyTo('Clipboard') },
    { key = 'c', mods = 'SHIFT|CTRL', action = act.CopyTo('Clipboard') },
    { key = 'c', mods = 'SUPER', action = act.CopyTo('Clipboard') },
    { key = 'Copy', mods = 'NONE', action = act.CopyTo('Clipboard') },
    { key = 'Insert', mods = 'CTRL', action = act.CopyTo('PrimarySelection') },
    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
    { key = '-', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
    { key = '_', mods = 'CTRL', action = act.DecreaseFontSize },
    { key = '_', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
    { key = 'M', mods = 'CTRL', action = act.Hide },
    { key = 'M', mods = 'SHIFT|CTRL', action = act.Hide },
    { key = 'm', mods = 'SHIFT|CTRL', action = act.Hide },
    { key = 'm', mods = 'SUPER', action = act.Hide },
    { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '+', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
    { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '=', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
    { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = 'PageUp', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(-1) },
    { key = 'PageDown', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(1) },
    -- { key = 'P', mods = 'CTRL', action = act.PaneSelect({ alphabet = '', mode = 'Activate' }) },
    { key = 'P', mods = 'SHIFT|CTRL', action = act.PaneSelect({ alphabet = '', mode = 'Activate' }) },
    { key = 'p', mods = 'SHIFT|CTRL', action = act.PaneSelect({ alphabet = '', mode = 'Activate' }) },
    { key = 'V', mods = 'CTRL', action = act.PasteFrom('Clipboard') },
    { key = 'V', mods = 'SHIFT|CTRL', action = act.PasteFrom('Clipboard') },
    { key = 'v', mods = 'SHIFT|CTRL', action = act.PasteFrom('Clipboard') },
    { key = 'v', mods = 'SUPER', action = act.PasteFrom('Clipboard') },
    { key = 'Paste', mods = 'NONE', action = act.PasteFrom('Clipboard') },
    { key = 'Insert', mods = 'SHIFT', action = act.PasteFrom('PrimarySelection') },
    { key = 'phys:Space', mods = 'SHIFT|CTRL', action = act.QuickSelect },
    { key = 'R', mods = 'CTRL', action = act.ReloadConfiguration },
    { key = 'R', mods = 'SHIFT|CTRL', action = act.ReloadConfiguration },
    { key = 'r', mods = 'SHIFT|CTRL', action = act.ReloadConfiguration },
    { key = 'r', mods = 'SUPER', action = act.ReloadConfiguration },
    { key = ')', mods = 'CTRL', action = act.ResetFontSize },
    { key = ')', mods = 'SHIFT|CTRL', action = act.ResetFontSize },
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },
    { key = '0', mods = 'SHIFT|CTRL', action = act.ResetFontSize },
    { key = '0', mods = 'SUPER', action = act.ResetFontSize },
    { key = 'PageUp', mods = 'SHIFT', action = act.ScrollByPage(-1) },
    { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },
    { key = 'F', mods = 'CTRL', action = act.Search('CurrentSelectionOrEmptyString') },
    { key = 'F', mods = 'SHIFT|CTRL', action = act.Search('CurrentSelectionOrEmptyString') },
    { key = 'f', mods = 'SHIFT|CTRL', action = act.Search('CurrentSelectionOrEmptyString') },
    { key = 'f', mods = 'SUPER', action = act.Search('CurrentSelectionOrEmptyString') },
    { key = 'L', mods = 'CTRL', action = act.ShowDebugOverlay },
    { key = 'L', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
    { key = 'l', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
    { key = 'T', mods = 'CTRL', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 'T', mods = 'SHIFT|CTRL', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 't', mods = 'SHIFT|CTRL', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 't', mods = 'SUPER', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 'N', mods = 'CTRL', action = act.SpawnWindow },
    { key = 'N', mods = 'SHIFT|CTRL', action = act.SpawnWindow },
    { key = 'n', mods = 'SHIFT|CTRL', action = act.SpawnWindow },
    { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
    { key = '%', mods = 'ALT|CTRL', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '%', mods = 'SHIFT|ALT|CTRL', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '5', mods = 'SHIFT|ALT|CTRL', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = '"', mods = 'ALT|CTRL', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = '"', mods = 'SHIFT|ALT|CTRL', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = '\'', mods = 'SHIFT|ALT|CTRL', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = 'Z', mods = 'CTRL', action = act.TogglePaneZoomState },
    { key = 'Z', mods = 'SHIFT|CTRL', action = act.TogglePaneZoomState },
    { key = 'z', mods = 'SHIFT|CTRL', action = act.TogglePaneZoomState },
}

config.key_tables = {
    copy_mode = {
        -- Custom mappings
        { key = 'd', mods = 'CTRL', action = act.CopyMode('PageDown') },
        { key = 'd', action = act.CopyMode('PageDown') },
        { key = 'u', mods = 'CTRL', action = act.CopyMode('PageUp') },
        { key = 'u', action = act.CopyMode('PageUp') },

        -- Default mappings
        { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'c', mods = 'CTRL', action = act.CopyMode('Close') },
        { key = 'g', mods = 'CTRL', action = act.CopyMode('Close') },
        { key = 'q', mods = 'NONE', action = act.CopyMode('Close') },
        { key = ';', mods = 'NONE', action = act.CopyMode('JumpAgain') },
        { key = ',', mods = 'NONE', action = act.CopyMode('JumpReverse') },
        { key = 'Tab', mods = 'SHIFT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'b', mods = 'NONE', action = act.CopyMode('MoveBackwardWord') },
        { key = 'b', mods = 'ALT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'LeftArrow', mods = 'ALT', action = act.CopyMode('MoveBackwardWord') },
        { key = 'j', mods = 'NONE', action = act.CopyMode('MoveDown') },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('MoveDown') },
        { key = 'Tab', mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
        { key = 'f', mods = 'ALT', action = act.CopyMode('MoveForwardWord') },
        { key = 'w', mods = 'NONE', action = act.CopyMode('MoveForwardWord') },
        { key = 'RightArrow', mods = 'ALT', action = act.CopyMode('MoveForwardWord') },
        { key = 'h', mods = 'NONE', action = act.CopyMode('MoveLeft') },
        { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode('MoveLeft') },
        { key = 'l', mods = 'NONE', action = act.CopyMode('MoveRight') },
        { key = 'RightArrow', mods = 'NONE', action = act.CopyMode('MoveRight') },
        { key = '$', mods = 'NONE', action = act.CopyMode('MoveToEndOfLineContent') },
        { key = '$', mods = 'SHIFT', action = act.CopyMode('MoveToEndOfLineContent') },
        { key = 'G', mods = 'NONE', action = act.CopyMode('MoveToScrollbackBottom') },
        { key = 'G', mods = 'SHIFT', action = act.CopyMode('MoveToScrollbackBottom') },
        { key = 'g', mods = 'NONE', action = act.CopyMode('MoveToScrollbackTop') },
        { key = 'o', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEnd') },
        { key = 'O', mods = 'NONE', action = act.CopyMode('MoveToSelectionOtherEndHoriz') },
        { key = 'O', mods = 'SHIFT', action = act.CopyMode('MoveToSelectionOtherEndHoriz') },
        { key = '0', mods = 'NONE', action = act.CopyMode('MoveToStartOfLine') },
        { key = '^', mods = 'NONE', action = act.CopyMode('MoveToStartOfLineContent') },
        { key = '^', mods = 'SHIFT', action = act.CopyMode('MoveToStartOfLineContent') },
        { key = 'm', mods = 'ALT', action = act.CopyMode('MoveToStartOfLineContent') },
        { key = 'Enter', mods = 'NONE', action = act.CopyMode('MoveToStartOfNextLine') },
        { key = 'L', mods = 'NONE', action = act.CopyMode('MoveToViewportBottom') },
        { key = 'L', mods = 'SHIFT', action = act.CopyMode('MoveToViewportBottom') },
        { key = 'M', mods = 'NONE', action = act.CopyMode('MoveToViewportMiddle') },
        { key = 'M', mods = 'SHIFT', action = act.CopyMode('MoveToViewportMiddle') },
        { key = 'H', mods = 'NONE', action = act.CopyMode('MoveToViewportTop') },
        { key = 'H', mods = 'SHIFT', action = act.CopyMode('MoveToViewportTop') },
        { key = 'k', mods = 'NONE', action = act.CopyMode('MoveUp') },
        { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('MoveUp') },
        { key = 'f', mods = 'CTRL', action = act.CopyMode('PageDown') },
        { key = 'PageDown', mods = 'NONE', action = act.CopyMode('PageDown') },
        { key = 'b', mods = 'CTRL', action = act.CopyMode('PageUp') },
        { key = 'PageUp', mods = 'NONE', action = act.CopyMode('PageUp') },
        { key = 'F', mods = 'NONE', action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
        { key = 'F', mods = 'SHIFT', action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
        { key = 'T', mods = 'NONE', action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
        { key = 'T', mods = 'SHIFT', action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
        { key = 'f', mods = 'NONE', action = act.CopyMode({ JumpForward = { prev_char = false } }) },
        { key = 't', mods = 'NONE', action = act.CopyMode({ JumpForward = { prev_char = true } }) },
        { key = 'v', mods = 'CTRL', action = act.CopyMode({ SetSelectionMode = 'Block' }) },
        { key = 'Space', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        { key = 'v', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Cell' }) },
        { key = 'V', mods = 'NONE', action = act.CopyMode({ SetSelectionMode = 'Line' }) },
        { key = 'V', mods = 'SHIFT', action = act.CopyMode({ SetSelectionMode = 'Line' }) },
        {
            key = 'y',
            mods = 'NONE',
            action = act.Multiple({ { CopyTo = 'ClipboardAndPrimarySelection' }, { CopyMode = 'Close' } }),
        },
    },

    search_mode = {
        -- Custom mappings
        -- This mapping fails to scroll, instead it clears the search input
        { key = 'd', mods = 'CTRL', action = act.CopyMode('PriorMatchPage') },
        { key = 'u', mods = 'CTRL', action = act.CopyMode('NextMatchPage') },

        -- Default mappings
        { key = 'Enter', mods = 'NONE', action = act.CopyMode('PriorMatch') },
        { key = 'Escape', mods = 'NONE', action = act.CopyMode('Close') },
        { key = 'n', mods = 'CTRL', action = act.CopyMode('NextMatch') },
        { key = 'p', mods = 'CTRL', action = act.CopyMode('PriorMatch') },
        { key = 'r', mods = 'CTRL', action = act.CopyMode('CycleMatchType') },
        { key = 'u', mods = 'CTRL', action = act.CopyMode('ClearPattern') },
        { key = 'PageUp', mods = 'NONE', action = act.CopyMode('PriorMatchPage') },
        { key = 'PageDown', mods = 'NONE', action = act.CopyMode('NextMatchPage') },
        { key = 'UpArrow', mods = 'NONE', action = act.CopyMode('PriorMatch') },
        { key = 'DownArrow', mods = 'NONE', action = act.CopyMode('NextMatch') },
    },
}

return config
