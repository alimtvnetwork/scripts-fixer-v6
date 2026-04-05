# Spec: Centralised JSON Logging System

## Overview

All scripts produce structured JSON log files in a single `scripts/logs/`
directory. Every `Write-Log` call during execution is captured as a timestamped
event. At script completion, events are flushed to disk as JSON.

---

## Directory Layout

```
scripts/
└── logs/                          # Gitignored -- never committed
    ├── install-vscode.json        # Normal log for script 01
    ├── install-golang.json        # Normal log for script 06
    ├── install-golang-error.json  # Error log (only when errors occur)
    ├── install-all-dev-tools.json # Orchestrator log for script 12
    └── ...
```

The `logs/` folder is auto-created by `Initialize-Logging` if it does not
exist. It is covered by the root `.gitignore` (`logs` pattern).

---

## Functions

All functions live in `scripts/shared/logging.ps1`.

| Function | Purpose |
|----------|---------|
| `Initialize-Logging` | Starts event collection for a script run |
| `Write-Log` | Prints a badged console message AND records a structured event |
| `Save-LogFile` | Flushes collected events to JSON files on disk |
| `Write-Banner` | Displays a titled banner block (no log recording) |
| `Import-JsonConfig` | Loads a JSON file with verbose logging |

---

## Usage

Every `run.ps1` follows this pattern:

```powershell
# After banner
Write-Banner -Title $logMessages.scriptName -Version $logMessages.version

# Start collecting events
Initialize-Logging -ScriptName $logMessages.scriptName

# ... script logic with Write-Log calls ...

# Flush to disk at the end
Save-LogFile -Status "ok"
```

### Dynamic Status

Scripts with success/failure tracking pass the status dynamically:

```powershell
Save-LogFile -Status $(if ($isSuccess) { "ok" } else { "fail" })
```

---

## File Name Convention

The `-ScriptName` parameter is sanitised to produce the filename:

| Script Name | Log File | Error File |
|-------------|----------|------------|
| `Install Golang` | `install-golang.json` | `install-golang-error.json` |
| `Install VS Code` | `install-vs-code.json` | `install-vs-code-error.json` |
| `Install All Dev Tools` | `install-all-dev-tools.json` | `install-all-dev-tools-error.json` |

**Sanitisation rules:**
1. Convert to lowercase
2. Replace non-alphanumeric sequences with `-`
3. Trim leading/trailing hyphens

---

## JSON Schema

### Normal Log (`<name>.json`)

```json
{
  "scriptName": "install-golang",
  "status": "ok",
  "startTime": "2026-04-05T15:30:00.0000000+08:00",
  "endTime": "2026-04-05T15:31:12.0000000+08:00",
  "duration": 72.34,
  "eventCount": 14,
  "errorCount": 0,
  "events": [
    {
      "timestamp": "2026-04-05T15:30:00.1234567+08:00",
      "level": "info",
      "message": "Checking for Chocolatey..."
    },
    {
      "timestamp": "2026-04-05T15:30:01.2345678+08:00",
      "level": "ok",
      "message": "Chocolatey found: v2.7.1"
    }
  ]
}
```

### Error Log (`<name>-error.json`)

```json
{
  "scriptName": "install-golang",
  "overallStatus": "fail",
  "startTime": "2026-04-05T15:30:00.0000000+08:00",
  "endTime": "2026-04-05T15:31:12.0000000+08:00",
  "duration": 72.34,
  "errorCount": 1,
  "errors": [
    {
      "timestamp": "2026-04-05T15:30:45.6789012+08:00",
      "level": "fail",
      "message": "Failed to install 'golang': exit code 1"
    }
  ]
}
```

---

## Error File Creation Rules

An error log file (`<name>-error.json`) is created when **either** condition
is true:

| Condition | Description |
|-----------|-------------|
| Any `fail`-level event | At least one `Write-Log -Level "error"` call was made during execution |
| Overall status is `"fail"` | `Save-LogFile -Status "fail"` was called (script-level failure) |

If neither condition is met, no error file is created.

---

## Event Levels

| Level | Badge | Colour | Description |
|-------|-------|--------|-------------|
| `ok` | `[  OK  ]` | Green | Success |
| `fail` | `[ FAIL ]` | Red | Error (also recorded in error log) |
| `info` | `[ INFO ]` | Cyan | Informational |
| `warn` | `[ WARN ]` | Yellow | Warning |
| `skip` | `[ SKIP ]` | DarkGray | Skipped step |

The `-Level` parameter accepts aliases: `success` maps to `ok`, `error` maps
to `fail`.

---

## Module-Scoped State

`logging.ps1` uses `$script:` scoped variables to track state across calls
within a single script execution:

| Variable | Type | Purpose |
|----------|------|---------|
| `$script:_LogEvents` | `ArrayList` | All recorded events |
| `$script:_LogErrors` | `ArrayList` | Error-level events only |
| `$script:_LogName` | `string` | Sanitised script name (used as filename) |
| `$script:_LogStart` | `DateTime` | Timestamp when `Initialize-Logging` was called |
| `$script:_LogsDir` | `string` | Resolved path to `scripts/logs/` |

These are reset on each `Initialize-Logging` call.

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Centralised `scripts/logs/` directory | Single location for all logs; easy to find, browse, and clean |
| JSON format (not transcript) | Structured, parseable, can be consumed by other tools |
| Separate error files | Quick scan for failures without parsing full event logs |
| Dual error-file trigger | Catches both individual error events and overall script failure |
| No logging for early exits | Help, disabled-check, and admin-check exits happen before `Initialize-Logging` -- these are trivial and don't need logs |
| Overwrite on re-run | Each run overwrites the previous log for that script; logs are ephemeral diagnostics, not audit trails |
| `$script:` scope | Avoids global pollution; each dot-sourced script gets its own event buffer |

---

## Replaced System

The previous logging used `Start-Transcript` to capture raw console output
into per-script `logs/` subdirectories. This was replaced because:

1. Transcript files are plain text, not structured
2. Each script had its own `logs/` folder, making discovery harder
3. No separation of errors from normal output
4. No machine-readable format for downstream processing
