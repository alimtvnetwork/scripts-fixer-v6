---
name: CHANGELOG missing speed filter entry
description: Speed filter was added after v0.26.0 version bump, so CHANGELOG is incomplete
priority: medium
discovered: 2026-04-16
---

# CHANGELOG Missing Speed Filter Entry

## Issue
The `Read-SpeedFilter` function and the 4-filter chain update were implemented
AFTER the v0.26.0 version bump and CHANGELOG entry were written. The CHANGELOG
only documents the 3-filter chain (RAM, Size, Capability) but the actual code
now has 4 filters (RAM, Size, Speed, Capability).

## Impact
- CHANGELOG does not fully reflect what shipped in v0.26.0
- Spec `spec/model-picker/readme.md` also still documents 3-filter chain

## Fix Required
1. Update CHANGELOG v0.26.0 entry to mention speed filter and 4-filter chain
2. Update `spec/model-picker/readme.md` to add Speed filter step between Size and Capability
3. Consider bumping to v0.26.1 if treating as a separate minor addition
