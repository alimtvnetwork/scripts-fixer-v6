# Spec: Choco Update Command

## Overview

The `.\run.ps1 update` command upgrades all installed Chocolatey packages
in a single operation with user confirmation.

---

## Usage

```powershell
.\run.ps1 update            # List packages, confirm, upgrade all
.\run.ps1 upgrade           # Alias
.\run.ps1 choco-update      # Alias
```

---

## Execution Flow

1. Verify Chocolatey is installed (`choco.exe` in PATH)
2. Run `choco list --local-only` to enumerate all installed packages
3. Display formatted table with package names and versions
4. Show total package count
5. Prompt: "Do you want to upgrade ALL packages? [Y/n]"
6. If confirmed, run `choco upgrade all -y`
7. Report success or failure

---

## Accepted Commands

| Command | Behaviour |
|---------|-----------|
| `update` | List + confirm + upgrade all |
| `upgrade` | Alias for `update` |
| `choco-update` | Alias for `update` |

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| User confirmation before upgrade | Prevents accidental mass upgrades |
| Show full package list first | User sees what will be affected |
| `choco upgrade all -y` | Standard Chocolatey bulk upgrade command |
| No logging initialisation | Lightweight utility, not a numbered script |
