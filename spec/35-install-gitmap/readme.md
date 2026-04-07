# Install GitMap (Script 35)

## Overview

Script 35 installs the **GitMap CLI** -- a Git repository navigator tool for Windows. It uses the remote installer from GitHub (`alimtvnetwork/gitmap-v2`).

## Install Command

```powershell
# Via run.ps1
.\run.ps1 install gitmap
.\run.ps1 -I 35

# Direct remote install (standalone)
irm https://raw.githubusercontent.com/alimtvnetwork/gitmap-v2/main/gitmap/scripts/install.ps1 | iex
```

## Config (`config.json`)

| Key                  | Description                                |
|----------------------|--------------------------------------------|
| `devDir.mode`        | Drive resolution mode (`smart` or legacy)  |
| `devDir.default`     | Default install directory                  |
| `devDir.override`    | Force a specific directory (overrides all) |
| `gitmap.enabled`     | Enable/disable GitMap install              |
| `gitmap.verifyCommand` | Command to check if GitMap is installed  |
| `gitmap.installUrl`  | URL to the remote install.ps1              |
| `gitmap.repo`        | GitHub repository                          |
| `gitmap.installDir`  | Override install directory (bypasses devDir)|

Default install directory: `C:\DevTools\GitMap` (resolved via `devDir` config).

## Install Directory Resolution

Priority order:
1. `gitmap.installDir` -- explicit override in config
2. `Resolve-DevDir` -- uses `$env:DEV_DIR`, smart drive detection (E: > D: > best drive), or user prompt
3. `devDir.default` -- legacy fallback from config
4. Hardcoded `C:\DevTools\GitMap`

The resolved path is passed as `-InstallDir` to the remote installer script.

## Remote Installer Flags

| Flag           | Description                          | Example                          |
|----------------|--------------------------------------|----------------------------------|
| `-InstallDir`  | Custom install directory             | `-InstallDir C:\tools\gitmap`    |
| `-Version`     | Pin a specific release               | `-Version v2.49.1`              |
| `-Arch`        | Force architecture (amd64, arm64)    | `-Arch arm64`                   |
| `-NoPath`      | Skip adding to user PATH             | `-NoPath`                       |

## Detection

1. Checks `gitmap` in PATH (`Get-Command`)
2. Falls back to known install paths: `$env:LOCALAPPDATA\gitmap\gitmap.exe` and `C:\DevTools\GitMap\gitmap.exe`
3. Also checks devDir-resolved path: `$env:DEV_DIR\GitMap\gitmap.exe`

## How It Works

1. Checks if GitMap is already installed
2. If not found, resolves install directory via devDir system
3. Downloads `install.ps1` from GitHub via `Invoke-RestMethod`
4. Executes the installer script with `-InstallDir <resolved-path>`
5. Refreshes PATH and verifies installation
6. Saves resolved state (includes installDir)

## Keywords

`gitmap`, `git-map`
