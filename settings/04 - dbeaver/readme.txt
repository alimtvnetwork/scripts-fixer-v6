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

To export your current DBeaver connections:
  DBeaver > File > Export > DBeaver Project
  Or manually copy files from %APPDATA%\DBeaverData\workspace6\General\.dbeaver\

Usage:
  .\run.ps1 install dbeaver            # Install DBeaver + sync settings
  .\run.ps1 install dbeaver-settings   # Sync settings only
  .\run.ps1 install install-dbeaver    # Install DBeaver only (no settings)
