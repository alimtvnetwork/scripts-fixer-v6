# Spec: Interactive Model Picker & aria2c Download System

## Overview

The model picker is an interactive numbered-selection system that lets users
browse, filter, and download GGUF/GGML models from a rich JSON catalog. It
uses aria2c for multi-connection accelerated downloads with a graceful
fallback to `Invoke-DownloadWithRetry`. Every successful download is tracked
in `.installed/` for idempotency and clean uninstall.

---

## File Structure

```
scripts/
├── shared/
│   └── aria2c-download.ps1         # Assert-Aria2c, Invoke-Aria2Download
└── 43-install-llama-cpp/
    ├── models-catalog.json          # 69-model catalog (standalone file)
    ├── config.json                  # Executable variants + aria2c settings
    ├── run.ps1                      # Entry point (Command: all|executables|models)
    └── helpers/
        ├── llama-cpp.ps1            # Install-LlamaCppExecutables, Uninstall-LlamaCpp
        └── model-picker.ps1         # Show-ModelCatalog, Read-CapabilityFilter,
                                     #   Read-ModelSelection, Install-SelectedModels,
                                     #   Invoke-ModelInstaller
```

---

## Interactive Flow

### Sequence Diagram

```
User runs: .\run.ps1 models
  │
  ├─ 1. Load models-catalog.json
  │     Parse JSON, validate model count
  │
  ├─ 2. Resolve models directory
  │     ├─ Orchestrator mode ($env:SCRIPTS_ROOT_RUN = "1"):
  │     │     Use default: <dev-dir>\llama-models
  │     └─ Interactive mode:
  │           Show default path, prompt user for override
  │           Create directory if missing
  │
  ├─ 3. Ensure aria2c
  │     ├─ Found in PATH → log version, continue
  │     └─ Missing → choco install aria2 → refresh PATH
  │           ├─ Success → continue with aria2c
  │           └─ Fail → warn, fall back to Invoke-DownloadWithRetry
  │
  ├─ 4. Capability filter (interactive only)
  │     ├─ Display 6 capability categories with model counts:
  │     │     [1] Coding (N models)
  │     │     [2] Reasoning (N models)
  │     │     [3] Writing (N models)
  │     │     [4] Chat (N models)
  │     │     [5] Voice / Speech (N models)
  │     │     [6] Multilingual (N models)
  │     ├─ Enter → skip filter, show all models
  │     ├─ Selection: single (1), range (1-3), mixed (1,3,5-6)
  │     └─ OR logic: model shown if ANY selected capability matches
  │         Models are re-indexed 1..N after filtering
  │
  ├─ 5. Display catalog table
  │     Columns: #, Model, Params, Quant, Size, RAM, Capabilities
  │     ├─ Starred (recommended) models grouped first
  │     ├─ Color-coded by rating:
  │     │     Green  = 9-10 (top tier)
  │     │     Yellow = 7-8
  │     │     White  = 5-6
  │     │     Gray   = below 5
  │     └─ Capabilities shown as: code, reason, write, voice, chat, multi
  │
  ├─ 6. Model selection
  │     ├─ Orchestrator mode: auto-select all models
  │     └─ Interactive mode:
  │           ├─ Single: 3
  │           ├─ Range: 1-5
  │           ├─ Mixed: 1-3,7,12-15
  │           ├─ All: "all"
  │           └─ Quit: "q" / "quit" / "exit"
  │
  ├─ 7. Disk space pre-check
  │     Sum fileSizeGB of selected models → Test-DiskSpace -WarnOnly
  │     Proceeds with warning if insufficient
  │
  └─ 8. Download selected models
        For each model:
        ├─ Check .installed/ tracking + file on disk
        │     ├─ Tracked + file exists → skip (already downloaded)
        │     └─ Tracked + file missing → remove stale record, re-download
        ├─ Download via Invoke-Aria2Download (16 connections)
        │     ├─ Success → Save-InstalledRecord
        │     └─ Fail → Write-FileError with exact path + reason
        └─ Summary: N downloaded, N skipped, N failed
```

---

## Model Catalog Format (`models-catalog.json`)

### Top-Level Structure

```json
{
  "catalogVersion": "3.0.0",
  "description": "Comprehensive GGUF/GGML model catalog...",
  "capabilityFlags": {
    "isCoding": "Model is trained/optimized for code generation...",
    "isReasoning": "Model supports chain-of-thought...",
    "isVoice": "Model supports voice/audio...",
    "isWriting": "Model is good at creative writing...",
    "isMultilingual": "Model supports multiple human languages...",
    "isChat": "Model is optimized for conversational interactions"
  },
  "models": [ ... ]
}
```

### Per-Model Schema

| Field               | Type     | Required | Description                                                |
|---------------------|----------|----------|------------------------------------------------------------|
| `id`                | string   | Yes      | Unique slug identifier (e.g. `qwen2.5-coder-3b`)          |
| `displayName`       | string   | Yes      | Human-readable name. Prefix with `★` for recommended.     |
| `family`            | string   | Yes      | Model family (e.g. `Alibaba Qwen`, `Meta Llama`)          |
| `parameters`        | string   | Yes      | Parameter count (e.g. `3B`, `14B`, `72B`)                  |
| `quantization`      | string   | Yes      | Quantization level (e.g. `Q4_K_M`, `Q5_K_M`, `Q8_0`)     |
| `fileSizeGB`        | number   | Yes      | Download size in GB                                        |
| `fileName`          | string   | Yes      | Output file name (no path, just the `.gguf` filename)      |
| `ramRequiredGB`     | number   | Yes      | Minimum RAM to load the model                              |
| `ramRecommendedGB`  | number   | Yes      | Recommended RAM for comfortable use                        |
| `isCoding`          | boolean  | Yes      | Capability flag                                            |
| `isReasoning`       | boolean  | Yes      | Capability flag                                            |
| `isVoice`           | boolean  | Yes      | Capability flag                                            |
| `isWriting`         | boolean  | Yes      | Capability flag                                            |
| `isMultilingual`    | boolean  | Yes      | Capability flag                                            |
| `isChat`            | boolean  | Yes      | Capability flag                                            |
| `rating`            | object   | Yes      | `{ coding, reasoning, speed, overall }` scores 0-10       |
| `bestFor`           | string   | Yes      | One-line description of ideal use case                     |
| `notes`             | string   | Yes      | Additional technical notes                                 |
| `source`            | string   | Yes      | Publisher / organization                                   |
| `license`           | string   | Yes      | License type (e.g. `Apache 2.0`, `Llama 3.1`)             |
| `downloadUrl`       | string   | Yes      | Direct GGUF download URL (Hugging Face)                    |
| `huggingfacePage`   | string   | Yes      | Hugging Face model page URL                                |
| `index`             | integer  | Yes      | Display order (1-based, sequential)                        |

### Design Decisions

| Decision                          | Rationale                                                   |
|-----------------------------------|-------------------------------------------------------------|
| No hardcoded paths in catalog     | Models directory resolved at runtime; catalog is portable   |
| Separate file from config.json    | Catalog is large (69 models); keeps config lean             |
| `★` prefix for recommended       | Visual grouping in terminal; starred models sort first      |
| `index` field pre-assigned        | Stable numbering for scripted/automated selection           |
| All 6 capability flags on every model | Enables filter without null checks                      |
| `rating.overall` drives color     | Quick visual quality signal in the catalog display          |

---

## aria2c Download System (`scripts/shared/aria2c-download.ps1`)

### Functions

| Function             | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| `Assert-Aria2c`      | Ensures aria2c is installed; auto-installs via Chocolatey      |
| `Invoke-Aria2Download` | Downloads a file with multi-connection; falls back on failure |

### Assert-Aria2c Flow

```
1. Get-Command aria2c.exe
   ├─ Found → log version, return $true
   └─ Not found →
        2. Assert-Choco (ensure Chocolatey available)
           ├─ Fail → log warn, return $false
           └─ OK →
                3. choco install aria2 -y --no-progress
                4. Refresh $env:Path (Machine + User)
                5. Get-Command aria2c.exe
                   ├─ Found → return $true
                   └─ Not found → return $false
```

### Invoke-Aria2Download Parameters

| Parameter          | Type   | Default  | Description                              |
|--------------------|--------|----------|------------------------------------------|
| `Uri`              | string | Required | Download URL                             |
| `OutFile`          | string | Required | Full output file path                    |
| `Label`            | string | `""`     | Friendly name for logs                   |
| `MaxConnections`   | int    | `16`     | Connections per server (`-x`)            |
| `MaxDownloads`     | int    | `16`     | Parallel download segments (`-s`)        |
| `ChunkSize`        | string | `"1M"`   | Download chunk size (`-k`)               |
| `ContinueDownload` | bool   | `$true`  | Resume partial downloads (`--continue`)  |

### aria2c Command-Line Arguments

```
aria2c.exe
    -x16                    # Max connections per server
    -s16                    # Split into N segments
    -k1M                    # Min split size
    --file-allocation=none  # Skip pre-allocation (faster start)
    --max-tries=3           # Retry on failure
    --retry-wait=5          # Wait between retries
    --timeout=60            # Per-connection timeout
    --continue=true         # Resume partial files
    -d <output-dir>         # Target directory
    -o <filename>           # Output file name
    <url>
```

### Fallback Chain

```
1. Try aria2c
   ├─ Exit code 0 + file valid → success
   ├─ Exit code non-zero → log warn → try fallback
   └─ Exception → log warn → try fallback
2. Fallback: Invoke-DownloadWithRetry
   ├─ 3 attempts, exponential backoff (5s, 10s, 20s)
   └─ Returns $true/$false
```

### aria2c Config in `config.json`

```json
{
  "aria2c": {
    "maxConnections": 16,
    "maxDownloads": 16,
    "chunkSize": "1M",
    "continueDownload": true
  }
}
```

Defaults are applied in `Install-SelectedModels` if config values are missing.

---

## .installed/ Tracking

### Purpose

Persistent idempotency records. Each downloaded model writes a tracking file
so subsequent runs skip already-downloaded models and uninstall can clean up.

### Record Location

```
.installed/model-<id>.json
```

Example: `.installed/model-qwen2.5-coder-3b.json`

### Record Format

Created by `Save-InstalledRecord`:

```json
{
  "name": "model-qwen2.5-coder-3b",
  "version": "Q4_K_M",
  "method": "aria2c",
  "installedAt": "2026-04-15T10:30:00Z"
}
```

### Tracking Logic

| Tracked? | File on disk? | Action                                     |
|----------|---------------|--------------------------------------------|
| Yes      | Yes           | Skip -- already downloaded                 |
| Yes      | No            | Stale record -- remove tracking, re-download |
| No       | Yes           | File exists outside tracking -- re-download (no record) |
| No       | No            | Normal -- download and create record       |

### Uninstall Cleanup

`Uninstall-LlamaCpp` in `llama-cpp.ps1` removes all `model-*` tracking records:

```powershell
$modelRecords = Get-ChildItem (Get-InstalledDir) -Filter "model-*.json"
foreach ($record in $modelRecords) {
    Remove-InstalledRecord -Name $record.BaseName
}
```

---

## Capability Filter (`Read-CapabilityFilter`)

### Capability Map

| # | Key              | Label            |
|---|------------------|------------------|
| 1 | `isCoding`       | Coding           |
| 2 | `isReasoning`    | Reasoning        |
| 3 | `isWriting`      | Writing          |
| 4 | `isChat`         | Chat             |
| 5 | `isVoice`        | Voice / Speech   |
| 6 | `isMultilingual` | Multilingual     |

### Selection Syntax

Same parser as model selection:
- Single: `1`
- Range: `1-3`
- Mixed: `1,3,5-6`
- Enter: skip filter (show all)

### Matching Logic

**OR** -- a model is included if it has `$true` for ANY of the selected
capability flags. For example, selecting `1,5` (Coding + Voice) shows all
models that are either coding OR voice models.

### Post-Filter Re-indexing

After filtering, models are re-indexed starting from 1 so the numbered
display is clean and contiguous. The original catalog indices are not
preserved in filtered view. `Install-SelectedModels` receives the filtered
array directly, so indices always match what the user sees.

---

## Orchestrator Mode

When `$env:SCRIPTS_ROOT_RUN = "1"` (set by the root dispatcher or script 12):

| Step                  | Behaviour                              |
|-----------------------|----------------------------------------|
| Models directory      | Auto-selects default, no prompt        |
| Capability filter     | Skipped entirely                       |
| Model selection       | Auto-selects all models                |
| Downloads             | Proceeds with full catalog             |

---

## Error Handling

### CODE RED Rule

Every file/path error includes exact path and failure reason via
`Write-FileError`:

```powershell
Write-FileError -FilePath $outputPath -Operation "download" `
    -Reason "Download failed after retries" -Module "Install-SelectedModels"
```

### Failure Points

| Operation              | Error Handling                                          |
|------------------------|---------------------------------------------------------|
| Catalog file missing   | `Write-FileError` + early return                        |
| aria2c install fails   | Warn + fall back to `Invoke-DownloadWithRetry`          |
| aria2c non-zero exit   | Warn + retry with `Invoke-DownloadWithRetry`            |
| Download produces 0 bytes | aria2c reports failure; fallback retries             |
| Disk space insufficient | Warn-only (non-blocking); user sees shortfall amount   |
| Stale tracking record  | Auto-cleanup + re-download                              |

---

## Dependencies

| Helper                    | Used For                                      |
|---------------------------|-----------------------------------------------|
| `logging.ps1`             | `Write-Log`, `Write-Banner`, `Import-JsonConfig` |
| `choco-utils.ps1`         | `Assert-Choco` (for aria2c install)           |
| `download-retry.ps1`      | `Invoke-DownloadWithRetry` (fallback)         |
| `aria2c-download.ps1`     | `Assert-Aria2c`, `Invoke-Aria2Download`       |
| `disk-space.ps1`          | `Test-DiskSpace` (pre-download check)         |
| `installed.ps1`           | `Save-InstalledRecord`, `Get-InstalledRecord`, `Remove-InstalledRecord` |
| `dev-dir.ps1`             | `Resolve-DevDir` (models directory default)   |
| `path-utils.ps1`          | PATH manipulation for executables             |
