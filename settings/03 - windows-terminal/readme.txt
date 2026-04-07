Windows Terminal Settings
========================

Place your settings.json file here.

Script 37 (install-windows-terminal) handles sync automatically:
1. Finds %LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\
2. Copies settings.json to that directory
3. Copies any additional files (themes, fragments) alongside it

Windows Terminal reads settings.json from LocalState on startup.

Usage:
  .\run.ps1 install wt              # Install WT + sync settings
  .\run.ps1 install wt-settings     # Sync settings only
