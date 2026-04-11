# v0.16.x Release Cycle Plan

## Overview

The v0.15.x cycle completed: enhanced choco update, settings export for 4 apps (DBeaver, NPP, OBS, WT), and a Python empty-version bugfix. The v0.16.x cycle focuses on **robustness**, **developer experience**, and **new script capabilities**.

---

## Feature 1: Audit Check 12 -- Export Coverage
**Priority:** High | **Estimated version:** v0.16.0

Add a new audit check that verifies every settings-capable script (32, 33, 36, 37) has:
- An `Export-*` function in helpers/
- An `"export"` command handler in run.ps1
- Export-related log messages in log-messages.json

This mirrors the existing Check 11 (Uninstall Coverage) pattern.

---

## Feature 2: `.\run.ps1 export` Command
**Priority:** High | **Estimated version:** v0.16.0

Add a root-level `export` subcommand to batch-export all settings at once:
```powershell
.\run.ps1 export              # export all settings (NPP, OBS, WT, DBeaver)
.\run.ps1 export npp,obs      # export specific apps only
```

Uses the same keyword mapping system. Iterates through settings-capable scripts and invokes their `export` subcommand.

---

## Feature 3: `.\run.ps1 status` Command
**Priority:** Medium | **Estimated version:** v0.16.1

Show a dashboard-style summary of all installed tools:
```
  Tool             Version        Status     Source
  ------------------------------------------------
  VS Code          1.96.0         ok         choco
  Node.js          22.12.0        outdated   choco
  Python           (not found)    missing    --
  Git              2.47.1         ok         choco
```

Reads from `.installed/` tracking files and optionally runs `choco outdated` for freshness. Flags tools with recorded errors.

---

## Feature 4: Defensive Empty-Version Guards
**Priority:** Medium | **Estimated version:** v0.16.1

The Python crash revealed a pattern: `--version` can return empty. Audit ALL install helpers for the same vulnerability:
- Scripts that call `Test-AlreadyInstalled` with a version from `& tool --version`
- Add `$hasVersion` guard before each call
- Affected scripts: potentially 01, 03, 06, 07, 09, 16, 17 and all database scripts

---

## Feature 5: VSCode Settings Export (Script 11)
**Priority:** Medium | **Estimated version:** v0.16.2

Script 11 already syncs settings TO the machine. Add the reverse `export` command to copy FROM the machine:
- Export `settings.json`, `keybindings.json` from `%APPDATA%\Code\User\`
- Export installed extensions list via `code --list-extensions`
- Export the active profile if available
- Save to the script 11 folder

---

## Feature 6: `.\run.ps1 doctor` Command
**Priority:** Low | **Estimated version:** v0.16.3

A quick health-check that verifies the project setup itself:
- Scripts root directory exists and has expected structure
- `version.json` is readable and valid
- `.logs/` and `.installed/` directories exist
- Registry IDs match folder count
- Chocolatey is reachable
- Admin rights check

Lighter than full audit -- runs in < 2 seconds for quick sanity checks.

---

## Feature 7: Shared `Assert-ToolVersion` Helper
**Priority:** Low | **Estimated version:** v0.16.3

Extract the repeated pattern of "run `--version`, guard empty, check tracking, log result" into a reusable shared helper:
```powershell
$result = Assert-ToolVersion -Name "python" -Command "python" -VersionFlag "--version"
# Returns: @{ Exists = $true; Version = "Python 3.12.0"; IsTracked = $true }
```

Reduces boilerplate across all 30+ install helpers and prevents future empty-version bugs.

---

## Release Sequence

| Version  | Features                                        |
|----------|-------------------------------------------------|
| v0.16.0  | Audit Check 12 (export coverage) + root export command |
| v0.16.1  | Status command + defensive version guards        |
| v0.16.2  | VSCode settings export                           |
| v0.16.3  | Doctor command + shared Assert-ToolVersion       |

---

## Not in Scope (Future)

- GUI/TUI for the interactive menu (consider for v0.17.x)
- Cross-machine settings sync via cloud storage
- Linux/macOS support
- New tool scripts (Docker, Rust, Java -- track as separate proposals)

---

## Status

- [x] Plan approved
- [x] v0.16.0 implementation (Audit Check 12 + root export command + .NET + Java scripts)
- [x] v0.16.1 implementation (Status command + defensive version guards)
- [x] v0.16.2 implementation (Python libraries script 41 + VSCode export)
- [x] v0.16.3 / v0.17.1 implementation (doctor command + Assert-ToolVersion)
