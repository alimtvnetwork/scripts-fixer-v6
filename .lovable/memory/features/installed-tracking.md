---
name: Installation tracking
description: .installed/ folder at project root tracks tool versions to skip redundant installs
type: feature
---
`.installed/` at project root contains per-tool JSON files (e.g. `nodejs.json`, `git.json`).
Each records: name, version, method, installedAt, installedBy.

Functions in `scripts/shared/installed.ps1` (auto-loaded by logging.ps1):
- `Test-AlreadyInstalled -Name <name> -CurrentVersion <ver>` -- returns $true if version matches
- `Save-InstalledRecord -Name <name> -Version <ver> -Method <method>` -- writes tracking file
- `Get-InstalledRecord -Name <name>` -- reads tracking file

All install helpers check tracking before installing. If version matches, skip entirely.
Delete a tracking JSON to force re-install of that tool.
