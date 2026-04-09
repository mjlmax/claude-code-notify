# claude-code-notify

Windows desktop notifications for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Get notified when tasks complete or need your input — never waste time switching back to check again.

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)
![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## What it does

When Claude Code finishes a task or needs your confirmation, you get:

- **Toast notification** — A Windows desktop popup with title and message
- **Sound alert** — A reminder chime via Windows notification audio
- **Taskbar flash** — VS Code icon flashes orange to catch your eye
- **Click to focus** — A button on the toast brings VS Code to the foreground

### Smart notification filtering

Not every Stop event deserves a popup. The plugin includes two guard layers to prevent notification spam:

- **Foreground detection** — If VS Code is already the active window, no notification fires. You're already looking at it.
- **30-second debounce** — Repeated triggers within 30 seconds are silently dropped. One notification is enough.

## How it works

```
Claude Code Stop/Notification event
        │
        ▼
  ┌─────────────┐     yes
  │ VS Code is  │──────────▶ skip (you're already looking)
  │ foreground? │
  └──────┬──────┘
         │ no
         ▼
  ┌─────────────┐     yes
  │  Last toast │──────────▶ skip (debounce)
  │  < 30s ago? │
  └──────┬──────┘
         │ no
         ▼
  ┌─────────────┐
  │ Flash VS    │
  │ Code icon   │
  └──────┬──────┘
         ▼
  ┌─────────────┐     fail    ┌────────────┐
  │ BurntToast  │────────────▶│ System WAV │
  │ + protocol  │             │ fallback   │
  │   button    │             └────────────┘
  └─────────────┘
```

## Requirements

| Requirement | How to get it |
|---|---|
| Windows 10/11 | — |
| PowerShell 7+ (`pwsh`) | `winget install Microsoft.PowerShell` |
| [BurntToast](https://github.com/Windos/BurntToast) module | `Install-Module -Name BurntToast -Force -Scope CurrentUser` |
| Claude Code | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |

## Installation

### Option A: Manual setup (recommended)

**1. Install dependencies**

```powershell
# Install PowerShell 7 (if not installed)
winget install Microsoft.PowerShell

# Install BurntToast module
pwsh -Command "Install-Module -Name BurntToast -Force -Scope CurrentUser"
```

**2. Download and place files**

Clone or download this repo, then copy the hook scripts to your Claude Code config directory:

```powershell
# Clone
git clone https://github.com/mjlmax/claude-code-notify.git

# Copy scripts
Copy-Item -Recurse claude-code-notify/hooks/scripts/* ~/.claude/hooks/
```

**3. Register the click-to-focus protocol**

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ~/.claude/hooks/register-protocol.ps1
```

This registers `claude-focus://` as a custom URI protocol. When you click the "Switch to Claude" button on a toast, it silently brings VS Code to the foreground via `wscript.exe` → VBScript → Win32 `SetForegroundWindow`.

**4. Add hooks to your Claude Code config**

Edit `~/.claude/settings.json` and add to the `hooks` section:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\notify.ps1\" -Title \"Claude Task Done\" -Message \"Task completed. Waiting for your input.\""
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\YOUR_USERNAME\\.claude\\hooks\\notify.ps1\" -Title \"Claude Needs Input\" -Message \"Claude is waiting for your confirmation.\""
          }
        ]
      }
    ]
  }
}
```

Replace `YOUR_USERNAME` with your Windows username.

**5. Verify**

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ~/.claude/hooks/notify.ps1 -Title "Test" -Message "Setup complete!"
```

You should see a toast popup with a "Switch to Claude" button.

### Option B: As a Claude Code plugin

If Claude Code plugin installation is available:

```
claude plugin install github:mjlmax/claude-code-notify
```

Then run `/setup-notify` in Claude Code to complete the setup.

## Configuration

### Hook parameters

| Parameter | Default | Description |
|---|---|---|
| `-Title` | `"Claude Code"` | Toast notification title |
| `-Message` | `"Task completed."` | Toast notification body |
| `-Cooldown` | `30` | Seconds to suppress duplicate notifications |

### Customization examples

**Longer cooldown for chatty sessions:**

```
... -File "notify.ps1" -Title "Done" -Message "Ready." -Cooldown 60
```

**Different messages for Stop vs Notification:**

Use distinct `-Title` and `-Message` values in each hook to tell them apart by sound context alone.

## File structure

```
claude-code-notify/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── hooks/
│   ├── hooks.json               # Hook event bindings
│   └── scripts/
│       ├── notify.ps1           # Main notification script
│       ├── focus-claude.ps1     # Win32 SetForegroundWindow helper
│       ├── focus-claude.vbs     # Silent VBScript wrapper (no console flash)
│       └── register-protocol.ps1 # Registers/unregisters claude-focus://
├── commands/
│   └── setup-notify.md          # /setup-notify slash command
├── skills/
│   └── notify-setup/
│       └── SKILL.md             # Auto-invoked setup/troubleshooting skill
├── LICENSE
└── README.md
```

## How click-to-focus works

Windows Toast notifications can't directly run scripts without flashing a console window. This plugin solves it with a three-layer chain:

```
Toast button click
    │  activationType="protocol"
    ▼
claude-focus://          ← Custom URI protocol (registered in HKCU)
    │
    ▼
wscript.exe              ← GUI host, no console window
    │  runs focus-claude.vbs
    ▼
pwsh -WindowStyle Hidden ← Hidden PowerShell process
    │  runs focus-claude.ps1
    ▼
SetForegroundWindow()    ← Win32 API brings VS Code to front
```

## Troubleshooting

**No toast appears**

```powershell
# Check PowerShell version (need 7+)
pwsh --version

# Check BurntToast is installed
pwsh -Command "Import-Module BurntToast; New-BurntToastNotification -Text 'Test'"
```

**Toast appears but no sound**

- Windows Settings → System → Notifications → Find PowerShell → Ensure sound is ON
- Check system volume is not muted

**Too many notifications / false triggers**

- Increase cooldown: add `-Cooldown 60` to the hook command
- The foreground detection automatically suppresses notifications when VS Code is active

**Click button doesn't focus VS Code**

```powershell
# Re-register the protocol
pwsh -NoProfile -ExecutionPolicy Bypass -File register-protocol.ps1

# Test protocol directly
Start-Process 'claude-focus://'
```

**Console window flashes briefly on click**

This shouldn't happen with the VBScript wrapper. If it does, verify `focus-claude.vbs` exists in the same directory as `focus-claude.ps1`.

## Uninstall

```powershell
# Remove the protocol handler
pwsh -NoProfile -ExecutionPolicy Bypass -File register-protocol.ps1 -Uninstall

# Remove hook scripts
Remove-Item ~/.claude/hooks/notify.ps1, ~/.claude/hooks/focus-claude.ps1, ~/.claude/hooks/focus-claude.vbs, ~/.claude/hooks/register-protocol.ps1

# Remove hooks from settings.json (edit manually)
```

## Why hooks instead of prompt rules?

You might think "just tell Claude to play a sound when it's done" in CLAUDE.md. We tried. It's unreliable.

- Prompt rules are **soft constraints** — Claude can forget, especially in long conversations
- Hooks are **hard constraints** — the Claude Code framework executes them mechanically on every matching event
- There's zero chance of a hook "forgetting" to fire

Anything that must happen 100% of the time belongs in a hook, not a prompt.

## Contact

WeChat: `mjlmax` (add as friend, note: GitHub)

## License

MIT
