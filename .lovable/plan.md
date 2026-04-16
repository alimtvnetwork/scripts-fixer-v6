# Project Plan -- Dev Tools Setup

## Current Version: v0.26.0
## Last Updated: 2026-04-16

---

## Completed Milestones

### v0.16.x Cycle (Done)
- [x] Audit Check 12 (export coverage) + root export command
- [x] Status command + defensive version guards
- [x] Python libraries script 41 + VSCode export
- [x] Doctor command + Assert-ToolVersion

### v0.17.x - v0.22.x Cycle (Done)
- [x] Flutter (38), .NET SDK (39), Java/OpenJDK (40) scripts
- [x] Windows Terminal (37), PowerShell Context Menu (31)
- [x] Help display alignment fixes
- [x] Settings export system (NPP, OBS, WT, DBeaver)
- [x] Installed tool version detection in help display
- [x] Combo shortcuts (backend, full-stack, data-dev, mobile-dev)

### v0.23.x Cycle (Done)
- [x] Script 42 -- Install Ollama (download, silent install, model pulling)
- [x] Script 43 -- Install llama.cpp (CUDA/AVX2 variants, ZIP extraction, PATH)
- [x] AI install keywords (ollama, llama-cpp, ai-tools, local-ai, ai-full)
- [x] 69-model GGUF catalog with interactive model picker
- [x] aria2c accelerated downloads with fallback
- [x] .installed/ tracking for models
- [x] Capability filter (coding, reasoning, writing, chat, voice, multilingual)

### v0.26.0 (Done -- Current)
- [x] Expanded catalog from 69 to 81 models (12 new small/fast models)
- [x] RAM filter (auto-detect system RAM or manual tier selection)
- [x] Download size filter (Tiny/Small/Medium/Large/XLarge tiers)
- [x] Speed tier column in catalog display (instant/fast/moderate/slow)
- [x] Speed filter (4-tier with multi-select support)
- [x] 4-filter chain: RAM -> Size -> Speed -> Capability
- [x] CUDA + AVX2 hardware detection for executable variants
- [x] Updated specs: model-picker, script 43

---

## Pending / Next Steps

### Documentation & Quality
- [ ] Update CHANGELOG v0.26.0 entry to include speed filter (added after version bump)
- [ ] Verify 4-filter chain re-indexing works correctly end-to-end
- [ ] Verify catalog column alignment with Speed column across all 81 models

### Future Features (Not Started)
- [ ] GUI/TUI for the interactive menu
- [ ] Cross-machine settings sync via cloud storage
- [ ] Linux/macOS support
- [ ] New tool scripts (Docker, Rust)
- [ ] Model catalog auto-update from Hugging Face trending
- [ ] Parallel model downloads (aria2c batch mode)
- [ ] Model integrity verification (SHA256 checksums in catalog)

---

## Architecture Notes

- 43 PowerShell scripts in `scripts/` folder
- Shared helpers in `scripts/shared/` (logging, path-utils, choco-utils, etc.)
- External JSON configs per script (config.json, log-messages.json)
- `.installed/` tracking for idempotent installs
- `.resolved/` for runtime state persistence
- `settings/` folder for app config sync (NPP, OBS, WT, DBeaver)
- Spec docs in `spec/` folder per script
