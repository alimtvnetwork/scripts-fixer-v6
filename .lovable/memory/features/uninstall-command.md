---
name: Uninstall command for all scripts
description: Every run.ps1 must support an uninstall subcommand that does full cleanup
type: feature
---
All scripts must support an `uninstall` subcommand that performs full cleanup:

1. **Chocolatey uninstall** -- `Uninstall-ChocoPackage` (shared helper in choco-utils.ps1)
2. **Environment variables** -- remove any env vars the script sets (User scope)
3. **PATH cleanup** -- `Remove-FromUserPath` (shared helper in path-utils.ps1)
4. **Dev directory subfolder** -- delete the tool's subfolder under dev dir
5. **Tracking records** -- `Remove-InstalledRecord` + `Remove-ResolvedData` (shared helpers)

Shared helpers added:
- `Uninstall-ChocoPackage` in choco-utils.ps1
- `Remove-InstalledRecord` in installed.ps1
- `Remove-ResolvedData` in resolved.ps1
- `Remove-FromUserPath` in path-utils.ps1

Reference implementation: scripts/05-install-python (completed)
Scripts remaining: all others need uninstall subcommand added
