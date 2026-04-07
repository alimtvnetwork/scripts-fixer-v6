# Spec: Script 37 -- Install Windows Terminal

## Purpose

Install Windows Terminal via Chocolatey and/or sync curated settings
(settings.json) from the bundled settings folder. Supports three modes.

## Naming Convention

| Shortcut Label | Meaning | Keyword |
|----------------|---------|---------|
| **WT + Settings** | Install Windows Terminal and sync settings | `wt+settings`, `wt`, `windows-terminal` |
| **WT Settings** | Sync settings only (no install) | `wt-settings` |
| **Install WT** | Install only (no settings sync) | `install-wt` |

## Usage

```powershell
.\run.ps1 install wt                # WT + Settings (default)
.\run.ps1 install wt+settings       # WT + Settings (explicit)
.\run.ps1 install wt-settings       # WT Settings only
.\run.ps1 install install-wt        # Install WT only
.\run.ps1 -I 37                     # WT + Settings (default mode)
.\run.ps1 -I 37 -- -Mode settings-only   # WT Settings only
.\run.ps1 -I 37 -- -Mode install-only    # Install WT only
```

## Settings Package

The settings source lives in the shared settings folder:
- `settings/03 - windows-terminal/`

### Sync Process

1. Locate the Windows Terminal package directory at
   `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\`
2. Copy `settings.json` from the settings source to the target directory
3. Copy any additional files (themes, fragments) to the same target

Windows Terminal reads `settings.json` from `LocalState\` on startup --
no CLI import command is needed.

### Important: Settings always sync

When the install check finds Windows Terminal is already installed
(via `.installed/windows-terminal.json`), the install step is skipped but
**settings sync still runs** in `install+settings` mode. This is intentional --
the user may want to restore corrupted or changed settings.

## Modes

### install+settings (WT + Settings)

1. Install Windows Terminal via Chocolatey (if not already installed)
2. Verify installation
3. Copy settings.json and extras to LocalState

### settings-only (WT Settings)

1. Skip Windows Terminal installation entirely
2. Copy settings.json and extras to LocalState

### install-only (Install WT)

1. Install Windows Terminal via Chocolatey (if not already installed)
2. Verify installation
3. Skip settings sync

## Mode Resolution Order

1. `-Mode` parameter on `run.ps1` (highest priority)
2. `$env:WT_MODE` environment variable (set by keyword resolver)
3. Default: `install+settings`

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `windowsTerminal.enabled` | bool | Toggle script |
| `windowsTerminal.chocoPackage` | string | Chocolatey package name (`microsoft-windows-terminal`) |
| `windowsTerminal.syncSettings` | bool | Whether to copy settings after install |
| `windowsTerminal.defaultMode` | string | Default mode when not specified |
| `windowsTerminal.validModes` | array | Valid mode values for audit validation |

## Verification

- `Get-Command wt` (PATH lookup)
- `%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe`

## Log Messages

Defined in `log-messages.json`. Key messages:
- `alreadyInstalled` -- shown when WT version matches tracked record
- `syncingSettings` / `settingsSynced` -- settings copy progress
- `settingsSkipped` -- no settings files found in settings source

## Helpers

| File | Function | Purpose |
|------|----------|---------|
| `windows-terminal.ps1` | `Install-WindowsTerminal` | Install via Chocolatey, verify, track (accepts `-Mode`) |
| `windows-terminal.ps1` | `Sync-WindowsTerminalSettings` | Copy settings.json to LocalState |
