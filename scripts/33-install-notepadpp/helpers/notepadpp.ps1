# --------------------------------------------------------------------------
#  Helper: Install Notepad++ via Chocolatey and sync settings
#  Supports 3 modes: install+settings (default), settings-only, install-only
# --------------------------------------------------------------------------

function Install-NotepadPP {
    param(
        [Parameter(Mandatory)] $NppConfig,
        [Parameter(Mandatory)] $LogMessages,
        [ValidateSet("install+settings", "settings-only", "install-only")]
        [string]$Mode = "install+settings"
    )

    $msgs = $LogMessages.messages

    # -- Mode announcement ---------------------------------------------
    $modeLabel = switch ($Mode) {
        "install+settings" { "NPP + Settings (install Notepad++ and sync settings)" }
        "settings-only"    { "NPP Settings (sync settings only)" }
        "install-only"     { "Install NPP (install Notepad++ only)" }
    }
    Write-Log "Mode: $modeLabel" -Level "info"
    Write-Host ""

    # -- Settings-only mode: skip install, go straight to sync ---------
    if ($Mode -eq "settings-only") {
        Write-Log "Skipping Notepad++ installation (settings-only mode)" -Level "info"
        $syncResult = Sync-NotepadPPSettings -LogMessages $LogMessages
        return $syncResult
    }

    # -- Check if already installed ------------------------------------
    $nppPath = Get-Command "notepad++" -ErrorAction SilentlyContinue
    if (-not $nppPath) {
        $commonPaths = @(
            "$env:ProgramFiles\Notepad++\notepad++.exe",
            "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
        )
        foreach ($p in $commonPaths) {
            if (Test-Path $p) {
                $nppPath = Get-Item $p
                break
            }
        }
    }

    if ($nppPath) {
        $version = "unknown"
        try {
            $exePath = if ($nppPath -is [System.Management.Automation.ApplicationInfo]) { $nppPath.Source } else { $nppPath.FullName }
            $version = (Get-Item $exePath).VersionInfo.ProductVersion
        } catch { }

        $isAlreadyInstalled = Test-AlreadyInstalled -Name "notepadpp" -CurrentVersion $version
        if ($isAlreadyInstalled) {
            Write-Log ($msgs.alreadyInstalled -replace '\{version\}', $version) -Level "success"
            if ($Mode -eq "install+settings") {
                Sync-NotepadPPSettings -LogMessages $LogMessages
            }
            return $true
        }
    }

    # -- Install via Chocolatey ----------------------------------------
    Write-Log $msgs.notFound -Level "info"
    Write-Host ""
    Write-Log $msgs.installing -Level "info"

    try {
        choco install $NppConfig.chocoPackage -y --no-progress | Out-Null
    } catch {
        Write-Log ($msgs.installFailed -replace '\{error\}', $_) -Level "error"
        Save-InstalledError -Name "notepadpp" -ErrorMessage "$_"
        return $false
    }

    # -- Verify installation -------------------------------------------
    $verifyPaths = @(
        "$env:ProgramFiles\Notepad++\notepad++.exe",
        "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe"
    )
    $installedPath = $null
    foreach ($p in $verifyPaths) {
        if (Test-Path $p) {
            $installedPath = $p
            break
        }
    }

    if (-not $installedPath) {
        $checkedPaths = $verifyPaths -join ", "
        Write-FileError -FilePath $checkedPaths -Operation "resolve" -Reason "notepad++.exe not found after Chocolatey install -- checked: $checkedPaths" -Module "Install-NotepadPP"
        Write-Log ($msgs.installFailed -replace '\{error\}', "notepad++.exe not found after install") -Level "error"
        return $false
    }

    $version = (Get-Item $installedPath).VersionInfo.ProductVersion
    Write-Log ($msgs.installSuccess) -Level "success"
    Write-Log ("Install target: $installedPath") -Level "success"
    Write-Host ""
    Save-InstalledRecord -Name "notepadpp" -Version $version -Method "chocolatey"

    # -- Sync settings (only in install+settings mode) -----------------
    if ($Mode -eq "install+settings") {
        Sync-NotepadPPSettings -LogMessages $LogMessages
    } else {
        Write-Log "Settings sync skipped (install-only mode)" -Level "info"
    }

    return $true
}

function Sync-NotepadPPSettings {
    param(
        [Parameter(Mandatory)] $LogMessages
    )

    $msgs = $LogMessages.messages
    $scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.ScriptName)
    $settingsSource = Join-Path $scriptDir "settings"
    $zipFile = Join-Path $settingsSource "notepadpp-settings.zip"

    # -- Target: %APPDATA%\Notepad++ -----------------------------------
    $appDataDir = Join-Path $env:APPDATA "Notepad++"
    Write-Log "Settings target: $appDataDir" -Level "info"

    # -- Check for zip -------------------------------------------------
    if (Test-Path $zipFile) {
        Write-Log $msgs.syncingSettings -Level "info"

        if (-not (Test-Path $appDataDir)) {
            New-Item -Path $appDataDir -ItemType Directory -Force | Out-Null
        }

        try {
            Expand-Archive -Path $zipFile -DestinationPath $appDataDir -Force
            Write-Log ($msgs.settingsSynced -replace '\{path\}', $appDataDir) -Level "success"
            return $true
        } catch {
            Write-FileError -FilePath $zipFile -Operation "extract" -Reason "Failed to extract settings zip to '$appDataDir': $_" -Module "Sync-NotepadPPSettings"
            Write-Log "Failed to extract settings zip: $_" -Level "error"
            return $false
        }
    }

    # -- Fallback: loose files in settings/ ----------------------------
    if (-not (Test-Path $settingsSource)) {
        Write-FileError -FilePath $settingsSource -Operation "read" -Reason "Settings source directory does not exist" -Module "Sync-NotepadPPSettings"
        Write-Log $msgs.settingsSkipped -Level "info"
        return $false
    }

    $settingsFiles = Get-ChildItem -Path $settingsSource -File -Exclude "*.zip" -ErrorAction SilentlyContinue
    if ($settingsFiles.Count -eq 0) {
        Write-FileError -FilePath $settingsSource -Operation "read" -Reason "No settings files found in source directory (excluding .zip)" -Module "Sync-NotepadPPSettings"
        Write-Log $msgs.settingsSkipped -Level "info"
        return $false
    }

    if (-not (Test-Path $appDataDir)) {
        New-Item -Path $appDataDir -ItemType Directory -Force | Out-Null
    }

    Write-Log $msgs.syncingSettings -Level "info"

    foreach ($file in $settingsFiles) {
        $dest = Join-Path $appDataDir $file.Name
        Copy-Item -Path $file.FullName -Destination $dest -Force
    }

    Write-Log ($msgs.settingsSynced -replace '\{path\}', $appDataDir) -Level "success"
    return $true
}
