# Spec: Root Dispatcher (run.ps1)

## Overview

The root-level `run.ps1` is the single entry point for running any numbered
script in the project. It handles git pull, log cleanup, environment flags,
and cache management before delegating to the target script.

---

## Usage

```powershell
.\run.ps1 -I <number>                  # Run a script
.\run.ps1 -I <number> -Merge           # Run with -Merge passed through
.\run.ps1 -I <number> -Clean           # Wipe .resolved/ cache, then run
.\run.ps1 -CleanOnly                   # Wipe .resolved/ cache and exit
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-I` | int | Yes (unless `-CleanOnly`) | Script number to run (maps to `scripts/<NN>-*/run.ps1`) |
| `-Merge` | switch | No | Passed through to child script (used by script 02 for deep-merge) |
| `-Clean` | switch | No | Wipes all `.resolved/` data before running, forcing fresh detection |
| `-CleanOnly` | switch | No | Wipes all `.resolved/` data and exits without running any script |

## Examples

```powershell
.\run.ps1 -I 1              # Pull, then run scripts/01-*/run.ps1
.\run.ps1 -I 2 -Merge       # Pull, then run scripts/02-*/run.ps1 with merge mode
.\run.ps1 -I 1 -Clean       # Wipe cache, pull, then run scripts/01-*/run.ps1
.\run.ps1 -CleanOnly         # Wipe all cached resolved data
```

## Execution Flow

1. If `-CleanOnly`: wipe `.resolved/` contents and exit immediately
2. Validate `-I` is provided (show usage help if missing)
3. If `-Clean`: wipe `.resolved/` contents, then continue
4. Dot-source `scripts/shared/git-pull.ps1`
5. Resolve script folder from `-I` (e.g. `1` -> `scripts/01-*/`)
6. Verify `run.ps1` exists in the target folder
7. Clean and recreate the target script's `logs/` folder
8. `Invoke-GitPull` from the repo root
9. Set `$env:SCRIPTS_ROOT_RUN = "1"` so child scripts skip their own git pull
10. Delegate to the child script, passing through any extra flags (`-Merge`)
11. Clean up `$env:SCRIPTS_ROOT_RUN`

## Environment Variables

| Variable | Set by | Purpose |
|----------|--------|---------|
| `$env:SCRIPTS_ROOT_RUN` | Root dispatcher | Set to `"1"` before delegating; child scripts check this to skip redundant git pull |

The flag is removed after the child script completes, preventing stale state
in future standalone runs.

## .resolved/ Cache Management

The `-Clean` and `-CleanOnly` flags provide direct control over the `.resolved/`
runtime cache without needing to manually delete folders.

| Flag | Requires -I | Effect |
|------|-------------|--------|
| `-Clean` | Yes | Wipe cache, then run script (forces fresh detection) |
| `-CleanOnly` | No | Wipe cache and exit |
| Neither | Yes | Run script using existing cache (cache-first detection) |

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `-I` is optional (not `Mandatory`) | Allows `-CleanOnly` to work without a script number |
| Usage help on missing `-I` | Better UX than a raw PowerShell parameter error |
| Clean before git pull | Ensures fresh detection even if git pull brings new config |
| Inline wipe (not via cleanup.ps1) | Root dispatcher runs before shared helpers are loaded; avoids dependency on logging |
| Flag passthrough via splatting | `$scriptArgs` hashtable makes it easy to add future flags |
