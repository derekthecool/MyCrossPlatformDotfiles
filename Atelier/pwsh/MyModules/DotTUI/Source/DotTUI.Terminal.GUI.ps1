# Terminal.Gui V1 with powershell great guide: https://blog.ironmansoftware.com/tui-powershell/
function Show-TerminalGuiV1Example
{
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        [object]$InputObject
    )
    begin
    {
        $items = @()
    }
    process
    {
        foreach ($item in $InputObject)
        {
            $items += $item
        }
    }
    end
    {
        # Init much always be run first
        [Terminal.Gui.Application]::Init()

        $Window = [Terminal.Gui.Window]::new()
        $Window.Title = "Hello, World"
        $Button = [Terminal.Gui.Button]::new()
        $Button.Text = "Button" 
        $Window.Add($Button)
        $ListView = [Terminal.Gui.ListView]::new()
        $ListView.SetSource($items)
        $ListView.Width = [Terminal.Gui.Dim]::Fill()
        $ListView.Height = [Terminal.Gui.Dim]::Fill()
        $Window.Add($ListView)

        [Terminal.Gui.Application]::Top.Add($Window)
        [Terminal.Gui.Application]::Run()
    }
}

function Show-TerminalGuiV2Example
{
    Write-Error "This function was an attempt to port this example: https://gui-cs.github.io/Terminal.Gui/index.html#simple-example from csharp to powershell but there were too many problems loading"
    # # Create and initialize the application
    # $app = [Terminal.Gui.App.Application]::Create()
    # $app.Init()
    #
    # # Create the window
    # $window = [Terminal.Gui.Views.Window]::new()
    # $window.Title = "Hello World (Esc to quit)"
    #
    # # Create the label
    # $label = [Terminal.Gui.Views.Label]::new()
    # $label.Text = "Hello, Terminal.Gui v2!"
    # $label.X = [Terminal.Gui.ViewBase.Pos]::Center()
    # $label.Y = [Terminal.Gui.ViewBase.Pos]::Center()
    #
    # # Add label to window
    # $window.Add($label)
    #
    # # Run the application
    # $app.Run($window)
}
