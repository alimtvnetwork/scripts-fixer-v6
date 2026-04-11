# Changelog

All notable changes to this project are documented in this file.

## [v0.15.2] -- 2026-04-11

### Fixed

- **Python install empty-version crash** (script 05) -- `Test-AlreadyInstalled` now only called when `python --version` returns a non-empty string, preventing `Cannot bind argument to parameter 'CurrentVersion'` error

---

## [v0.15.1] -- 2026-04-11

### Added

- **Notepad++ settings export** (script 33) -- `.\run.ps1 -I 33 -- export`
  - Exports config files (.xml, .json, .ini) from `%APPDATA%\Notepad++\`
  - Exports subdirectories (themes, userDefineLangs) recursively
  - Skips runtime folders (backup, session, plugins) and files > 512 KB
  - Saves to `settings/01 - notepad++/`

### Fixed

- **Typo in `Uninstall-NotepadPP`** -- `$$NppConfig` corrected to `$NppConfig`

---

## [v0.15.0] -- 2026-04-11

### Added

- **Enhanced choco update command** -- extracted to `scripts/shared/choco-update.ps1`
  - `.\run.ps1 update` now shows only outdated packages (via `choco outdated`) instead of listing all
  - `.\run.ps1 update nodejs,git` -- selective package updates
  - `.\run.ps1 update --check` -- check-only mode (list outdated, no upgrade)
  - `.\run.ps1 update -y` -- auto-confirm mode (skip [Y/n] prompt)
  - `.\run.ps1 update --exclude=pkg1,pkg2` -- upgrade all except listed packages
  - Root `-Y` switch also honored for auto-confirm

---

## [v0.14.1] -- 2026-04-11

### Added

- **OBS settings export** (script 36) -- `.\run.ps1 -I 36 -- export`
  - Exports scene collections (.json) and profile folders from `%APPDATA%\obs-studio\basic\`
  - Saves to `settings/02 - obs-settings/`
  - Skips files > 512 KB
- **Windows Terminal settings export** (script 37) -- `.\run.ps1 -I 37 -- export`
  - Exports `settings.json` and extra config files from LocalState
  - Saves to `settings/03 - windows-terminal/`
  - Excludes `state.json` (runtime state)

### Fixed

- **Typo in `Uninstall-OBS`** -- `$$ObsConfig` corrected to `$ObsConfig`
- **Typo in `Uninstall-WindowsTerminal`** -- `$$WtConfig` corrected to `$WtConfig`

---

## [v0.14.0] -- 2026-04-11

### Added

- **DBeaver settings export** (script 32) -- `.\run.ps1 -I 32 -- export`
  - Copies settings FROM `%APPDATA%\DBeaverData\workspace6\General\.dbeaver\` TO `settings/04 - dbeaver/`
  - Exports `.json` config files and subdirectories (drivers, templates)
  - Skips files > 512 KB (cache, not config)
  - Preserves existing `readme.txt` in target

### Fixed

- **Typo in `Uninstall-Dbeaver`** -- `$$DbConfig` corrected to `$DbConfig`

---

## [v0.13.1] -- 2026-04-11

### Added

- **Uninstall coverage audit check** (Check 11) -- Verifies every script has:
  - An `Uninstall-*` function in its helper file
  - An `uninstall` command handler in `run.ps1`
  - Uninstall help entries in `log-messages.json`
  - Exempt scripts: 02 (Chocolatey), 12 (orchestrator), audit, databases

### Fixed

- **Stale `\dev` path references** in audit symlink check (`checks.ps1` lines 457, 472) -- now correctly uses `\dev-tool`

---

## [v0.13.0] -- 2026-04-11

### Added

- **`path` command** -- Persistently set, view, or reset the default dev directory
  - `.\run.ps1 path D:\devtools` -- save custom dev directory
  - `.\run.ps1 path` -- show current saved path
  - `.\run.ps1 path --reset` -- clear saved path, revert to smart detection
  - Saved to `scripts/dev-path.json`; all scripts pick it up automatically via `Resolve-DevDir`
  - Priority: `-Path` param > `$env:DEV_DIR` > saved path > smart detection

---

## [v0.12.1] -- 2026-04-11

### Fixed

- **Default dev directory references** -- Updated all remaining `\dev` path references to `\dev-tool` across configs, specs, memory files, and shared helpers (43 files total)

---

## [v0.12.0] -- 2026-04-11

### Added

- **`uninstall` subcommand rolled out to all 34 scripts** (01-38, excluding 02-Chocolatey)
  - Each script now supports `.\run.ps1 uninstall` with full cleanup logic
  - Chocolatey packages removed via `Uninstall-ChocoPackage`
  - Environment variables and PATH entries cleaned up
  - Dev directory subfolders deleted
  - Tracking records purged (`.installed/` and `.resolved/`)
  - Special handling: registry cleanup (10, 31), dotnet tool (29), tracking-only (14, 15)
- **Batch uninstall in script 12 orchestrator**
  - Interactive: `[U] Uninstall` option in quick menu with checkbox picker
  - Flag-based: `-Uninstall`, `-Uninstall -All`, `-Uninstall -Only 03,05,07`
  - Dry run: `-Uninstall -DryRun` to preview without changes
  - Safety: Chocolatey (02) always skipped, reverse execution order, YES confirmation required
- **Batch uninstall in databases orchestrator** (`scripts/databases/run.ps1`)
  - `.\run.ps1 -Uninstall` -- interactive picker
  - `.\run.ps1 -Uninstall -All` -- uninstall all databases
  - `.\run.ps1 -Uninstall -Only mysql,redis` -- uninstall specific databases
  - `.\run.ps1 -Uninstall -DryRun` -- preview mode
  - Reverse order execution with YES confirmation
- **`-Path` parameter rolled out to all 38 `run.ps1` scripts**
  - Consistent `[Parameter(Position = 1)] [string]$Path` across all scripts
  - Overrides `$env:DEV_DIR` and smart drive detection
  - Orchestrators propagate `-Path` to child scripts via `$env:DEV_DIR`

### Changed

- **Default dev directory** changed from `\dev` to `\dev-tool` (e.g. `E:\dev-tool`)
  - Updated `Get-SafeDevDirFallback`, `Resolve-SmartDevDir`, user prompts
  - All help text and spec docs updated to reflect new default
  - GitMap fallback path updated from `C:\DevTools\GitMap` to `C:\dev-tool\GitMap`
- **Help output** now shows `-Path` override example and smart detection info

---

## [v0.11.0] -- 2026-04-11

### Added

- **`-Path` parameter** -- Script 05 (Install Python) now accepts `-Path` to override dev directory
  - `.\run.ps1 all F:\dev` installs and configures pip to `F:\dev\python`
  - Overrides both smart drive detection and `$env:DEV_DIR`
  - Pattern to be rolled out to all scripts
- **`uninstall` subcommand** -- Script 05 (Install Python) reference implementation
  - Runs `choco uninstall python3 --remove-dependencies`
  - Removes `PYTHONUSERBASE` environment variable
  - Removes `Scripts\` from User PATH
  - Deletes `<devDir>\python` subfolder
  - Purges `.installed/python.json` and `.resolved/05-install-python/`
- **Shared uninstall helpers** for all scripts to use:
  - `Uninstall-ChocoPackage` in `choco-utils.ps1`
  - `Remove-FromUserPath` in `path-utils.ps1`
  - `Remove-InstalledRecord` in `installed.ps1`
  - `Remove-ResolvedData` in `resolved.ps1`
- **Help system upgrade** -- `help.ps1` now auto-injects `-Path` parameter in help output for all scripts
  - Reads `help.parameters` block from `log-messages.json`
  - Renamed "Flags:" section to "Parameters:" for clarity
- **Install keywords documentation** -- added Install Keywords section to all 35+ spec readmes
  - Each spec now documents direct keywords, mode overrides, and group shortcuts
  - Consistent formatting with tables and PowerShell usage examples
- **`data-dev` group shortcut** -- bundles PostgreSQL (20), Redis (24), DuckDB (28), DBeaver (32)
  - Also aliased as `datadev`
- **`mobile-dev` group shortcut** -- bundles Flutter-related scripts
- **Flutter mode overrides** -- `flutter-only`, `flutter+android`, `flutter-extensions` keywords

---

## [v0.10.0] -- 2026-04-10

### Added

- **Script 38 -- Install Flutter** -- complete Flutter development environment setup
  - Installs Flutter SDK (includes Dart) via Chocolatey
  - Installs Android Studio via Chocolatey
  - Installs Google Chrome for Flutter web development
  - Installs VS Code Flutter and Dart extensions (`Dart-Code.dart-code`, `Dart-Code.flutter`)
  - Runs `flutter doctor` post-install and auto-accepts Android licenses
  - Subcommands: `all`, `install`, `android`, `chrome`, `extensions`, `doctor`
- Registered script 38 in `registry.json` and orchestrator config
- Added to "Everything" group and execution sequence
- Created spec at `spec/38-install-flutter/readme.md`

---

## [v0.9.1] -- 2026-04-10

### Fixed

- Fixed `Test-KeywordModes` audit check crash when config.json has no top-level `validModes` -- replaced direct property access with safe `PSObject.Properties.Name -contains` check to avoid strict-mode errors

---

## [v0.9.0] -- 2026-04-10

### Added

- **DBeaver settings sync** -- Script 32 now supports 3 modes: `install+settings`, `settings-only`, `install-only`
- New `Sync-DbeaverSettings` function syncs config files from `settings/04 - dbeaver/` to `%APPDATA%\DBeaverData\workspace6\General\.dbeaver\`
- Created `settings/04 - dbeaver/` folder with readme explaining usage
- Added keywords: `dbeaver+settings`, `dbeaver-settings`, `install-dbeaver` with mode mappings
- Settings-only mode does not require admin privileges
- Updated spec/32 readme with full mode documentation

---

## [v0.8.9] -- 2026-04-10

### Fixed

- Changed `ghDesktopNotFound` log level from `warn` to `info` in Script 08 -- "not found, installing" is expected install flow, not a warning

---


## [v0.8.8] -- 2026-04-09

**Maintenance release -- verified v0.8.7 changes**

### Verified

- GitHub Desktop folder scanning (`Add-ReposToGitHubDesktop`) tested end-to-end
- Simple Sticky Notes SSN keyword and custom data folder confirmed working
- OBS/WT settings sync `$PSScriptRoot` path fix confirmed
- `Install-OBS` return value propagation confirmed
- PS 5.1 `Join-Path` compatibility confirmed across all scripts

---

## [v0.8.7] -- 2026-04-09

**GitHub Desktop: post-install folder scanning for Git repos**

### Added

- `scanFolders` config block in Script 08 (`config.json`) with `paths`, `maxDepth`, and `excludePatterns`
- `Add-ReposToGitHubDesktop` function -- scans configured folders for `.git` directories and adds discovered repos to `%APPDATA%\GitHub Desktop\repositories.json`
- `Find-GitRepos` helper -- breadth-first search for `.git` folders with depth limit and exclusion patterns
- Log messages for scan progress, discovery, and summary

---

## [v0.8.6] -- 2026-04-09

**Simple Sticky Notes: SSN keyword + custom data folder**

### Added

- `ssn` keyword shortcut for Script 34 in `install-keywords.json`
- Custom data folder support for Simple Sticky Notes: redirects `%APPDATA%\Simple Sticky Notes` to a configurable path (default `D:\notes`) via directory symlink
- New `Set-StickyNotesDataFolder` function in `helpers/sticky-notes.ps1` -- creates target folder, migrates existing data, creates symlink
- `dataFolder` config block in `config.json` with `enabled`, `path`, and `createIfMissing` fields

---

## [v0.8.5] -- 2026-04-09

**Fix Join-Path PS 5.1 compatibility in Get-ScriptVersion**

### Fixed

- `Get-ScriptVersion` in `run.ps1` used 3-argument `Join-Path` which only works in PowerShell 7+; PS 5.1 threw "positional parameter cannot be found that accepts argument 'version.json'" -- nested to `Join-Path (Join-Path ...) "version.json"`

---

## [v0.8.4] -- 2026-04-09

**Install-OBS return value fix**

### Fixed

- `Install-OBS` now correctly returns `$false` when `Sync-OBSSettings` fails -- previously returned `$true` after a successful install even if settings sync failed, causing the root dispatcher to report `1 of 1` instead of `0 of 1`

---

## [v0.8.3] -- 2026-04-09

**PSScriptRoot path fix for OBS and WT settings sync**

### Fixed

- OBS settings sync (`Sync-OBSSettings`) now uses `$PSScriptRoot` instead of `$MyInvocation.ScriptName` to resolve the repo root -- fixes incorrect path when dot-sourced from `run.ps1`
- WT settings sync (`Sync-WTSettings`) updated with the same `$PSScriptRoot` path resolution fix for consistency
- Added `37 = "WT_MODE"` to `$modeEnvVars` in `run.ps1` so WT mode keywords (`wt-settings`, `wt+settings`) pass the mode correctly

---

## [v0.8.2] -- 2026-04-08

**Version header, self-update on update command, WT keywords, OBS path fix**

### Added

- Version header (`Scripts Fixer vX.Y.Z`) displayed at top of `run.ps1` output (no-params, `-Help`, `update`)
- `Get-ScriptVersion` and `Show-VersionHeader` helpers in `run.ps1` reading from `scripts/version.json`
- WT keywords added to `Show-RootHelp` and `Show-KeywordTable`: `wt`, `windows-terminal`, `wt+settings`, `wt-settings`, `install-wt` (script 37)
- All missing keywords (scripts 31-37) added to `spec/root-dispatcher/readme.md` keyword table

### Changed

- `update` command now performs git pull (self-update) before running `choco upgrade all`
- Updated `spec/root-dispatcher/readme.md` with version header docs, separate execution flow sections, and self-update behaviour

### Fixed

- OBS settings sync path traversal bug -- `Sync-OBSSettings` was resolving to `scripts/settings/` instead of project root `settings/` (added missing `Split-Path -Parent` level)

---

## [v0.8.1] -- 2026-04-08

**Orchestrator config fix, repo URL update to v6**

### Fixed

- Added scripts 34 (Sticky Notes), 36 (OBS Studio), 37 (Windows Terminal) to orchestrator config (`scripts/12-install-all-dev-tools/config.json`) -- scripts block, execution sequence, and "Everything (01-37)" group

### Changed

- Repository clone URL updated from `scripts-fixer-v5` to `scripts-fixer-v6` in `readme.md`

---

## [v0.7.4] -- 2026-04-07

**Windows Terminal 3-mode installer, golangci-lint + go vet, combo keywords in summary, GitMap URL update**

### Added

- Script 37: **Windows Terminal** installer via winget (`Microsoft.WindowsTerminal`) with 3-mode support
  - `install+settings` (default) -- install WT + sync settings
  - `settings-only` -- sync settings only (restore/fix config)
  - `install-only` -- install without touching settings
  - Mode resolution: `-Mode` param > `$env:WT_MODE` > default
- Settings sync copies from `settings/03 - windows-terminal/` to `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\`
- Keywords: `wt`, `windows-terminal`, `wt+settings`, `wt-settings`, `install-wt` with mode mappings
- **golangci-lint** install support in script 06 (Go) -- installs via `go install` with version pinning
- **go vet** integration in script 06 -- runs `go vet ./...` after Go install for verification
- Combo keywords section in `spec/script-registry-summary.md` -- lists multi-script keywords (e.g. `web-dev`, `full-stack`, `essentials`) with mapped script IDs

### Changed

- GitMap install URL updated from `alimtvnetwork/git-repo-navigator` to `alimtvnetwork/gitmap-v2` in `scripts/35-install-gitmap/config.json`
- Updated `spec/35-install-gitmap/readme.md` to reflect new gitmap-v2 repo URL
- Mode env var dispatcher in `run.ps1` now includes `37 = WT_MODE`

---

## [v0.7.3] -- 2026-04-07

**OBS settings sync rework, keyword modes audit check**

### Changed

- OBS settings sync reworked: extract zip to `%TEMP%`, copy `.json` scene collections to `basic\scenes\`, profile folders to `basic\profiles\`
- Settings source changed from script-local folder to `settings/02 - obs-settings/` (shared settings directory)
- OBS picks up scenes and profiles automatically on startup -- no CLI import needed

### Added

- Audit Check 10: **Keyword modes vs config validModes** -- verifies every mode in `install-keywords.json` maps to a valid entry in the target script's `config.json` `validModes` array
- Added `validModes` arrays to `config.json` for scripts 16 (PHP), 33 (NPP), 36 (OBS)

---

## [v0.7.2] -- 2026-04-07

**OBS Studio 3-mode installer script**

### Added

- Script 36: **OBS Studio** installer via Chocolatey (`obs-studio`) with 3-mode support
  - `install+settings` (default) -- install OBS + sync settings
  - `settings-only` -- sync settings only (restore/fix config)
  - `install-only` -- install without touching settings
  - Mode resolution: `-Mode` param > `$env:OBS_MODE` > default
- Settings sync extracts zip from `settings/02 - obs-settings/` to `%APPDATA%\obs-studio\`
- Keywords: `obs`, `obs-studio`, `obs+settings`, `obs-settings`, `install-obs`

### Changed

- Mode env var dispatcher in `run.ps1` now includes `36 = OBS_MODE`

---

## [v0.7.1] -- 2026-04-07

**Combo keywords, Simple Sticky Notes, Choco update, PHP+phpMyAdmin modes**

### Added

- Script 34: **Simple Sticky Notes** installer via Chocolatey (`simple-sticky-notes`)
- `.\run.ps1 update` command -- lists all installed Chocolatey packages, prompts for confirmation, runs `choco upgrade all -y`
  - Aliases: `update`, `upgrade`, `choco-update`
- PHP + phpMyAdmin 3-mode support in script 16:
  - `php+phpmyadmin` (default) -- install both
  - `php-only` -- PHP only
  - `phpmyadmin-only` -- phpMyAdmin only
  - Mode resolution: `-Mode` param > `$env:PHP_MODE` > default
- Combo shortcut keywords:
  - `vscode+settings` / `vscode+s` -- VSCode + Settings Sync (01, 11)
  - `vscode+menu+settings` / `vms` -- VSCode + Menu Fix + Sync (01, 10, 11)
  - `git+desktop` / `git+gh` -- Git + GitHub Desktop (07, 08)
  - `node+pnpm` -- Node.js + pnpm (03, 04)
  - `frontend` -- VSCode + Node + pnpm + Sync (01, 03, 04, 11)
  - `backend` -- Python + Go + PHP + PostgreSQL (05, 06, 16, 20)
  - `web-dev` / `webdev` -- VSCode + Node + pnpm + Git + Sync (01, 03, 04, 07, 11)
  - `essentials` -- VSCode + Choco + Node + Git + Sync (01, 02, 03, 07, 11)
  - `full-stack` / `fullstack` -- Everything for full-stack dev (01-09, 11, 16)
- Help tables updated with "Combo Shortcuts" section

### Fixed

- **OrderedDictionary ArgumentOutOfRangeException** -- `[int]` keys in `[ordered]@{}` were treated as positional indexes; changed to string keys
- Generic mode env var dispatcher (`$modeEnvVars` map) replaces hardcoded `$env:NPP_MODE`

---

## [v0.7.0] -- 2026-04-07

**Code Red: Mandatory file-path error logging with Write-FileError helper**

### Added

- `Write-FileError` centralised helper in `scripts/shared/logging.ps1` -- enforces exact file path, operation, reason, and module in every file/path error log
- Structured `file-error` event type in JSON logs with fields: `filePath`, `operation`, `reason`, `module`, `fallback`
- Auto-detects calling module from PowerShell call stack when `-Module` is not provided
- Spec document: `spec/02-app-issues/error-management-file-path-and-missing-file-code-red-rule.md`

### Improved

- `Import-JsonConfig` -- now calls `Write-FileError` when config file is missing
- `Backup-File` -- file copy failures include exact source and destination paths
- `New-DbSymlink` -- unresolved install directory and junction creation failures include full paths
- `Clear-ResolvedData` -- edition clear and full wipe failures include resolved directory path
- `Save-ResolvedData` -- read and write failures include resolved.json path
- `Add-ToUserPath` / `Add-ToMachinePath` -- PATH update failures include target directory
- `Install-NotepadPP` -- post-install EXE verification logs all checked paths on failure
- `Sync-NotepadPPSettings` -- zip extraction, missing source dir, and empty settings all log exact paths
- `Install-Gitmap` -- remote installer failure logs install directory
- `Resolve-SourceFiles` -- profile parse failure logs profile path
- `Apply-Settings` / `Apply-Keybindings` -- copy failures log source and destination paths
- `Invoke-Edition` -- missing settings.json after apply logs expected target path

### Rule

- **CODE RED**: Every file-related or path-related error MUST include exact file path and failure reason. Generic "file not found" without path is forbidden.

---

## [v0.6.9] -- 2026-04-07

**Keyword mode-merging fix -- duplicate script runs prevented**

### Fixed

- `Resolve-InstallKeywords` now merges multiple keywords targeting the same script ID into a single entry using highest-priority mode (e.g. `npp,npp-settings` → one run with `install+settings` instead of two separate runs)
- Mode priority system: `install+settings` (3) > `install-only` (2) > `settings-only` (1)

### Improved

- Keyword resolver deduplicates by script ID before execution loop, preventing redundant Chocolatey installs
- Execution loop applies per-entry `$env:NPP_MODE` correctly for merged mode

---

## [v0.6.8] -- 2026-04-07

**Notepad++ 3-variant installation modes with bundled settings zip**

### Added

- Three installation modes for script 33 (`NPP` = Notepad++):
  - **NPP + Settings** (`install+settings`) -- install Notepad++ and extract settings (default)
  - **NPP Settings** (`settings-only`) -- extract settings zip only, no install
  - **Install NPP** (`install-only`) -- install only, no settings sync
- Bundled `notepadpp-settings.zip` in `scripts/33-install-notepadpp/settings/` -- extracted to `%APPDATA%\Notepad++\` (full replace)
- New keywords: `npp+settings`, `npp-settings`, `install-npp` with dedicated mode mappings
- `modes` map in `install-keywords.json` -- keyword resolver sets `$env:NPP_MODE` per script invocation
- Mode resolution chain: `-Mode` param > `$env:NPP_MODE` > default `install+settings`

### Improved

- `run.ps1` keyword resolver (`Resolve-InstallKeywords`) now reads `modes` map and injects env vars
- Help tables and Available Scripts section updated with all NPP variant keywords
- `spec/33-install-notepadpp/readme.md` rewritten with full 3-mode documentation

---

## [v0.6.7] -- 2026-04-07

**Notepad++ installer with settings sync**

### Added

- Script 33 (`33-install-notepadpp`) -- installs Notepad++ via Chocolatey and syncs custom settings to `%APPDATA%\Notepad++\`
- `Sync-NotepadPPSettings` helper copies all files from script's `settings/` folder, replacing existing config
- `npp`, `notepad++`, `notepadpp`, `notepad-plus-plus` install keywords mapping to script ID 33
- Notepad++ added to Everything group preset and registry
- `spec/33-install-notepadpp/readme.md` with full usage documentation

---

## [v0.6.6] -- 2026-04-07

**Install target path now logged prominently before drive detection**

### Improved

- Install target path logged immediately with `success` level and visual spacing so it stands out
- Changed "GitMap not found" from `warn` to `info` level (expected during first install, no longer pollutes error log)
- Updated log message to "Install target: {path}" for clarity

---

## [v0.6.5] -- 2026-04-07

**Fixed logging: warnings no longer cause false fail status + improved drive detection + one-line summary**

### Fixed

- `_LogErrors` was tracking both warnings and errors, causing scripts with harmless warnings to report `overallStatus: "fail"` -- now only actual errors trigger fail
- Split warning tracking into separate `_LogWarnings` collection in `logging.ps1`
- Drives reporting 0 GB free (phantom/card reader drives) now logged as `info` instead of `warn`, preventing false warning noise

### Added

- One-line copy-paste-friendly summary printed at end of every script run (e.g. `[install-gitmap] Status: ok | Duration: 1.7s`)
- Error details printed with `>>` prefix for quick scanning when failures occur
- `warnCount` field added to main log JSON output

---

## [v0.6.4] -- 2026-04-07

**Updated root-dispatcher spec with -List flag documentation**

### Docs

- Added `-List` flag to parameters table in `spec/root-dispatcher/readme.md`
- Updated execution flow to include `-List` check before `-Help` and `-Clean`
- Added `-List` usage example to spec

---

## [v0.6.3] -- 2026-04-07

**Added -List flag to run.ps1**

### Added

- `-List` flag on `run.ps1` that prints only the keyword-to-script-ID table for quick reference
- `Show-KeywordTable` function for compact keyword listing

---

## [v0.6.2] -- 2026-04-07

**GitMap folder-specific install via devDir integration**

### Changed

- GitMap installer now resolves install directory via `Resolve-DevDir` (smart drive detection, `$env:DEV_DIR`, config override)
- Passes `-InstallDir <resolved-path>` to the remote installer from GitHub
- `run.ps1` now dot-sources `dev-dir.ps1` and passes `$config.devDir` to the helper
- Detection also checks `$env:DEV_DIR\GitMap\gitmap.exe`
- Resolved state now includes `installDir` field
- Added `installDir` log message to `log-messages.json`
- Updated spec with devDir resolution priority, remote installer flags, and detection paths

---

## [v0.6.1] -- 2026-04-07

**GitMap added to Everything group preset**

### Changed

- Added script 35 (GitMap) to the Everything group preset (letter `n`) in `scripts/12-install-all-dev-tools/config.json`
- Updated group label from `Everything (01-32)` to `Everything (01-35)`

---

## [v0.6.0] -- 2026-04-07

**GitMap installer, global -Defaults/-Y flags, and run.ps1 enhancements**

### Added

- Script 35 (`35-install-gitmap`) -- installs GitMap CLI via remote installer from GitHub (`alimtvnetwork/git-repo-navigator`)
- `gitmap`, `git-map` install keywords mapping to script ID 35
- GitMap entry in all-dev `config.json` and `registry.json`
- Global `-Defaults` (`-D`) and `-Y` flags on `run.ps1` -- propagated to child scripts as `ExtraArgs`
- `-Defaults` shows all default values and prompts for confirmation before proceeding
- `-Defaults -Y` auto-confirms and proceeds without prompting
- `-Defaults` without `-I` defaults to script 12 (all-dev)
- Defaults Mode section in `run.ps1 -Help` showing default dev directory, VS Code edition, and sync mode
- `spec/35-install-gitmap/readme.md` with full usage documentation

---

## [v0.5.5] -- 2026-04-07

**Release pipeline script for versioned ZIP packaging**

### Added

- `release.ps1` -- packages `scripts/`, `run.ps1`, `bump-version.ps1`, `readme.md`, `LICENSE`, and `CHANGELOG.md` into a versioned ZIP under `.release/`
- Supports `-DryRun` (preview contents) and `-Force` (overwrite existing ZIP) flags
- Reads version automatically from `.gitmap/release/latest.json`
- `spec/release-pipeline/readme.md` with full usage documentation

---

## [v0.5.4] -- 2026-04-06

**Audit --DryRun flag and Invoke-WithTimeout shared helper**

### Added

- `--DryRun` flag for audit symlink verification (`Test-VerifySymlinks`) -- previews which symlinks would be removed, created, or skipped without modifying the filesystem
- `Invoke-WithTimeout` shared helper (`scripts/shared/invoke-with-timeout.ps1`) -- wraps any script block in a background job with a configurable timeout guard, polling progress logs, and forceful termination on timeout
- 6 new `timeout*` log message keys in `scripts/shared/log-messages.json`
- Usage examples for `--DryRun` in `spec/audit/readme.md`
- Full `invoke-with-timeout.ps1` section in `spec/shared/readme.md`

---

## [v0.5.3] -- 2026-04-06

**DBeaver Community installer, combo group presets, and database menu integration**

### Added

- Script 32 (`32-install-dbeaver`) -- installs DBeaver Community Edition via Chocolatey with `config.json`, `helpers/dbeaver.ps1`, `log-messages.json`, and `run.ps1`
- `spec/32-install-dbeaver/readme.md` -- spec doc for the DBeaver installer
- `dbeaver`, `db-viewer`, `dbviewer` install keywords mapping to script ID 32
- DBeaver entry in `databases/config.json` as type `"tool"` so it appears in the interactive database installer menu (script 30)
- New all-dev menu combo group presets in `12-install-all-dev-tools/config.json`:
  - `o` -- All Dev + MySQL
  - `p` -- All Dev + PostgreSQL
  - `r` -- All Dev + PostgreSQL + Redis
  - `s` -- SQLite + DBeaver
  - `t` -- All DBs + DBeaver (18-29, 32)
- New database menu groups in `databases/config.json`:
  - `f` -- Popular + DBeaver
  - `g` -- All + DBeaver
- Registry entry for script 32 in `scripts/registry.json`
- DBeaver added to orchestrator config sequence and `"Everything"` group

---

## [v0.5.2] -- 2026-04-06

**Post-install symlink verification for database scripts**

### Added

- `Test-PostInstallSymlink` helper in `databases/run.ps1` -- verifies junction exists and is a valid reparse point after each database install
- `symlinkVerifyOk`, `symlinkVerifyMissing`, `symlinkVerifyNotJunction` log messages in `databases/log-messages.json`
- `Invoke-DbScript` now accepts `$Key` parameter and triggers symlink verification automatically after script completion

---

## [v0.5.1] -- 2026-04-06

**Drive override flag, audit --Fix for broken symlinks, and new spec docs**

### Added

- `-Drive` flag on `databases/run.ps1` -- override auto-detected drive (e.g. `.\run.ps1 -Drive F`)
- `-Fix` flag on `audit/run.ps1` -- removes broken junctions and recreates them automatically
- `driveOverride` log message in `databases/log-messages.json`
- Audit fix log messages (`symlinkFixRemoved`, `symlinkFixCreated`, `symlinkFixSkipped`, `symlinkFixMissing`) in `audit/log-messages.json`
- `spec/shared/dev-dir.md` -- smart drive selection, 10 GB threshold, `Test-DriveQualified` / `Find-BestDevDrive` / `Resolve-SmartDevDir` docs
- `spec/shared/symlink-utils.md` -- `Resolve-DbInstallDir` and `New-DbSymlink` function docs

### Changed

- `audit/helpers/checks.ps1` `Test-VerifySymlinks` now accepts `-Fix` to repair broken and missing junctions
- `audit/run.ps1` dot-sources `symlink-utils.ps1` and passes `-Fix` through

### Fixed

- Broken or stale database junctions can now be auto-repaired instead of requiring manual cleanup

---

## [v0.5.0] -- 2026-04-06

**Smart drive detection, database symlinks, and dynamic dev directory resolution**

### Added

- Smart drive detection in `dev-dir.ps1`: priority E: > D: > best non-system drive > user prompt
- `Test-DriveQualified` function -- checks drive exists and has at least 10 GB free space
- `Find-BestDevDrive` function -- scans fixed drives and picks the best candidate
- `Resolve-SmartDevDir` function -- orchestrates detection with user prompt fallback
- `scripts/shared/symlink-utils.ps1` with `Resolve-DbInstallDir` and `New-DbSymlink` functions
- Directory junction creation from `<devDir>\databases\<name>` to actual Chocolatey install paths
- 15 new log messages (8 drive detection + 7 symlink) in `shared/log-messages.json`
- All 12 database `run.ps1` files now call `New-DbSymlink` after successful install

### Changed

- All `config.json` files updated from `"mode": "json-or-prompt"` / `"default": "E:\\dev"` to `"mode": "smart"` / `"default": "auto"`
- `Resolve-DevDir` now uses smart drive detection instead of hardcoded defaults
- `installMode: "devDir"` config option now actually creates junctions to the dev directory

### Fixed

- Databases previously installed to system default locations ignoring `devDir` config -- now symlinked to `<devDir>\databases\<name>`
- Dev directory no longer hardcoded to E: drive -- dynamically selects the best available drive

---

## [v0.4.1] -- 2026-04-07

**Crash-safe error logging, VS Code/pwsh detection fallbacks, and full-path error diagnostics**

### Added

- `try/catch/finally` wrapper in all 31 `run.ps1` files -- `Save-LogFile` now always runs, even on unhandled exceptions
- Warnings (warn-level) now captured in error log files alongside errors, with separate `errors` and `warnings` arrays
- `warnCount` field added to error log JSON schema
- 4-tier VS Code exe fallback chain: config paths → Chocolatey shim/lib → `Get-Command` → `where.exe` (script 10)
- Chocolatey shim fallback for `pwsh.exe` detection (script 31)
- Detailed per-step failure logging for all fallback paths in scripts 10 and 31

### Changed

- `fileExistsAtPath` log message now includes the full file path being checked, not just True/False
- File-not-found checks in scripts 10 and 31 now log at error/warn level instead of info (captured in error logs)
- `Get-InstalledDir` function replaces `$script:_InstalledDir` variable for robust sourcing context
- `Save-InstalledRecord` accepts empty version strings gracefully (falls back to `'unknown'`)
- Error log creation trigger expanded: any warn OR fail event now generates an error log file

### Fixed

- `$script:_InstalledDir` variable not set error -- replaced with `Get-InstalledDir` function that works regardless of dot-sourcing context
- Empty version string error in `Save-InstalledRecord` when `choco list` returns no match
- Missing error log files when scripts crashed with unhandled exceptions before `Save-LogFile` could run
- VS Code exe not found after Chocolatey install because `config.json` only had user/system paths, not choco paths

### Docs

- Issue 4 added to `scripts/10-vscode-context-menu-fix/issues.md` documenting Chocolatey path detection root cause
- `spec/shared/logging.md` updated with warn-level capture, new error log schema, and crash-safe `try/catch/finally` pattern
- `spec/shared/installed.md` updated with `Get-InstalledDir`, empty version fallback, and Error Tracking section

---

## [v0.4.0] -- 2026-04-06

**Error tracking, registry API migration, database menu option, and spec updates**

### Added

- `Save-InstalledError` catch blocks in all 13 install helper scripts (vscode, choco, nodejs, pnpm, python, golang, git, github-desktop, mingw, winget, php, powershell, databases)
- All Databases Only option (`mode: alldb`) as option 3 in script 12 quick menu
- Error Tracking section in `spec/shared/installed.md` with field docs, JSON examples, and retry behaviour
- `Save-InstalledError` column in spec tracking table showing coverage across all scripts

### Changed

- Scripts 10 and 31 migrated from `reg.exe` to .NET `Microsoft.Win32.Registry` API to fix Invalid syntax errors with nested quotes
- Script 12 questionnaire reordered: Install All (1), Dev Tools Only (2), All Databases Only (3), Custom (4)

### Fixed

- Registry command failures in scripts 10 (VS Code context menu) and 31 (PowerShell context menu) caused by `cmd.exe /c` parsing of nested quotes in `pwsh.exe -Command` strings

### Docs

- Updated `spec/shared/installed.md` with error JSON schema fields (`lastError`, `errorAt`), recovery examples, and retry behaviour
- Updated `scripts/10-vscode-context-menu-fix/issues.md` with root cause analysis and .NET API migration notes

---

## [v0.3.0] -- 2026-04-05

**Database scripts, installation tracking, front-loaded questionnaire, shared helpers, and structured logging**

### Added

- Database installation scripts (18-29): MySQL, MariaDB, PostgreSQL, SQLite, MongoDB, CouchDB, Redis, Cassandra, Neo4j, Elasticsearch, DuckDB, LiteDB
- Database orchestrator (`scripts/databases/`) with interactive menu, `-All`, `-Only`, `-Skip`, `-DryRun` flags
- Generic `Install-Database` function in `scripts/databases/helpers/install-db.ps1` (choco and dotnet-tool methods)
- Installation tracking via `.installed/` folder with per-tool JSON files (name, version, method, timestamps, error fields)
- Shared `installed.ps1` with `Test-AlreadyInstalled`, `Save-InstalledRecord`, `Save-InstalledError`, `Get-InstalledRecord`
- Front-loaded questionnaire in script 12: dev dir, VS Code editions, sync mode, Git name/email asked upfront
- Quick menu in script 12: Install All Dev (1), All Dev + All DBs (2), Custom (3)
- `-D` / `-Defaults` flag for zero-prompt runs with default answers
- `.resolved/` folder pattern with `Save-ResolvedData` and `Get-ResolvedDir` shared helpers
- Structured JSON logging system: `Initialize-Logging`, `Write-Log` event collection, `Save-LogFile` to `.logs/`
- Error log auto-creation when fail-level events are recorded
- Shared helpers: `choco-utils.ps1`, `path-utils.ps1`, `dev-dir.ps1`
- Script 14 (winget): detection, install via MSIX, PATH refresh
- Script 15 (windows-tweaks): system tweaks with confirmation skip under orchestrator
- Script 16 (PHP): Chocolatey-based install with upgrade support
- Script 17 (PowerShell): pwsh install/upgrade via Chocolatey
- Script 31 (pwsh-context-menu): PowerShell Here context menu entries for folders, backgrounds, and admin mode
- Audit script (`scripts/audit/`): system checks and validation
- `install-keywords.json` mapping natural-language keywords to script IDs
- Interactive menu in script 12: lettered group shortcuts, CSV/space number input, loop-back after install

### Changed

- All install helpers now use `Test-AlreadyInstalled` to skip redundant installs when version matches
- `Write-Banner` auto-reads `scripts/version.json` for project version display
- Logging moved from `scripts/logs/` to `.logs/` at project root
- Version numbers in `Write-Log` output highlighted in Yellow
- Config files are declarative input only -- runtime state goes to `.resolved/`

### Docs

- `spec/shared/installed.md`: installation tracking specification
- `spec/shared/logging.md`: structured logging specification
- Spec docs for all new scripts (14-29, 31, audit, databases)
- Memory files for database-scripts, installed-tracking, interactive-menu, questionnaire, resolved-folder, shared-helpers, logging

---

## [v0.2.0] -- 2026-04-03

Initial tagged release (no changelog recorded).

---

## [v0.1.0] -- 2026-04-03

Initial tagged release (no changelog recorded).
