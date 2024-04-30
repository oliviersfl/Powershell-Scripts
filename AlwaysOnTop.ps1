param(
    [string]$windowTitle,
    [switch]$Disable
)

if ([System.Type]::GetType("WinApi") -isnot [System.Type]) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class WinApi {
        [DllImport("user32.dll", EntryPoint = "FindWindow", SetLastError = true)]
        public static extern IntPtr FindWindow(IntPtr lpClassName, string lpWindowName);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

        public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
        public static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);
        public static readonly uint SWP_NOMOVE = 0x0002;
        public static readonly uint SWP_NOSIZE = 0x0001;
    }
"@
}

$hwnd = [WinApi]::FindWindow([System.IntPtr]::Zero, $windowTitle)

if ($hwnd -ne [IntPtr]::Zero) {
    if ($Disable) {
        [WinApi]::SetWindowPos($hwnd, [WinApi]::HWND_NOTOPMOST, 0, 0, 0, 0, [WinApi]::SWP_NOMOVE -bor [WinApi]::SWP_NOSIZE)
        "Window no longer always on top."
    } else {
        [WinApi]::SetWindowPos($hwnd, [WinApi]::HWND_TOPMOST, 0, 0, 0, 0, [WinApi]::SWP_NOMOVE -bor [WinApi]::SWP_NOSIZE)
        "Window set to always on top successfully."
    }
} else {
    "Window not found."
}
