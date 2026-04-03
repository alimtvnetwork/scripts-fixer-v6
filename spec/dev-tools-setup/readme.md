# Spec: Dev Environment Setup Scripts (03-08)

## Overview

A suite of PowerShell scripts that set up a complete Windows development
environment from scratch. Each script handles one concern and can run
standalone or be orchestrated by script 08.

All tools are installed into a configurable **dev directory** (default: `E:\dev`)
with structured subdirectories per tool.

---

## Script Inventory

| Script | Folder | Purpose | Requires Admin |
|--------|--------|---------|----------------|
| 03 | `03-install-package-managers` | Install/update Chocolatey + Winget | Yes |
| 04 | `04-install-golang` | Install Go via Choco, configure GOPATH + go env | Yes |
| 05 | `05-install-nodejs` | Install Node.js via Choco, configure prefix | Yes |
| 06 | `06-install-python` | Install Python via Choco, configure pip | Yes |
| 07 | `07-install-pnpm` | Install + configure pnpm (global store in dev dir) | No |
| 08 | `08-install-all-dev-tools` | Orchestrator: runs 03-07 in sequence | Yes |

---

## Shared Dev Directory Structure

```
E:\dev\                                # Configurable root (default E:\dev)
├── go\                                # GOPATH
│   ├── bin\                           # Go binaries (added to PATH)
│   ├── pkg\mod\                       # GOMODCACHE
│   └── cache\build\                   # GOCACHE
├── nodejs\                            # Node.js custom install prefix
│   └── node_modules\                  # Global modules
├── python\                            # Python user site / virtualenvs
│   └── Scripts\                       # pip scripts (added to PATH)
└── pnpm\                              # pnpm global store
    └── store\                         # Content-addressable store
```

---

## Shared Helpers (new additions)

| File | Functions | Purpose |
|------|-----------|---------|
| `scripts/shared/path-utils.ps1` | `Add-ToUserPath`, `Add-ToMachinePath`, `Test-InPath` | Safe PATH manipulation with dedup |
| `scripts/shared/choco-utils.ps1` | `Assert-Choco`, `Install-ChocoPackage`, `Upgrade-ChocoPackage` | Chocolatey wrappers with logging |
| `scripts/shared/dev-dir.ps1` | `Resolve-DevDir`, `Initialize-DevDir` | Dev directory resolution + creation |

---

## Script 03: install-package-managers

### Purpose
Install and/or update Chocolatey and Winget package managers.

### Subcommands
```powershell
.\run.ps1 choco              # Install/update Chocolatey only
.\run.ps1 winget             # Install/verify Winget only
.\run.ps1 all                # Install both (default)
.\run.ps1 --help             # Show available commands
```

### File Structure
```
scripts/03-install-package-managers/
├── config.json
├── log-messages.json
├── run.ps1
└── helpers/
    ├── choco.ps1            # Chocolatey install/update logic
    └── winget.ps1           # Winget verification/install logic
```

### config.json Schema
```json
{
  "chocolatey": {
    "enabled": true,
    "installUrl": "https://chocolatey.org/install.ps1",
    "upgradeOnRun": true
  },
  "winget": {
    "enabled": true,
    "installIfMissing": true,
    "msStoreId": "9NBLGGH4NNS1"
  }
}
```

### Flow
1. Parse subcommand (default: `all`)
2. If `--help`: display usage and exit
3. Assert admin privileges
4. For Chocolatey: check `choco.exe` in PATH, install if missing, upgrade if configured
5. For Winget: check `winget.exe` in PATH, install via MS Store/GitHub if missing
6. Save resolved versions + paths to `.resolved/`

---

## Script 04: install-golang

### Purpose
Install Go via Chocolatey, configure GOPATH, GOMODCACHE, GOCACHE, GOPROXY,
GOPRIVATE, and update PATH. Adapted from user's existing `go-install.ps1`.

### Subcommands
```powershell
.\run.ps1 install            # Install Go (default)
.\run.ps1 configure          # Configure env only (skip install)
.\run.ps1 --help             # Show available commands
```

### File Structure
```
scripts/04-install-golang/
├── config.json              # Adapted from go-config.sample.json
├── log-messages.json
├── run.ps1
└── helpers/
    └── golang.ps1           # Install, path resolution, go env configuration
```

### config.json Schema
Preserves the proven structure from the user's existing `go-config.json`:
```json
{
  "enabled": true,
  "chocoPackageName": "golang",
  "alwaysUpgradeToLatest": true,
  "devDirSubfolder": "go",
  "gopath": {
    "mode": "json-or-prompt",
    "default": "E:\\dev\\go",
    "override": ""
  },
  "path": {
    "updateUserPath": true,
    "ensureGoBinInPath": true
  },
  "goEnv": {
    "applyMode": "json-or-prompt",
    "relativeToGopath": true,
    "settings": {
      "GOMODCACHE": { "enabled": true, "relativePath": "pkg\\mod" },
      "GOCACHE": { "enabled": true, "relativePath": "cache\\build" },
      "GOPROXY": { "enabled": true, "value": "https://proxy.golang.org,direct" },
      "GOPRIVATE": { "enabled": true, "value": "", "promptOnFirstRun": true }
    }
  }
}
```

### Reused Logic from Existing Script
| Original Function | New Location | Changes |
|-------------------|-------------|---------|
| `Ensure-Chocolatey` | `shared/choco-utils.ps1` | Shared across all scripts |
| `Resolve-Gopath` | `helpers/golang.ps1` | Uses shared `Resolve-DevDir` for base, keeps Go-specific logic |
| PATH update block | `shared/path-utils.ps1` | Extracted as `Add-ToUserPath` with dedup |
| `Set-GoEnv` | `helpers/golang.ps1` | Keeps as-is, uses shared logging |
| Config schema | `config.json` | Updated defaults to use dev dir |

---

## Script 05: install-nodejs

### Purpose
Install Node.js (LTS) via Chocolatey, configure npm global prefix inside dev dir.

### File Structure
```
scripts/05-install-nodejs/
├── config.json
├── log-messages.json
├── run.ps1
└── helpers/
    └── nodejs.ps1
```

### config.json Schema
```json
{
  "enabled": true,
  "chocoPackageName": "nodejs-lts",
  "alwaysUpgradeToLatest": true,
  "devDirSubfolder": "nodejs",
  "npm": {
    "setGlobalPrefix": true,
    "globalPrefix": "E:\\dev\\nodejs"
  },
  "path": {
    "updateUserPath": true,
    "ensureNpmBinInPath": true
  }
}
```

---

## Script 06: install-python

### Purpose
Install Python via Chocolatey, configure pip user site inside dev dir.

### File Structure
```
scripts/06-install-python/
├── config.json
├── log-messages.json
├── run.ps1
└── helpers/
    └── python.ps1
```

### config.json Schema
```json
{
  "enabled": true,
  "chocoPackageName": "python3",
  "alwaysUpgradeToLatest": true,
  "devDirSubfolder": "python",
  "pip": {
    "setUserSite": true,
    "userSitePath": "E:\\dev\\python"
  },
  "path": {
    "updateUserPath": true,
    "ensurePipInPath": true
  }
}
```

---

## Script 07: install-pnpm

### Purpose
Install pnpm globally and configure the global store inside dev dir.

### File Structure
```
scripts/07-install-pnpm/
├── config.json
├── log-messages.json
├── run.ps1
└── helpers/
    └── pnpm.ps1
```

### config.json Schema
```json
{
  "enabled": true,
  "installMethod": "npm",
  "devDirSubfolder": "pnpm",
  "store": {
    "setStorePath": true,
    "storePath": "E:\\dev\\pnpm\\store"
  },
  "path": {
    "updateUserPath": true
  }
}
```

### Flow
1. Check if `pnpm` is available
2. If not: install via `npm install -g pnpm` (requires Node.js from script 05)
3. Configure `pnpm config set store-dir` to dev dir
4. Add pnpm global bin to PATH
5. Save resolved to `.resolved/`

---

## Script 08: install-all-dev-tools

### Purpose
Orchestrator that runs scripts 03-07 in sequence. Resolves the dev directory
once, passes it to all child scripts via environment variable.

### Subcommands
```powershell
.\run.ps1                    # Run all (default)
.\run.ps1 --skip 05,07       # Skip Node.js and pnpm
.\run.ps1 --only 03,04       # Run only package managers + Go
.\run.ps1 --help             # Show available commands
```

### File Structure
```
scripts/08-install-all-dev-tools/
├── config.json
├── log-messages.json
├── run.ps1
└── helpers/
    └── orchestrator.ps1
```

### config.json Schema
```json
{
  "devDir": {
    "mode": "json-or-prompt",
    "default": "E:\\dev",
    "override": ""
  },
  "scripts": {
    "03": { "enabled": true },
    "04": { "enabled": true },
    "05": { "enabled": true },
    "06": { "enabled": true },
    "07": { "enabled": true }
  },
  "sequence": ["03", "04", "05", "06", "07"]
}
```

### Flow
1. Resolve dev directory (prompt user or use config default)
2. Create dev directory structure
3. Set `$env:DEV_DIR` so child scripts read it
4. Run each enabled script in sequence
5. Summary of what was installed, paths configured

---

## --help Convention

Every script supports `--help` (or `-Help`) which prints:
- Script name and version
- One-line description
- Available subcommands with descriptions
- Example usage

```
  VS Code Settings Sync -- v5.0.0
  Imports settings, keybindings, and extensions for VS Code.

  Commands:
    (default)    Run full sync
    -Merge       Deep-merge settings instead of replacing

  Usage:
    .\run.ps1              # Replace mode
    .\run.ps1 -Merge       # Merge mode

  Flags:
    -Help        Show this help message
```

---

## Conventions (all scripts follow)

| Convention | Detail |
|------------|--------|
| Shared helpers | Dot-source from `scripts/shared/` |
| Script helpers | `helpers/` subfolder per script |
| Config files | `config.json` (read-only at runtime) |
| Log messages | `log-messages.json` for all display strings |
| Runtime state | `.resolved/<script-folder>/resolved.json` |
| Logging | Shared `Write-Log` with status badges |
| Admin check | `Assert-Admin` where elevation is needed |
| PATH safety | Dedup before adding, user PATH preferred |
| Dev dir | All tools install into `$env:DEV_DIR` subfolders |
| No hardcoded paths | Everything in config.json with env var expansion |

---

## Root README Update

The project `readme.md` needs updating to document:
1. What this project is (collection of Windows dev setup scripts)
2. Table of all scripts (01-08) with descriptions
3. Quick start guide
4. Shared helpers overview
5. How to add a new script
