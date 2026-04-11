# Spec: Script 41 -- Install Python Libraries

## Purpose

Install common Python/ML libraries via `pip` into the configured
`PYTHONUSERBASE` directory. Packages are organized into groups that can
be installed individually or all at once.

## Subcommands

| Command | Description |
|---------|-------------|
| `all` | Install all configured libraries (default) |
| `group <name>` | Install a specific library group |
| `add <pkg ...>` | Install specific packages by name |
| `list` | List available groups and their packages |
| `installed` | Show currently installed pip packages |
| `uninstall` | Uninstall all tracked libraries |
| `uninstall <pkg>` | Uninstall specific packages |
| `-Help` | Show usage information |

## Library Groups

| Group | Label | Packages |
|-------|-------|----------|
| `ml` | Machine Learning | numpy, scipy, scikit-learn, torch, tensorflow, keras |
| `data` | Data & Analytics | pandas, polars |
| `viz` | Visualization | matplotlib, seaborn, plotly |
| `web` | Web Frameworks | django, flask, fastapi, uvicorn |
| `scraping` | Scraping & HTTP | requests, beautifulsoup4 |
| `cv` | Computer Vision | opencv-python |
| `db` | Database | sqlalchemy |

## Parameters

| Parameter | Position | Description |
|-----------|----------|-------------|
| `-Path` | N/A | Not used directly; relies on `PYTHONUSERBASE` set by script 05 |

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `requiresPython` | bool | Asserts Python is installed before proceeding |
| `installToUserSite` | bool | Use `--user` flag with pip (installs to PYTHONUSERBASE) |
| `groups` | object | Named groups of packages |
| `allPackages` | array | Full list of all packages for `all` command |

## Flow

1. Assert Python and pip are available
2. Check `PYTHONUSERBASE` -- if set, install with `--user` flag
3. Install requested packages (all, group, or custom)
4. Save resolved state with installed package list
5. Save installed record

## Install Keywords

| Keyword |
|---------|
| `python-libs` |
| `pip-libs` |
| `ml-libs` |
| `python-packages` |

**Group shortcuts** (installs multiple scripts):

| Keyword | Scripts |
|---------|---------|
| `python+libs` | 5, 41 |
| `ml-dev` | 5, 41 |

```powershell
.\run.ps1                          # Install all libraries
.\run.ps1 group ml                 # Install ML group only
.\run.ps1 group viz                # Install visualization only
.\run.ps1 add jupyterlab streamlit # Install custom packages
.\run.ps1 list                     # Show available groups
.\run.ps1 installed                # Show pip packages
.\run.ps1 uninstall                # Remove all tracked libraries
.\run.ps1 uninstall numpy pandas   # Remove specific packages
```
