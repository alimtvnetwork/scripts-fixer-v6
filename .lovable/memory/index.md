# Project Memory

## Core
Project includes PowerShell utility scripts alongside the React web app.
User prefers structured script projects: external JSON configs, spec docs, suggestions folder, colorful logging.
Script 12 uses front-loaded questionnaire: ask all questions first, then run unattended.
DB installs use system default path (no --install-directory, Chocolatey Business only).
All scripts read version from single `scripts/version.json` — Write-Banner auto-loads it.
Logs stored in `.logs/` at project root, not scripts/logs/.
`.installed/` tracks tool versions; skip install if version matches.

## Memories
- [Script structure](mem://preferences/script-structure) — How the user wants scripts organized with configs, specs, and suggestions
- [Shared helpers](mem://features/shared-helpers) — All shared PS1 helpers inventory and logging system
- [Questionnaire pattern](mem://features/questionnaire) — Front-loaded questions in script 12, env var injection, DB install approach
- [Naming conventions](mem://preferences/naming-conventions) — is/has prefix for booleans, avoid bare -not
- [Terminal banners](mem://constraints/terminal-banners) — Avoid em dashes and wide Unicode in box-drawing
- [Interactive menu](mem://features/interactive-menu) — Script 12 checkbox menu with group shortcuts
- [Resolved folder](mem://features/resolved-folder) — .resolved/ runtime state persistence
- [Database scripts](mem://features/database-scripts) — DB install scripts 18-29 and script 30 orchestrator
- [Logging](mem://features/logging) — .logs/ at root, version highlighting in Yellow
- [Installed tracking](mem://features/installed-tracking) — .installed/ per-tool JSON, skip if version matches
