# Spec: Install DBeaver Community

## Overview

Installs DBeaver Community Edition, a universal database visualization and
management tool that supports MySQL, PostgreSQL, SQLite, MongoDB, Redis,
and many other databases.

## What It Does

1. Checks if DBeaver is already installed (PATH + common install locations)
2. Installs DBeaver Community via Chocolatey (`choco install dbeaver`)
3. Refreshes PATH and verifies the install
4. Saves resolved state to `.resolved/32-install-dbeaver/resolved.json`

## Configuration

| Key | Purpose |
|-----|---------|
| `database.enabled` | Enable/disable the install |
| `database.chocoPackage` | Chocolatey package name (`dbeaver`) |
| `database.verifyCommand` | CLI command to verify install (`dbeaver-cli`) |

## Usage

```powershell
.\run.ps1 -I 32                   # Install DBeaver
.\run.ps1 install dbeaver         # Install via keyword
.\run.ps1 -I 32 -- -Help          # Show help
```

## Notes

- DBeaver Community is free and open-source (Apache 2.0 license)
- The `dbeaver-cli` command may not be in PATH on all systems; the installer
  also checks `Program Files\DBeaver\` as a fallback
- Pairs well with database installs (SQLite, MySQL, PostgreSQL, etc.)
