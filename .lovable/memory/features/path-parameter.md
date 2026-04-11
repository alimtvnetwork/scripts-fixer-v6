---
name: Path parameter for all scripts
description: Every run.ps1 should accept a -Path parameter (Position 1) to override the dev directory
type: feature
---
All scripts should support a `-Path` parameter so users can specify a custom dev directory.
When provided, it overrides smart drive detection and `$env:DEV_DIR`.

Pattern:
```powershell
param(
    [Parameter(Position = 0)]
    [string]$Command = "all",
    [Parameter(Position = 1)]
    [string]$Path,
    [switch]$Help
)
```

Resolution priority becomes: `-Path` param > `$env:DEV_DIR` > smart detection.

Usage: `.\run.ps1 all F:\dev` or `.\run.ps1 -Path E:\dev`

Scripts updated so far: 05-install-python
Scripts remaining: all others that use dev-dir resolution
