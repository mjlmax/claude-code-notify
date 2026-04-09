---
name: setup-notify
description: Install and configure Windows desktop notifications for Claude Code
---

# Setup Notifications

Run this command to set up Windows desktop toast notifications for Claude Code.

## What it does

1. Installs the BurntToast PowerShell module (if not present)
2. Registers the `claude-focus://` protocol handler for click-to-focus
3. Sends a test notification to verify everything works

## Quick Setup

Run in PowerShell 7 (`pwsh`):

```powershell
# Install BurntToast
Install-Module -Name BurntToast -Force -Scope CurrentUser

# Register click-to-focus protocol
pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/register-protocol.ps1"
```

## Test

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/notify.ps1" -Title "Test" -Message "Setup complete!"
```
