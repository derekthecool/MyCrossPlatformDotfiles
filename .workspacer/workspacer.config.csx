// #r "C:\Users\dlomax\scoop\apps\workspacer\current\workspacer.Shared.dll"
// #r "C:\Users\dlomax\scoop\apps\workspacer\current\plugins\workspacer.Bar\workspacer.Bar.dll"
// #r "C:\Users\dlomax\scoop\apps\workspacer\current\plugins\workspacer.Gap\workspacer.Gap.dll"
// #r "C:\Users\dlomax\scoop\apps\workspacer\current\plugins\workspacer.TitleBar\workspacer.TitleBar.dll"
// #r "C:\Users\dlomax\scoop\apps\workspacer\current\plugins\workspacer.ActionMenu\workspacer.ActionMenu.dll"
// #r "C:\Users\dlomax\scoop\apps\workspacer\current\plugins\workspacer.FocusIndicator\workspacer.FocusIndicator.dll"

#r "C:\Program Files\workspacer\workspacer.Shared.dll"
#r "C:\Program Files\workspacer\plugins\workspacer.Bar\workspacer.Bar.dll"
#r "C:\Program Files\workspacer\plugins\workspacer.Gap\workspacer.Gap.dll"
#r "C:\Program Files\workspacer\plugins\workspacer.TitleBar\workspacer.TitleBar.dll"
#r "C:\Program Files\workspacer\plugins\workspacer.ActionMenu\workspacer.ActionMenu.dll"
#r "C:\Program Files\workspacer\plugins\workspacer.FocusIndicator\workspacer.FocusIndicator.dll"

using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.IO;

using workspacer;
using workspacer.Bar;
using workspacer.Bar.Widgets;
using workspacer.ActionMenu;
using workspacer.FocusIndicator;
using workspacer.Gap;
using workspacer.TitleBar;

public static class MyWorkSpaceNames
{
    public static string Terminal = "🛠️";
    public static string Web = "🕸️";
    public static string Chat = "💬";
    public static string Plover = "⌨️";
    public static string Docs = "📄";
    public static string Device = "📞";
    public static string PlusOne = "7";
    public static string PlusTwo = "8";
    public static string PlusThree = "9";
}

return new Action<IConfigContext>((IConfigContext context) =>
{
    // Set higher logging than default
    context.ConsoleLogLevel = LogLevel.Debug;
    context.FileLogLevel = LogLevel.Warn;

    // Variables
    var fontSize = 15;
    var barHeight = 25;
    var fontName = "Hack NF";
    var background = new Color(0x33, 0x33, 0x33);

    // false by default
    context.CanMinimizeWindows = false;

    // Gap
    var gap = 2;
    context.AddGap(
        new GapPluginConfig()
        {
            InnerGap = gap,
            OuterGap = gap / 2,
            Delta = gap / 2,
        }
    );

    // TitleBar
    var titleBarPluginConfig = new TitleBarPluginConfig(new TitleBarStyle(showTitleBar: false, showSizingBorder: false));
    context.AddTitleBar(titleBarPluginConfig);

    // Bar
    context.AddBar(new BarPluginConfig()
    {
        FontSize = fontSize,
        BarHeight = barHeight,
        FontName = fontName,
        DefaultWidgetBackground = background,
        LeftWidgets = () => new IBarWidget[]
        {
            new WorkspaceWidget(),
            new TextWidget(":"),
            new TitleWidget() {
                IsShortTitle = true,
            }
        },
        RightWidgets = () => new IBarWidget[]
        {
            new FocusedMonitorWidget(),
            new ActiveLayoutWidget(),
        }
    });

    // Bar focus indicator
    context.AddFocusIndicator(
        new FocusIndicatorPluginConfig()
        {
            BorderColor = new Color(0x79, 0xf7, 0x7f),
            BorderSize = 15,
            TimeToShow = 700,
        });

    // Default layouts
    Func<ILayoutEngine[]> defaultLayouts = () => new ILayoutEngine[]
    {
        new TallLayoutEngine(),
        new VertLayoutEngine(),
        new HorzLayoutEngine(),
        new FullLayoutEngine(),
    };

    context.DefaultLayouts = defaultLayouts;

    // Array of workspace names and their layouts
    (string, ILayoutEngine[])[] workspaces =
    {
        (MyWorkSpaceNames.Terminal, new ILayoutEngine[] {  new TallLayoutEngine(), new FullLayoutEngine() }),
        (MyWorkSpaceNames.Web, new ILayoutEngine[] { new TallLayoutEngine(), new FullLayoutEngine() }),
        (MyWorkSpaceNames.Chat, new ILayoutEngine[] {  new TallLayoutEngine(), new FullLayoutEngine() }),
        (MyWorkSpaceNames.Plover, new ILayoutEngine[] { new TallLayoutEngine(), new FullLayoutEngine() }),
        (MyWorkSpaceNames.Docs, defaultLayouts()),
        (MyWorkSpaceNames.Device, defaultLayouts()),
        (MyWorkSpaceNames.PlusOne, defaultLayouts()),
        (MyWorkSpaceNames.PlusTwo, defaultLayouts()),
        (MyWorkSpaceNames.PlusThree, defaultLayouts()),
    };

    foreach ((string name, ILayoutEngine[] layouts) in workspaces)
    {
        context.WorkspaceContainer.CreateWorkspace(name, layouts);
    }

    // Tips for finding window information:
    // Ideally you can use the workspacer debug window, however this has not
    // been working for me lately as of 2023.
    // There is AHK window spy as well
    // Or you can use an application named winspy, 'scoop install winspy' to get it

    // Routes: automatically send opened applications to the specified workspace
    // Terminal applications
    context.WindowRouter.RouteTitle("Email", MyWorkSpaceNames.Chat); // thunderbird neovim terminal
    context.WindowRouter.RouteProcessName("alacritty", MyWorkSpaceNames.Terminal);
    context.WindowRouter.RouteProcessName("wezterm-gui", MyWorkSpaceNames.Terminal);
    // context.WindowRouter.RouteWindowClass("org.wezfurlong.wezterm", MyWorkSpaceNames.Terminal);
    // Terminal catch all
    // context.WindowRouter.RouteWindowClass("ConsoleWindowClass", MyWorkSpaceNames.Terminal);

    // Visual Studio
    context.WindowRouter.RouteProcessName("devenv", MyWorkSpaceNames.Terminal);

    // Remote desktop
    context.WindowRouter.RouteProcessName("mstsc", MyWorkSpaceNames.PlusOne);

    // Web browsers
    context.WindowRouter.RouteProcessName("Vieb", MyWorkSpaceNames.Web);
    context.WindowRouter.RouteProcessName("firefox", MyWorkSpaceNames.Web);
    // I do not like chrome but often use it for development purposes, it has a
    // class of "Chrome_WidgetWin_1". But this is not too good to use because so
    // many electron applications use this as well.
    // Send this to the last tab
    context.WindowRouter.RouteProcessName("chrome", MyWorkSpaceNames.PlusThree);

    // Chat apps
    // Old teams
    context.WindowRouter.RouteProcessName("Teams", MyWorkSpaceNames.Chat);
    // New teams released 2023
    context.WindowRouter.RouteWindowClass("TeamsWebView", MyWorkSpaceNames.Chat);
    context.WindowRouter.RouteProcessName("thunderbird", MyWorkSpaceNames.Chat);

    // WSL gui applications, mainly for zathura PDF viewer
    context.WindowRouter.RouteProcessName("vcxsrv", MyWorkSpaceNames.Docs);
    // Okular PDF viewer
    context.WindowRouter.RouteProcessName("okular", MyWorkSpaceNames.Docs);
    // Love 2D windows
    context.WindowRouter.RouteProcessName("love", MyWorkSpaceNames.Docs);

    // Documents
    context.WindowRouter.RouteProcessName("Obsidian", MyWorkSpaceNames.Docs);
    context.WindowRouter.RouteProcessName("WINWORD", MyWorkSpaceNames.Docs);
    context.WindowRouter.RouteProcessName("EXCEL", MyWorkSpaceNames.Docs);
    context.WindowRouter.RouteProcessName("POWERPNT", MyWorkSpaceNames.Docs);
    context.WindowRouter.RouteProcessName("explorer", MyWorkSpaceNames.Docs);

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

    // Action menu
    var actionMenu = context.AddActionMenu(new ActionMenuPluginConfig()
    {
        RegisterKeybind = false,
        MenuHeight = barHeight,
        FontSize = fontSize,
        FontName = fontName,
        Background = background,
    });

    // Action menu builder
    Func<ActionMenuItemBuilder> createActionMenuBuilder = () =>
    {
        var menuBuilder = actionMenu.Create();

        // Switch to workspace
        menuBuilder.AddMenu("switch", () =>
        {
            var workspaceMenu = actionMenu.Create();
            var monitor = context.MonitorContainer.FocusedMonitor;
            var workspaces = context.WorkspaceContainer.GetWorkspaces(monitor);

            Func<int, Action> createChildMenu = (workspaceIndex) => () =>
            {
                context.Workspaces.SwitchMonitorToWorkspace(monitor.Index, workspaceIndex);
            };

            int workspaceIndex = 0;
            foreach (var workspace in workspaces)
            {
                workspaceMenu.Add(workspace.Name, createChildMenu(workspaceIndex));
                workspaceIndex++;
            }

            return workspaceMenu;
        });

        // Move window to workspace
        menuBuilder.AddMenu("move", () =>
        {
            var moveMenu = actionMenu.Create();
            var focusedWorkspace = context.Workspaces.FocusedWorkspace;

            var workspaces = context.WorkspaceContainer.GetWorkspaces(focusedWorkspace).ToArray();
            Func<int, Action> createChildMenu = (index) => () => { context.Workspaces.MoveFocusedWindowToWorkspace(index); };

            for (int i = 0; i < workspaces.Length; i++)
            {
                moveMenu.Add(workspaces[i].Name, createChildMenu(i));
            }

            return moveMenu;
        });

        // Create workspace
        menuBuilder.AddFreeForm("create workspace", (name) =>
        {
            context.WorkspaceContainer.CreateWorkspace(name);
        });

        // Delete focused workspace
        menuBuilder.Add("close", () =>
        {
            context.WorkspaceContainer.RemoveWorkspace(context.Workspaces.FocusedWorkspace);
        });

        // Workspacer
        menuBuilder.Add("toggle keybind helper", () => context.Keybinds.ShowKeybindDialog());
        menuBuilder.Add("toggle enabled", () => context.Enabled = !context.Enabled);
        menuBuilder.Add("restart", () => context.Restart());
        menuBuilder.Add("quit", () => context.Quit());
        menuBuilder.Add("Derek Test Print", () => Console.WriteLine("Derek was here!"));
        menuBuilder.Add("Derek Test Print1", () => Console.Error.WriteLine("Derek was here!"));

        return menuBuilder;
    };
    var actionMenuBuilder = createActionMenuBuilder();

    // Keybindings
    // Disable all my custom bindings for now
    Action setKeybindings = () =>
    {

        KeyModifiers mod = KeyModifiers.Alt;
        context.Keybinds.UnsubscribeAll();

        // J & K movements
        context.Keybinds.Subscribe(mod, Keys.J, () => context.Workspaces.FocusedWorkspace.FocusNextWindow(), "focus next window");
        context.Keybinds.Subscribe(mod, Keys.K, () => context.Workspaces.FocusedWorkspace.FocusPreviousWindow(), "focus previous window");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.J, () => context.Workspaces.FocusedWorkspace.SwapFocusAndNextWindow(), "swap focus and next window");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.K, () => context.Workspaces.FocusedWorkspace.SwapFocusAndPreviousWindow(), "swap focus and previous window");

        // Mouse movements
        context.Keybinds.Subscribe(MouseEvent.LButtonDown, () => context.Workspaces.SwitchFocusedMonitorToMouseLocation());

        // Punctuation commands
        context.Keybinds.Subscribe(mod, Keys.Oemcomma, () => context.Workspaces.FocusedWorkspace.IncrementNumberOfPrimaryWindows(), "increment # primary windows");
        context.Keybinds.Subscribe(mod, Keys.OemPeriod, () => context.Workspaces.FocusedWorkspace.DecrementNumberOfPrimaryWindows(), "decrement # primary windows");
        context.Keybinds.Subscribe(mod, Keys.Oemtilde, () => context.Workspaces.SwitchToLastFocusedWorkspace(), "switch to last focused workspace");

        // Show keybind map
        context.Keybinds.Subscribe(mod, Keys.S, () => context.Keybinds.ShowKeybindDialog(), "toggle keybind window");

        // Non letter or punctuation commands
        context.Keybinds.Subscribe(mod, Keys.Space, () => context.Workspaces.FocusedWorkspace.NextLayoutEngine(), "next layout");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.Space, () => context.Workspaces.FocusedWorkspace.PreviousLayoutEngine(), "previous layout");
        context.Keybinds.Subscribe(mod, Keys.Escape, () => context.Enabled = !context.Enabled, "toggle enable/disable");
        //context.Keybinds.Subscribe(mod, Keys.Enter, () => context.Workspaces.FocusedWorkspace.SwapFocusAndPrimaryWindow(), "swap focus and primary window");

        context.Keybinds.Subscribe(mod, Keys.X, () => context.Workspaces.FocusedWorkspace.CloseFocusedWindow(), "close focused window");
        context.Keybinds.Subscribe(mod, Keys.N, () => context.Workspaces.FocusedWorkspace.ResetLayout(), "reset layout");
        context.Keybinds.Subscribe(mod, Keys.M, () => context.Workspaces.FocusedWorkspace.FocusPrimaryWindow(), "focus primary window");
        context.Keybinds.Subscribe(mod, Keys.H, () => context.Workspaces.FocusedWorkspace.ShrinkPrimaryArea(), "shrink primary area");
        context.Keybinds.Subscribe(mod, Keys.L, () => context.Workspaces.FocusedWorkspace.ExpandPrimaryArea(), "expand primary area");
        context.Keybinds.Subscribe(mod, Keys.T, () => context.Windows.ToggleFocusedWindowTiling(), "toggle tiling for focused window");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.Q, context.Quit, "quit workspacer");
        context.Keybinds.Subscribe(mod, Keys.Q, context.Restart, "restart workspacer");

        // Open action menu
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.I, () => actionMenu.ShowMenu(actionMenuBuilder), "show action menu");
        // mod + I == Windows Power Toys launcher (external program, not part of workspacer)

        // Go to previous workspaces
        // Use the steno s for left and r for right
        // context.Keybinds.Subscribe(mod, Keys.S, () => context.Workspaces.SwitchToPreviousWorkspace(), "switch to previous workspace");
        // context.Keybinds.Subscribe(mod, Keys.R, () => context.Workspaces.SwitchToNextWorkspace(), "switch to next workspace");
        // context.Keybinds.Subscribe(mod | KeyModifiers.Control, Keys.S, () => context.Workspaces.MoveFocusedWindowAndSwitchToPreviousWorkspace(), "move window to previous workspace and switch to it");
        // context.Keybinds.Subscribe(mod | KeyModifiers.Control, Keys.R, () => context.Workspaces.MoveFocusedWindowAndSwitchToNextWorkspace(), "move window to next workspace and switch to it");

        // Jump to specific monitors
        // Use the steno vowels: AOEU for index
        context.Keybinds.Subscribe(mod, Keys.A, () => context.Workspaces.SwitchFocusedMonitor(0), "focus monitor 1");
        context.Keybinds.Subscribe(mod, Keys.O, () => context.Workspaces.SwitchFocusedMonitor(1), "focus monitor 2");
        context.Keybinds.Subscribe(mod, Keys.E, () => context.Workspaces.SwitchFocusedMonitor(2), "focus monitor 3");
        context.Keybinds.Subscribe(mod, Keys.U, () => context.Workspaces.SwitchFocusedMonitor(3), "focus monitor 4");

        // // Send app to specific monitor -- I've never used this and now it
        // // conflicts with the new teams shortcuts to start calls
        // // Use the steno vowels: AOEU for index
        // context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.A, () => context.Workspaces.MoveFocusedWindowToMonitor(0), "move focused window to monitor 1");
        // context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.O, () => context.Workspaces.MoveFocusedWindowToMonitor(1), "move focused window to monitor 2");
        // context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.E, () => context.Workspaces.MoveFocusedWindowToMonitor(2), "move focused window to monitor 3");
        // context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.U, () => context.Workspaces.MoveFocusedWindowToMonitor(3), "move focused window to monitor 4");

        // Access workspace indexes
        context.Keybinds.Subscribe(mod, Keys.D1, () => context.Workspaces.SwitchToWorkspace(0), "switch to workspace 1");
        context.Keybinds.Subscribe(mod, Keys.D2, () => context.Workspaces.SwitchToWorkspace(1), "switch to workspace 2");
        context.Keybinds.Subscribe(mod, Keys.D3, () => context.Workspaces.SwitchToWorkspace(2), "switch to workspace 3");
        context.Keybinds.Subscribe(mod, Keys.D4, () => context.Workspaces.SwitchToWorkspace(3), "switch to workspace 4");
        context.Keybinds.Subscribe(mod, Keys.D5, () => context.Workspaces.SwitchToWorkspace(4), "switch to workspace 5");
        context.Keybinds.Subscribe(mod, Keys.D6, () => context.Workspaces.SwitchToWorkspace(5), "switch to workspace 6");
        context.Keybinds.Subscribe(mod, Keys.D7, () => context.Workspaces.SwitchToWorkspace(6), "switch to workspace 7");
        context.Keybinds.Subscribe(mod, Keys.D8, () => context.Workspaces.SwitchToWorkspace(7), "switch to workspace 8");
        context.Keybinds.Subscribe(mod, Keys.D9, () => context.Workspaces.SwitchToWorkspace(8), "switch to workpsace 9");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D1, () => context.Workspaces.MoveFocusedWindowToWorkspace(0), "switch focused window to workspace 1");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D2, () => context.Workspaces.MoveFocusedWindowToWorkspace(1), "switch focused window to workspace 2");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D3, () => context.Workspaces.MoveFocusedWindowToWorkspace(2), "switch focused window to workspace 3");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D4, () => context.Workspaces.MoveFocusedWindowToWorkspace(3), "switch focused window to workspace 4");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D5, () => context.Workspaces.MoveFocusedWindowToWorkspace(4), "switch focused window to workspace 5");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D6, () => context.Workspaces.MoveFocusedWindowToWorkspace(5), "switch focused window to workspace 6");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D7, () => context.Workspaces.MoveFocusedWindowToWorkspace(6), "switch focused window to workspace 7");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D8, () => context.Workspaces.MoveFocusedWindowToWorkspace(7), "switch focused window to workspace 8");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D9, () => context.Workspaces.MoveFocusedWindowToWorkspace(8), "switch focused window to workspace 9");

        // Debug terminal
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.D, () => context.Windows.DumpWindowDebugOutput(), "dump debug info to console for all windows");
        context.Keybinds.Subscribe(mod, Keys.D, () => context.Windows.DumpWindowDebugOutputForFocusedWindow(), "dump debug info to console for current window");
        context.Keybinds.Subscribe(mod | KeyModifiers.LShift, Keys.G, () => context.Windows.DumpWindowUnderCursorDebugOutput(), "dump debug info to console for window under cursor");
        context.Keybinds.Subscribe(mod, Keys.G, () => context.ToggleConsoleWindow(), "toggle debug console");

    };
    setKeybindings();
});
// vim:ft=cs
