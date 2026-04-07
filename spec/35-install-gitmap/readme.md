# Install GitMap (Script 35)

## Overview

Script 35 installs the **GitMap CLI** -- a Git repository navigator tool for Windows. It uses the remote installer from GitHub (`alimtvnetwork/git-repo-navigator`).

## Install Command

```powershell
# Via run.ps1
.\run.ps1 install gitmap
.\run.ps1 -I 35

# Direct remote install (standalone)
irm https://raw.githubusercontent.com/alimtvnetwork/git-repo-navigator/main/gitmap/scripts/install.ps1 | iex
```

## Config (`config.json`)

| Key                  | Description                                |
|----------------------|--------------------------------------------|
| `gitmap.enabled`     | Enable/disable GitMap install              |
| `gitmap.verifyCommand` | Command to check if GitMap is installed  |
| `gitmap.installUrl`  | URL to the remote install.ps1              |
| `gitmap.repo`        | GitHub repository                          |
| `gitmap.installDir`  | Override install directory (empty = default)|

Default install directory: `C:\DevTools\GitMap` (configurable via `devDir.default`).

## Detection

1. Checks `gitmap` in PATH (`Get-Command`)
2. Falls back to known install paths: `$env:LOCALAPPDATA\gitmap\gitmap.exe` and `C:\DevTools\GitMap\gitmap.exe`

## How It Works

1. Checks if GitMap is already installed
2. If not found, downloads `install.ps1` from GitHub via `Invoke-RestMethod`
3. Executes the installer script with optional `-InstallDir` override
4. Refreshes PATH and verifies installation
5. Saves resolved state

## Keywords

`gitmap`, `git-map`
