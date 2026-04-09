param(
    [string]$Title    = "Claude Code",
    [string]$Message  = "Task completed.",
    [int]$Cooldown    = 30
)

# --- Skip if VS Code is the foreground window (user is already looking) ---
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FocusCheck {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
}
"@ -ErrorAction SilentlyContinue

    $fgHwnd = [FocusCheck]::GetForegroundWindow()
    $fgPid = 0u
    [FocusCheck]::GetWindowThreadProcessId($fgHwnd, [ref]$fgPid) | Out-Null

    if ($fgPid -ne 0) {
        $fgProc = Get-Process -Id $fgPid -ErrorAction SilentlyContinue
        if ($fgProc -and $fgProc.ProcessName -eq 'Code') {
            exit 0
        }
    }
} catch { }

# --- Debounce: skip if last notification was within $Cooldown seconds ---
$lockFile = Join-Path $env:TEMP 'claude-notify-last.txt'
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

if (Test-Path $lockFile) {
    $lastRaw = Get-Content $lockFile -Raw -ErrorAction SilentlyContinue
    $last = 0
    if ([long]::TryParse($lastRaw.Trim(), [ref]$last)) {
        if (($now - $last) -lt $Cooldown) {
            exit 0
        }
    }
}

$now.ToString() | Set-Content $lockFile -NoNewline -Force

# --- Flash VS Code taskbar icon to attract attention ---
try {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FlashWindow {
    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }
    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    public static void Flash(IntPtr hwnd) {
        FLASHWINFO fi = new FLASHWINFO();
        fi.cbSize = (uint)Marshal.SizeOf(typeof(FLASHWINFO));
        fi.hwnd = hwnd;
        fi.dwFlags = 3;   // FLASHW_ALL (caption + taskbar)
        fi.uCount = 5;
        fi.dwTimeout = 0;
        FlashWindowEx(ref fi);
    }
}
"@ -ErrorAction SilentlyContinue

    $proc = Get-Process -Name Code -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 } |
        Select-Object -First 1
    if ($proc) {
        [FlashWindow]::Flash($proc.MainWindowHandle)
    }
} catch { }

# --- Toast notification ---
$shown = $false

# Method 1: BurntToast with click-to-focus button
if (-not $shown) {
    try {
        Import-Module BurntToast -ErrorAction Stop
        $btn = New-BTButton -Content 'Switch to Claude' -Arguments 'claude-focus://' -ActivationType Protocol
        New-BurntToastNotification -Text $Title, $Message -Button $btn -Sound 'Reminder'
        $shown = $true
    } catch { }
}

# Method 2: System sound only
if (-not $shown) {
    try {
        $soundFile = @(
            ($env:SystemRoot + '\Media\Windows Notify Calendar.wav'),
            ($env:SystemRoot + '\Media\Windows Notify System Generic.wav'),
            ($env:SystemRoot + '\Media\Windows Notify.wav')
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1

        if ($soundFile) {
            $player = [System.Media.SoundPlayer]::new($soundFile)
            try { $player.PlaySync() } finally { $player.Dispose() }
        } else {
            [System.Media.SystemSounds]::Asterisk.Play()
            Start-Sleep -Milliseconds 300
        }
    } catch {
        [System.Media.SystemSounds]::Asterisk.Play()
        Start-Sleep -Milliseconds 300
    }
}
