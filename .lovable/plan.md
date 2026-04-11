# v0.14.0 Plan: Enhanced Choco Update Command

## Current State

The `.\run.ps1 update` command does one thing: lists all installed packages, confirms, then runs `choco upgrade all -y`. No selective updates, no outdated check, no skip/exclude support.

## Proposed Enhancements

### 1. Outdated Check (`update` default behaviour change)

Instead of listing all packages, first run `choco outdated` to show only packages with available updates. This gives the user a clearer picture of what will actually change.

```
  Outdated Packages
  =================

    Package              Current    Available
    -------------------  ---------  ---------
    nodejs.install       20.11.0    22.3.0
    python3              3.12.1     3.13.0
    git.install          2.43.0     2.45.0

  3 package(s) have updates available
```

### 2. Selective Update (`update <packages>`)

Allow updating specific packages by name:

```powershell
.\run.ps1 update nodejs           # Update only Node.js
.\run.ps1 update nodejs,python3   # Update Node.js + Python
.\run.ps1 update git              # Update Git
```

### 3. Check-Only Mode (`update --check`)

Show outdated packages without upgrading:

```powershell
.\run.ps1 update --check          # List outdated packages, no upgrade
```

### 4. Force Mode (`update -y`)

Skip the confirmation prompt:

```powershell
.\run.ps1 update -y               # Upgrade all without confirmation
.\run.ps1 update nodejs -y        # Upgrade nodejs without confirmation
```

### 5. Exclude Packages (`update --exclude`)

Upgrade all except specified packages:

```powershell
.\run.ps1 update --exclude chocolatey,chocolatey-core.extension
```

## Updated Command Summary

| Command | Description |
|---------|-------------|
| `.\run.ps1 update` | Show outdated, confirm, upgrade all |
| `.\run.ps1 update nodejs,git` | Upgrade specific packages only |
| `.\run.ps1 update --check` | List outdated packages (no upgrade) |
| `.\run.ps1 update -y` | Upgrade all, skip confirmation |
| `.\run.ps1 update --exclude pkg1,pkg2` | Upgrade all except listed |

## Implementation Tasks

1. **Extract `Invoke-ChocoUpdate` to `scripts/shared/choco-update.ps1`** -- Move from inline function in `run.ps1` to a dedicated shared helper for maintainability
2. **Add `choco outdated` parsing** -- Replace `choco list --local-only` with `choco outdated` to show only updatable packages
3. **Add selective package support** -- Parse remaining positional args after `update` as package names
4. **Add `--check` flag** -- Show outdated list and exit without upgrading
5. **Add `-y` auto-confirm** -- Skip the `[Y/n]` prompt when `-y` is passed
6. **Add `--exclude` support** -- Filter packages before running upgrade
7. **Update help text** -- Add new update modes to `Show-RootHelp`
8. **Update spec doc** -- Rewrite `spec/choco-update/readme.md` with new features
9. **Add log messages** -- Add update-specific messages to shared log-messages.json
10. **Bump version to v0.14.0**

## Files to Modify

| File | Change |
|------|--------|
| `scripts/shared/choco-update.ps1` | **NEW** -- Extracted + enhanced update logic |
| `run.ps1` | Replace inline function with dot-source; parse `update` args |
| `scripts/shared/log-messages.json` | Add update log messages |
| `spec/choco-update/readme.md` | Full rewrite with new features |
| `CHANGELOG.md` | v0.14.0 entry |
| `scripts/version.json` | Bump to 0.14.0 |

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| `choco outdated` output format changes | LOW | Parse defensively; fallback to `choco list` |
| Selective update with wrong package name | LOW | Chocolatey itself reports "package not found" |
| Breaking existing `update` flow | LOW | Default behaviour (update all) is preserved; enhancements are additive |

## Status

- [x] Plan approved
- [x] Implementation complete (v0.15.0)
