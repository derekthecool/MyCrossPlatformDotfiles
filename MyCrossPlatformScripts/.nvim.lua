-- Simple .nvim.lua
local delay_ms = 3000

vim.defer_fn(function()
    local toggleterm = require("toggleterm")

    -- Using leader key here causes delays in insert mode
    local keymap_starter_key = '`'

    local mapping_options = { 't', 'n', 'i', }

    -- local build = 'Import-Module PowershellTools -Force -Verbose'
    -- vim.keymap.set(mapping_options, keymap_starter_key .. "u;", function()
    --     toggleterm.exec(build)
    -- end, { silent = true, desc = build })

    local test = 'Invoke-Pester'
    vim.keymap.set(mapping_options, keymap_starter_key .. "ui", function()
        toggleterm.exec(test)
    end, { silent = true, desc = test })

    -- local run = 'dotnet run'
    -- vim.keymap.set(mapping_options, keymap_starter_key .. "uu", function()
    --     toggleterm.exec(run)
    -- end, { silent = true, desc = run })

    -- -- Set current working directory
    -- vim.cmd('cd ./Benchmarks')

    -- Run initial start up commands in the terminal
    vim.cmd('ToggleTerm direction=tab')
    toggleterm.exec('Import-Module PowershellTools -Force -Verbose')

    vim.notify('Ready to run', vim.log.levels.INFO, { title = '.nvim.lua commands' })
end, delay_ms)
