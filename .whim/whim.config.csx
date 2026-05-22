#nullable enable
#r "C:\Program Files\Whim\whim.dll"
#r "C:\Program Files\Whim\plugins\Whim.Bar\Whim.Bar.dll"
#r "C:\Program Files\Whim\plugins\Whim.CommandPalette\Whim.CommandPalette.dll"
#r "C:\Program Files\Whim\plugins\Whim.FloatingWindow\Whim.FloatingWindow.dll"
#r "C:\Program Files\Whim\plugins\Whim.FocusIndicator\Whim.FocusIndicator.dll"
#r "C:\Program Files\Whim\plugins\Whim.Gaps\Whim.Gaps.dll"
#r "C:\Program Files\Whim\plugins\Whim.LayoutPreview\Whim.LayoutPreview.dll"
#r "C:\Program Files\Whim\plugins\Whim.SliceLayout\Whim.SliceLayout.dll"
#r "C:\Program Files\Whim\plugins\Whim.TreeLayout\Whim.TreeLayout.dll"
#r "C:\Program Files\Whim\plugins\Whim.TreeLayout.Bar\Whim.TreeLayout.Bar.dll"
#r "C:\Program Files\Whim\plugins\Whim.TreeLayout.CommandPalette\Whim.TreeLayout.CommandPalette.dll"
#r "C:\Program Files\Whim\plugins\Whim.Updater\Whim.Updater.dll"
#r "C:\Program Files\Whim\plugins\Whim.Yaml\Whim.Yaml.dll"

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using Microsoft.UI;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;
using Whim;
using Whim.Bar;
using Whim.CommandPalette;
using Whim.FloatingWindow;
using Whim.FocusIndicator;
using Whim.Gaps;
using Whim.LayoutPreview;
using Whim.SliceLayout;
using Whim.TreeLayout;
using Whim.TreeLayout.Bar;
using Whim.TreeLayout.CommandPalette;
using Whim.Updater;
using Whim.Yaml;
using Windows.Win32.UI.Input.KeyboardAndMouse;

void DoConfig(IContext context)
{
    context.Logger.Config = new LoggerConfig();
    // context.Logger.Config = new LoggerConfig() { BaseMinLogLevel = LogLevel.Debug };
    // // The logger will log messages with a level of `Debug` or higher to a file.
    // if (context.Logger.Config.FileSink is FileSinkConfig fileSinkConfig)
    // {
    //     fileSinkConfig.MinLogLevel = LogLevel.Debug;
    // }

    // YAML config. It's best to load this first so that you can use it in your C# config.
    YamlLoader.Load(context);

    // Customize your config in C# here.
    // For more, see https://dalyisaac.github.io/Whim/script/scripting.html
    // Example configs
    // https://github.com/formesean/configs/blob/d076ef27e74898b31e511126c9b01b0a34d2649c/whim/whim.config.csx#L4
    // https://github.com/urob/whim-config/blob/3387b154edadf384271c90d2ed75a90c10e53790/whim.config.csx#L4


    Dictionary<string, string> workspaces = new Dictionary<string, string>();
    void AddWorkspace(string name, string icon)
    {
        workspaces.Add(name, icon);
        context.WorkspaceManager.Add(icon);
    }

    AddWorkspace("terminal", "1");
    AddWorkspace("web", "2");
    AddWorkspace("chat", "3");
    AddWorkspace("plover", "4");
    AddWorkspace("docs", "5");
    AddWorkspace("device", "6");
    AddWorkspace("one", "7");
    AddWorkspace("two", "8");
    AddWorkspace("three", "9");

    // Load routes and filters from ~/Atelier/workspaces/*.json
    var workspacePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Atelier", "workspaces");
    var workspaceNames = new Dictionary<int, string>
    {
        { 1, "terminal" }, { 2, "web" }, { 3, "chat" }, { 4, "plover" }, { 5, "docs" },
        { 6, "device" }, { 7, "one" }, { 8, "two" }, { 9, "three" }
    };

    for (int i = 1; i <= 9; i++)
    {
        var jsonFile = Path.Combine(workspacePath, $"{i}.json");
        if (!File.Exists(jsonFile)) continue;
        try
        {
            var routes = JsonSerializer.Deserialize<JsonElement>(File.ReadAllText(jsonFile));
            if (routes.ValueKind != JsonValueKind.Array) continue;
            foreach (var route in routes.EnumerateArray())
            {
                string app = route.GetProperty("app").GetString();
                string wsName = workspaceNames[i];
                switch (route.GetProperty("type").GetString())
                {
                    case "process":
                        context.RouterManager.AddProcessFileNameRoute(app.EndsWith(".exe") ? app : $"{app}.exe", workspaces[wsName]);
                        break;
                    case "class":
                        context.RouterManager.AddWindowClassRoute(app, workspaces[wsName]);
                        break;
                    case "title":
                        context.RouterManager.AddTitleMatchRoute(app, workspaces[wsName]);
                        break;
                }
            }
        }
        catch (Exception ex) { Console.WriteLine($"Error loading routes from {jsonFile}: {ex.Message}"); }
    }

    var filtersFile = Path.Combine(workspacePath, "filters.json");
    if (File.Exists(filtersFile))
    {
        try
        {
            var filters = JsonSerializer.Deserialize<JsonElement>(File.ReadAllText(filtersFile));
            if (filters.ValueKind == JsonValueKind.Array)
            {
                foreach (var filter in filters.EnumerateArray())
                {
                    string app = filter.GetProperty("app").GetString();
                    switch (filter.GetProperty("type").GetString())
                    {
                        case "process":
                            string pn = app.EndsWith(".exe") ? app : $"{app}.exe";
                            context.FilterManager.AddTitleMatchFilter(pn);
                            context.FilterManager.AddWindowClassFilter(pn);
                            context.FilterManager.AddProcessFileNameFilter(pn);
                            break;
                        case "class":
                        case "title":
                            context.FilterManager.AddTitleMatchFilter(app);
                            context.FilterManager.AddWindowClassFilter(app);
                            context.FilterManager.AddProcessFileNameFilter(app);
                            break;
                    }
                }
            }
        }
        catch (Exception ex) { Console.WriteLine($"Error loading filters from {filtersFile}: {ex.Message}"); }
    }

    // Close active window
    // https://github.com/urob/whim-config/blob/3387b154edadf384271c90d2ed75a90c10e53790/whim.commands.csx
    context.CommandManager.Add(
        identifier: "close_window",
        title: "Close focused window",
        callback: () => context.WorkspaceManager.ActiveWorkspace.LastFocusedWindow.Close()
    );

    // Activate next workspace, skipping over those that are active on other monitors
    context.CommandManager.Add(
        identifier: "activate_previous_workspace",
        title: "Activate the previous inactive workspace",
        callback: () => context.Store.Dispatch(new ActivateAdjacentWorkspaceTransform(Reverse: true, SkipActive: true))
    );

    // Activate previous workspace, skipping over those that are active on other monitors
    context.CommandManager.Add(
        identifier: "activate_next_workspace",
        title: "Activate the next inactive workspace",
        callback: () => context.Store.Dispatch(new ActivateAdjacentWorkspaceTransform(SkipActive: true))
    );

    // // Activate monitor by index
    // var MAXIMUM_MONITORS = 4;
    // for(int i = 1; i <= MAXIMUM_MONITORS; i++)
    // {
    //     context.CommandManager.Add(
    //         identifier: $"activate_monitor_{i}",
    //         title: $"Activate monitor {i}",
    //         callback: () => {
    //             if (!context.Store.Pick(Pickers.PickMonitorByIndex(0)).TryGet(out IMonitor monitor))
    //             {
    //                 return;
    //             }
    //             if (!context.Store.Pick(Pickers.PickWorkspaceByMonitor(monitor.Handle)).TryGet(out IWorkspace workspace))
    //             {
    //                 return;
    //             }
    //             context.Store.Dispatch(new FocusWorkspaceTransform(workspace.Id));
    //         }
    //     );
    // }

    // Loop approach didn't work?? Let's do it this way instead.
    context.CommandManager.Add(
        identifier: $"activate_monitor_1",
        title: $"Activate monitor 1",
        callback: () => {
            if (!context.Store.Pick(Pickers.PickMonitorByIndex(0)).TryGet(out IMonitor monitor)) return;
            if (!context.Store.Pick(Pickers.PickWorkspaceByMonitor(monitor.Handle)).TryGet(out IWorkspace workspace)) return;
            context.Store.Dispatch(new FocusWorkspaceTransform(workspace.Id));
        }
    );
    context.CommandManager.Add(
        identifier: $"activate_monitor_2",
        title: $"Activate monitor 2",
        callback: () => {
            if (!context.Store.Pick(Pickers.PickMonitorByIndex(1)).TryGet(out IMonitor monitor)) return;
            if (!context.Store.Pick(Pickers.PickWorkspaceByMonitor(monitor.Handle)).TryGet(out IWorkspace workspace)) return;
            context.Store.Dispatch(new FocusWorkspaceTransform(workspace.Id));
        }
    );
    context.CommandManager.Add(
        identifier: $"activate_monitor_3",
        title: $"Activate monitor 3",
        callback: () => {
            if (!context.Store.Pick(Pickers.PickMonitorByIndex(2)).TryGet(out IMonitor monitor)) return;
            if (!context.Store.Pick(Pickers.PickWorkspaceByMonitor(monitor.Handle)).TryGet(out IWorkspace workspace)) return;
            context.Store.Dispatch(new FocusWorkspaceTransform(workspace.Id));
        }
    );

    // Modifiers
    KeyModifiers mod1 = KeyModifiers.LAlt;
    KeyModifiers mod2 = KeyModifiers.LAlt | KeyModifiers.LShift;

    void Bind(KeyModifiers mod, string key, string cmd)
    {
        VIRTUAL_KEY vk = (VIRTUAL_KEY)Enum.Parse(typeof(VIRTUAL_KEY), "VK_" + key);
        context.KeybindManager.SetKeybind(cmd, new Keybind(mod, vk));
    }

    Bind(mod1, "X", "whim.custom.close_window");
    Bind(mod1, "H", "whim.core.focus_window_in_direction.left");
    Bind(mod1, "L", "whim.core.focus_window_in_direction.right");
    Bind(mod1, "K", "whim.core.focus_window_in_direction.up");
    Bind(mod1, "J", "whim.core.focus_window_in_direction.down");

    // Monitor selection based on plover AOEU placement
    // I like 1 based monitor indexing
    Bind(mod1, "A", "whim.custom.activate_monitor_1");
    Bind(mod1, "O", "whim.custom.activate_monitor_2");
    Bind(mod1, "E", "whim.custom.activate_monitor_3");
    // Bind(mod1, "U", "whim.custom.activate_monitor_4");
}

// We return doConfig here so that Whim can call it when it loads.
return DoConfig;
