OBS Studio Settings Package
==========================

Contains scene collections (.json) and profile folders.

Script 36 (install-obs) handles sync automatically:
1. Extracts the .zip to a temp directory
2. Copies .json files to %APPDATA%\obs-studio\basic\scenes\
3. Copies profile folders to %APPDATA%\obs-studio\basic\profiles\
4. Cleans up temp

OBS discovers scenes and profiles from these directories on startup.

Usage:
  .\run.ps1 install obs            # Install OBS + sync settings
  .\run.ps1 install obs-settings   # Sync settings only
