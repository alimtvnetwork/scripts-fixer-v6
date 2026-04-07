# Spec: Install Simple Sticky Notes (Script 34)

## Overview

Script 34 installs **Simple Sticky Notes** via Chocolatey -- a lightweight
desktop sticky notes application for Windows.

---

## Usage

```powershell
.\run.ps1 install sticky-notes       # Install Simple Sticky Notes
.\run.ps1 install stickynotes        # Alias
.\run.ps1 -I 34                      # By script ID
.\run.ps1 -I 34 -- -Help             # Show help
```

## Keywords

| Keyword | Script ID |
|---------|-----------|
| `sticky-notes` | 34 |
| `stickynotes` | 34 |
| `sticky` | 34 |

---

## Config (`config.json`)

| Field | Value |
|-------|-------|
| `chocoPackage` | `simple-sticky-notes` |
| `enabled` | `true` |
| `verifyCommand` | `SimpleSticky` |

---

## Execution Flow

1. Check if Simple Sticky Notes is already installed (common paths + `Get-Command`)
2. If found, log and skip
3. If missing, install via `choco install simple-sticky-notes -y`
4. Verify EXE exists at expected path after install (CODE RED: exact path logged on failure)
5. Save install record to `.installed/sticky-notes.json`
6. Save resolved state to `.resolved/34-install-sticky-notes/resolved.json`

---

## Verification Paths

- `$env:ProgramFiles\Simple Sticky Notes\SimpleSticky.exe`
- `${env:ProgramFiles(x86)}\Simple Sticky Notes\SimpleSticky.exe`

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Simple Sticky Notes (Choco) | User selected over Microsoft Sticky Notes (UWP) or Stickies |
| EXE verification post-install | CODE RED rule: exact path logged if not found |
| `Install-ChocoPackage` helper | Consistent with all other Choco-based scripts |
