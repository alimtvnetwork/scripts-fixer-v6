# Spec: Script 05 -- Install Python

## Purpose

Install Python via Chocolatey and configure `PYTHONUSERBASE` so that
`pip install --user` targets the shared dev directory.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install Python + configure pip (default) |
| `install` | Install/upgrade Python only |
| `configure` | Configure pip site and PATH only |
| `uninstall` | Uninstall Python, remove env vars, clean dev dir, purge tracking |
| `-Help` | Show usage information |

## Parameters

| Parameter | Position | Description |
|-----------|----------|-------------|
| `-Path` | 1 (after command) | Custom dev directory path. Overrides smart drive detection and `$env:DEV_DIR`. All pip site configuration uses this path. |

### Usage with -Path

```powershell
.\run.ps1 all F:\dev           # Install + configure pip to F:\dev\python
.\run.ps1 install D:\projects  # Install Python, dev dir set to D:\projects
.\run.ps1 -Path E:\dev         # Same as: .\run.ps1 all E:\dev
.\run.ps1 configure G:\tools   # Configure pip site to G:\tools\python
```

When `-Path` is provided, the script skips smart drive detection entirely
and uses the given path as the dev directory. The pip user site will be
set to `<Path>\python` (the `devDirSubfolder` from config.json).

## Uninstall

The `uninstall` subcommand performs a full cleanup:

1. **Chocolatey uninstall** -- removes the Python package and its dependencies
2. **Environment variable** -- removes `PYTHONUSERBASE` from User scope
3. **PATH cleanup** -- removes the `Scripts\` directory from User PATH
4. **Dev directory** -- deletes the `<devDir>\python` subfolder and all its contents
5. **Tracking records** -- purges `.installed/python.json` and `.resolved/05-install-python/`

```powershell
.\run.ps1 uninstall            # Full uninstall with smart dev dir detection
.\run.ps1 uninstall E:\dev     # Uninstall, clean E:\dev\python specifically
```

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `chocoPackageName` | string | Chocolatey package (`python3`) |
| `alwaysUpgradeToLatest` | bool | Upgrade on every run |
| `devDirSubfolder` | string | Subfolder under dev dir |
| `pip.setUserSite` | bool | Whether to set PYTHONUSERBASE |
| `pip.userSitePath` | string | Fallback site path |
| `path.updateUserPath` | bool | Add Scripts dir to PATH |
| `path.ensurePipInPath` | bool | Ensure pip is reachable |

## Flow

1. Assert admin + Chocolatey
2. Install/upgrade Python via Chocolatey
3. Set `PYTHONUSERBASE` env var to dev dir subfolder
4. Add `Scripts\` to User PATH
5. Save resolved state

## Install Keywords

| Keyword |
|---------|
| `python` |
| `pip` |
| `python-pip` |
| `pythonpip` |
| `python+pip` |

**Group shortcuts** (installs multiple scripts):

| Keyword | Scripts |
|---------|---------|
| `full-stack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16 |
| `fullstack` | 1, 2, 3, 4, 5, 7, 8, 9, 11, 16 |
| `backend` | 5, 6, 16, 20 |

```powershell
.\run.ps1 install python
.\run.ps1 install full-stack
```
