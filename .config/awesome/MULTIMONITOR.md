# Multi-Monitor Support for AwesomeWM

## Overview

The xrandr.lua helper provides easy multi-monitor configuration support for AwesomeWM. It allows you to cycle through all possible screen arrangements with a simple keybinding.

## Keybindings

Two keybindings have been added to cycle through monitor configurations:

- **Mod4 + XF86Display**: Cycle through monitor configurations (Display key)
- **Alt + Ctrl + x**: Alternative keybinding for monitor cycling

> Note: Mod4 is your Super/Windows key, Alt is your Mod1 key (configured in rc.lua)

## How It Works

1. **Press the keybinding** once to see the first available configuration
2. A **notification popup** appears showing the current configuration option
3. **Press again** within 4 seconds to cycle to the next configuration
4. **Stop pressing** and the configuration shown in the popup is applied automatically

## Available Configurations

The script automatically detects your connected monitors and generates configurations including:

- **Single monitor**: Each connected monitor can be used alone
- **Extended desktop**:
  - Monitor to the left/right
  - Monitor above/below
- **Mirrored displays**: Same content on multiple monitors
- **Keep current**: Option to maintain your current setup

## Configuration Examples

For a laptop with external monitor setup:

```
Only eDP1                    - Use only laptop screen
Only HDMI1                   - Use only external monitor
HDMI1 right of eDP1          - External monitor to the right
HDMI1 left of eDP1           - External monitor to the left
Mirror eDP1 and HDMI1        - Both screens show same content
Keep current configuration   - Don't change anything
```

## Manual Configuration

If you need more specific control over your monitors, you can use xrandr directly:

```bash
# List connected monitors and their modes
xrandr -q

# Set specific resolution
xrandr --output HDMI1 --mode 1920x1080

# Set primary monitor
xrandr --output HDMI1 --primary

# Complex setup (example)
xrandr --output eDP1 --auto --output HDMI1 --auto --right-of eDP1 --primary
```

## Troubleshooting

### Monitor not detected
- Check cable connection
- Run `xrandr -q` to see if monitor is listed
- Restart AwesomeWM: Mod + Shift + r

### Configuration doesn't apply
- Make sure xrandr is installed: `pacman -S xorg-xrandr`
- Check the notification shows the correct configuration
- Try running the xrandr command manually in a terminal

### Keybinding doesn't work
- Check that xrandr.lua is in your Awesome config directory
- Restart AwesomeWM: Mod + Shift + r
- Check for errors in `~/.config/awesome/stderr`

## File Locations

- **xrandr.lua**: `/home/derek/.config/awesome/xrandr.lua`
- **rc.lua**: `/home/derek/.config/awesome/rc.lua` (with require statement added)
- **This guide**: `/home/derek/.config/awesome/MULTIMONITOR.md`

## Customization

### Change timeout
Edit xrandr.lua and modify the timeout value (default 4 seconds):

```lua
timer = awful.timer({ timeout = 4 })  -- Change 4 to your desired seconds
```

### Add custom configurations
Edit the `config_generator()` function in xrandr.lua to add your specific setups.

### Change keybindings
Edit the Globalkeys section in rc.lua where the xrandr keybindings are defined.

## Sources

- [AwesomeWM xrandr Recipe](https://awesomewm.org/recipes/xrandr/)
- [xrandr Manual](https://wiki.archlinux.org/title/xrandr)
