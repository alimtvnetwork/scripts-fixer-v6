# Spec: Script 36 -- Install OBS Studio

## Purpose

Install OBS Studio via Chocolatey and/or sync curated settings
from the bundled zip to the user's AppData directory. Supports three modes.

## Naming Convention

| Shortcut Label | Meaning | Keyword |
|----------------|---------|---------|
| **OBS + Settings** | Install OBS and sync settings | `obs+settings`, `obs` |
| **OBS Settings** | Sync settings only (no install) | `obs-settings` |
| **Install OBS** | Install only (no settings sync) | `install-obs` |

## Usage

```powershell
.\run.ps1 install obs              # OBS + Settings (default)
.\run.ps1 install obs+settings     # OBS + Settings (explicit)
.\run.ps1 install obs-settings     # OBS Settings only
.\run.ps1 install install-obs      # Install OBS only
.\run.ps1 -I 36                    # OBS + Settings (default mode)
.\run.ps1 -I 36 -- -Mode settings-only   # OBS Settings only
.\run.ps1 -I 36 -- -Mode install-only    # Install OBS only
```

## Settings Package

The settings are bundled as `scripts/36-install-obs/settings/obs-settings.zip`.

The zip is extracted to the user-specific roaming path:
- `%APPDATA%\obs-studio\` (resolves to `C:\Users\{user}\AppData\Roaming\obs-studio\`)

This is a **full replace** -- all files in the zip overwrite whatever exists
in the target directory. Contents include: profiles, scenes, global.ini,
plugin_config.

### Important: Settings always sync

When the install check finds OBS is already installed (via `.installed/obs.json`),
the install step is skipped but **settings sync still runs** in `install+settings`
mode. This is intentional -- the user may want to restore corrupted or changed settings.

## Modes

### install+settings (OBS + Settings)

1. Install OBS Studio via Chocolatey (if not already installed)
2. Verify installation
3. Extract settings zip to `%APPDATA%\obs-studio\`

### settings-only (OBS Settings)

1. Skip OBS installation entirely
2. Extract settings zip to `%APPDATA%\obs-studio\`

### install-only (Install OBS)

1. Install OBS Studio via Chocolatey (if not already installed)
2. Verify installation
3. Skip settings sync

## Mode Resolution Order

1. `-Mode` parameter on `run.ps1` (highest priority)
2. `$env:OBS_MODE` environment variable (set by keyword resolver)
3. Default: `install+settings`

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `obs.enabled` | bool | Toggle script |
| `obs.chocoPackage` | string | Chocolatey package name (`obs-studio`) |
| `obs.syncSettings` | bool | Whether to copy settings after install |
| `obs.defaultMode` | string | Default mode when not specified |

## Verification Paths

- `$env:ProgramFiles\obs-studio\bin\64bit\obs64.exe`
- `${env:ProgramFiles(x86)}\obs-studio\bin\64bit\obs64.exe`

## Log Messages

Defined in `log-messages.json`. Key messages:
- `alreadyInstalled` -- shown when OBS version matches tracked record
- `syncingSettings` / `settingsSynced` -- settings extraction progress
- `settingsSkipped` -- no settings files found in script folder

## Helpers

| File | Function | Purpose |
|------|----------|---------|
| `obs.ps1` | `Install-OBS` | Install via Chocolatey, verify, track (accepts `-Mode`) |
| `obs.ps1` | `Sync-OBSSettings` | Extract settings zip to AppData |
