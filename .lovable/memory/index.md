# Memory: index.md
Updated: now

# Project Memory

## Core
Project includes PowerShell utility scripts alongside the React web app.
User prefers structured script projects: external JSON configs, spec docs, suggestions folder, colorful logging.
Config files are read-only at runtime. Runtime state goes to .resolved/ (gitignored), never into config.json.

## Memories
- [Script structure](mem://preferences/script-structure) -- How the user wants scripts organized with configs, specs, and suggestions
- [Naming conventions](mem://preferences/naming-conventions) -- Kebab-case files/folders, PascalCase PS functions
- [Terminal banners](mem://constraints/terminal-banners) -- Avoid em dashes and wide Unicode in box-drawing banners
- [Resolved folder pattern](mem://features/resolved-folder) -- Runtime state to .resolved/, cache-first detection, shared resolved.ps1
- [Shared helpers inventory](mem://features/shared-helpers) -- All scripts/shared/ PS1 files and their functions
