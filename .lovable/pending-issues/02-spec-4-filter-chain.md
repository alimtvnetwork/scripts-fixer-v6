---
name: Model picker spec outdated (3 vs 4 filters)
description: spec/model-picker/readme.md documents 3-filter chain but code has 4 filters
priority: medium
discovered: 2026-04-16
---

# Model Picker Spec -- 3 vs 4 Filter Chain

## Issue
`spec/model-picker/readme.md` was updated to document the 3-filter chain
(RAM -> Size -> Capability). After that update, the Speed filter was added
as a 4th step between Size and Capability.

## Current State
- Code: RAM -> Size -> Speed -> Capability (4 filters)
- Spec: RAM -> Size -> Capability (3 filters, missing Speed)

## Fix Required
1. Add Speed filter section to spec/model-picker/readme.md
2. Update flow diagram step numbers (currently steps 4-10, need to insert step 6.5)
3. Update Orchestrator Mode table to show Speed filter is also skipped
