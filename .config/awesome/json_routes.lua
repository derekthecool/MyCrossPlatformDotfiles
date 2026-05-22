-- JSON-based window routing for AwesomeWM
-- Reads routes from ~/Atelier/workspaces/*.json files

local awful = require("awful")
local json = require("json")  -- rxi/json.lua

-- Store routes for use in signal handler
local _routes = {}

local workspace_path = os.getenv("HOME") .. "/Atelier/workspaces"
local workspace_names = {
    [1] = "1",
    [2] = "2",
    [3] = "3",
    [4] = "4",
    [5] = "5",
    [6] = "6",
    [7] = "7",
    [8] = "8",
    [9] = "9"
}

-- Helper function to read JSON file
local function read_json(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return json.decode(content)
end

-- Load routes from JSON files (for tag routing)
local function load_routes()
    _routes = {}

    for i = 1, 9 do
        local json_file = workspace_path .. "/" .. i .. ".json"
        local routes = read_json(json_file)

        if routes and type(routes) == "table" then
            for _, route in ipairs(routes) do
                local app = route.app
                local route_type = route.type

                local route_info = {
                    tag_index = i,
                    app = app,
                    type = route_type
                }

                table.insert(_routes, route_info)
            end
        end
    end

    return _routes
end

-- Apply routes to a client
local function apply_routes(c)
    for _, route in ipairs(_routes) do
        local matches = false

        -- Check if this route matches the client
        if route.type == "class" then
            if c.class and c.class == route.app then
                matches = true
            end
        elseif route.type == "process" or route.type == "instance" then
            if c.instance and c.instance == route.app then
                matches = true
            end
        elseif route.type == "title" or route.type == "name" then
            if c.name and c.name:match(route.app) then
                matches = true
            end
        elseif route.type == "role" then
            if c.role and c.role == route.app then
                matches = true
            end
        end

        -- If matched, move to the specified tag
        if matches then
            local s = c.screen or awful.screen.focused()
            if s and s.tags and s.tags[route.tag_index] then
                c:move_to_tag(s.tags[route.tag_index])
                return true  -- Stop after first match
            end
        end
    end

    return false
end

-- Load filters from JSON file
local function load_filters()
    local filters_file = workspace_path .. "/filters.json"
    local filters = read_json(filters_file)

    if not filters or type(filters) ~= "table" then
        return {}
    end

    local instance_filters = {}
    local class_filters = {}
    local name_filters = {}
    local role_filters = {}

    for _, filter in ipairs(filters) do
        local app = filter.app
        local filter_type = filter.type

        if filter_type == "class" then
            table.insert(class_filters, app)
        elseif filter_type == "process" or filter_type == "instance" then
            table.insert(instance_filters, app)
        elseif filter_type == "title" or filter_type == "name" then
            table.insert(name_filters, app)
        elseif filter_type == "role" then
            table.insert(role_filters, app)
        end
    end

    return {
        instance = instance_filters,
        class = class_filters,
        name = name_filters,
        role = role_filters
    }
end

-- Export functions
return {
    load_routes = load_routes,
    load_filters = load_filters,
    apply_routes = apply_routes
}
