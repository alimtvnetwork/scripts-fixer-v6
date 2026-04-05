---
name: Front-loaded questionnaire pattern
description: Script 12 asks all config questions upfront (dev dir, VS Code editions, sync mode), stores in env vars, child scripts run unattended
type: feature
---
## Front-loaded questionnaire

Script 12 uses a 3-option quick menu:
1. All Dev (no DBs) -- IDs 01-11, 16-17, 31
2. All Dev + All DBs -- adds 18-29
3. Custom -- full interactive checkbox menu

All config questions (dev dir, VS Code editions, sync mode) are asked BEFORE any scripts run.
Answers are stored in env vars: `$env:DEV_DIR`, `$env:VSCODE_EDITIONS`, `$env:VSCODE_SYNC_MODE`.

## DB install approach
- Chocolatey free edition does NOT support `--install-directory`
- All DB scripts install to system default location
- No install-path prompts in individual DB run.ps1 files
