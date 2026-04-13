# Reliability Report: Scripts 42 (Ollama) & 43 (llama.cpp)

**Date:** 2026-04-13
**Version:** v0.23.0
**Status:** Initial assessment -- pre-deployment

---

## Executive Summary

Both scripts follow the established project patterns (JSON config, structured
logging, installed tracking, resolved state, uninstall support). The primary
risk areas are **large file downloads over unreliable networks** and
**hardcoded GitHub/HuggingFace URLs that may break on new releases**.

| Category | Script 42 (Ollama) | Script 43 (llama.cpp) |
|----------|--------------------|-----------------------|
| Overall Risk | Medium | Medium-High |
| Error Handling | Good | Good |
| Network Resilience | Low | Low |
| Idempotency | Good | Good |
| Uninstall Safety | Good | Good |

---

## Script 42: Install Ollama

### Strengths

| # | Item |
|---|------|
| 1 | Silent installer with exit-code checking (`/VERYSILENT /NORESTART`) |
| 2 | Already-installed detection via `Get-Command ollama` before downloading |
| 3 | Version tracking through `.installed/ollama.json` |
| 4 | Resolved state saved with timestamp for audit trail |
| 5 | Uninstaller searches two known paths (`LOCALAPPDATA`, `Program Files`) |
| 6 | `OLLAMA_MODELS` env var set at User scope (survives reboots) |
| 7 | PATH refresh after install for immediate CLI availability |
| 8 | Prompt for custom models directory with sensible default |
| 9 | Model pull is per-model opt-in (user confirms each) |
| 10 | Full try/catch with `Save-InstalledError` on failure |

### Issues Found

| # | Severity | Issue | Impact | Recommendation |
|---|----------|-------|--------|----------------|
| 1 | **HIGH** | No download retry on network failure | Single `Invoke-WebRequest` call; transient DNS/timeout failures abort install | Add retry loop (3 attempts with exponential backoff) |
| 2 | **HIGH** | No file integrity check after download | Corrupted/partial OllamaSetup.exe runs silently, may produce cryptic installer errors | Add file-size validation or SHA256 checksum to config.json |
| 3 | **MEDIUM** | Hardcoded download URL in config.json | `https://ollama.com/download/OllamaSetup.exe` may change paths on major releases | Consider fetching latest URL from ollama.com API or version-pinned releases |
| 4 | **MEDIUM** | `ollama pull` has no timeout | Large models (4-5 GB) can hang indefinitely on slow connections | Wrap with `Invoke-WithTimeout` or document expected duration |
| 5 | **MEDIUM** | No disk space check before model pull | Models total ~11.6 GB; user may run out of space mid-pull | Check free space on target drive before starting pulls |
| 6 | **LOW** | Version parse assumes `ollama --version` returns digits | If Ollama changes output format, version tracking stores garbage | Already handled with regex fallback in run.ps1 version map |
| 7 | **LOW** | Temp directory cleanup not performed | Downloaded `OllamaSetup.exe` stays in dev dir after install | Add cleanup step or document as intentional cache |
| 8 | **LOW** | `Configure-OllamaModels` prompts even under Script 12 orchestrator | When `$env:SCRIPTS_ROOT_RUN = "1"`, model dir prompt should use default | Check `$env:SCRIPTS_ROOT_RUN` and skip `Read-Host` |
| 9 | **LOW** | `Pull-OllamaModels` prompts per model under Script 12 | Same issue -- each model asks yes/no during unattended orchestration | Auto-accept when `$env:SCRIPTS_ROOT_RUN` is set |

### Edge Cases

| Scenario | Current Behaviour | Risk |
|----------|-------------------|------|
| Ollama installed by MSI (not InnoSetup) | Uninstaller paths won't match | Uninstall silently fails, reports error |
| Ollama installed via `winget` | `Get-Command ollama` finds it, skips install | Correct -- no conflict |
| User has custom OLLAMA_MODELS already set | Overwrites with new path | Should warn and confirm before overwriting |
| No internet connectivity | Download fails, `Save-InstalledError` fires | Correct -- but no retry |
| Antivirus blocks OllamaSetup.exe | Installer fails with access denied | Exit code check catches it; error message may be unclear |
| Disk full during model pull | `ollama pull` fails with OS error | Caught by try/catch, but error message from Ollama CLI may be opaque |

---

## Script 43: Install llama.cpp

### Strengths

| # | Item |
|---|------|
| 1 | Config-driven executable list (add/remove variants without code changes) |
| 2 | Per-executable skip logic (checks file size + extracted bin folder) |
| 3 | ZIP extraction with nested-folder fallback search (`Get-ChildItem -Recurse`) |
| 4 | Each executable tracked individually (`llama-cpp-{slug}`) |
| 5 | `Write-FileError` called on download/extract failures (CODE RED compliance) |
| 6 | PATH entries added per-binary with dedup check (`Test-InPath`) |
| 7 | Uninstall removes folders, PATH entries, and tracking per executable |
| 8 | Idempotent -- re-running skips already-downloaded files |
| 9 | Session PATH refresh after all executables processed |
| 10 | Models directory prompt with user override |

### Issues Found

| # | Severity | Issue | Impact | Recommendation |
|---|----------|-------|--------|----------------|
| 1 | **HIGH** | No download retry on network failure | 6 executables + 5 models = 11 large downloads; any transient failure skips that item | Add retry loop with backoff per download |
| 2 | **HIGH** | No partial download detection | If download is interrupted, a partial ZIP exists with size > 0; next run skips it as "already downloaded" | Validate ZIP integrity (test `Expand-Archive` header) or store expected file size in config |
| 3 | **HIGH** | Hardcoded release URLs with pinned build numbers | `b7709` and `b6869` URLs will 404 when GitHub releases are cleaned up | Add URL validation step or version-check against GitHub API |
| 4 | **MEDIUM** | No disk space check | Total downloads: ~1.5 GB ZIPs + ~68 GB models; can exhaust disk silently | Check free space before each large download |
| 5 | **MEDIUM** | KoboldCPP EXE placed in folder but no rename | `koboldcpp.exe` and `koboldcpp_nocuda.exe` have different names; both added to PATH | Works but both folders in PATH may cause confusion if user has other koboldcpp installs |
| 6 | **MEDIUM** | Model downloads have no progress indicator | `$ProgressPreference = "SilentlyContinue"` suppresses progress for multi-GB files | Show size estimate and elapsed time, or use a streaming download with progress |
| 7 | **MEDIUM** | Models directory prompt not suppressed under Script 12 | Same as Ollama -- `Read-Host` fires during unattended orchestration | Check `$env:SCRIPTS_ROOT_RUN` |
| 8 | **LOW** | `Get-FileSize` returns -1 for missing files but caller checks `> 0` | Correct logic, but naming implies size not boolean; minor readability concern | Consider `Test-FileExists` wrapper |
| 9 | **LOW** | ZIP extraction uses `-Force` which overwrites silently | Re-extraction overwrites any user modifications in bin folders | Document or add backup step |
| 10 | **LOW** | HuggingFace model URLs may require authentication for gated models | Current models are public, but future additions might be gated | Add auth token support in config |

### Edge Cases

| Scenario | Current Behaviour | Risk |
|----------|-------------------|------|
| GitHub rate-limits unauthenticated downloads | `Invoke-WebRequest` gets 403, caught by try/catch | Download fails for that variant; others continue |
| ZIP contains unexpected folder structure | Nested-folder fallback search finds exe | Correct -- robust handling |
| User PATH exceeds 2048 chars (Windows limit) | `Add-ToUserPath` may truncate or fail silently | PATH corruption risk on systems with many tools |
| AVX2 not supported on CPU | Binary downloaded but crashes on execution | No CPU feature detection; user gets unhelpful error |
| CUDA not installed | CUDA variants downloaded but won't run | No CUDA detection; wastes bandwidth downloading unusable binaries |
| Antivirus quarantines koboldcpp.exe | File disappears after download; next run re-downloads | Infinite download loop possible |
| Network drops mid-ZIP extraction | Partial extraction leaves corrupt files | `-Force` on next run overwrites; self-healing |

---

## Cross-Script Concerns

### 1. Network Resilience (Both Scripts)

**Current state:** Single-attempt `Invoke-WebRequest` with no retry.

**Recommendation:** Create a shared `Invoke-DownloadWithRetry` helper:

```
function Invoke-DownloadWithRetry {
    param(
        [string]$Uri,
        [string]$OutFile,
        [int]$MaxRetries = 3,
        [int]$BaseDelaySec = 5
    )
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
            return $true
        } catch {
            if ($attempt -eq $MaxRetries) { throw }
            $delay = $BaseDelaySec * [math]::Pow(2, $attempt - 1)
            Write-Log "Download attempt $attempt failed, retrying in ${delay}s..." -Level "warn"
            Start-Sleep -Seconds $delay
        }
    }
}
```

### 2. Orchestrator Integration (Both Scripts)

Both scripts use `Read-Host` prompts that will block Script 12 during
unattended execution. The `$env:SCRIPTS_ROOT_RUN` flag should suppress
prompts and use defaults:

- Ollama: model directory prompt + per-model pull confirmation
- llama.cpp: models directory prompt

### 3. Disk Space (Both Scripts)

Combined worst-case download size:

| Component | Size |
|-----------|------|
| OllamaSetup.exe | ~100 MB |
| Ollama models (3x) | ~11.6 GB |
| llama.cpp ZIPs (4x) | ~1.2 GB |
| KoboldCPP EXEs (2x) | ~200 MB |
| GGUF models (5x) | ~68 GB |
| **Total** | **~81 GB** |

Pre-flight disk space check is essential before starting downloads.

### 4. URL Freshness

| Script | URL Type | Staleness Risk |
|--------|----------|----------------|
| 42 | `ollama.com/download/OllamaSetup.exe` | Low (stable URL) |
| 43 | GitHub pinned releases (`b7709`, `b6869`) | **High** (old releases get removed) |
| 43 | GitHub `latest` releases | Low (always resolves) |
| 43 | HuggingFace model URLs | Medium (model repos may be reorganized) |

---

## Recommended Priority Fixes

| Priority | Fix | Effort | Scripts |
|----------|-----|--------|---------|
| P1 | Add download retry with backoff | 2h | Both (shared helper) |
| P1 | Add partial/corrupt file detection | 2h | 43 |
| P2 | Suppress prompts under `$env:SCRIPTS_ROOT_RUN` | 1h | Both |
| P2 | Add disk space pre-check | 1h | Both (shared helper) |
| P2 | Validate pinned GitHub URLs still resolve | 1h | 43 |
| P3 | Add CUDA/AVX2 CPU feature detection | 2h | 43 |
| P3 | Add file integrity (SHA256) verification | 2h | Both |
| P3 | Add download progress indicator for large files | 2h | 43 |

---

## Test Matrix

| Test Case | Script | Expected Result |
|-----------|--------|-----------------|
| Fresh install (no Ollama, no llama.cpp) | Both | Full install, tracking created |
| Re-run after successful install | Both | Skips downloads, "already installed" messages |
| Run without admin rights | Both | Exits with admin-required error |
| Run with `--help` | Both | Shows help, no side effects |
| Run with `-Path C:\custom` | Both | Uses custom dev directory |
| Run under Script 12 (`$env:SCRIPTS_ROOT_RUN=1`) | Both | **FAILS** -- prompts still appear |
| Network disconnect during download | Both | Error logged, script continues (43) or exits (42) |
| Partial ZIP from previous failed download | 43 | **FAILS** -- skips as "already downloaded" |
| Uninstall then reinstall | Both | Clean uninstall, fresh reinstall works |
| Disk full during model download | Both | Error caught, logged, script continues |
| Invalid/changed download URL | Both | Error caught, logged |

---

## Conclusion

Both scripts follow project conventions well and have solid error handling
foundations. The **critical gap** is network resilience -- no retry logic for
large downloads over potentially unreliable connections. The secondary concern
is **orchestrator integration** where interactive prompts will block
unattended Script 12 execution. Addressing P1 and P2 items would bring both
scripts to production-ready reliability.
