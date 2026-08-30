using System.Diagnostics;
using System.Runtime.InteropServices;
using CreateShareableRegionWindow.Models;

namespace CreateShareableRegionWindow.Forms;

internal sealed class ShareableRegionWindowForm : Form
{
    private readonly CaptureRegion _region;
    private readonly bool _includeCursor;
    private readonly IReadOnlySet<string> _excludedProcesses;
    private readonly System.Windows.Forms.Timer _refreshTimer;
    private readonly System.Windows.Forms.Timer _filterTimer;
    private HashSet<IntPtr> _filteredWindows = [];
    private IntPtr _magnifier;
    private bool _magnifierInitialized;

    public ShareableRegionWindowForm(CaptureRegion region, bool includeCursor, IReadOnlySet<string> excludedProcesses)
    {
        _region = region;
        _includeCursor = includeCursor;
        _excludedProcesses = excludedProcesses;
        Text = "Shareable Region Window";
        FormBorderStyle = FormBorderStyle.None;
        BackColor = Color.Black;
        KeyPreview = true;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = FitToWorkingArea(region.Width, region.Height);
        MinimumSize = new Size(320, 180);
        SetStyle(ControlStyles.ResizeRedraw, true);

        _refreshTimer = new System.Windows.Forms.Timer { Interval = 1000 / 30 };
        _refreshTimer.Tick += (_, _) =>
        {
            if (!RefreshMagnifier()) ShowCaptureError("The selected screen region could not be refreshed.");
        };
        _filterTimer = new System.Windows.Forms.Timer { Interval = 500 };
        _filterTimer.Tick += (_, _) =>
        {
            if (!UpdateWindowFilter()) ShowCaptureError("The process exclusion list could not be refreshed.");
        };
        Shown += (_, _) => StartMagnifier();
        FormClosed += (_, _) => StopMagnifier();
        Resize += (_, _) => UpdateMagnifierLayout();
        KeyDown += (_, e) =>
        {
            if (e.KeyCode == Keys.Escape) Close();
        };
    }

    protected override CreateParams CreateParams
    {
        get
        {
            var parameters = base.CreateParams;
            parameters.ExStyle |= WindowStyleExtendedLayered;
            return parameters;
        }
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        if (e.Button != MouseButtons.Left) return;
        ReleaseCapture();
        SendMessage(Handle, WindowMessageNonClientLeftButtonDown, HitCaption, 0);
    }

    protected override void WndProc(ref Message message)
    {
        base.WndProc(ref message);
        if (message.Msg != WindowMessageNonClientHitTest || WindowState == FormWindowState.Maximized) return;

        var cursor = PointToClient(Cursor.Position);
        var left = cursor.X <= ResizeGrip;
        var right = cursor.X >= ClientSize.Width - ResizeGrip;
        var top = cursor.Y <= ResizeGrip;
        var bottom = cursor.Y >= ClientSize.Height - ResizeGrip;

        message.Result = (left, right, top, bottom) switch
        {
            (true, _, true, _) => HitTopLeft,
            (_, true, true, _) => HitTopRight,
            (true, _, _, true) => HitBottomLeft,
            (_, true, _, true) => HitBottomRight,
            (true, _, _, _) => HitLeft,
            (_, true, _, _) => HitRight,
            (_, _, true, _) => HitTop,
            (_, _, _, true) => HitBottom,
            _ => message.Result
        };
    }

    private void StartMagnifier()
    {
        if (!MagInitialize())
        {
            ShowCaptureError("Windows Magnification could not be initialized.");
            return;
        }

        _magnifierInitialized = true;
        SetLayeredWindowAttributes(Handle, 0, 255, LayeredWindowAlpha);
        var style = WindowStyleChild;
        if (_includeCursor) style |= MagnifierShowCursor;

        _magnifier = CreateWindowEx(WindowStyleExtendedTransparent, MagnifierWindowClass, null, style,
            0, 0, ClientSize.Width, ClientSize.Height, Handle, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero);
        if (_magnifier == IntPtr.Zero)
        {
            ShowCaptureError($"The magnifier window could not be created (error {Marshal.GetLastWin32Error()}).");
            return;
        }

        UpdateMagnifierLayout();
        if (!UpdateWindowFilter())
        {
            ShowCaptureError("The process exclusion list could not be applied.");
            return;
        }

        if (!RefreshMagnifier())
        {
            ShowCaptureError("The selected screen region could not be captured.");
            return;
        }

        ShowWindow(_magnifier, ShowWindowShow);
        InvalidateRect(_magnifier, IntPtr.Zero, false);
        _refreshTimer.Start();
        _filterTimer.Start();
    }

    private void StopMagnifier()
    {
        _refreshTimer.Stop();
        _refreshTimer.Dispose();
        _filterTimer.Stop();
        _filterTimer.Dispose();
        if (_magnifier != IntPtr.Zero)
        {
            DestroyWindow(_magnifier);
            _magnifier = IntPtr.Zero;
        }
        if (_magnifierInitialized)
        {
            MagUninitialize();
            _magnifierInitialized = false;
        }
    }

    private bool RefreshMagnifier()
    {
        if (_magnifier == IntPtr.Zero || WindowState == FormWindowState.Minimized) return true;

        var source = new Rect(_region.X, _region.Y, _region.X + _region.Width, _region.Y + _region.Height);
        if (!MagSetWindowSource(_magnifier, source)) return false;

        return InvalidateRect(_magnifier, IntPtr.Zero, false);
    }

    private void UpdateMagnifierLayout()
    {
        if (_magnifier == IntPtr.Zero || ClientSize.Width <= 0 || ClientSize.Height <= 0) return;

        var bounds = FitAspect(new Size(_region.Width, _region.Height), ClientRectangle);
        MoveWindow(_magnifier, bounds.X, bounds.Y, bounds.Width, bounds.Height, true);
        var transform = MagnificationTransform.Create((float)bounds.Width / _region.Width);
        MagSetWindowTransform(_magnifier, ref transform);
    }

    private bool UpdateWindowFilter()
    {
        if (_magnifier == IntPtr.Zero) return true;

        var windows = new HashSet<IntPtr> { Handle };
        if (_excludedProcesses.Count > 0)
        {
            EnumWindows((window, _) =>
            {
                GetWindowThreadProcessId(window, out var processId);
                try
                {
                    using var process = Process.GetProcessById((int)processId);
                    if (_excludedProcesses.Contains(process.ProcessName)) windows.Add(window);
                }
                catch (ArgumentException) { }
                catch (InvalidOperationException) { }
                catch (System.ComponentModel.Win32Exception) { }
                return true;
            }, IntPtr.Zero);
        }

        var handles = windows.ToArray();
        if (!MagSetWindowFilterList(_magnifier, MagnifierFilterExclude, handles.Length, handles)) return false;

        var newlyFilteredWindows = windows.Except(_filteredWindows).Where(window => window != Handle).ToArray();
        _filteredWindows = windows;
        foreach (var window in newlyFilteredWindows)
        {
            RedrawWindow(window, IntPtr.Zero, IntPtr.Zero, RedrawWindowRefreshFlags);
        }

        if (newlyFilteredWindows.Length > 0) DwmFlush();
        InvalidateRect(_magnifier, IntPtr.Zero, false);
        return true;
    }

    private void ShowCaptureError(string message)
    {
        _refreshTimer.Stop();
        _filterTimer.Stop();
        Text = $"Shareable Region Window — capture stopped: {message}";
        Invalidate();
    }

    private static Rectangle FitAspect(Size source, Rectangle destination)
    {
        var scale = Math.Min((double)destination.Width / source.Width, (double)destination.Height / source.Height);
        var width = (int)(source.Width * scale);
        var height = (int)(source.Height * scale);
        return new Rectangle(destination.X + (destination.Width - width) / 2,
            destination.Y + (destination.Height - height) / 2, width, height);
    }

    private static Size FitToWorkingArea(int width, int height)
    {
        var area = Screen.PrimaryScreen?.WorkingArea.Size ?? new Size(1280, 720);
        var scale = Math.Min(0.75, Math.Min((double)area.Width / width, (double)area.Height / height));
        return new Size(Math.Max(320, (int)(width * scale)), Math.Max(180, (int)(height * scale)));
    }

    private const string MagnifierWindowClass = "Magnifier";
    private const int MagnifierFilterExclude = 0;
    private const int MagnifierShowCursor = 0x0001;
    private const int WindowStyleChild = 0x40000000;
    private const int WindowStyleExtendedLayered = 0x00080000;
    private const int WindowStyleExtendedTransparent = 0x00000020;
    private const int LayeredWindowAlpha = 0x00000002;
    private const int ShowWindowShow = 5;
    private const uint RedrawWindowRefreshFlags = 0x0001 | 0x0080 | 0x0100 | 0x0400;
    private const int ResizeGrip = 7;
    private const int WindowMessageNonClientHitTest = 0x0084;
    private const int WindowMessageNonClientLeftButtonDown = 0x00A1;
    private const int HitCaption = 2;
    private const int HitLeft = 10;
    private const int HitRight = 11;
    private const int HitTop = 12;
    private const int HitTopLeft = 13;
    private const int HitTopRight = 14;
    private const int HitBottom = 15;
    private const int HitBottomLeft = 16;
    private const int HitBottomRight = 17;

    [StructLayout(LayoutKind.Sequential)]
    private readonly struct Rect(int left, int top, int right, int bottom)
    {
        public readonly int Left = left;
        public readonly int Top = top;
        public readonly int Right = right;
        public readonly int Bottom = bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MagnificationTransform
    {
        public float M00, M01, M02;
        public float M10, M11, M12;
        public float M20, M21, M22;

        public static MagnificationTransform Create(float scale) => new()
        {
            M00 = scale,
            M11 = scale,
            M22 = 1
        };
    }

    private delegate bool EnumWindowsCallback(IntPtr window, IntPtr parameter);

    [DllImport("Magnification.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MagInitialize();

    [DllImport("Magnification.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MagUninitialize();

    [DllImport("Magnification.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MagSetWindowSource(IntPtr magnifier, Rect source);

    [DllImport("Magnification.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MagSetWindowTransform(IntPtr magnifier, ref MagnificationTransform transform);

    [DllImport("Magnification.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MagSetWindowFilterList(IntPtr magnifier, int filterMode, int count,
        [In] IntPtr[] windows);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    private static extern IntPtr CreateWindowEx(int extendedStyle, string className, string? windowName,
        int style, int x, int y, int width, int height, IntPtr parent, IntPtr menu, IntPtr instance, IntPtr parameter);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DestroyWindow(IntPtr window);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool MoveWindow(IntPtr window, int x, int y, int width, int height, bool repaint);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool ShowWindow(IntPtr window, int command);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetLayeredWindowAttributes(IntPtr window, uint colorKey, byte alpha, uint flags);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool InvalidateRect(IntPtr window, IntPtr rectangle, bool erase);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool RedrawWindow(IntPtr window, IntPtr updateRectangle, IntPtr updateRegion, uint flags);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool EnumWindows(EnumWindowsCallback callback, IntPtr parameter);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr window, int message, int wParam, int lParam);

    [DllImport("dwmapi.dll")]
    private static extern int DwmFlush();
}
