namespace CreateShareableRegionWindow.Models;

internal sealed record Settings(
    int X,
    int Y,
    int Width,
    int Height,
    bool IncludeCursor,
    bool TopMost,
    string? ExcludedProcesses = null);
