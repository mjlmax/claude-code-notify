# claude-code-notify

[English](README.md) | **中文**

Claude Code 的 Windows 桌面通知插件 —— 任务完成或需要确认时自动弹窗提醒，告别反复切屏。

![Windows 10/11](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)
![PowerShell 7+](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)
![License MIT](https://img.shields.io/badge/License-MIT-green)

## 功能特性

当 Claude Code 完成任务或需要你确认时，你会收到：

- **桌面弹窗** — Windows 右下角 Toast 通知卡片
- **提示音** — 系统通知音效提醒
- **任务栏闪烁** — VS Code 图标橙色闪烁，吸引注意力
- **一键切换** — 弹窗上的按钮可直接唤醒 VS Code 到前台

### 智能过滤

不是每次 Stop 事件都需要弹窗。插件内置两层防骚扰机制：

- **前台检测** — 如果 VS Code 已经是当前活动窗口，不弹窗。你已经在看了，不需要提醒。
- **30 秒防抖** — 30 秒内重复触发会被静默忽略，一次通知就够了。

## 工作原理

```
Claude Code Stop/Notification 事件
        │
        ▼
  ┌─────────────┐     是
  │  VS Code    │──────────▶ 跳过（你正在看）
  │  在前台？   │
  └──────┬──────┘
         │ 否
         ▼
  ┌─────────────┐     是
  │  距上次通知 │──────────▶ 跳过（防抖）
  │  < 30秒？   │
  └──────┬──────┘
         │ 否
         ▼
  ┌─────────────┐
  │ 闪烁 VS     │
  │ Code 图标   │
  └──────┬──────┘
         ▼
  ┌─────────────┐  失败   ┌────────────┐
  │ BurntToast  │────────▶│ 系统音效   │
  │ + 协议按钮  │         │ 降级方案   │
  └─────────────┘         └────────────┘
```

## 环境要求

| 要求 | 安装方式 |
|---|---|
| Windows 10/11 | — |
| PowerShell 7+（`pwsh`） | `winget install Microsoft.PowerShell` |
| [BurntToast](https://github.com/Windos/BurntToast) 模块 | `Install-Module -Name BurntToast -Force -Scope CurrentUser` |
| Claude Code | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |

## 安装步骤

### 方式一：手动安装（推荐）

**1. 安装依赖**

```powershell
# 安装 PowerShell 7（如果还没装）
winget install Microsoft.PowerShell

# 安装 BurntToast 模块
pwsh -Command "Install-Module -Name BurntToast -Force -Scope CurrentUser"
```

**2. 下载并放置文件**

克隆仓库，将脚本文件复制到 Claude Code 配置目录：

```powershell
# 克隆仓库
git clone https://github.com/mjlmax/claude-code-notify.git

# 复制脚本
Copy-Item -Recurse claude-code-notify/hooks/scripts/* ~/.claude/hooks/
```

**3. 注册一键切换协议**

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ~/.claude/hooks/register-protocol.ps1
```

这一步会注册 `claude-focus://` 自定义 URI 协议。点击弹窗上的「切换到 Claude」按钮时，系统会通过 `wscript.exe` → VBScript → Win32 `SetForegroundWindow` 静默唤醒 VS Code 窗口。

**4. 配置 Claude Code 钩子**

编辑 `~/.claude/settings.json`，在 `hooks` 部分添加：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\你的用户名\\.claude\\hooks\\notify.ps1\" -Title \"Claude 任务完成\" -Message \"任务已完成，等待你的输入。\""
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
            "command": "pwsh -NoProfile -ExecutionPolicy Bypass -File \"C:\\Users\\你的用户名\\.claude\\hooks\\notify.ps1\" -Title \"Claude 需要确认\" -Message \"Claude 需要你的授权操作。\""
          }
        ]
      }
    ]
  }
}
```

把 `你的用户名` 替换成你自己 Windows 的用户名。

**5. 验证安装**

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ~/.claude/hooks/notify.ps1 -Title "测试" -Message "如果看到这个弹窗，说明安装成功！"
```

右下角应该弹出一张通知卡片，上面有一个「切换到 Claude」按钮。

### 方式二：作为 Claude Code 插件安装

如果你的 Claude Code 支持插件安装：

```
claude plugin install github:mjlmax/claude-code-notify
```

然后在 Claude Code 中运行 `/setup-notify` 完成配置。

## 参数说明

| 参数 | 默认值 | 说明 |
|---|---|---|
| `-Title` | `"Claude Code"` | 通知标题 |
| `-Message` | `"Task completed."` | 通知正文 |
| `-Cooldown` | `30` | 防抖冷却时间（秒） |

### 自定义示例

**加长防抖时间（适合频繁对话场景）：**

```
... -File "notify.ps1" -Title "完成" -Message "就绪" -Cooldown 60
```

**Stop 和 Notification 使用不同的提示文案：**

在两个钩子中分别设置不同的 `-Title` 和 `-Message`，光听声音就能分辨发生了什么。

## 文件结构

```
claude-code-notify/
├── .claude-plugin/
│   └── plugin.json              # 插件清单
├── hooks/
│   ├── hooks.json               # 钩子事件绑定
│   └── scripts/
│       ├── notify.ps1           # 主通知脚本
│       ├── focus-claude.ps1     # Win32 SetForegroundWindow 聚焦助手
│       ├── focus-claude.vbs     # VBScript 静默包装器（无黑窗）
│       └── register-protocol.ps1 # 注册/卸载 claude-focus:// 协议
├── commands/
│   └── setup-notify.md          # /setup-notify 斜杠命令
├── skills/
│   └── notify-setup/
│       └── SKILL.md             # 自动触发的安装/排障技能
├── LICENSE
└── README.md
```

## 一键切换原理

Windows Toast 通知无法直接运行脚本（会闪一下命令行黑窗）。本插件用三层链路解决了这个问题：

```
点击弹窗按钮
    │  activationType="protocol"
    ▼
claude-focus://          ← 自定义 URI 协议（注册在 HKCU）
    │
    ▼
wscript.exe              ← GUI 宿主，无命令行窗口
    │  执行 focus-claude.vbs
    ▼
pwsh -WindowStyle Hidden ← 隐藏的 PowerShell 进程
    │  执行 focus-claude.ps1
    ▼
SetForegroundWindow()    ← Win32 API 将 VS Code 唤醒到前台
```

## 常见问题

**没有弹窗**

```powershell
# 检查 PowerShell 版本（需要 7+）
pwsh --version

# 检查 BurntToast 是否已安装
pwsh -Command "Import-Module BurntToast; New-BurntToastNotification -Text '测试'"
```

**弹窗出来了但是没有声音**

- Windows 设置 → 系统 → 通知 → 找到 PowerShell → 确保声音没有被关掉
- 检查系统音量是否静音

**通知太频繁 / 误报**

- 加长防抖时间：在钩子命令中添加 `-Cooldown 60`
- 前台检测会在 VS Code 处于活动窗口时自动抑制通知

**点击按钮没有唤醒 VS Code**

```powershell
# 重新注册协议
pwsh -NoProfile -ExecutionPolicy Bypass -File register-protocol.ps1

# 直接测试协议
Start-Process 'claude-focus://'
```

**点击时闪了一下命令行窗口**

正常情况下 VBScript 包装器不会有黑窗。如果出现，请确认 `focus-claude.vbs` 和 `focus-claude.ps1` 在同一个目录下。

## 卸载

```powershell
# 移除协议处理器
pwsh -NoProfile -ExecutionPolicy Bypass -File register-protocol.ps1 -Uninstall

# 删除钩子脚本
Remove-Item ~/.claude/hooks/notify.ps1, ~/.claude/hooks/focus-claude.ps1, ~/.claude/hooks/focus-claude.vbs, ~/.claude/hooks/register-protocol.ps1

# 从 settings.json 中移除钩子配置（手动编辑）
```

## 为什么用 Hook 而不是提示词？

你可能想过一个更简单的办法：在 CLAUDE.md 里告诉 Claude "每次干完活播放提示音"。

试过了，不靠谱。

- 提示词是**软约束** — Claude 可能忘记，对话长了之后尤其容易
- Hook 是**硬约束** — Claude Code 的程序框架在事件触发时机械执行，不依赖 AI 判断
- Hook 不存在"忘了"这种可能

凡是需要百分之百可靠执行的事情，都应该交给机制，而不是交给概率。

## 联系方式

微信：`mjlmax`（加好友请备注 GitHub）

## 许可证

MIT
