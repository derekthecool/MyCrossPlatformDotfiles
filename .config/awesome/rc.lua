-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, 'luarocks.loader')

-- Standard awesome library
local gears = require('gears')
local awful = require('awful')
require('awful.autofocus')

-- Widget and layout library
local wibox = require('wibox')

-- Extra package for widgets by community
local vicious = require('vicious')

-- Theme handling library
local beautiful = require('beautiful')

-- Notification library
local naughty = require('naughty')
local menubar = require('menubar')
local hotkeys_popup = require('awful.hotkeys_popup')

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
-- require('awful.hotkeys_popup.keys')

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = 'Oops, there were errors during startup!',
        text = awesome.startup_errors,
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal('debug::error', function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then
            return
        end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = 'Oops, an error happened!',
            text = tostring(err),
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. 'default/theme.lua')

-- This is used later as the default terminal and editor to run.
Terminal = 'wezterm'
Editor = os.getenv('EDITOR') or 'nvim'
EditorCommand = Terminal .. ' -e ' .. Editor

-- Default modkey.
-- Mod1 = alt
-- Mod4 = super (windows key)
ModKey = 'Mod1'

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    -- awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
MyAwesomeMenu = {
    {
        'hotkeys',
        function()
            hotkeys_popup.show_help(nil, awful.screen.focused())
        end,
    },
    { 'manual', Terminal .. ' -e man awesome' },
    { 'edit config', EditorCommand .. ' ' .. awesome.conffile },
    { 'restart', awesome.restart },
    {
        'quit',
        function()
            awesome.quit()
        end,
    },
}

MyMainMenu =
    awful.menu({ items = { { 'awesome', MyAwesomeMenu, beautiful.awesome_icon }, { 'open terminal', Terminal } } })

MyLauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = MyMainMenu })

-- Menubar configuration
menubar.utils.terminal = Terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
MyKeyboardLayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
MyTextClock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t)
        t:view_only()
    end),
    awful.button({ ModKey }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ ModKey }, 3, function(t)
        if client.focus then
            client.focus:toggle_tag(t)
        end
    end),
    awful.button({}, 4, function(t)
        awful.tag.viewnext(t.screen)
    end),
    awful.button({}, 5, function(t)
        awful.tag.viewprev(t.screen)
    end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal('request::activate', 'tasklist', { raise = true })
        end
    end),
    awful.button({}, 3, function()
        awful.menu.client_list({ theme = { width = 250 } })
    end),
    awful.button({}, 4, function()
        awful.client.focus.byidx(1)
    end),
    awful.button({}, 5, function()
        awful.client.focus.byidx(-1)
    end)
)

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == 'function' then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal('property::geometry', set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ 'Terminal', 'Web', 'Chat', 'Plover', 'Docs', 'Device', '7', '8', '9' }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 3, function()
            awful.layout.inc(-1)
        end),
        awful.button({}, 4, function()
            awful.layout.inc(1)
        end),
        awful.button({}, 5, function()
            awful.layout.inc(-1)
        end)
    ))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
    })

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist({
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
    })

    local docker_widget = require('awesome-wm-widgets.docker-widget.docker')

    -- Battery widget
    local batteryarc_widget = require('awesome-wm-widgets.batteryarc-widget.batteryarc')
    volume_widget = require('awesome-wm-widgets.volume-widget.volume')
    local calendar_widget = require('awesome-wm-widgets.calendar-widget.calendar')
    -- ...
    -- Create a textclock widget
    mytextclock = wibox.widget.textclock()
    local cw = calendar_widget()
    mytextclock:connect_signal('button::press', function(_, _, _, button)
        if button == 1 then
            cw.toggle()
        end
    end)

    -- local datewidget = wibox.widget.textbox()
    -- vicious.register(datewidget, vicious.widgets.date, '%I:%M:%S %p')

    -- Pacman Widget
    local pacwidget = wibox.widget.textbox()

    local pacwidget_t = awful.tooltip({ objects = { pacwidget } })

    vicious.register(pacwidget, vicious.widgets.pkg, function(widget, args)
        local io = { popen = io.popen }
        local output = io.popen('pacman -Qu')
        local str = ''

        local count = 0
        for line in output:lines() do
            -- str = str .. line .. '\n'
            count = count + 1
            print(line)
        end
        pacwidget_t:set_text(str)
        output:close()
        return '|UPDATES: ' .. count .. '|'
    end, 1, 'Arch')

    --'1800' means check every 30 minutes

    -- End custom widgets

    -- Create the wibox
    s.mywibox = awful.wibar({ position = 'top', screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            MyLauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            MyKeyboardLayout,
            wibox.widget.systray(),
            batteryarc_widget(),
            volume_widget(),
            docker_widget(),
            mytextclock,
            s.mylayoutbox,
        },
    })
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({}, 3, function()
        MyMainMenu:toggle()
    end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
Globalkeys = gears.table.join(
    awful.key({ ModKey }, 's', hotkeys_popup.show_help, { description = 'show help', group = 'awesome' }),
    awful.key({ ModKey }, 'Left', awful.tag.viewprev, { description = 'view previous', group = 'tag' }),
    awful.key({ ModKey }, 'Right', awful.tag.viewnext, { description = 'view next', group = 'tag' }),
    awful.key({ ModKey }, 'Escape', awful.tag.history.restore, { description = 'go back', group = 'tag' }),
    awful.key({ ModKey }, 'j', function()
        awful.client.focus.byidx(1)
    end, { description = 'focus next by index', group = 'client' }),

    awful.key({ ModKey }, 'k', function()
        awful.client.focus.byidx(-1)
    end, { description = 'focus previous by index', group = 'client' }),

    awful.key({ ModKey }, 'w', function()
        MyMainMenu:show()
    end, { description = 'show main menu', group = 'awesome' }),

    -- Layout manipulation
    awful.key({ ModKey, 'Shift' }, 'j', function()
        awful.client.swap.byidx(1)
    end, { description = 'swap with next client by index', group = 'client' }),
    awful.key({ ModKey, 'Shift' }, 'k', function()
        awful.client.swap.byidx(-1)
    end, { description = 'swap with previous client by index', group = 'client' }),
    awful.key({ ModKey, 'Control' }, 'j', function()
        awful.screen.focus_relative(1)
    end, { description = 'focus the next screen', group = 'screen' }),

    awful.key({ ModKey, 'Control' }, 'k', function()
        awful.screen.focus_relative(-1)
    end, { description = 'focus the previous screen', group = 'screen' }),
    awful.key({ ModKey }, 'u', awful.client.urgent.jumpto, { description = 'jump to urgent client', group = 'client' }),
    awful.key({ ModKey }, 'Tab', function()
        awful.client.focus.history.previous()
        if client.focus then
            client.focus:raise()
        end
    end, { description = 'go back', group = 'client' }),

    -- Standard program
    awful.key({ ModKey }, 'Return', function()
        awful.spawn(Terminal)
    end, { description = 'open a terminal', group = 'launcher' }),

    -- awful.key({ ModKey, 'Shift' }, 'Return', Terminal .. ' -e man awesome', { description = 'lua man page', group = 'launcher' }),

    awful.key({ ModKey }, 'q', awesome.restart, { description = 'reload awesome', group = 'awesome' }),
    awful.key({ ModKey, 'Shift' }, 'q', awesome.quit, { description = 'quit awesome', group = 'awesome' }),
    awful.key({ ModKey }, 'h', function()
        awful.tag.incmwfact(0.05)
    end, { description = 'increase master width factor', group = 'layout' }),

    awful.key({ ModKey }, 'l', function()
        awful.tag.incmwfact(-0.05)
    end, { description = 'decrease master width factor', group = 'layout' }),
    awful.key({ ModKey, 'Shift' }, 'h', function()
        awful.tag.incnmaster(1, nil, true)
    end, { description = 'increase the number of master clients', group = 'layout' }),
    awful.key({ ModKey, 'Shift' }, 'l', function()
        awful.tag.incnmaster(-1, nil, true)
    end, { description = 'decrease the number of master clients', group = 'layout' }),
    awful.key({ ModKey, 'Control' }, 'h', function()
        awful.tag.incncol(1, nil, true)
    end, { description = 'increase the number of columns', group = 'layout' }),
    awful.key({ ModKey, 'Control' }, 'l', function()
        awful.tag.incncol(-1, nil, true)
    end, { description = 'decrease the number of columns', group = 'layout' }),

    awful.key({ ModKey }, 'space', function()
        awful.layout.inc(1)
    end, { description = 'select next', group = 'layout' }),

    awful.key({ ModKey, 'Shift' }, 'space', function()
        awful.layout.inc(-1)
    end, { description = 'select previous', group = 'layout' }),

    awful.key({ ModKey, 'Control' }, 'n', function()
        local c = awful.client.restore()
        -- Focus restored client
        if c then
            c:emit_signal('request::activate', 'key.unminimize', { raise = true })
        end
    end, { description = 'restore minimized', group = 'client' }),

    -- Rofi program launcher
    awful.key({ ModKey }, 'i', function()
        awful.spawn('rofi -show combi -modes combi -combi-modes "window,drun,run"')
    end, { description = 'run rofi', group = 'launcher' }),

    -- TODO: find why Plover key SKWHUFRB and SKWHEFRB are not working
    awful.key({}, 'XF86AudioRaiseVolume', function()
        volume_widget:inc(5)
    end),
    awful.key({}, 'XF86AudioLowerVolume', function()
        volume_widget:dec(5)
    end),
    awful.key({}, 'XF86AudioMute', function()
        volume_widget:toggle()
    end),

    -- TODO: 2022-11-26 add back key for lua prompt
    -- awful.key({ modkey }, 'x', function()
    --     awful.prompt.run({
    --         prompt = 'Run Lua code: ',
    --         textbox = awful.screen.focused().mypromptbox.widget,
    --         exe_callback = awful.util.eval,
    --         history_path = awful.util.get_cache_dir() .. '/history_eval',
    --     })
    -- end, { description = 'lua execute prompt', group = 'awesome' }),

    -- Menubar
    awful.key({ ModKey }, 'p', function()
        menubar.show()
    end, { description = 'show the menubar', group = 'launcher' })
)

ClientKeys = gears.table.join(
    awful.key({ ModKey }, 'f', function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, { description = 'toggle fullscreen', group = 'client' }),

    awful.key({ ModKey }, 'x', function(c)
        c:kill()
    end, { description = 'close', group = 'client' }),

    awful.key(
        { ModKey, 'Control' },
        'space',
        awful.client.floating.toggle,
        { description = 'toggle floating', group = 'client' }
    ),

    awful.key({ ModKey, 'Control' }, 'Return', function(c)
        c:swap(awful.client.getmaster())
    end, { description = 'move to master', group = 'client' }),

    awful.key({ ModKey }, 'o', function(c)
        c:move_to_screen()
    end, { description = 'move to screen', group = 'client' }),

    awful.key({ ModKey }, 't', function(c)
        c.ontop = not c.ontop
    end, { description = 'toggle keep on top', group = 'client' }),

    awful.key({ ModKey }, 'n', function(c)
        -- The client currently has the input focus, so it cannot be
        -- minimized, since minimized clients can't have the focus.
        c.minimized = true
    end, { description = 'minimize', group = 'client' }),

    awful.key({ ModKey }, 'm', function(c)
        c.maximized = not c.maximized
        c:raise()
    end, { description = '(un)maximize', group = 'client' }),

    awful.key({ ModKey, 'Control' }, 'm', function(c)
        c.maximized_vertical = not c.maximized_vertical
        c:raise()
    end, { description = '(un)maximize vertically', group = 'client' }),

    awful.key({ ModKey, 'Shift' }, 'm', function(c)
        c.maximized_horizontal = not c.maximized_horizontal
        c:raise()
    end, { description = '(un)maximize horizontally', group = 'client' })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    Globalkeys = gears.table.join(
        Globalkeys,
        -- View tag only.
        awful.key({ ModKey }, '#' .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                tag:view_only()
            end
        end, { description = 'view tag #' .. i, group = 'tag' }),

        -- Toggle tag display.
        awful.key({ ModKey, 'Control' }, '#' .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end, { description = 'toggle tag #' .. i, group = 'tag' }),

        -- Move client to tag.
        awful.key({ ModKey, 'Shift' }, '#' .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, { description = 'move focused client to tag #' .. i, group = 'tag' }),

        -- Toggle tag on focused client.
        awful.key({ ModKey, 'Control', 'Shift' }, '#' .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end, { description = 'toggle focused client on tag #' .. i, group = 'tag' })
    )
end

ClientButtons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal('request::activate', 'mouse_click', { raise = true })
    end),
    awful.button({ ModKey }, 1, function(c)
        c:emit_signal('request::activate', 'mouse_click', { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ ModKey }, 3, function(c)
        c:emit_signal('request::activate', 'mouse_click', { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(Globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = ClientKeys,
            buttons = ClientButtons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
                'DTA', -- Firefox addon DownThemAll.
                'copyq', -- Includes session name in class.
                'pinentry',
            },
            class = {
                'Arandr',
                'Blueman-manager',
                'Gpick',
                'Kruler',
                'MessageWin', -- kalarm.
                'Sxiv',
                'Tor Browser', -- Needs a fixed window size to avoid fingerprinting by screen size.
                'Wpa_gui',
                'veromix',
                'xtightvncviewer',
            },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
                'Event Tester', -- xev.
            },
            role = {
                'AlarmWindow', -- Thunderbird's calendar.
                'ConfigManager', -- Thunderbird's about:config.
                'pop-up', -- e.g. Google Chrome's (detached) Developer Tools.
            },
        },
        properties = { floating = true },
    },

    -- Add titlebars to normal clients and dialogs
    { rule_any = { type = { 'normal', 'dialog' } }, properties = { titlebars_enabled = true } },

    -- First tag: terminal
    { rule = { class = 'Alacritty' }, properties = { screen = 1, tag = 'Terminal' } },
    { rule = { class = 'Wezterm' }, properties = { screen = 1, tag = 'Terminal' } },

    -- Second tag: web
    { rule = { class = 'Firefox' }, properties = { screen = 1, tag = 'Web' } },
    { rule = { class = 'Vieb' }, properties = { screen = 1, tag = 'Web' } },

    -- Third tag: chat

    -- Forth tag: Plover stenography. Send everything except Plover lookup to Plover tag
    {
        rule_any = { class = { 'Plover' } },
        except_any = { name = { 'Plover: Lookup', 'Plover: Add Translation' } },
        properties = { screen = 1, tag = 'Plover' },
    },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal('manage', function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then
        awful.client.setslave(c)
    end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal('request::titlebars', function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal('request::activate', 'titlebar', { raise = true })
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal('request::activate', 'titlebar', { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c):setup({
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal,
        },
        { -- Middle
            { -- Title
                align = 'center',
                widget = awful.titlebar.widget.titlewidget(c),
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal,
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal(),
        },
        layout = wibox.layout.align.horizontal,
    })
end)

client.connect_signal('focus', function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal('unfocus', function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- Gaps
beautiful.useless_gap = 3

-- Startup
-- use images from Derek Taylor (DT) : git clone https://gitlab.com/dwt1/wallpapers.git ~/MyDesktopBackgrounds
awful.spawn.with_shell('nitrogen --set-zoom-fill --random ~/MyDesktopBackgrounds/')
awful.spawn.with_shell('picom -b')
awful.spawn.with_shell('wezterm')
