# --------------------------------------------------------------------------
#  Helper: Install DBeaver Community via Chocolatey and sync settings
#  Supports 3 modes: install+settings (default), settings-only, install-only
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers --------------------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
}
$_chocoUtilsPath = Join-Path $_sharedDir "choco-utils.ps1"
if ((Test-Path $_chocoUtilsPath) -and -not (Get-Command Install-ChocoPackage -ErrorAction SilentlyContinue)) {
    . $_chocoUtilsPath
}

function Test-DbeaverInstalled {
    # DBeaver doesn't always add to PATH -- check common locations
    $cmd = Get-Command "dbeaver-cli" -ErrorAction SilentlyContinue
    $isInPath = $null -ne $cmd
    if ($isInPath) { return $true }

    # Check default Chocolatey install location
    $defaultPaths = @(
        "$env:ProgramFiles\DBeaver\dbeaver-cli.exe",
        "${env:ProgramFiles(x86)}\DBeaver\dbeaver-cli.exe",
        "$env:LOCALAPPDATA\DBeaver\dbeaver-cli.exe"
    )
    foreach ($p in $defaultPaths) {
        $isPresent = Test-Path $p
        if ($isPresent) { return $true }
    }

    return $false
}

function Save-DbeaverResolvedState {
    Save-ResolvedData -ScriptFolder "32-install-dbeaver" -Data @{
        resolvedAt = (Get-Date -Format "o")
        resolvedBy = $env:USERNAME
    }
}

function Install-Dbeaver {
    <#
    .SYNOPSIS
        Installs DBeaver Community Edition via Chocolatey.
        Supports 3 modes: install+settings, settings-only, install-only.
        Returns $true on success, $false on failure.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$DbConfig,
        [Parameter(Mandatory)]
        $LogMessages,
        [ValidateSet("install+settings", "settings-only", "install-only")]
        [string]$Mode = "install+settings"
    )

    $msgs = $LogMessages.messages

    # -- Mode announcement ---------------------------------------------
    $modeLabel = switch ($Mode) {
        "install+settings" { "DBeaver + Settings (install DBeaver and sync settings)" }
        "settings-only"    { "DBeaver Settings (sync settings only)" }
        "install-only"     { "Install DBeaver (install DBeaver only)" }
    }
    Write-Log "Mode: $modeLabel" -Level "info"
    Write-Host ""

    # -- Settings-only mode: skip install, go straight to sync ---------
    if ($Mode -eq "settings-only") {
        Write-Log "Skipping DBeaver installation (settings-only mode)" -Level "info"
        $syncResult = Sync-DbeaverSettings -LogMessages $LogMessages
        return $syncResult
    }

    $isDisabled = -not $DbConfig.enabled
    if ($isDisabled) {
        Write-Log $msgs.disabled -Level "info"
        return $true
    }

    Write-Log $msgs.checking -Level "info"

    $isDbeaverReady = Test-DbeaverInstalled
    if ($isDbeaverReady) {
        $version = "unknown"
        try {
            $chocoVersion = (choco list --local-only --exact $DbConfig.chocoPackage 2>&1 | Select-String $DbConfig.chocoPackage) -replace ".*$($DbConfig.chocoPackage)\s*", "" | ForEach-Object { $_.Trim() }
            if ($chocoVersion) { $version = $chocoVersion }
        } catch { }

        $isAlreadyTracked = Test-AlreadyInstalled -Name "dbeaver" -CurrentVersion $version
        if ($isAlreadyTracked) {
            Write-Log $msgs.found -Level "success"
            if ($Mode -eq "install+settings") {
                $syncOk = Sync-DbeaverSettings -LogMessages $LogMessages
                return $syncOk
            }
            return $true
        }

        Write-Log $msgs.found -Level "success"
        Save-InstalledRecord -Name "dbeaver" -Version $version
        Save-DbeaverResolvedState

        if ($Mode -eq "install+settings") {
            $syncOk = Sync-DbeaverSettings -LogMessages $LogMessages
            return $syncOk
        }
        return $true
    }

    Write-Log $msgs.notFound -Level "info"
    Write-Log $msgs.installing -Level "info"

    $isInstalled = Install-ChocoPackage -PackageName $DbConfig.chocoPackage
    $hasInstallFailed = -not $isInstalled
    if ($hasInstallFailed) {
        Write-Log ($msgs.installFailed -replace '\{error\}', "Install returned failure") -Level "error"
        Save-InstalledError -Name "dbeaver" -ErrorMessage "Install returned failure"
        return $false
    }

    # Refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    $isDbeaverReady = Test-DbeaverInstalled
    if ($isDbeaverReady) {
        Write-Log $msgs.installSuccess -Level "success"
    } else {
        Write-Log $msgs.notInPath -Level "info"
        # Still mark as success -- DBeaver GUI works even without CLI in PATH
    }

    $version = "unknown"
    try {
        $chocoVersion = (choco list --local-only --exact $DbConfig.chocoPackage 2>&1 | Select-String $DbConfig.chocoPackage) -replace ".*$($DbConfig.chocoPackage)\s*", "" | ForEach-Object { $_.Trim() }
        if ($chocoVersion) { $version = $chocoVersion }
    } catch { }

    Save-InstalledRecord -Name "dbeaver" -Version $version -Method "chocolatey"
    Save-DbeaverResolvedState

    # -- Sync settings (only in install+settings mode) -----------------
    if ($Mode -eq "install+settings") {
        $syncOk = Sync-DbeaverSettings -LogMessages $LogMessages
        return $syncOk
    } else {
        Write-Log "Settings sync skipped (install-only mode)" -Level "info"
    }

    return $true
}

function Sync-DbeaverSettings {
    <#
    .SYNOPSIS
        Syncs DBeaver settings from settings/04 - dbeaver/ to
        %APPDATA%\DBeaverData\workspace6\General\.dbeaver\
        Copies data-sources.json and any other config files.
    #>
    param(
        [Parameter(Mandatory)] $LogMessages
    )

    $msgs = $LogMessages.messages

    # $PSScriptRoot = helpers/ -> parent = 32-install-dbeaver/ -> parent = scripts/ -> parent = repo root
    $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $settingsSource = Join-Path $repoRoot "settings\04 - dbeaver"

    # -- Target: %APPDATA%\DBeaverData\workspace6\General\.dbeaver\ ----
    $dbeaverDataDir = Join-Path $env:APPDATA "DBeaverData"
    $targetDir = Join-Path $dbeaverDataDir "workspace6\General\.dbeaver"
    Write-Log "Settings target: $targetDir" -Level "info"

    # -- Check settings source exists ----------------------------------
    $isSourceMissing = -not (Test-Path $settingsSource)
    if ($isSourceMissing) {
        Write-FileError -FilePath $settingsSource -Operation "read" -Reason "DBeaver settings source directory does not exist" -Module "Sync-DbeaverSettings"
        Write-Log $msgs.settingsSkipped -Level "info"
        return $false
    }

    # -- Find config files in source -----------------------------------
    $sourceFiles = Get-ChildItem -Path $settingsSource -File -Exclude "readme.txt" -ErrorAction SilentlyContinue
    $hasNoFiles = $null -eq $sourceFiles -or $sourceFiles.Count -eq 0
    if ($hasNoFiles) {
        Write-FileError -FilePath $settingsSource -Operation "read" -Reason "No config files found in DBeaver settings source directory" -Module "Sync-DbeaverSettings"
        Write-Log $msgs.settingsSkipped -Level "info"
        return $false
    }

    Write-Log ($msgs.syncingSettings -replace '\{source\}', $settingsSource) -Level "info"

    # -- Ensure target directory exists --------------------------------
    $isTargetMissing = -not (Test-Path $targetDir)
    if ($isTargetMissing) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    # -- Copy files to target ------------------------------------------
    $copiedCount = 0
    foreach ($file in $sourceFiles) {
        try {
            $dest = Join-Path $targetDir $file.Name
            Copy-Item -Path $file.FullName -Destination $dest -Force
            Write-Log "Synced: $($file.Name)" -Level "success"
            $copiedCount++
        } catch {
            Write-FileError -FilePath $file.FullName -Operation "copy" -Reason "Failed to copy $($file.Name): $_" -Module "Sync-DbeaverSettings"
            Write-Log "Failed to copy $($file.Name): $_" -Level "error"
        }
    }

    # -- Also copy subdirectories (drivers, templates, etc.) -----------
    $sourceDirs = Get-ChildItem -Path $settingsSource -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $sourceDirs) {
        try {
            $dest = Join-Path $targetDir $dir.Name
            Copy-Item -Path $dir.FullName -Destination $dest -Recurse -Force
            Write-Log "Synced folder: $($dir.Name)" -Level "success"
            $copiedCount++
        } catch {
            Write-FileError -FilePath $dir.FullName -Operation "copy" -Reason "Failed to copy folder $($dir.Name): $_" -Module "Sync-DbeaverSettings"
            Write-Log "Failed to copy folder $($dir.Name): $_" -Level "error"
        }
    }

    $summary = $msgs.settingsSynced -replace '\{count\}', $copiedCount -replace '\{path\}', $targetDir
    Write-Log $summary -Level "success"
    return $true
}

function Uninstall-Dbeaver {
    <#
    .SYNOPSIS
        Full DBeaver Community uninstall: choco uninstall, purge tracking.
    #>
    param(
        $DbConfig,
        $LogMessages
    )

    $packageName = $$DbConfig.chocoPackage

    # 1. Uninstall via Chocolatey
    Write-Log ($LogMessages.messages.uninstalling -replace '\{name\}', "DBeaver Community") -Level "info"
    $isUninstalled = Uninstall-ChocoPackage -PackageName $packageName
    if ($isUninstalled) {
        Write-Log ($LogMessages.messages.uninstallSuccess -replace '\{name\}', "DBeaver Community") -Level "success"
    } else {
        Write-Log ($LogMessages.messages.uninstallFailed -replace '\{name\}', "DBeaver Community") -Level "error"
    }

    # 2. Remove tracking records
    Remove-InstalledRecord -Name "dbeaver"
    Remove-ResolvedData -ScriptFolder "32-install-dbeaver"

    Write-Log $LogMessages.messages.uninstallComplete -Level "success"
}
