using ShowOffTUI;
using Terminal.Gui;

Application.Init();

try
{
    var json = args.Length > 0 ? args[0] : null;
    Application.Run(new MyView(json));
}
finally
{
    Application.Shutdown();
}
