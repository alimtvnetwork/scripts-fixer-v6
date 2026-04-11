# --------------------------------------------------------------------------
#  Python helper functions
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers --------------------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
}


function Install-Python {
    param(
        $Config,
        $LogMessages
    )

    $packageName = $Config.chocoPackageName

    $existing = Get-Command python -ErrorAction SilentlyContinue
    if ($existing) {
        $currentVersion = & python --version 2>$null
        $hasVersion = -not [string]::IsNullOrWhiteSpace($currentVersion)

        # Check .installed/ tracking -- skip if version matches
        if ($hasVersion) {
            $isAlreadyTracked = Test-AlreadyInstalled -Name "python" -CurrentVersion $currentVersion
            if ($isAlreadyTracked) {
                Write-Log ($LogMessages.messages.pythonAlreadyInstalled -replace '\{version\}', $currentVersion) -Level "info"
                return
            }
        }

        Write-Log ($LogMessages.messages.pythonAlreadyInstalled -replace '\{version\}', $currentVersion) -Level "info"

        if ($Config.alwaysUpgradeToLatest) {
            try {
                Upgrade-ChocoPackage -PackageName $packageName

                # Refresh PATH so upgraded python is discoverable
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

                $newVersion = try { & python --version 2>$null } catch { $null }
                $hasNewVersion = -not [string]::IsNullOrWhiteSpace($newVersion)
                if ($hasNewVersion) {
                    Write-Log ($LogMessages.messages.pythonUpgradeSuccess -replace '\{version\}', $newVersion) -Level "success"
                    Save-InstalledRecord -Name "python" -Version $newVersion
                } else {
                    Write-Log ($LogMessages.messages.pythonUpgradeSuccess -replace '\{version\}', "(version pending)") -Level "success"
                    Save-InstalledRecord -Name "python" -Version "installed"
                }
                Save-InstalledRecord -Name "python" -Version $newVersion
            } catch {
                Write-Log "Python upgrade failed: $_" -Level "error"
                Save-InstalledError -Name "python" -ErrorMessage "$_"
            }
        }
    }
    else {
        Write-Log $LogMessages.messages.pythonNotFound -Level "info"
        try {
            Install-ChocoPackage -PackageName $packageName

            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

            $installedVersion = & python --version 2>$null
            Write-Log ($LogMessages.messages.pythonInstallSuccess -replace '\{version\}', $installedVersion) -Level "success"
            Save-InstalledRecord -Name "python" -Version $installedVersion
        } catch {
            Write-Log "Python install failed: $_" -Level "error"
            Save-InstalledError -Name "python" -ErrorMessage "$_"
        }
    }
}

function Configure-PipSite {
    param(
        $Config,
        $LogMessages,
        [string]$DevDir
    )

    $pipConfig = $Config.pip
    $isSetSiteDisabled = -not $pipConfig.setUserSite
    if ($isSetSiteDisabled) { return }

    # Resolve site path
    $sitePath = if ($DevDir) {
        Join-Path $DevDir $Config.devDirSubfolder
    } else {
        $pipConfig.userSitePath
    }

    # Ensure directory exists
    $isDirMissing = -not (Test-Path $sitePath)
    if ($isDirMissing) {
        New-Item -Path $sitePath -ItemType Directory -Force | Out-Null
    }

    # Set PYTHONUSERBASE environment variable (controls pip install --user target)
    $currentBase = [System.Environment]::GetEnvironmentVariable("PYTHONUSERBASE", "User")
    if ($currentBase -eq $sitePath) {
        Write-Log ($LogMessages.messages.pipSiteAlreadySet -replace '\{path\}', $sitePath) -Level "info"
    }
    else {
        Write-Log ($LogMessages.messages.configuringPipSite -replace '\{path\}', $sitePath) -Level "info"
        [System.Environment]::SetEnvironmentVariable("PYTHONUSERBASE", $sitePath, "User")
        $env:PYTHONUSERBASE = $sitePath
        Write-Log ($LogMessages.messages.pipSiteSet -replace '\{path\}', $sitePath) -Level "success"
    }

    return $sitePath
}

function Update-PythonPath {
    param(
        $Config,
        $LogMessages,
        [string]$SitePath
    )

    $isPathUpdateDisabled = -not $Config.path.updateUserPath
    if ($isPathUpdateDisabled) { return }

    $hasNoSitePath = -not $SitePath
    if ($hasNoSitePath) { return }

    # Python user Scripts directory
    $scriptsDir = Join-Path $SitePath "Scripts"

    $isDirMissing = -not (Test-Path $scriptsDir)
    if ($isDirMissing) {
        New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null
    }

    $isAlreadyInPath = Test-InPath -Directory $scriptsDir
    if ($isAlreadyInPath) {
        Write-Log ($LogMessages.messages.pathAlreadyContains -replace '\{path\}', $scriptsDir) -Level "info"
    }
    else {
        Write-Log ($LogMessages.messages.addingToPath -replace '\{path\}', $scriptsDir) -Level "info"
        Add-ToUserPath -Directory $scriptsDir
    }
}

function Uninstall-Python {
    <#
    .SYNOPSIS
        Full Python uninstall: choco uninstall, remove PYTHONUSERBASE env var,
        remove Scripts dir from PATH, clean dev dir subfolder, purge tracking.
    #>
    param(
        $Config,
        $LogMessages,
        [string]$DevDir
    )

    $packageName = $Config.chocoPackageName

    # 1. Uninstall via Chocolatey
    Write-Log ($LogMessages.messages.uninstallingPython) -Level "info"
    $isUninstalled = Uninstall-ChocoPackage -PackageName $packageName
    if ($isUninstalled) {
        Write-Log ($LogMessages.messages.pythonUninstallSuccess) -Level "success"
    } else {
        Write-Log ($LogMessages.messages.pythonUninstallFailed) -Level "error"
    }

    # 2. Remove PYTHONUSERBASE environment variable
    $currentBase = [System.Environment]::GetEnvironmentVariable("PYTHONUSERBASE", "User")
    $hasUserBase = -not [string]::IsNullOrWhiteSpace($currentBase)
    if ($hasUserBase) {
        Write-Log "Removing PYTHONUSERBASE env var: $currentBase" -Level "info"
        [System.Environment]::SetEnvironmentVariable("PYTHONUSERBASE", $null, "User")
        $env:PYTHONUSERBASE = $null
    }

    # 3. Remove Scripts dir from PATH
    $sitePath = if ($DevDir) {
        Join-Path $DevDir $Config.devDirSubfolder
    } else {
        $Config.pip.userSitePath
    }

    $hasValidSitePath = -not [string]::IsNullOrWhiteSpace($sitePath)
    if ($hasValidSitePath) {
        $scriptsDir = Join-Path $sitePath "Scripts"
        Remove-FromUserPath -Directory $scriptsDir
    }

    # 4. Clean dev directory subfolder
    if ($hasValidSitePath -and (Test-Path $sitePath)) {
        Write-Log "Removing dev directory subfolder: $sitePath" -Level "info"
        Remove-Item -Path $sitePath -Recurse -Force
        Write-Log "Dev directory subfolder removed: $sitePath" -Level "success"
    }

    # 5. Remove tracking records
    Remove-InstalledRecord -Name "python"
    Remove-ResolvedData -ScriptFolder "05-install-python"

    Write-Log ($LogMessages.messages.pythonUninstallComplete) -Level "success"
}
