namespace CreateShareableRegionWindow.Forms;

/// <summary>A non-interactive overlay marking the source region without appearing in its capture.</summary>
internal sealed class RegionBorderForm : Form
{
    private const int BorderThickness = 4;
    private const int WindowStyleExtendedTransparent = 0x00000020;
    private const int WindowStyleExtendedToolWindow = 0x00000080;
    private const int WindowStyleExtendedNoActivate = 0x08000000;

    public RegionBorderForm(Rectangle region)
    {
        var bounds = region;
        bounds.Inflate(BorderThickness, BorderThickness);

        Bounds = bounds;
        StartPosition = FormStartPosition.Manual;
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        TopMost = true;
        BackColor = Color.Black;
        TransparencyKey = Color.Black;
    }

    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            var parameters = base.CreateParams;
            parameters.ExStyle |= WindowStyleExtendedTransparent |
                                  WindowStyleExtendedToolWindow |
                                  WindowStyleExtendedNoActivate;
            return parameters;
        }
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        using var border = new Pen(Color.Red, BorderThickness);
        var inset = BorderThickness / 2;
        e.Graphics.DrawRectangle(border, inset, inset,
            ClientSize.Width - BorderThickness, ClientSize.Height - BorderThickness);
    }
}
