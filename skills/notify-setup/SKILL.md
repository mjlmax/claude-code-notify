---
name: notify-setup
description: Use when the user asks to set up, configure, install, troubleshoot, or customize Claude Code desktop notifications on Windows. Also use when the user mentions toast notifications, notification sounds, task completion alerts, or BurntToast.
version: 1.0.0
---

# Claude Code Notify — Setup Guide

This skill helps users install and configure Windows desktop notifications for Claude Code.

## Prerequisites Check

Before setup, verify these requirements:

1. **PowerShell 7** — Run `pwsh --version`. If not installed: `winget install Microsoft.PowerShell`
2. **BurntToast module** — Run `pwsh -Command "Install-Module -Name BurntToast -Force -Scope CurrentUser"`

## Installation Steps

### Step 1: Register the click-to-focus protocol

Run the registration script:
```
pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/register-protocol.ps1"
```

### Step 2: Verify the installation

Test notification:
```
pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/notify.ps1" -Title "Test" -Message "If you see this, setup is complete!"
```

Test click-to-focus:
```
pwsh -Command "Start-Process 'claude-focus://'"
```

## Customization

Users can adjust these parameters in their `settings.json` hooks:

- **Title**: The notification title text
- **Message**: The notification body text
- **Cooldown**: Debounce interval in seconds (default: 30)

## Troubleshooting

- **No toast popup**: Check `pwsh --version` (need v7+), verify BurntToast is installed
- **No sound**: Check Windows notification settings, ensure the app is not set to silent
- **False triggers**: Increase the `-Cooldown` parameter (e.g., `-Cooldown 60`)
- **Click doesn't focus VS Code**: Re-run `register-protocol.ps1`, then test with `Start-Process 'claude-focus://'`

## Uninstall

To remove the protocol handler:
```
pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/register-protocol.ps1" -Uninstall
```
