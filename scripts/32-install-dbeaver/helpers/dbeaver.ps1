# --------------------------------------------------------------------------
#  Helper -- DBeaver Community installer
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
        Returns $true on success, $false on failure.
    #>
    param(
        [PSCustomObject]$DbConfig,
        $LogMessages
    )

    $isDisabled = -not $DbConfig.enabled
    if ($isDisabled) {
        Write-Log $LogMessages.messages.disabled -Level "info"
        return $true
    }

    Write-Log $LogMessages.messages.checking -Level "info"

    $isDbeaverReady = Test-DbeaverInstalled
    if ($isDbeaverReady) {
        Write-Log $LogMessages.messages.found -Level "success"
        Save-DbeaverResolvedState
        return $true
    }

    Write-Log $LogMessages.messages.notFound -Level "warn"
    Write-Log $LogMessages.messages.installing -Level "info"

    $isInstalled = Install-ChocoPackage -PackageName $DbConfig.chocoPackage
    $hasInstallFailed = -not $isInstalled
    if ($hasInstallFailed) {
        Write-Log ($LogMessages.messages.installFailed -replace '\{error\}', "Install returned failure") -Level "error"
        return $false
    }

    # Refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    $isDbeaverReady = Test-DbeaverInstalled
    if ($isDbeaverReady) {
        Write-Log $LogMessages.messages.installSuccess -Level "success"
        Save-DbeaverResolvedState
    } else {
        Write-Log $LogMessages.messages.notInPath -Level "warn"
        # Still mark as success -- DBeaver GUI works even without CLI in PATH
        Save-DbeaverResolvedState
    }

    return $true
}
