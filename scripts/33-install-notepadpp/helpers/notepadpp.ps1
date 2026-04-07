# --------------------------------------------------------------------------
#  Helper: Install Notepad++ via Chocolatey and sync settings
# --------------------------------------------------------------------------

function Install-NotepadPP {
    param(
        [Parameter(Mandatory)] $NppConfig,
        [Parameter(Mandatory)] $LogMessages
    )

    $msgs = $LogMessages.messages

    # -- Check if already installed ----------------------------------------
    $nppPath = Get-Command "notepad++" -ErrorAction SilentlyContinue
    if (-not $nppPath) {
        # Also check common install locations
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
        # Get version
        $version = "unknown"
        try {
            $exePath = if ($nppPath -is [System.Management.Automation.ApplicationInfo]) { $nppPath.Source } else { $nppPath.FullName }
            $version = (Get-Item $exePath).VersionInfo.ProductVersion
        } catch { }

        $isAlreadyInstalled = Test-AlreadyInstalled -Name "notepadpp" -CurrentVersion $version
        if ($isAlreadyInstalled) {
            Write-Log ($msgs.alreadyInstalled -replace '\{version\}', $version) -Level "success"
            Sync-NotepadPPSettings -LogMessages $LogMessages
            return $true
        }
    }

    # -- Install via Chocolatey --------------------------------------------
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

    # -- Verify installation -----------------------------------------------
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
        Write-Log ($msgs.installFailed -replace '\{error\}', "notepad++.exe not found after install") -Level "error"
        return $false
    }

    $version = (Get-Item $installedPath).VersionInfo.ProductVersion
    Write-Log ($msgs.installSuccess) -Level "success"
    Write-Log ("Install target: $installedPath") -Level "success"
    Write-Host ""
    Save-InstalledRecord -Name "notepadpp" -Version $version -Method "chocolatey"

    # -- Sync settings -----------------------------------------------------
    Sync-NotepadPPSettings -LogMessages $LogMessages

    return $true
}

function Sync-NotepadPPSettings {
    param(
        [Parameter(Mandatory)] $LogMessages
    )

    $msgs = $LogMessages.messages
    $scriptDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.ScriptName)
    # Settings source: scripts/33-install-notepadpp/settings/
    $settingsSource = Join-Path $scriptDir "settings"

    if (-not (Test-Path $settingsSource)) {
        Write-Log $msgs.settingsSkipped -Level "info"
        return
    }

    $settingsFiles = Get-ChildItem -Path $settingsSource -File -ErrorAction SilentlyContinue
    if ($settingsFiles.Count -eq 0) {
        Write-Log $msgs.settingsSkipped -Level "info"
        return
    }

    $appDataDir = Join-Path $env:APPDATA "Notepad++"
    if (-not (Test-Path $appDataDir)) {
        New-Item -Path $appDataDir -ItemType Directory -Force | Out-Null
    }

    Write-Log $msgs.syncingSettings -Level "info"

    foreach ($file in $settingsFiles) {
        $dest = Join-Path $appDataDir $file.Name
        Copy-Item -Path $file.FullName -Destination $dest -Force
    }

    Write-Log ($msgs.settingsSynced -replace '\{path\}', $appDataDir) -Level "success"
}
