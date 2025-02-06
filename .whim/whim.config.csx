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
}

// We return doConfig here so that Whim can call it when it loads.
return DoConfig;
