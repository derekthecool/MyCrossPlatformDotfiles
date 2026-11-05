#nullable enable
#r "C:\Program Files\Whim\whim.dll"
#r "C:\Program Files\Whim\plugins\Whim.Bar\Whim.Bar.dll"
#r "C:\Program Files\Whim\plugins\Whim.CommandPalette\Whim.CommandPalette.dll"
#r "C:\Program Files\Whim\plugins\Whim.FloatingWindow\Whim.FloatingWindow.dll"
#r "C:\Program Files\Whim\plugins\Whim.FocusIndicator\Whim.FocusIndicator.dll"
#r "C:\Program Files\Whim\plugins\Whim.Gaps\Whim.Gaps.dll"
#r "C:\Program Files\Whim\plugins\Whim.LayoutPreview\Whim.LayoutPreview.dll"
#r "C:\Program Files\Whim\plugins\Whim.SliceLayout\Whim.SliceLayout.dll"
#r "C:\Program Files\Whim\plugins\Whim.Updater\Whim.Updater.dll"
#r "C:\Program Files\Whim\plugins\Whim.Yaml\Whim.Yaml.dll"

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
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
using Whim.Updater;
using Whim.Yaml;
using Windows.Win32.UI.Input.KeyboardAndMouse;

// Brave/Chrome run all profiles in a single shared process once you switch profiles from the
// in-app avatar menu (ProcessId is identical across profile windows), so the only per-window
// signal that distinguishes them is the AppUserModelID the taskbar uses to group them separately.
internal static class AppUserModelIdHelper
{
    [DllImport("shell32.dll")]
    private static extern int SHGetPropertyStoreForWindow(IntPtr hwnd, ref Guid riid, out IPropertyStore? propertyStore);

    [ComImport, Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore
    {
        int GetCount(out uint cProps);
        int GetAt(uint iProp, out PROPERTYKEY pkey);
        int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        int SetValue(ref PROPERTYKEY key, ref PROPVARIANT pv);
        int Commit();
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROPERTYKEY
    {
        public Guid fmtid;
        public uint pid;
        public PROPERTYKEY(Guid g, uint p) { fmtid = g; pid = p; }
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct PROPVARIANT
    {
        public ushort vt;
        public ushort wReserved1, wReserved2, wReserved3;
        public IntPtr p;
        public int p2;
    }

    private static readonly PROPERTYKEY PKEY_AppUserModel_ID =
        new(new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), 5);

    public static string? GetAppUserModelId(IntPtr hwnd)
    {
        try
        {
            Guid iid = typeof(IPropertyStore).GUID;
            if (SHGetPropertyStoreForWindow(hwnd, ref iid, out IPropertyStore? store) != 0 || store is null)
                return null;

            PROPERTYKEY key = PKEY_AppUserModel_ID;
            if (store.GetValue(ref key, out PROPVARIANT pv) != 0)
                return null;

            return pv.vt == 31 /* VT_LPWSTR */ && pv.p != IntPtr.Zero ? Marshal.PtrToStringUni(pv.p) : null;
        }
        catch
        {
            // Any COM/threading failure (closed window, no property set, etc.) just means
            // "couldn't tell" - fall through to normal routing rather than breaking Whim.
            return null;
        }
    }

    private delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hwnd);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);

    /// <summary>
    /// Visits every visible top-level window belonging to <paramref name="processIds"/> and hands
    /// its AppUserModelID (possibly null) to <paramref name="visit"/>. Returning false stops early.
    /// </summary>
    public static void VisitWindows(ISet<uint> processIds, Func<IntPtr, string?, bool> visit)
    {
        if (processIds.Count == 0)
            return;

        try
        {
            EnumWindows(
                (hwnd, lParam) =>
                {
                    if (!IsWindowVisible(hwnd))
                        return true;

                    GetWindowThreadProcessId(hwnd, out uint pid);
                    return !processIds.Contains(pid) || visit(hwnd, GetAppUserModelId(hwnd));
                },
                IntPtr.Zero
            );
        }
        catch
        {
            // Enumeration is best-effort: a failure means "couldn't tell".
        }
    }
}

/// <summary>
/// Declarative "start these apps with Whim" engine. The list itself lives in startup.json next to
/// this file so adding/removing a program never means touching C#. Nothing is launched twice: each
/// entry is checked against the running processes first (or, for Chromium profiles that share one
/// process, against the per-window AppUserModelID).
/// </summary>
internal static class StartupApps
{
    private sealed class Spec
    {
        public string Name = "";
        public List<string> Paths = new();
        public string Args = "";
        public bool Enabled = true;
        public List<string> ProcessNames = new();
        public string? AumidEndsWith;
        public List<string> AumidExcludes = new();
        public int DelayMs;
        public string? WorkingDirectory;
    }

    private sealed class Config
    {
        public int InitialDelayMs = 2000;
        public int StaggerMs = 500;
        public List<Spec> Apps = new();
    }

    private static readonly char[] Wildcards = { '*', '?' };

    private static readonly JsonDocumentOptions JsonOptions =
        new() { CommentHandling = JsonCommentHandling.Skip, AllowTrailingCommas = true };

    private static readonly string[] ConfigPaths =
    {
        @"~\.whim\startup.json",
        @"~\Atelier\workspaces\startup.json",
    };

    private static readonly string ReportPath = ExpandVars(@"~\.whim\startup-report.txt");

    // ---------------------------------------------------------------- public API

    /// <summary>Launches everything that isn't already running, off the Whim startup thread.</summary>
    public static void Start() => _ = Task.Run(() => Run(launch: true));

    /// <summary>Dry run: resolves every entry and reports what would happen, launching nothing.</summary>
    public static string Report() => Run(launch: false);

    /// <summary>Launches synchronously on the caller's thread (used by the manual command).</summary>
    public static string LaunchNow() => Run(launch: true);

    // ---------------------------------------------------------------- engine

    private static string Run(bool launch)
    {
        StringBuilder log = new();
        void Say(string line)
        {
            log.AppendLine(line);
            Console.WriteLine(line);
        }

        Say($"[startup] {DateTime.Now:yyyy-MM-dd HH:mm:ss} ({(launch ? "launch" : "dry run")})");

        if (!TryLoadConfig(out Config config, out string source, Say))
        {
            Flush(log);
            return log.ToString();
        }

        Say($"[startup] config: {source}");

        if (launch && config.InitialDelayMs > 0)
        {
            Thread.Sleep(config.InitialDelayMs);
        }

        bool launchedAny = false;

        foreach (Spec spec in config.Apps)
        {
            try
            {
                if (!spec.Enabled)
                {
                    Say($"[startup] skip     {spec.Name}: disabled");
                    continue;
                }

                string? exe = Resolve(spec.Paths);
                if (exe is null)
                {
                    Say($"[startup] MISSING  {spec.Name}: no candidate path exists ({string.Join(" | ", spec.Paths)})");
                    continue;
                }

                if (IsRunning(spec, exe))
                {
                    Say($"[startup] running  {spec.Name}");
                    continue;
                }

                if (!launch)
                {
                    Say($"[startup] WOULD RUN {spec.Name}: \"{exe}\" {spec.Args}".TrimEnd());

                    if (spec.AumidEndsWith is not null || spec.AumidExcludes.Count > 0)
                    {
                        // Makes a mis-configured AppUserModelID matcher obvious at a glance.
                        Say($"[startup]            observed ids: {string.Join(", ", ObservedAumids(spec, exe).DefaultIfEmpty("(none)"))}");
                    }

                    continue;
                }

                if (launchedAny && config.StaggerMs > 0)
                {
                    Thread.Sleep(config.StaggerMs);
                }

                if (spec.DelayMs > 0)
                {
                    Thread.Sleep(spec.DelayMs);
                }

                Process.Start(
                    new ProcessStartInfo
                    {
                        FileName = exe,
                        Arguments = spec.Args,
                        WorkingDirectory = spec.WorkingDirectory is null
                            ? Path.GetDirectoryName(exe) ?? string.Empty
                            : ExpandVars(spec.WorkingDirectory),
                        UseShellExecute = true,
                    }
                );

                launchedAny = true;
                Say($"[startup] LAUNCHED {spec.Name}: \"{exe}\" {spec.Args}".TrimEnd());
            }
            catch (Exception ex)
            {
                // One bad entry must never take down the rest of startup.
                Say($"[startup] ERROR    {spec.Name}: {ex.Message}");
            }
        }

        Flush(log);
        return log.ToString();
    }

    private static void Flush(StringBuilder log)
    {
        try
        {
            File.WriteAllText(ReportPath, log.ToString());
        }
        catch
        {
            // Reporting is a convenience, never a failure mode.
        }
    }

    // ---------------------------------------------------------------- "is it already running?"

    private static bool IsRunning(Spec spec, string exePath)
    {
        HashSet<uint> pids = ProcessIds(spec, exePath);

        if (spec.AumidEndsWith is null && spec.AumidExcludes.Count == 0)
        {
            return pids.Count > 0;
        }

        // Chromium runs every profile in one process, so the process check can't tell profiles
        // apart - the per-window AppUserModelID (what the taskbar groups by) can. Note the default
        // profile gets the bare base id ("Brave.<hash>"), while every other profile appends
        // ".UserData.<ProfileDir>" - hence both a positive and a negative matcher.
        bool found = false;
        AppUserModelIdHelper.VisitWindows(
            pids,
            (hwnd, aumid) =>
            {
                if (!Matches(spec, aumid))
                {
                    return true;
                }

                found = true;
                return false;
            }
        );

        return found;
    }

    /// <summary>Every AppUserModelID currently on screen for this entry's process(es).</summary>
    private static IReadOnlyList<string> ObservedAumids(Spec spec, string exePath)
    {
        List<string> observed = new();
        AppUserModelIdHelper.VisitWindows(
            ProcessIds(spec, exePath),
            (hwnd, aumid) =>
            {
                if (aumid is not null && !observed.Contains(aumid))
                {
                    observed.Add(aumid);
                }

                return true;
            }
        );

        return observed;
    }

    private static bool Matches(Spec spec, string? aumid)
    {
        // A window we can't read an id from tells us nothing, so it never counts as a match.
        if (aumid is null)
        {
            return false;
        }

        if (spec.AumidEndsWith is not null
            && !aumid.EndsWith(spec.AumidEndsWith, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return !spec.AumidExcludes.Any(exclude => aumid.Contains(exclude, StringComparison.OrdinalIgnoreCase));
    }

    private static HashSet<uint> ProcessIds(Spec spec, string exePath)
    {
        IEnumerable<string> names =
            spec.ProcessNames.Count > 0
                ? spec.ProcessNames
                : new[] { Path.GetFileNameWithoutExtension(exePath) };

        HashSet<uint> pids = new();
        foreach (string name in names)
        {
            try
            {
                foreach (Process process in Process.GetProcessesByName(name))
                {
                    pids.Add((uint)process.Id);
                }
            }
            catch
            {
                // Access-denied on a foreign process just means it isn't ours to see.
            }
        }

        return pids;
    }

    // ---------------------------------------------------------------- path resolution

    /// <summary>First pattern that matches anything wins; within a pattern, the newest match wins.</summary>
    private static string? Resolve(IEnumerable<string> patterns)
    {
        foreach (string pattern in patterns)
        {
            string? best = Glob(pattern)
                .OrderByDescending(SortKey, StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault();

            if (best is not null)
            {
                return best;
            }
        }

        return null;
    }

    /// <summary>Zero-pads digit runs so "Plover 5.12.0" sorts above "Plover 5.3.0".</summary>
    private static string SortKey(string path) => Regex.Replace(path, @"\d+", m => m.Value.PadLeft(10, '0'));

    private static string ExpandVars(string raw)
    {
        string path = raw.Trim();

        if (path.StartsWith("~", StringComparison.Ordinal))
        {
            path = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile) + path.Substring(1);
        }

        return Environment.ExpandEnvironmentVariables(path).Replace('/', Path.DirectorySeparatorChar);
    }

    /// <summary>Expands ~, %VARS% and wildcards in any path segment into concrete existing files.</summary>
    private static IReadOnlyList<string> Glob(string pattern)
    {
        string full = ExpandVars(pattern);

        // A bare name ("wezterm-gui.exe") is looked up on PATH, so entries don't have to know
        // where a shim lives.
        if (!Path.IsPathRooted(full) && full.IndexOf(Path.DirectorySeparatorChar) < 0)
        {
            return SearchPath(full);
        }

        if (full.IndexOfAny(Wildcards) < 0)
        {
            return File.Exists(full) ? new[] { full } : Array.Empty<string>();
        }

        string root = Path.GetPathRoot(full) ?? string.Empty;
        if (root.Length == 0)
        {
            return Array.Empty<string>();
        }

        string[] segments = full.Substring(root.Length)
            .Split(new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar }, StringSplitOptions.RemoveEmptyEntries);

        List<string> current = new() { root };

        for (int i = 0; i < segments.Length && current.Count > 0; i++)
        {
            bool isLast = i == segments.Length - 1;
            string segment = segments[i];
            List<string> next = new();

            foreach (string directory in current)
            {
                try
                {
                    if (segment.IndexOfAny(Wildcards) < 0)
                    {
                        string candidate = Path.Combine(directory, segment);
                        if (isLast ? File.Exists(candidate) : Directory.Exists(candidate))
                        {
                            next.Add(candidate);
                        }
                    }
                    else
                    {
                        next.AddRange(isLast ? Directory.GetFiles(directory, segment) : Directory.GetDirectories(directory, segment));
                    }
                }
                catch
                {
                    // Unreadable directory - just not a match.
                }
            }

            current = next;
        }

        return current;
    }

    /// <summary>Resolves a bare executable name against PATH (and PATHEXT when extensionless).</summary>
    private static IReadOnlyList<string> SearchPath(string name)
    {
        List<string> results = new();

        string[] extensions = Path.HasExtension(name)
            ? new[] { "" }
            : (Environment.GetEnvironmentVariable("PATHEXT") ?? ".EXE;.CMD;.BAT")
                .Split(';', StringSplitOptions.RemoveEmptyEntries);

        foreach (string directory in (Environment.GetEnvironmentVariable("PATH") ?? "")
            .Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            foreach (string extension in extensions)
            {
                try
                {
                    string candidate = Path.Combine(ExpandVars(directory.Trim('"')), name + extension);
                    if (File.Exists(candidate))
                    {
                        results.Add(candidate);
                    }
                }
                catch
                {
                    // Malformed PATH entry - ignore it.
                }
            }

            if (results.Count > 0)
            {
                // PATH is ordered by precedence, so stop at the first directory that has a hit.
                break;
            }
        }

        return results;
    }

    // ---------------------------------------------------------------- startup.json

    private static bool TryLoadConfig(out Config config, out string source, Action<string> say)
    {
        config = new Config();
        source = "";

        string? file = ConfigPaths.Select(ExpandVars).FirstOrDefault(File.Exists);
        if (file is null)
        {
            say($"[startup] no startup.json found (looked in {string.Join(", ", ConfigPaths)})");
            return false;
        }

        source = file;

        try
        {
            using JsonDocument document = JsonDocument.Parse(File.ReadAllText(file), JsonOptions);
            JsonElement root = document.RootElement;

            JsonElement apps = root;
            if (root.ValueKind == JsonValueKind.Object)
            {
                config.InitialDelayMs = GetInt(root, "initialDelayMs", config.InitialDelayMs);
                config.StaggerMs = GetInt(root, "staggerMs", config.StaggerMs);

                if (!root.TryGetProperty("apps", out apps))
                {
                    say($"[startup] {file} has no \"apps\" array");
                    return false;
                }
            }

            if (apps.ValueKind != JsonValueKind.Array)
            {
                say($"[startup] {file} must contain an array of apps");
                return false;
            }

            foreach (JsonElement element in apps.EnumerateArray())
            {
                Spec spec = new()
                {
                    Name = GetString(element, "name") ?? "(unnamed)",
                    Paths = GetStrings(element, "paths", "path"),
                    Args = GetString(element, "args", "arguments") ?? "",
                    Enabled = GetBool(element, "enabled", true),
                    ProcessNames = GetStrings(element, "process", "processes", "processNames"),
                    AumidEndsWith = GetString(element, "aumidEndsWith"),
                    AumidExcludes = GetStrings(element, "aumidExcludes"),
                    DelayMs = GetInt(element, "delayMs", 0),
                    WorkingDirectory = GetString(element, "cwd", "workingDirectory"),
                };

                if (spec.Paths.Count == 0)
                {
                    say($"[startup] skip     {spec.Name}: no \"paths\"");
                    continue;
                }

                config.Apps.Add(spec);
            }

            return true;
        }
        catch (Exception ex)
        {
            say($"[startup] failed to read {file}: {ex.Message}");
            return false;
        }
    }

    private static bool TryProperty(JsonElement element, string[] names, out JsonElement value)
    {
        foreach (string name in names)
        {
            if (element.ValueKind == JsonValueKind.Object && element.TryGetProperty(name, out value))
            {
                return true;
            }
        }

        value = default;
        return false;
    }

    private static string? GetString(JsonElement element, params string[] names) =>
        TryProperty(element, names, out JsonElement value) && value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;

    private static int GetInt(JsonElement element, string name, int fallback) =>
        TryProperty(element, new[] { name }, out JsonElement value) && value.TryGetInt32(out int parsed)
            ? parsed
            : fallback;

    private static bool GetBool(JsonElement element, string name, bool fallback) =>
        TryProperty(element, new[] { name }, out JsonElement value)
        && (value.ValueKind == JsonValueKind.True || value.ValueKind == JsonValueKind.False)
            ? value.GetBoolean()
            : fallback;

    /// <summary>Accepts either a single string or an array of strings.</summary>
    private static List<string> GetStrings(JsonElement element, params string[] names)
    {
        List<string> results = new();

        if (!TryProperty(element, names, out JsonElement value))
        {
            return results;
        }

        if (value.ValueKind == JsonValueKind.String)
        {
            string? single = value.GetString();
            if (!string.IsNullOrWhiteSpace(single))
            {
                results.Add(single!);
            }
        }
        else if (value.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement item in value.EnumerateArray())
            {
                if (item.ValueKind == JsonValueKind.String && !string.IsNullOrWhiteSpace(item.GetString()))
                {
                    results.Add(item.GetString()!);
                }
            }
        }

        return results;
    }
}

void DoConfig(IContext context)
{
    context.Logger.Config = new LoggerConfig() { BaseMinLogLevel = LogLevel.Debug };

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
        context.Store.Dispatch(new AddWorkspaceTransform(icon));
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

    // Route Brave's "Freeus" profile to the "chat" workspace, separately from the "Derek" profile
    // (which falls through to the broad brave->web rule loaded from 2.json below). Must be added
    // before that rule is registered, since RouterManager is first-match-wins in insertion order.
    context.RouterManager.Add(window =>
    {
        if (window.ProcessFileName is null || !window.ProcessFileName.Equals("brave.exe", StringComparison.OrdinalIgnoreCase))
            return null;

        string? aumid = AppUserModelIdHelper.GetAppUserModelId(window.Handle);
        if (aumid is null || !aumid.EndsWith(".UserData.Profile1", StringComparison.OrdinalIgnoreCase))
            return null;

        return context.Store.Pick(Pickers.PickWorkspaceByName(workspaces["chat"])).TryGet(out IWorkspace ws) ? ws : null;
    });

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

    // Startup applications. The list lives in ~/.whim/startup.json; see StartupApps above.
    context.CommandManager.Add(
        identifier: "startup_apps",
        title: "Launch startup applications (skips anything already running)",
        callback: () => StartupApps.Start()
    );

    context.CommandManager.Add(
        identifier: "startup_report",
        title: "Report startup application status (dry run -> ~/.whim/startup-report.txt)",
        callback: () =>
        {
            _ = Task.Run(() => StartupApps.Report());
        }
    );

    // Close active window
    // https://github.com/urob/whim-config/blob/3387b154edadf384271c90d2ed75a90c10e53790/whim.commands.csx
    context.CommandManager.Add(
        identifier: "close_window",
        title: "Close focused window",
        callback: () =>
        {
            if (context.Store.Pick(Pickers.PickLastFocusedWindow()).TryGet(out IWindow window))
            {
                window.Close();
            }
        }
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

    // Kick off startup apps last, on a background thread, so a slow or missing program can never
    // delay or break Whim's own startup. Safe to re-run on Alt+q restart: already-running apps are
    // skipped.
    StartupApps.Start();
}

// We return doConfig here so that Whim can call it when it loads.
return DoConfig;
