// JSON-based window routing for Whim
// Reads routes from ~/Atelier/workspaces/*.json files

using System.Text.Json;
using System.IO;

// Load routes from JSON files
var workspacePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Atelier", "workspaces");
var workspaceNames = new Dictionary<int, string>
{
    { 1, "terminal" },
    { 2, "web" },
    { 3, "chat" },
    { 4, "plover" },
    { 5, "docs" },
    { 6, "device" },
    { 7, "one" },
    { 8, "two" },
    { 9, "three" }
};

// Load routes for each workspace
for (int i = 1; i <= 9; i++)
{
    var jsonFile = Path.Combine(workspacePath, $"{i}.json");
    if (!File.Exists(jsonFile)) continue;

    try
    {
        var json = File.ReadAllText(jsonFile);
        var routes = JsonSerializer.Deserialize<JsonElement>(json);

        if (routes != null && routes.ValueKind == JsonValueKind.Array)
        {
            foreach (var route in routes.EnumerateArray())
            {
                string app = route.GetProperty("app").GetString();
                string type = route.GetProperty("type").GetString();
                string workspaceName = workspaceNames[i];

                switch (type)
                {
                    case "process":
                        string processName = app.EndsWith(".exe") ? app : $"{app}.exe";
                        context.RouterManager.AddProcessFileNameRoute(processName, workspaces[workspaceName]);
                        break;
                    case "class":
                        context.RouterManager.AddWindowClassRoute(app, workspaces[workspaceName]);
                        break;
                    case "title":
                        context.RouterManager.AddTitleMatchRoute(app, workspaces[workspaceName]);
                        break;
                }
            }
        }
    }
    catch (Exception ex)
    {
        // Log error but continue with other workspaces
        System.Console.WriteLine($"Error loading routes from {jsonFile}: {ex.Message}");
    }
}

// Load filters from filters.json
var filtersFile = Path.Combine(workspacePath, "filters.json");
if (File.Exists(filtersFile))
{
    try
    {
        var json = File.ReadAllText(filtersFile);
        var filters = JsonSerializer.Deserialize<JsonElement>(json);

        if (filters != null && filters.ValueKind == JsonValueKind.Array)
        {
            var filterList = new List<string>();

            foreach (var filter in filters.EnumerateArray())
            {
                string app = filter.GetProperty("app").GetString();
                string type = filter.GetProperty("type").GetString();

                switch (type)
                {
                    case "process":
                        string processName = app.EndsWith(".exe") ? app : $"{app}.exe";
                        filterList.Add(processName);
                        break;
                    case "class":
                        filterList.Add(app);
                        break;
                    case "title":
                        filterList.Add(app);
                        break;
                }
            }

            // Apply all filters
            filterList.ForEach(program =>
            {
                context.FilterManager.AddTitleMatchFilter(program);
                context.FilterManager.AddWindowClassFilter(program);
                context.FilterManager.AddProcessFileNameFilter(program);
            });
        }
    }
    catch (Exception ex)
    {
        System.Console.WriteLine($"Error loading filters from {filtersFile}: {ex.Message}");
    }
}
