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
| `-Help` | Show usage information |

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
