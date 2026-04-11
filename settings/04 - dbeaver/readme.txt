DBeaver Settings
================

Place your DBeaver configuration files here.

Script 32 (install-dbeaver) handles sync automatically:
1. Finds %APPDATA%\DBeaverData\workspace6\General\.dbeaver\
2. Copies all config files (data-sources.json, etc.) to that directory
3. Copies any subdirectories (drivers, templates) alongside them

Common files to include:
- data-sources.json     -- Connection profiles (exported from DBeaver)
- credentials-config.json -- Encrypted credential store

To export your current DBeaver settings to this folder:
  .\run.ps1 -I 32 -- export

This copies all .json config files and subdirectories from
%APPDATA%\DBeaverData\workspace6\General\.dbeaver\ into this folder.
Files larger than 512 KB are skipped (likely cache, not config).

Usage:
  .\run.ps1 install dbeaver            # Install DBeaver + sync settings
  .\run.ps1 install dbeaver-settings   # Sync settings only
  .\run.ps1 install install-dbeaver    # Install DBeaver only (no settings)
  .\run.ps1 -I 32 -- export           # Export settings from machine to repo
