---
name: Notepad++ settings sync
description: After installing Notepad++, replace all settings in %APPDATA%\Notepad++ with files from scripts/33-install-notepadpp/settings/
type: feature
---
After Notepad++ is installed, copy ALL files from `scripts/33-install-notepadpp/settings/` 
to `%APPDATA%\Notepad++\`, overwriting everything. This is a full replace, not a merge.

User will provide the settings files to place in the `settings/` subfolder.
