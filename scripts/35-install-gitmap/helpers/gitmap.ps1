# --------------------------------------------------------------------------
#  Helper -- GitMap CLI installer
#  Uses the remote install.ps1 from GitHub to install gitmap.
#  Integrates with devDir resolution for folder-specific installs.
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers --------------------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
}

$_devDirPath = Join-Path $_sharedDir "dev-dir.ps1"
if ((Test-Path $_devDirPath) -and -not (Get-Command Resolve-DevDir -ErrorAction SilentlyContinue)) {
    . $_devDirPath
}

function Test-GitmapInstalled {
    $cmd = Get-Command "gitmap" -ErrorAction SilentlyContinue
    $isInPath = $null -ne $cmd
    if ($isInPath) { return $true }

    # Check default install location
    $defaultPaths = @(
        "$env:LOCALAPPDATA\gitmap\gitmap.exe",
        "C:\DevTools\GitMap\gitmap.exe"
    )

    # Also check devDir-resolved path if DEV_DIR is set
    $hasDevDir = -not [string]::IsNullOrWhiteSpace($env:DEV_DIR)
    if ($hasDevDir) {
        $devDirGitmap = Join-Path $env:DEV_DIR "GitMap\gitmap.exe"
        $defaultPaths += $devDirGitmap
    }

    foreach ($p in $defaultPaths) {
        $isPresent = Test-Path $p
        if ($isPresent) { return $true }
    }

    return $false
}

function Save-GitmapResolvedState {
    param(
        [string]$InstallDir = ""
    )
    Save-ResolvedData -ScriptFolder "35-install-gitmap" -Data @{
        resolvedAt  = (Get-Date -Format "o")
        resolvedBy  = $env:USERNAME
        installDir  = $InstallDir
    }
}

function Resolve-GitmapInstallDir {
    <#
    .SYNOPSIS
        Resolves the GitMap install directory using devDir config.
        Priority: gitmap.installDir override > devDir resolution > config default.
    #>
    param(
        [PSCustomObject]$GitmapConfig,
        [PSCustomObject]$DevDirConfig
    )

    # 1. Explicit installDir override in gitmap config
    $hasInstallDir = -not [string]::IsNullOrWhiteSpace($GitmapConfig.installDir)
    if ($hasInstallDir) {
        return $GitmapConfig.installDir
    }

    # 2. Resolve via devDir system (env var, smart detection, etc.)
    $devDir = Resolve-DevDir -DevDirConfig $DevDirConfig
    $hasDevDir = -not [string]::IsNullOrWhiteSpace($devDir)
    if ($hasDevDir) {
        return Join-Path $devDir "GitMap"
    }

    # 3. Fallback to config default
    $hasDefault = -not [string]::IsNullOrWhiteSpace($DevDirConfig.default)
    if ($hasDefault) {
        return $DevDirConfig.default
    }

    return "C:\DevTools\GitMap"
}

function Install-Gitmap {
    <#
    .SYNOPSIS
        Installs GitMap CLI via the remote install.ps1 from GitHub.
        Uses devDir resolution for the install directory.
        Returns $true on success, $false on failure.
    #>
    param(
        [PSCustomObject]$GitmapConfig,
        [PSCustomObject]$DevDirConfig,
        $LogMessages
    )

    $isDisabled = -not $GitmapConfig.enabled
    if ($isDisabled) {
        Write-Log $LogMessages.messages.disabled -Level "info"
        return $true
    }

    Write-Log $LogMessages.messages.checking -Level "info"

    $isGitmapReady = Test-GitmapInstalled
    if ($isGitmapReady) {
        Write-Log $LogMessages.messages.found -Level "success"
        Save-GitmapResolvedState
        return $true
    }

    Write-Log $LogMessages.messages.notFound -Level "info"

    # Resolve install directory FIRST -- log it prominently before anything else
    $installDir = Resolve-GitmapInstallDir -GitmapConfig $GitmapConfig -DevDirConfig $DevDirConfig
    Write-Host ""
    Write-Log ($LogMessages.messages.installDir -replace '\{path\}', $installDir) -Level "success"
    Write-Host ""

    Write-Log $LogMessages.messages.downloadingInstaller -Level "info"

    try {
        Write-Log $LogMessages.messages.runningInstaller -Level "info"

        # Download and execute the remote installer with -InstallDir
        $installerScript = Invoke-RestMethod -Uri $GitmapConfig.installUrl -UseBasicParsing
        $scriptBlock = [ScriptBlock]::Create($installerScript)
        & $scriptBlock -InstallDir $installDir

    } catch {
        Write-FileError -FilePath $installDir -Operation "inject" -Reason "Remote installer script failed: $($_.Exception.Message)" -Module "Install-Gitmap"
        Write-Log ($LogMessages.messages.installFailed -replace '\{error\}', $_.Exception.Message) -Level "error"
        return $false
    }

    # Refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    $isGitmapReady = Test-GitmapInstalled
    if ($isGitmapReady) {
        Write-Log $LogMessages.messages.installSuccess -Level "success"
        Save-GitmapResolvedState -InstallDir $installDir
    } else {
        Write-Log $LogMessages.messages.notInPath -Level "warn"
        # Still mark as success -- binary may need shell restart to appear in PATH
        Save-GitmapResolvedState -InstallDir $installDir
    }

    return $true
}
