# Script 43 -- Install llama.cpp

## Purpose
Downloads llama.cpp pre-built binaries (CUDA, AVX2 CPU, KoboldCPP), extracts them to the dev directory, adds binary folders to user PATH, and downloads a comprehensive catalog of GGUF/GGML models via aria2c accelerated downloads.

## Directory Structure
```
scripts/43-install-llama-cpp/
  config.json           # Executable variants, 30+ model catalog, aria2c config, paths
  log-messages.json     # All log message templates
  run.ps1               # Entry point (param: Command, Path, -Help)
  helpers/
    llama-cpp.ps1       # Install-LlamaCppExecutables, Install-LlamaCppModels, Uninstall-LlamaCpp
```

## Install Flow

### Pre-flight Checks
1. **URL freshness** -- HEAD-checks all download URLs; blocks if any executable URL is stale, warns for model URLs
2. **Disk space** -- blocks if insufficient space for executables, warns for models

### Executables
1. For each variant in `config.executables`:
   - Check if already downloaded (skip if present)
   - For ZIPs: validate integrity (magic bytes `PK\x03\x04` + expected size +-10%)
   - If corrupt/partial: delete and re-download automatically
   - Download with retry (3 attempts, exponential backoff via `Invoke-DownloadWithRetry`)
   - Extract ZIP to `<dev-dir>\llama-cpp\<targetFolderName>`
   - Verify executable exists (`llama-cli.exe` or `koboldcpp.exe`)
   - Add bin subfolder to user PATH
2. Refresh PATH for current session

### Models
1. **aria2c setup** -- Ensures aria2c is installed (via `choco install aria2`); falls back to `Invoke-DownloadWithRetry` if unavailable
2. **Models directory** -- Prompt user for custom path or use default (`<dev-dir>\llama-models`)
   - User presses Enter (Y) = default path
   - User types a path = custom directory
   - Skipped under orchestrator (`$env:SCRIPTS_ROOT_RUN = "1"`) -- uses default
3. **Catalog summary** -- Displays total models, default count, total size, categories
4. For each model in `config.modelItems` (30+ models):
   - Check `.installed/model-<slug>.json` tracking AND file on disk
   - If tracked but file missing: remove stale tracking, re-download
   - Display model info (category, params, quant, context length, [DEFAULT] tag)
   - Download via `Invoke-Aria2Download` (16 connections, auto-fallback)
   - On success: save `.installed/model-<slug>.json` tracking record
5. **Summary** -- Shows downloaded/skipped/failed counts

## aria2c Download Accelerator

aria2c provides multi-connection parallel downloads for large model files:

| Setting | Default | Description |
|---------|---------|-------------|
| `maxConnections` | 16 | Connections per server |
| `maxDownloads` | 16 | Parallel download segments |
| `chunkSize` | `1M` | Download chunk size |
| `continueDownload` | `true` | Resume partial downloads |

**Fallback chain:** aria2c -> Invoke-DownloadWithRetry (3 retries, exponential backoff)

**Installation:** `choco install aria2 -y` (automatic, requires Chocolatey)

## Model Catalog

### Categories
| Category | Description | Models |
|----------|-------------|--------|
| `fast-router` | Tiny models for routing/classification | 4 |
| `coding` | Code generation and completion | 5 |
| `reasoning` | Chain-of-thought and deep analysis | 6 |
| `writing` | Creative writing and content gen | 4 |
| `fs-tools` | Filesystem/tool orchestration | 2 |
| `voice` | Speech-to-text (Whisper variants) | 10 |

### Default Models (6)
| Role | Model | Params | Size |
|------|-------|--------|------|
| General | Llama-3.2-1B-Instruct | 1B | 761 MB |
| Thinking | TinyLlama-1.1B-Chat | 1.1B | 669 MB |
| Coding | Nemotron-Orchestrator-8B | 8B | 5.0 GB |
| Writing | Phi-3-mini-4k-instruct | 3.8B | 2.4 GB |
| Voice | Whisper-Tiny | 39M | 75 MB |
| Files | Qwen2.5-1.5B-Instruct | 1.5B | 1.0 GB |

### Installed Tracking

Each downloaded model is tracked in `.installed/model-<slug>.json`:
- Checked on subsequent runs to skip re-downloads
- Stale records (file missing on disk) are auto-cleaned and re-downloaded
- Removed on `uninstall` command

## Integrity Checks

ZIP files are validated before skipping re-download:

1. **Magic bytes** -- first 4 bytes must be `PK\x03\x04` (ZIP header)
2. **Size check** -- file size must be within 10% of `expectedSizeBytes` from config
3. **Corrupt recovery** -- invalid ZIPs are deleted and re-downloaded automatically

## Orchestrator Integration

When `$env:SCRIPTS_ROOT_RUN = "1"` (running under Script 12):

- Models directory prompt uses default (no `Read-Host`)

## Default Install Directory
```
<dev-dir>\llama-cpp\
  llama-b7709-cuda-12.4-x64\bin\     # CUDA 12.4 b7709
  llama-b6869-cuda-12.4-x64\bin\     # CUDA 12.x b6869
  cudart-llama-b6869-cuda-12.4-x64\  # CUDA + bundled runtime
  llama-avx2-x64\bin\                # AVX2 CPU fallback
  koboldcpp-cuda\                    # KoboldCPP CUDA (single EXE)
  koboldcpp-cpu\                     # KoboldCPP CPU (single EXE)

<dev-dir>\llama-models\              # All GGUF/GGML model files
```

## Commands

| Command       | Description                                          |
|---------------|------------------------------------------------------|
| `all`         | Download executables + all models (default)           |
| `executables` | Download and extract executables only                 |
| `models`      | Download all models from catalog via aria2c           |
| `uninstall`   | Remove binaries, models tracking, clean PATH          |

## Executable Variants

| Slug | Display Name | Type | Source |
|------|-------------|------|--------|
| `llama-b7709-cuda` | llama.cpp CUDA 12.4 b7709 | ZIP | GitHub ggml-org |
| `llama-b6869-cuda` | llama.cpp CUDA 12.x b6869 | ZIP | GitHub ggml-org |
| `llama-cudart-b6869` | CUDA 12.4 + bundled runtime | ZIP | GitHub ggml-org |
| `llama-avx2-cpu` | AVX2 CPU fallback | ZIP | GitHub ggml-org |
| `koboldcpp-cuda` | KoboldCPP CUDA (single EXE) | EXE | GitHub LostRuins |
| `koboldcpp-cpu` | KoboldCPP CPU (single EXE) | EXE | GitHub LostRuins |

## Install Keywords

| Keyword       | Scripts |
|---------------|---------|
| `llama-cpp`   | 43      |
| `llamacpp`    | 43      |
| `llama`       | 43      |
| `llama.cpp`   | 43      |
| `koboldcpp`   | 43      |
| `gguf`        | 43      |
| `ai-tools`    | 42, 43  |
| `local-ai`    | 42, 43  |
| `ai-full`     | 5, 41, 42, 43 |

## Usage
```powershell
.\run.ps1 -I 43                    # Full install (executables + models)
.\run.ps1 install llama-cpp        # Via keyword
.\run.ps1 install llama            # Short keyword
.\run.ps1 -I 43 -- executables    # Executables only
.\run.ps1 -I 43 -- models         # Models only
.\run.ps1 -I 43 -- uninstall      # Remove everything
.\run.ps1 install ai-tools         # Install both Ollama (42) + llama.cpp (43)
.\run.ps1 install ai-full          # Python + libs + Ollama + llama.cpp
```

## PATH Entries Added
Each executable variant's bin subfolder is added to user PATH:
- `<dev-dir>\llama-cpp\llama-b7709-cuda-12.4-x64\bin`
- `<dev-dir>\llama-cpp\llama-avx2-x64\bin`
- `<dev-dir>\llama-cpp\koboldcpp-cuda`
- etc.

After install, `llama-cli`, `llama-server`, `koboldcpp` are available from any terminal.

## Dependencies

- Shared: `logging.ps1`, `resolved.ps1`, `git-pull.ps1`, `help.ps1`,
  `path-utils.ps1`, `dev-dir.ps1`, `installed.ps1`, `download-retry.ps1`,
  `disk-space.ps1`, `url-freshness.ps1`, `aria2c-download.ps1`, `choco-utils.ps1`
- Optional: aria2c (auto-installed via Chocolatey; falls back to Invoke-WebRequest)
- Requires: Administrator privileges, internet access

## Resolved State
```json
{
  "baseDir": "E:\\dev\\llama-cpp",
  "installedSlugs": ["llama-b7709-cuda", "llama-avx2-cpu", ...],
  "timestamp": "2026-04-15T..."
}
```
