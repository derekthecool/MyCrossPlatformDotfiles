-- Test theme configuration
describe("AwesomeWM Theme Configuration", function()

  -- Load beautiful module for theme testing
  local beautiful = require("beautiful")

  it("can load the custom theme", function()
    -- Test that theme file exists and can be loaded
    local theme_path = os.getenv("HOME") .. "/.config/awesome/custom-theme.lua"

    local f = io.open(theme_path, "r")
    assert.is_not_nil(f, "Theme file should exist")
    f:close()
  end)

  it("defines notification background color", function()
    -- Check that notification_bg is defined in theme
    local theme_path = os.getenv("HOME") .. "/.config/awesome/custom-theme.lua"
    local f = io.open(theme_path, "r")
    local content = f:read("*all")
    f:close()

    assert.is_truthy(content:match("theme%.notification_bg"), "Theme should define notification_bg")
  end)

  it("defines notification foreground color", function()
    local theme_path = os.getenv("HOME") .. "/.config/awesome/custom-theme.lua"
    local f = io.open(theme_path, "r")
    local content = f:read("*all")
    f:close()

    assert.is_truthy(content:match("theme%.notification_fg"), "Theme should define notification_fg")
  end)

  it("defines notification border color", function()
    local theme_path = os.getenv("HOME") .. "/.config/awesome/custom-theme.lua"
    local f = io.open(theme_path, "r")
    local content = f:read("*all")
    f:close()

    assert.is_truthy(content:match("theme%.notification_border_color"), "Theme should define notification_border_color")
  end)

  it("uses valid hex color for notification background", function()
    local theme_path = os.getenv("HOME") .. "/.config/awesome/custom-theme.lua"
    local f = io.open(theme_path, "r")
    local content = f:read("*all")
    f:close()

    -- Extract the notification_bg value
    local bg_color = content:match("theme%.notification_bg%s*=%s*['\"](#%x%x%x%x%x%x)['\"]")
    assert.is_not_nil(bg_color, "notification_bg should be a valid hex color")
  end)
end)