---
name: Current workflow status
description: What is done and what is pending as of v0.26.0
type: feature
---

# Workflow Status -- v0.26.0 (2026-04-16)

## Done This Session

| Task | Status | Details |
|------|--------|---------|
| Add 12 new small/fast models to catalog | Done | Gemma 3, Llama 3.2, SmolLM2, Phi-4, Granite 3.1, Qwen3 1.7B, Functionary |
| Add download size filter | Done | Read-SizeFilter with 5 tiers in model-picker.ps1 |
| Add speed tier column | Done | instant/fast/moderate/slow based on fileSizeGB |
| Add speed-based filter | Done | Read-SpeedFilter with multi-select, added to 4-filter chain |
| RAM filter with auto-detect | Done | Read-RamFilter using WMI Get-CimInstance |
| CUDA/AVX2 hardware detection | Done | Get-HardwareProfile in hardware-detect.ps1 |
| Update spec/model-picker/readme.md | Done | Full 3-filter chain, new model table, speed tier |
| Update spec/43-install-llama-cpp/readme.md | Done | RAM/Size/Capability filter steps, 81-model count |
| Bump version to v0.26.0 | Done | version.json + CHANGELOG.md entry |

## Pending

| Task | Priority | Notes |
|------|----------|-------|
| Update CHANGELOG for speed filter | Medium | Speed filter added after v0.26.0 bump |
| Verify 4-filter re-indexing | Medium | Test RAM -> Size -> Speed -> Capability chain |
| Verify column alignment | Low | Speed column may shift alignment on long names |
| Update model-picker spec for speed filter | Medium | Spec currently shows 3-filter, now has 4 |

## Filter Chain Architecture

```
Read-RamFilter → Read-SizeFilter → Read-SpeedFilter → Read-CapabilityFilter → Show-ModelCatalog
```

Each filter: prompt user → filter array → re-index 1..N → return. All optional (Enter to skip).
