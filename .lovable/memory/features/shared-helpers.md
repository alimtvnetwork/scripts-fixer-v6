---
name: Shared helpers inventory
description: All shared PS1 helpers in scripts/shared/ -- logging, json-utils, resolved, git-pull
type: feature
---
## scripts/shared/ inventory

| File | Functions | Purpose |
|------|-----------|---------|
| `logging.ps1` | `Write-Log`, `Write-Banner`, `Initialize-Logging`, `Import-JsonConfig` | Console output with status badges, transcript logging, JSON loading |
| `json-utils.ps1` | `Backup-File`, `ConvertTo-OrderedHashtable`, `Merge-JsonDeep` | File backups, PSCustomObject-to-hashtable conversion, recursive JSON merge |
| `resolved.ps1` | `Get-ResolvedDir`, `Save-ResolvedData` | Persist runtime state to `.resolved/` folder |
| `cleanup.ps1` | `Clear-ResolvedData` | Wipe .resolved/ contents (all or per-edition) for fresh detection |
| `git-pull.ps1` | `Invoke-GitPull` | Git pull with `$env:SCRIPTS_ROOT_RUN` skip guard |

## Rule
When adding new utility functions, check if they belong in an existing shared helper first. If reusable across scripts, put them in `scripts/shared/`. Script-specific helpers stay in `<script>/helpers/`.
