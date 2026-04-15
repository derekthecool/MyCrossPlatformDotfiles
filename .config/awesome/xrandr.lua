-- xrandr.lua
-- Helper for multiple monitors (based on xrandr)
-- From https://awesomewm.org/recipes/xrandr/

local awful = require('awful')
local naughty = require('naughty')
local gears = require('gears')
local table = table
local tonumber = tonumber
local tostring = tostring
local ipairs = ipairs
local pairs = pairs

-- xrandr executions
local function xrandr()
    local f = io.popen('xrandr -q')
    if not f then
        return {}
    end
    local lines = {}
    for line in f:lines() do
        lines[#lines + 1] = line
    end
    f:close()
    return lines
end

-- Get active and connected screens
local function screens()
    local ws, cs = {}, {}
    for _, line in ipairs(xrandr()) do
        if line:match(' connected') then
            cs[#cs + 1] = line
        end
        if line:match('%*%w*') then
            ws[#ws + 1] = line
        end
    end
    return ws, cs
end

-- Return a table with all active screens
local function get_screen_list()
    local list = {}
    for _, s in ipairs(screens()) do
        local name = s:match('(%w+-%d+)') or s:match('(%w+)%s')
        if name then
            list[#list + 1] = name
        end
    end
    return list
end

-- Return a table with all connected screens
local function get_screen_list_connected()
    local list = {}
    local _, cs = screens()
    for _, s in ipairs(cs) do
        local name = s:match('(%w+-%d+)') or s:match('(%w+)%s')
        if name then
            list[#list + 1] = name
        end
    end
    return list
end

-- Get screen resolution
local function get_resolution(screen)
    for _, line in ipairs(xrandr()) do
        local s = line:match(screen .. ' connected')
        if s then
            local _, _, res = line:find('(%d+)x(%d+)%+')
            if res then
                return line:match('(%d+)x(%d+)%+')
            end
        end
    end
    return 'error'
end

-- Generate all possible configurations
local function config_generator()
    local configs = {}
    local active_screens = get_screen_list()
    local connected_screens = get_screen_list_connected()

    -- Single screen configurations
    for _, s in ipairs(connected_screens) do
        configs[#configs + 1] = { command = 'xrandr --auto', message = 'Only ' .. s }
        configs[#configs + 1] = {
            command = 'xrandr --output ' .. s .. ' --auto --output ' .. (s == 'eDP1' and 'HDMI1' or 'eDP1') .. ' --off',
            message = 'Only ' .. s,
        }
    end

    -- Dual screen configurations
    if #connected_screens >= 2 then
        for i, s1 in ipairs(connected_screens) do
            for j, s2 in ipairs(connected_screens) do
                if s1 ~= s2 then
                    local res1 = get_resolution(s1)
                    local res2 = get_resolution(s2)
                    configs[#configs + 1] = {
                        command = 'xrandr --output ' .. s1 .. ' --auto --output ' .. s2 .. ' --auto --right-of ' .. s1,
                        message = s2 .. ' right of ' .. s1,
                    }
                    configs[#configs + 1] = {
                        command = 'xrandr --output ' .. s1 .. ' --auto --output ' .. s2 .. ' --auto --left-of ' .. s1,
                        message = s2 .. ' left of ' .. s1,
                    }
                    configs[#configs + 1] = {
                        command = 'xrandr --output ' .. s1 .. ' --auto --output ' .. s2 .. ' --auto --above ' .. s1,
                        message = s2 .. ' above ' .. s1,
                    }
                    configs[#configs + 1] = {
                        command = 'xrandr --output ' .. s1 .. ' --auto --output ' .. s2 .. ' --auto --below ' .. s1,
                        message = s2 .. ' below ' .. s1,
                    }
                end
            end
        end
    end

    -- Mirror configurations
    if #connected_screens >= 2 then
        for i, s1 in ipairs(connected_screens) do
            for j, s2 in ipairs(connected_screens) do
                if i < j then
                    configs[#configs + 1] = {
                        command = 'xrandr --output ' .. s1 .. ' --auto --output ' .. s2 .. ' --auto --same-as ' .. s1,
                        message = 'Mirror ' .. s1 .. ' and ' .. s2,
                    }
                end
            end
        end
    end

    -- Keep current configuration
    configs[#configs + 1] = { command = '', message = 'Keep current configuration' }

    return configs
end

-- Execute xrandr command
local function spawn(command)
    if command == '' then
        return
    end
    awful.spawn.with_shell(command)
end

-- Notification timer
local timer
local notification
local index = 1
local configs = config_generator()

-- Main xrandr function to cycle through configurations
local function xrandr_cycle()
    -- Cancel existing timer
    if timer then
        timer:stop()
        timer = nil
    end

    -- Update configuration list (in case monitors were plugged/unplugged)
    configs = config_generator()

    -- Get current configuration
    local current_config = configs[index]

    -- Show notification
    if notification then
        naughty.destroy(notification)
    end
    notification = naughty.notify({
        text = current_config.message,
        timeout = 4,
        screen = mouse.screen,
    })

    -- Setup timer to apply configuration
    timer = gears.timer({ timeout = 4 })
    timer:connect_signal('timeout', function()
        spawn(current_config.command)
        if notification then
            naughty.destroy(notification)
            notification = nil
        end
        timer:stop()
        timer = nil
    end)
    timer:start()

    -- Cycle to next configuration
    index = index % #configs + 1
end

return {
    xrandr = xrandr_cycle,
    get_screen_list = get_screen_list,
    get_screen_list_connected = get_screen_list_connected,
    config_generator = config_generator,
}
