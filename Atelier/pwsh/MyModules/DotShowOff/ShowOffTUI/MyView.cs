namespace ShowOffTUI
{
    using System.Dynamic;
    using System.Reflection;
    using System.Text;
    using System.Text.Json;
    using Terminal.Gui;

    public partial class MyView : Window
    {
        private TextView objectTextView;

        public MyView(string? json)
        {
            Title = "Object Inspector";
            Width = Dim.Fill();
            Height = Dim.Fill();

            InitializeComponent();

            objectTextView = new TextView
            {
                X = 1,
                Y = 1,
                Width = Dim.Fill() - 2,
                Height = Dim.Fill() - 3,
                ReadOnly = true,
            };

            var closeButton = new Button
            {
                Text = "Close",
                X = Pos.Center(),
                Y = Pos.Percent(90),
            };

            closeButton.Accept += (s, e) => Application.RequestStop();

            Add(objectTextView, closeButton);

            if (!string.IsNullOrWhiteSpace(json))
            {
                try
                {
                    dynamic? dyn = JsonSerializer.Deserialize<object>(json);
                    objectTextView.Text = FormatObjectInfo(dyn);
                }
                catch (Exception ex)
                {
                    objectTextView.Text = $"Failed to parse object:\n{ex.Message}";
                }
            }
            else
            {
                objectTextView.Text = "No JSON data provided.";
            }
        }

        private string FormatObjectInfo(dynamic? obj)
        {
            if (obj is null)
                return "Null object.";

            var type = obj.GetType();
            var sb = new StringBuilder();
            sb.AppendLine($"Type: {type}");

            sb.AppendLine("\n[Properties]");
            foreach (var prop in type.GetProperties(BindingFlags.Instance | BindingFlags.Public))
            {
                sb.AppendLine($"- {prop.Name} : {prop.PropertyType.Name}");
            }

            sb.AppendLine("\n[Methods]");
            foreach (var method in type.GetMethods(BindingFlags.Instance | BindingFlags.Public))
            {
                if (!method.IsSpecialName)
                    sb.AppendLine($"- {method.Name}()");
            }

            return sb.ToString();
        }
    }
}
