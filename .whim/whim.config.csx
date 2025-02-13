#nullable enable
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\whim.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.Bar\Whim.Bar.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.CommandPalette\Whim.CommandPalette.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.FloatingWindow\Whim.FloatingWindow.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.FocusIndicator\Whim.FocusIndicator.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.Gaps\Whim.Gaps.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.LayoutPreview\Whim.LayoutPreview.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.SliceLayout\Whim.SliceLayout.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.TreeLayout\Whim.TreeLayout.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.TreeLayout.Bar\Whim.TreeLayout.Bar.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.TreeLayout.CommandPalette\Whim.TreeLayout.CommandPalette.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.Updater\Whim.Updater.dll"
#r "C:\Users\dlomax\AppData\Local\Programs\Whim\plugins\Whim.Yaml\Whim.Yaml.dll"


using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
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

/// <summary>
/// This is what's called when Whim is loaded.
/// </summary>
/// <param name="context"></param>
void DoConfig(IContext context)
{
	context.Logger.Config = new LoggerConfig();

	// YAML config. It's best to load this first so that you can use it in your C# config.
	YamlLoader.Load(context);

	// Customize your config in C# here.
	// For more, see https://dalyisaac.github.io/Whim/script/scripting.html
	// ...
    //
    // Example configs
    // https://github.com/formesean/configs/blob/d076ef27e74898b31e511126c9b01b0a34d2649c/whim/whim.config.csx#L4
    // https://github.com/urob/whim-config/blob/3387b154edadf384271c90d2ed75a90c10e53790/whim.config.csx#L4

    // TODO: (Derek Lomax) 2/6/2025 4:17:02 PM, this command was not working right away
    // // Create the command.
    // context.CommandManager.Add(
    //     // Automatically namespaced to `whim.custom`.
    //     identifier: "close_window",
    //     title: "Close focused window",
    //     callback: () =>
    //     {
    //         if (context.Store.Pick(Pickers.PickLastFocusedWindow).TryGet(out IWindow window))
    //         {
    //             window.Close();
    //         }
    //     }
    // );
    //
    // // Create an associated keybind.
    // // context.KeybindManager.SetKeybind("whim.custom.close_window", new Keybind(IKeybind.Alt, VIRTUAL_KEY.VK_X));

    Dictionary<string, string> workspaces = new Dictionary<string, string>();
    void AddWorkspace(string name, string icon) {
        workspaces.Add(name, icon);
        context.WorkspaceManager.Add(icon);
    }

    AddWorkspace("terminal", "🛠️");
    AddWorkspace("web", "🏄");
    AddWorkspace("chat", "💬");
    AddWorkspace("plover", "⌨️");
    AddWorkspace("docs", "📄");
    AddWorkspace("device", "📞");
    AddWorkspace("one", "7");
    AddWorkspace("two", "8");
    AddWorkspace("three", "9");

    // // Set up layout engines.
    // // TODO: (Derek Lomax) 2/11/2025 9:52:34 AM, not working from website guide
    // context.Store.Dispatch(
    //     new SetCreateLayoutEnginesTransform(
    //         () => new CreateLeafLayoutEngine[]
    //         {
    //             (id) => SliceLayouts.CreatePrimaryStackLayout(context, sliceLayoutPlugin, id),
    //             (id) => new TreeLayoutEngine(context, treeLayoutPlugin, id)
    //         }
    //     )
    // );


    // Plover
    context.RouterManager.AddProcessFileNameRoute("pythonw", workspaces["plover"]);

    // // https://dalyisaac.github.io/Whim/script/core/filtering.html?q=filter
    // context.FilterManager.AddTitleMatchFilter(".*Plover: Lookup.*");
    // context.FilterManager.AddTitleMatchFilter(".*Plover: Add Translation.*");

    new List<string> {
        "keypirinha_wndcls_run",
        ".*Plover: Lookup.*",
        ".*Plover: Add Translation.*"
    }
    .ForEach(program => {
            context.FilterManager.AddTitleMatchFilter(program);
            context.FilterManager.AddWindowClassFilter(program);
            }
            );

    context.RouterManager.AddProcessFileNameRoute("firefox.exe", workspaces["web"]);

    // Tips for finding window information:
    // Ideally you can use the workspacer debug window, however this has not
    // been working for me lately as of 2023.
    // There is AHK window spy as well
    // Or you can use an application named winspy, 'scoop install winspy' to get it

    // {{{ Routes
    new List<string> { "wezterm-gui", "alacritty", "devenv" }
    .ForEach(program => context.RouterManager.AddProcessFileNameRoute(program, workspaces["terminal"]));

    // Chat
    new List<string> { "TeamsWebView" }
    .ForEach(program => context.RouterManager.AddWindowClassRoute(program, workspaces["chat"]));

   void Route(List<string> programs, string workspace)
    {
         foreach(var program in programs)
         {
             context.RouterManager.AddProcessFileNameRoute($"{program}.exe", workspaces[workspace]);
         }
    }

    // Docs and music
    var docs_programs = new List<string> {
        "vcxsrv",
        "love",
        "Obsidian",
        "WINWORD",
        "EXCEL",
        "POWERPNT",
        "explorer",
        "okular",
        "MusicBee",
    };

    var one_programs = new List<string> {
        "wsl-usb-gui",
        // Windows device manager
        "mmc",
        // Remote desktop
        "mstsc",
    };

    // three programs
    var three_programs = new List<string> {
        "ConsoleWindowClass",
    };

    Route(docs_programs, "docs");
    Route(one_programs, "one");


    // }}}

    /*
    // context.RouterManager.AddProcessFileNameRoute("TIDAL.exe", workspaces["other"]);
    //
    // Web browsers
    context.WindowRouter.RouteProcessName("Vieb", MyWorkSpaceNames.Web);
    context.WindowRouter.RouteProcessName("firefox", MyWorkSpaceNames.Web);
    // I do not like chrome but often use it for development purposes, it has a
    // class of "Chrome_WidgetWin_1". But this is not too good to use because so
    // many electron applications use this as well.
    // Send this to the last tab
    context.WindowRouter.RouteProcessName("chrome", MyWorkSpaceNames.PlusThree);

    // QXDM
    context.WindowRouter.RouteProcessName("QXDM", MyWorkSpaceNames.PlusOne);

    // Plover stenography: use the RouteWindowClass instead to move all windows
    context.WindowRouter.RouteProcessName("pythonw", MyWorkSpaceNames.Plover);
    // context.WindowRouter.RouteWindowClass("Qt5152QWindowIcon", MyWorkSpaceNames.Plover);

    // Route my applications
    context.WindowRouter.RouteProcessName("BelleLTE_DataLogger", MyWorkSpaceNames.Device);
    // All versions of the "Belle LTE Utility", not sure how to do a regex on process names
    // context.WindowRouter.RouteWindowClass("#32770", MyWorkSpaceNames.Device);

    // My apps using Avalonia TODO: find a way to get a regex in process name
    context.WindowRouter.RouteProcessName("BelleDealerAudioInterface.Desktop", MyWorkSpaceNames.PlusTwo);
    context.WindowRouter.RouteWindowClass("Avalonia-eeffded2-1696-4c6b-b5c5-596e477cd4c5", MyWorkSpaceNames.PlusTwo);
    context.WindowRouter.RouteProcessName("FreeusSerialLogger", MyWorkSpaceNames.PlusTwo);
    context.WindowRouter.RouteTitle("FotaRemoteAdd", MyWorkSpaceNames.Device);

    // Application development with flutter
    context.WindowRouter.RouteWindowClass("FLUTTERVIEW", MyWorkSpaceNames.Chat);

    // When debugging dotnet applications in neovim, it opens a useless external terminal
    context.WindowRouter.RouteProcessName("dotnet", MyWorkSpaceNames.PlusThree);
    context.WindowRouter.RouteTitle(@"C:\Program Files\dotnet\dotnet.exe", MyWorkSpaceNames.PlusThree);
    context.WindowRouter.RouteProcessName("WindowsTerminal", MyWorkSpaceNames.PlusThree);

    // Wireshark
    context.WindowRouter.RouteProcessName("Wireshark", MyWorkSpaceNames.PlusThree);

    // Zoom and Teams video calls
    context.WindowRouter.RouteProcessName("Zoom", MyWorkSpaceNames.PlusOne);

    // My applications do not get tiled when run as admin
    context.WindowRouter.RouteProcessName("Wallaby_Tool", MyWorkSpaceNames.Device);
    context.WindowRouter.RouteProcessName("BelleX_Server", MyWorkSpaceNames.Device);
    context.WindowRouter.RouteProcessName("Quokka Companion", MyWorkSpaceNames.Device);
    context.WindowRouter.RouteProcessName("BelleX_DealerTool", MyWorkSpaceNames.Device);
    // The title of glow window appears in all of my WPF apps
    context.WindowRouter.RouteTitle("GlowWindow", MyWorkSpaceNames.Device);

    // Filters: Filters will stop a window from being tiled or routed
    // Micron device firmware update tool
    context.WindowRouter.AddFilter((window) => !window.Title.Contains("Upgrade_Tool"));
    context.WindowRouter.AddFilter((window) => !window.Class.Contains("TMainWindow"));
    context.WindowRouter.AddFilter((window) => !window.Class.Contains("TApplication"));

    // Plover windows that need to remain floating
    context.WindowRouter.AddFilter((window) => !window.Title.Contains("Plover: Lookup"));
    context.WindowRouter.AddFilter((window) => !window.Title.Contains("Plover: Add Translation"));

    // Windows Screen Snipper
    context.WindowRouter.AddFilter((window) => !window.Title.Contains("Screen Snipping"));

    // Any connect client cisco
    context.WindowRouter.AddFilter((window) => !window.Title.Contains("Cisco AnyConnect"));
    // context.WindowRouter.AddFilter((window) => !window.Title.Contains("Cisco AnyConnect Secure Mobility Client"));
    // context.WindowRouter.AddFilter((window) => !window.Title.Contains("Cisco AnyConnect Login"));

    // Odd items that have exe of explorer but are actually web applications
    // These are items like teams authentication sign in, azure cli sign in etc.
    context.WindowRouter.AddFilter((window) => !window.Class.Contains("ApplicationFrameWindow"));
      */

    // Close active window
    // https://github.com/urob/whim-config/blob/3387b154edadf384271c90d2ed75a90c10e53790/whim.commands.csx
    context.CommandManager.Add(
        identifier: "close_window",
        title: "Close focused window",
        callback: () => context.WorkspaceManager.ActiveWorkspace.LastFocusedWindow.Close()
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
}

// We return doConfig here so that Whim can call it when it loads.
return DoConfig;
