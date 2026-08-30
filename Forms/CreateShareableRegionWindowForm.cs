using System.Text.Json;
using CreateShareableRegionWindow.Models;

namespace CreateShareableRegionWindow.Forms;

internal sealed class CreateShareableRegionWindowForm : Form
{
    private readonly NumericUpDown _x = CreateNumber(-100000, 100000, 0);
    private readonly NumericUpDown _y = CreateNumber(-100000, 100000, 0);
    private readonly NumericUpDown _width = CreateNumber(64, 16384, 1920);
    private readonly NumericUpDown _height = CreateNumber(64, 16384, 1080);
    private readonly TextBox _excludedProcesses = new() { Width = 300, PlaceholderText = "notepad.exe, teams.exe" };
    private readonly CheckBox _cursor = new() { Text = "Include mouse pointer", Checked = true, AutoSize = true };
    private readonly CheckBox _topMost = new() { Text = "Keep Shareable Region Window on top", AutoSize = true };
    private readonly Label _status = new() { AutoSize = true, ForeColor = Color.FromArgb(80, 80, 80) };
    private ShareableRegionWindowForm? _shareableRegionWindow;

    public CreateShareableRegionWindowForm()
    {
        Text = "Create Shareable Region Window";
        StartPosition = FormStartPosition.CenterScreen;
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        AutoSize = true;
        AutoSizeMode = AutoSizeMode.GrowAndShrink;
        AutoScaleMode = AutoScaleMode.Dpi;
        Padding = new Padding(26, 22, 26, 22);
        Font = new Font("Segoe UI", 10f);
        BackColor = Color.FromArgb(248, 249, 251);

        var help = new Label
        {
            Text = "Choose an area, select Create, then share the\nShareable Region Window in your meeting.",
            AutoSize = true,
            ForeColor = Color.FromArgb(75, 80, 90),
            Margin = new Padding(0, 0, 0, 14)
        };

        var choose = MakeButton("Select area…", (_, _) => SelectArea());
        var grid = new TableLayoutPanel
        {
            AutoSize = true,
            ColumnCount = 5,
            RowCount = 2,
            Margin = new Padding(0, 0, 0, 12)
        };
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 110));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        AddField(grid, "Left", _x, 0, 0);
        AddField(grid, "Top", _y, 2, 0);
        AddField(grid, "Width", _width, 0, 1);
        AddField(grid, "Height", _height, 2, 1);
        choose.Anchor = AnchorStyles.None;
        choose.Margin = new Padding(12, 3, 0, 3);
        grid.Controls.Add(choose, 4, 0);
        grid.SetRowSpan(choose, 2);

        var exclusionsRow = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight };
        exclusionsRow.Controls.Add(new Label { Text = "Hide processes", AutoSize = true, Margin = new Padding(0, 7, 8, 0) });
        exclusionsRow.Controls.Add(_excludedProcesses);

        var create = MakeButton("Create", (_, _) => CreateShareableRegionWindow(), primary: true);
        var buttons = new FlowLayoutPanel { AutoSize = true, Margin = new Padding(0, 12, 0, 4) };
        buttons.Controls.Add(create);

        var content = new FlowLayoutPanel
        {
            FlowDirection = FlowDirection.TopDown,
            WrapContents = false,
            AutoSize = true,
            Location = new Point(Padding.Left, Padding.Top),
            Margin = Padding.Empty
        };
        content.Controls.AddRange([help, grid, exclusionsRow, _cursor, _topMost, buttons, _status]);
        Controls.Add(content);

        _topMost.CheckedChanged += (_, _) =>
        {
            if (_shareableRegionWindow is not null) _shareableRegionWindow.TopMost = _topMost.Checked;
        };
    }

    private CaptureRegion SelectedCaptureRegion => new((int)_x.Value, (int)_y.Value, (int)_width.Value, (int)_height.Value);

    protected override void OnLoad(EventArgs e)
    {
        base.OnLoad(e);
        LoadSettings();
        SetStatus("Ready");
    }

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        SaveSettings();
        CloseShareableWindow();
        base.OnFormClosing(e);
    }

    private void SelectArea()
    {
        using var selector = new RegionSelectorForm(SelectedCaptureRegion.Rectangle);
        Hide();
        try
        {
            if (selector.ShowDialog() == DialogResult.OK)
            {
                var region = selector.SelectedRegion;
                SetNumber(_x, region.X);
                SetNumber(_y, region.Y);
                SetNumber(_width, region.Width);
                SetNumber(_height, region.Height);
                SetStatus($"Selected {region.Width} × {region.Height} at {region.X}, {region.Y}");
            }
        }
        finally
        {
            Show();
            Activate();
        }
    }

    private void CreateShareableRegionWindow()
    {
        CloseShareableWindow();
        var region = SelectedCaptureRegion;
        var excludedProcesses = ParseProcessNames(_excludedProcesses.Text);
        SaveSettings();
        _shareableRegionWindow = new ShareableRegionWindowForm(region, _cursor.Checked, excludedProcesses)
        {
            TopMost = _topMost.Checked
        };
        _shareableRegionWindow.FormClosed += (_, _) => _shareableRegionWindow = null;
        _shareableRegionWindow.Show();
        var exclusions = excludedProcesses.Count == 0 ? "" : $"; hiding {string.Join(", ", excludedProcesses)}";
        SetStatus($"Capturing {region.Width} × {region.Height} at {region.X}, {region.Y}{exclusions}");
    }

    private void CloseShareableWindow()
    {
        if (_shareableRegionWindow is null) return;
        var shareableRegionWindow = _shareableRegionWindow;
        _shareableRegionWindow = null;
        shareableRegionWindow.Close();
        shareableRegionWindow.Dispose();
        SetStatus("Shareable Region Window closed");
    }

    private void LoadSettings()
    {
        try
        {
            if (!File.Exists(SettingsPath)) return;
            var settings = JsonSerializer.Deserialize<Settings>(File.ReadAllText(SettingsPath));
            if (settings is null) return;
            SetNumber(_x, settings.X);
            SetNumber(_y, settings.Y);
            SetNumber(_width, settings.Width);
            SetNumber(_height, settings.Height);
            _cursor.Checked = settings.IncludeCursor;
            _topMost.Checked = settings.TopMost;
            _excludedProcesses.Text = settings.ExcludedProcesses ?? "";
        }
        catch { /* Invalid settings should not prevent startup. */ }
    }

    private void SaveSettings()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(SettingsPath)!);
            var value = new Settings((int)_x.Value, (int)_y.Value, (int)_width.Value,
                (int)_height.Value, _cursor.Checked, _topMost.Checked, _excludedProcesses.Text);
            File.WriteAllText(SettingsPath, JsonSerializer.Serialize(value));
        }
        catch { /* Closing the app should remain reliable. */ }
    }

    private static string SettingsPath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "CreateShareableRegionWindow", "settings.json");

    private static NumericUpDown CreateNumber(int min, int max, int value) => new()
    {
        Minimum = min,
        Maximum = max,
        Value = value,
        Width = 100,
        ThousandsSeparator = true
    };

    private static void AddField(TableLayoutPanel grid, string label, Control input, int column, int row)
    {
        grid.Controls.Add(new Label { Text = label, AutoSize = true, Margin = new Padding(0, 7, 8, 0) }, column, row);
        grid.Controls.Add(input, column + 1, row);
    }

    private static Button MakeButton(string text, EventHandler click, bool primary = false)
    {
        var button = new Button
        {
            Text = text,
            AutoSize = true,
            Padding = new Padding(8, 3, 8, 3),
            FlatStyle = primary ? FlatStyle.Flat : FlatStyle.Standard
        };
        if (primary)
        {
            button.BackColor = Color.FromArgb(37, 99, 235);
            button.ForeColor = Color.White;
            button.FlatAppearance.BorderSize = 0;
        }
        button.Click += click;
        return button;
    }

    private static void SetNumber(NumericUpDown target, int value) =>
        target.Value = Math.Clamp(value, (int)target.Minimum, (int)target.Maximum);

    private void SetStatus(string value) => _status.Text = value;

    private static IReadOnlySet<string> ParseProcessNames(string value) => value
        .Split([',', ';', '\r', '\n'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
        .Select(Path.GetFileNameWithoutExtension)
        .Where(name => !string.IsNullOrWhiteSpace(name))
        .ToHashSet(StringComparer.OrdinalIgnoreCase)!;
}
