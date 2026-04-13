# Script 43 -- Install llama.cpp

## Purpose
Downloads llama.cpp pre-built binaries (CUDA, AVX2 CPU, KoboldCPP), extracts them to the dev directory, adds binary folders to user PATH, and optionally downloads GGUF models from Hugging Face.

## Directory Structure
```
scripts/43-install-llama-cpp/
  config.json           # Executable variants, model definitions, paths
  log-messages.json     # All log message templates
  run.ps1               # Entry point (param: Command, Path, -Help)
  helpers/
    llama-cpp.ps1       # Install-LlamaCppExecutables, Install-LlamaCppModels, Uninstall-LlamaCpp
```

## Install Flow

### Executables
1. For each variant in `config.executables`:
   - Check if already downloaded (skip if present)
   - Download from GitHub releases via `Invoke-WebRequest`
   - Extract ZIP to `<dev-dir>\llama-cpp\<targetFolderName>`
   - Verify executable exists (`llama-cli.exe` or `koboldcpp.exe`)
   - Add bin subfolder to user PATH
2. Refresh PATH for current session

### Models
1. Prompt user for models directory (default: `<dev-dir>\llama-models`)
2. For each model in `config.models`:
   - Skip if GGUF file already exists
   - Download from Hugging Face

## Default Install Directory
```
<dev-dir>\llama-cpp\
  llama-b7709-cuda-12.4-x64\bin\     # CUDA 12.4 b7709
  llama-b6869-cuda-12.4-x64\bin\     # CUDA 12.x b6869
  cudart-llama-b6869-cuda-12.4-x64\  # CUDA + bundled runtime
  llama-avx2-x64\bin\                # AVX2 CPU fallback
  koboldcpp-cuda\                    # KoboldCPP CUDA (single EXE)
  koboldcpp-cpu\                     # KoboldCPP CPU (single EXE)
```

## Commands

| Command       | Description                                          |
|---------------|------------------------------------------------------|
| `all`         | Download executables + models (default)              |
| `executables` | Download and extract executables only                 |
| `models`      | Download GGUF models only                             |
| `uninstall`   | Remove binaries, clean PATH, purge tracking           |

## Executable Variants

| Slug | Display Name | Type | Source |
|------|-------------|------|--------|
| `llama-b7709-cuda` | llama.cpp CUDA 12.4 b7709 | ZIP | GitHub ggml-org |
| `llama-b6869-cuda` | llama.cpp CUDA 12.x b6869 | ZIP | GitHub ggml-org |
| `llama-cudart-b6869` | CUDA 12.4 + bundled runtime | ZIP | GitHub ggml-org |
| `llama-avx2-cpu` | AVX2 CPU fallback | ZIP | GitHub ggml-org |
| `koboldcpp-cuda` | KoboldCPP CUDA (single EXE) | EXE | GitHub LostRuins |
| `koboldcpp-cpu` | KoboldCPP CPU (single EXE) | EXE | GitHub LostRuins |

## GGUF Models

| Model | Parameters | Quantization | Purpose | Size |
|-------|-----------|-------------|---------|------|
| Qwen2.5 Coder 7B | 7B | Q5_K_M | Coding | ~5 GB |
| Qwen2.5 Coder 14B | 14B | Q4_K_M | Coding | ~8.9 GB |
| Qwen2.5 14B | 14B | Q4_K_M | General | ~8.9 GB |
| DeepSeek R1 8B | 8B | Q5_K_M | Reasoning | ~5.6 GB |
| DeepSeek R1 70B | 70B | Q4_K_M | Reasoning | ~40 GB |

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

## Resolved State
Saved to `.resolved/43-install-llama-cpp.json`:
- `baseDir` -- Base installation directory
- `installedSlugs` -- Array of installed variant slugs
- `timestamp` -- ISO 8601 timestamp
