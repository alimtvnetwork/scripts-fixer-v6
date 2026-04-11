# --------------------------------------------------------------------------
#  Python helper functions
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers --------------------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
}

$_toolVersionPath = Join-Path $_sharedDir "tool-version.ps1"
$isToolVersionMissing = -not (Test-Path $_toolVersionPath)
if ($isToolVersionMissing) {
    Write-FileError -FilePath $_toolVersionPath -Operation "load" -Reason "Shared helper file does not exist" -Module "05-install-python/helpers/python.ps1"
    throw "Missing shared helper: $_toolVersionPath"
}

$isPythonResolverMissing = -not (Get-Command Resolve-PythonExe -ErrorAction SilentlyContinue)
if ($isPythonResolverMissing) {
    . $_toolVersionPath
}


function Add-DirectoryToProcessPath {
    param(
        [string]$Directory
    )

    $hasDirectory = -not [string]::IsNullOrWhiteSpace($Directory) -and (Test-Path $Directory -PathType Container)
    $isDirectoryMissing = -not $hasDirectory
    if ($isDirectoryMissing) {
        return
    }

    $pathEntries = @($env:Path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $isAlreadyInPath = $false
    foreach ($pathEntry in $pathEntries) {
        $isSameEntry = $pathEntry.TrimEnd('\\') -ieq $Directory.TrimEnd('\\')
        if ($isSameEntry) {
            $isAlreadyInPath = $true
            break
        }
    }

    if ($isAlreadyInPath) {
        return
    }

    $hasExistingPath = -not [string]::IsNullOrWhiteSpace($env:Path)
    if ($hasExistingPath) {
        $env:Path = "$Directory;$env:Path"
    } else {
        $env:Path = $Directory
    }
}

function Set-PythonRuntimeEnvironment {
    param(
        $PythonInfo
    )

    $hasPythonInfo = $null -ne $PythonInfo -and $PythonInfo.IsValid
    $isPythonInfoMissing = -not $hasPythonInfo
    if ($isPythonInfoMissing) {
        return
    }

    $env:PYTHON_EXE = $PythonInfo.Path
    [System.Environment]::SetEnvironmentVariable("PYTHON_EXE", $PythonInfo.Path, "User")

    $pythonDir = Split-Path -Parent $PythonInfo.Path
    Add-DirectoryToProcessPath -Directory $pythonDir

    $pythonScriptsDir = Join-Path $pythonDir "Scripts"
    $hasPythonScriptsDir = Test-Path $pythonScriptsDir -PathType Container
    if ($hasPythonScriptsDir) {
        Add-DirectoryToProcessPath -Directory $pythonScriptsDir
    }
}

function Resolve-InstalledPython {
    param(
        $LogMessages,
        [switch]$RequirePip
    )

    $pythonInfo = Resolve-PythonExe -ReturnInfo -RefreshPath
    $hasPythonInfo = $null -ne $pythonInfo -and $pythonInfo.IsValid
    $isPythonInfoMissing = -not $hasPythonInfo
    if ($isPythonInfoMissing) {
        return $null
    }

    $isPipRequiredButMissing = $RequirePip -and -not $pythonInfo.HasPip
    if ($isPipRequiredButMissing) {
        Write-Log "pip not detected for '$($pythonInfo.Path)'. Running ensurepip..." -Level "warn"
        try {
            & $pythonInfo.Path -m ensurepip --upgrade 2>&1 | Out-Null
        } catch {
        }

        $pythonInfo = Resolve-PythonExe -RequirePip -ReturnInfo -RefreshPath
        $hasPythonInfo = $null -ne $pythonInfo -and $pythonInfo.IsValid
        $isPythonInfoMissing = -not $hasPythonInfo
        if ($isPythonInfoMissing) {
            return $null
        }
    }

    Set-PythonRuntimeEnvironment -PythonInfo $pythonInfo
    return $pythonInfo
}


function Install-Python {
    param(
        $Config,
        $LogMessages
    )

    $packageName = $Config.chocoPackageName

    $existingPython = Resolve-InstalledPython -LogMessages $LogMessages -RequirePip
    $hasExistingPython = $null -ne $existingPython
    if ($hasExistingPython) {
        $currentVersion = $existingPython.Version
        $isAlreadyTracked = Test-AlreadyInstalled -Name "python" -CurrentVersion $currentVersion
        Write-Log ($LogMessages.messages.pythonAlreadyInstalled -replace '\{version\}', $currentVersion) -Level "info"

        $isUpgradeDisabled = -not $Config.alwaysUpgradeToLatest
        if ($isAlreadyTracked -and $isUpgradeDisabled) {
            return $existingPython
        }
    } else {
        Write-Log $LogMessages.messages.pythonNotFound -Level "info"
    }

    $isUpgrade = $hasExistingPython

    try {
        if ($isUpgrade) {
            Upgrade-ChocoPackage -PackageName $packageName
        } else {
            Install-ChocoPackage -PackageName $packageName
        }

        $resolvedPython = Resolve-InstalledPython -LogMessages $LogMessages -RequirePip
        $hasResolvedPython = $null -ne $resolvedPython
        $isResolvedPythonMissing = -not $hasResolvedPython
        if ($isResolvedPythonMissing) {
            $failureMessage = "Chocolatey completed, but no working python executable could be resolved after install."
            Write-Log $failureMessage -Level "error"
            Save-InstalledError -Name "python" -ErrorMessage $failureMessage
            throw $failureMessage
        }

        $resolvedVersion = $resolvedPython.Version
        if ($isUpgrade) {
            Write-Log ($LogMessages.messages.pythonUpgradeSuccess -replace '\{version\}', $resolvedVersion) -Level "success"
        } else {
            Write-Log ($LogMessages.messages.pythonInstallSuccess -replace '\{version\}', $resolvedVersion) -Level "success"
        }

        Save-InstalledRecord -Name "python" -Version $resolvedVersion
        return $resolvedPython
    } catch {
        $failureMessage = $_.Exception.Message
        if ([string]::IsNullOrWhiteSpace($failureMessage)) {
            $failureMessage = "$_"
        }

        if ($isUpgrade) {
            Write-Log "Python upgrade failed: $failureMessage" -Level "error"
        } else {
            Write-Log "Python install failed: $failureMessage" -Level "error"
        }

        Save-InstalledError -Name "python" -ErrorMessage $failureMessage
        throw
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
        $env:PYTHONUSERBASE = $sitePath
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
    Add-DirectoryToProcessPath -Directory $scriptsDir
    if ($isAlreadyInPath) {
        Write-Log ($LogMessages.messages.pathAlreadyContains -replace '\{path\}', $scriptsDir) -Level "info"
    }
    else {
        Write-Log ($LogMessages.messages.addingToPath -replace '\{path\}', $scriptsDir) -Level "info"
        Add-ToUserPath -Directory $scriptsDir
    }

    $pythonInfo = Resolve-PythonExe -ReturnInfo -RefreshPath
    $hasPythonInfo = $null -ne $pythonInfo -and $pythonInfo.IsValid
    if ($hasPythonInfo) {
        Set-PythonRuntimeEnvironment -PythonInfo $pythonInfo
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
