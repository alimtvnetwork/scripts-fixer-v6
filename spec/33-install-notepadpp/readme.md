# Spec: Script 33 -- Install Notepad++

## Purpose

Install Notepad++ text editor via Chocolatey and sync user settings
from the script's `settings/` folder to the user's AppData directory.

## Usage

```powershell
.\run.ps1 -I 33            # Install Notepad++
.\run.ps1 Install notepad++ # Keyword shortcut
```

## Settings Sync

After installation, all files in `scripts/33-install-notepadpp/settings/`
are copied (overwrite) to `%APPDATA%\Notepad++\`. This replaces any
existing settings with the curated defaults.

| Source | Destination |
|--------|-------------|
| `settings/*` | `%APPDATA%\Notepad++\*` |

To update settings: replace files in the `settings/` folder and re-run.

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `notepadpp.enabled` | bool | Toggle script |
| `notepadpp.chocoPackage` | string | Chocolatey package name |
| `notepadpp.syncSettings` | bool | Whether to copy settings after install |

## Log Messages

Defined in `log-messages.json`. Key messages:
- `alreadyInstalled` -- shown when Notepad++ version matches tracked record
- `syncingSettings` / `settingsSynced` -- settings copy progress
- `settingsSkipped` -- no settings files found in script folder

## Helpers

| File | Function | Purpose |
|------|----------|---------|
| `notepadpp.ps1` | `Install-NotepadPP` | Install via Chocolatey, verify, track |
| `notepadpp.ps1` | `Sync-NotepadPPSettings` | Copy settings to AppData |
