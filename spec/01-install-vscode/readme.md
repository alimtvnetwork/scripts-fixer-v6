# Spec: Install VS Code (Script 01)

## Overview

Installs Visual Studio Code via Chocolatey. Supports Stable and Insiders
editions with a runtime prompt for edition selection.

## Features

- Installs VS Code Stable and/or Insiders via Chocolatey
- Runtime edition prompt (Stable / Insiders / Both)
- Upgrades existing installations to latest version
- Can bypass prompt via subcommand (`stable`, `insiders`)

## Config (`config.json`)

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `editions.stable.enabled` | bool | Include Stable when not prompting |
| `editions.stable.chocoPackageName` | string | Chocolatey package name |
| `editions.insiders.enabled` | bool | Include Insiders when not prompting |
| `editions.insiders.chocoPackageName` | string | Chocolatey package name |
| `promptEdition` | bool | Show interactive edition picker |

## Usage

```powershell
.\run.ps1              # Interactive edition prompt
.\run.ps1 stable       # Install only Stable
.\run.ps1 insiders     # Install only Insiders
.\run.ps1 -Help        # Show help
```

## Dependencies

- Administrator privileges
- Chocolatey (auto-installed via `Assert-Choco`)
