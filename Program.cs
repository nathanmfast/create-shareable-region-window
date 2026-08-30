using CreateShareableRegionWindow.Forms;

namespace CreateShareableRegionWindow;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        ApplicationConfiguration.Initialize();
        Application.Run(new CreateShareableRegionWindowForm());
    }
}
