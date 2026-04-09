# Spec: Script 08 -- Install GitHub Desktop

## Purpose

Install GitHub Desktop via Chocolatey. After installation, optionally scans
configured folders for Git repositories and adds them to GitHub Desktop's
internal repo list.

## Usage

```powershell
.\run.ps1 install github-desktop    # Install + scan folders
.\run.ps1 install gh                # Alias
.\run.ps1 -I 8                      # By script ID
.\run.ps1 -I 8 -- -Help             # Show help
```

## config.json

| Key | Type | Purpose |
|-----|------|---------|
| `enabled` | bool | Master toggle |
| `chocoPackageName` | string | Chocolatey package (`github-desktop`) |
| `alwaysUpgradeToLatest` | bool | Upgrade on every run |
| `scanFolders.enabled` | bool | Enable post-install folder scanning |
| `scanFolders.paths` | string[] | Folders to scan for Git repos (e.g. `["D:\\dev", "D:\\projects"]`) |
| `scanFolders.maxDepth` | int | How deep to recurse (default `2`) |
| `scanFolders.excludePatterns` | string[] | Folder names to skip (e.g. `node_modules`, `.archive`) |

## Flow

1. Assert admin + Chocolatey
2. Check if GitHub Desktop is installed (command or AppData path)
3. Install via Chocolatey if missing, upgrade if configured
4. **Scan configured folders** for `.git` directories (up to `maxDepth`)
5. Load `%APPDATA%\GitHub Desktop\repositories.json`
6. Add any newly discovered repos that aren't already tracked
7. Write updated repo list back to `repositories.json`
8. Save resolved state

## Folder Scanning Details

- Uses breadth-first search up to `maxDepth` levels deep
- Skips folders matching `excludePatterns` and dot-prefixed folders
- Does not recurse into discovered repos (avoids nested repo issues)
- Normalises paths for comparison (forward/back slashes, case-insensitive)
- Creates `%APPDATA%\GitHub Desktop` directory if it doesn't exist yet
- Safe to re-run: already-tracked repos are skipped with a log message

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| BFS with depth limit | Prevents runaway scanning of deep folder trees |
| Skip dot-prefixed folders | `.git`, `.cache`, `.venv` etc. are never repo containers |
| Forward-slash in repo entry | GitHub Desktop uses forward slashes internally |
| Array wrapper for single item | `ConvertTo-Json` unwraps single-element arrays; manual wrap needed |
