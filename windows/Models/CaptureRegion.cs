namespace CreateShareableRegionWindow.Models;

internal readonly record struct CaptureRegion(int X, int Y, int Width, int Height)
{
    public Rectangle Rectangle => new(X, Y, Width, Height);
}
