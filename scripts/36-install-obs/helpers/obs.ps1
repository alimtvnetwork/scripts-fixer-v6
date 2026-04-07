# --------------------------------------------------------------------------
#  Helper: Install OBS Studio via Chocolatey and sync settings
#  Supports 3 modes: install+settings (default), settings-only, install-only
# --------------------------------------------------------------------------

function Install-OBS {
    param(
        [Parameter(Mandatory)] $ObsConfig,
        [Parameter(Mandatory)] $LogMessages,
        [ValidateSet("install+settings", "settings-only", "install-only")]
        [string]$Mode = "install+settings"
    )

    $msgs = $LogMessages.messages

    # -- Mode announcement ---------------------------------------------
    $modeLabel = switch ($Mode) {
        "install+settings" { "OBS + Settings (install OBS Studio and sync settings)" }
        "settings-only"    { "OBS Settings (sync settings only)" }
        "install-only"     { "Install OBS (install OBS Studio only)" }
    }
    Write-Log "Mode: $modeLabel" -Level "info"
    Write-Host ""

    # -- Settings-only mode: skip install, go straight to sync ---------
    if ($Mode -eq "settings-only") {
        Write-Log "Skipping OBS Studio installation (settings-only mode)" -Level "info"
        $syncResult = Sync-OBSSettings -LogMessages $LogMessages
        return $syncResult
    }

    # -- Check if already installed ------------------------------------
    $obsPath = $null
    $commonPaths = @(
        "$env:ProgramFiles\obs-studio\bin\64bit\obs64.exe",
        "${env:ProgramFiles(x86)}\obs-studio\bin\64bit\obs64.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            $obsPath = Get-Item $p
            break
        }
    }

    # Fallback: check Get-Command
    if (-not $obsPath) {
        $obsCmd = Get-Command "obs64" -ErrorAction SilentlyContinue
        if ($obsCmd) {
            $obsPath = Get-Item $obsCmd.Source
        }
    }

    if ($obsPath) {
        $version = "unknown"
        try {
            $exePath = if ($obsPath -is [System.Management.Automation.ApplicationInfo]) { $obsPath.Source } else { $obsPath.FullName }
            $version = (Get-Item $exePath).VersionInfo.ProductVersion
        } catch { }

        $isAlreadyInstalled = Test-AlreadyInstalled -Name "obs" -CurrentVersion $version
        if ($isAlreadyInstalled) {
            Write-Log ($msgs.alreadyInstalled -replace '\{version\}', $version) -Level "success"
            # Settings always sync (user may want to restore/fix)
            if ($Mode -eq "install+settings") {
                Sync-OBSSettings -LogMessages $LogMessages
            }
            return $true
        }
    }

    # -- Install via Chocolatey ----------------------------------------
    Write-Log $msgs.notFound -Level "info"
    Write-Host ""
    Write-Log $msgs.installing -Level "info"

    try {
        choco install $ObsConfig.chocoPackage -y --no-progress | Out-Null
    } catch {
        Write-FileError -FilePath "$env:ProgramFiles\obs-studio\bin\64bit\obs64.exe" -Operation "install" -Reason "$_" -Module "Install-OBS"
        Write-Log ($msgs.installFailed -replace '\{error\}', $_) -Level "error"
        Save-InstalledError -Name "obs" -ErrorMessage "$_"
        return $false
    }

    # -- Verify installation -------------------------------------------
    $verifyPaths = @(
        "$env:ProgramFiles\obs-studio\bin\64bit\obs64.exe",
        "${env:ProgramFiles(x86)}\obs-studio\bin\64bit\obs64.exe"
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
        Write-FileError -FilePath $checkedPaths -Operation "resolve" -Reason "obs64.exe not found after Chocolatey install -- checked: $checkedPaths" -Module "Install-OBS"
        Write-Log ($msgs.installFailed -replace '\{error\}', "obs64.exe not found after install") -Level "error"
        return $false
    }

    $version = (Get-Item $installedPath).VersionInfo.ProductVersion
    Write-Log ($msgs.installSuccess) -Level "success"
    Write-Log ("Install target: $installedPath") -Level "success"
    Write-Host ""
    Save-InstalledRecord -Name "obs" -Version $version -Method "chocolatey"

    # -- Sync settings (only in install+settings mode) -----------------
    if ($Mode -eq "install+settings") {
        Sync-OBSSettings -LogMessages $LogMessages
    } else {
        Write-Log "Settings sync skipped (install-only mode)" -Level "info"
    }

    return $true
}

function Sync-OBSSettings {
    param(
        [Parameter(Mandatory)] $LogMessages
    )

    $msgs = $LogMessages.messages
    $scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.ScriptName)
    $settingsSource = Join-Path $scriptDir "settings"
    $zipFile = Join-Path $settingsSource "obs-settings.zip"

    # -- Target: %APPDATA%\obs-studio ----------------------------------
    $appDataDir = Join-Path $env:APPDATA "obs-studio"
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
            Write-FileError -FilePath $zipFile -Operation "extract" -Reason "Failed to extract OBS settings zip to '$appDataDir': $_" -Module "Sync-OBSSettings"
            Write-Log "Failed to extract settings zip: $_" -Level "error"
            return $false
        }
    }

    # -- Fallback: loose files in settings/ ----------------------------
    if (-not (Test-Path $settingsSource)) {
        Write-FileError -FilePath $settingsSource -Operation "read" -Reason "Settings source directory does not exist" -Module "Sync-OBSSettings"
        Write-Log $msgs.settingsSkipped -Level "info"
        return $false
    }

    $settingsFiles = Get-ChildItem -Path $settingsSource -File -Exclude "*.zip" -ErrorAction SilentlyContinue
    if ($settingsFiles.Count -eq 0) {
        Write-FileError -FilePath $settingsSource -Operation "read" -Reason "No settings files found in source directory (excluding .zip)" -Module "Sync-OBSSettings"
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
