namespace CreateShareableRegionWindow.Forms;

internal sealed class RegionSelectorForm : Form
{
    private Point _start;
    private Rectangle _selection;
    private bool _dragging;

    public RegionSelectorForm(Rectangle initial)
    {
        var virtualScreen = SystemInformation.VirtualScreen;
        Bounds = virtualScreen;
        StartPosition = FormStartPosition.Manual;
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        BackColor = Color.Black;
        Opacity = 0.32;
        Cursor = Cursors.Cross;
        DoubleBuffered = true;
        KeyPreview = true;

        if (initial.Width > 0 && initial.Height > 0)
            _selection = new Rectangle(initial.X - virtualScreen.X, initial.Y - virtualScreen.Y, initial.Width, initial.Height);

        MouseDown += OnSelectorMouseDown;
        MouseMove += OnSelectorMouseMove;
        MouseUp += OnSelectorMouseUp;
        KeyDown += (_, e) =>
        {
            if (e.KeyCode == Keys.Escape) { DialogResult = DialogResult.Cancel; Close(); }
            if (e.KeyCode == Keys.Enter && _selection.Width >= 16 && _selection.Height >= 16) Accept();
        };
    }

    public Rectangle SelectedRegion
    {
        get
        {
            var virtualScreen = SystemInformation.VirtualScreen;
            return new Rectangle(_selection.X + virtualScreen.X, _selection.Y + virtualScreen.Y,
                _selection.Width, _selection.Height);
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        if (_selection.Width <= 0 || _selection.Height <= 0) return;
        using var fill = new SolidBrush(Color.FromArgb(90, Color.DeepSkyBlue));
        using var border = new Pen(Color.DeepSkyBlue, 3);
        e.Graphics.FillRectangle(fill, _selection);
        e.Graphics.DrawRectangle(border, _selection);

        var text = $"{_selection.Width} × {_selection.Height}   Release to select · Esc to cancel";
        var textSize = e.Graphics.MeasureString(text, Font);
        var label = new RectangleF(_selection.X, Math.Max(0, _selection.Y - textSize.Height - 8), textSize.Width + 12, textSize.Height + 6);
        using var labelFill = new SolidBrush(Color.FromArgb(225, 15, 23, 42));
        e.Graphics.FillRectangle(labelFill, label);
        e.Graphics.DrawString(text, Font, Brushes.White, label.X + 6, label.Y + 3);
    }

    private void OnSelectorMouseDown(object? sender, MouseEventArgs e)
    {
        if (e.Button != MouseButtons.Left) return;
        _start = e.Location;
        _selection = Rectangle.Empty;
        _dragging = true;
    }

    private void OnSelectorMouseMove(object? sender, MouseEventArgs e)
    {
        if (!_dragging) return;
        _selection = Rectangle.FromLTRB(Math.Min(_start.X, e.X), Math.Min(_start.Y, e.Y),
            Math.Max(_start.X, e.X), Math.Max(_start.Y, e.Y));
        Invalidate();
    }

    private void OnSelectorMouseUp(object? sender, MouseEventArgs e)
    {
        if (!_dragging || e.Button != MouseButtons.Left) return;
        _dragging = false;
        if (_selection.Width >= 16 && _selection.Height >= 16) Accept();
    }

    private void Accept()
    {
        DialogResult = DialogResult.OK;
        Close();
    }
}
