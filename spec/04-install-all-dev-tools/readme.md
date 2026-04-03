# Spec: Script 04 -- Install All Dev Tools

## Purpose

Orchestrator that resolves the dev directory once, sets `$env:DEV_DIR`,
then runs scripts 03, 05-10 in sequence. Supports `--skip` and `--only` filters.

## Usage

```powershell
.\run.ps1                    # Run all enabled scripts
.\run.ps1 -Skip "06,08"     # Skip Node.js and pnpm
.\run.ps1 -Only "03,05"     # Run only package managers + Go
.\run.ps1 -Help             # Show usage
```

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `devDir.mode` | string | Resolution mode (json-or-prompt) |
| `devDir.default` | string | Default dev directory path |
| `devDir.override` | string | Hard override (skips prompt) |
| `scripts.<id>.enabled` | bool | Toggle per script |
| `scripts.<id>.folder` | string | Script folder name |
| `scripts.<id>.name` | string | Display name |
| `sequence` | array | Execution order |

## Available Scripts

| ID | Name | Description |
|----|------|-------------|
| 03 | Package Managers | Install Chocolatey and Winget |
| 05 | Go | Install Go, configure GOPATH and go env |
| 06 | Node.js | Install Node.js LTS, configure npm prefix |
| 07 | Python | Install Python, configure pip user site |
| 08 | pnpm | Install pnpm, configure global store |
| 09 | Git + LFS + gh | Install Git, Git LFS, GitHub CLI, configure settings |
| 10 | GitHub Desktop | Install GitHub Desktop |

## Sequence

Default order: `03 (Package Managers) > 09 (Git + LFS + gh) > 05 (Go) > 06 (Node.js) > 07 (Python) > 08 (pnpm) > 10 (GitHub Desktop)`

## Flow

1. Assert admin privileges
2. Resolve dev directory (env > config override > prompt > default)
3. Create dev directory structure
4. Set `$env:DEV_DIR` for child scripts
5. Build filtered script list (apply --skip / --only)
6. Run each script's `run.ps1` in sequence
7. Print summary table with status badges
8. Save resolved state

## Summary Output

```
--- Summary ---
  [OK]   03 - Package Managers
  [OK]   09 - Git + LFS + gh
  [OK]   05 - Go
  [SKIP] 06 - Node.js
  [OK]   07 - Python
  [SKIP] 08 - pnpm
  [OK]   10 - GitHub Desktop
```
