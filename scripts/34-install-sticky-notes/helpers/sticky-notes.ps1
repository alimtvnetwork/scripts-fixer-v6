# --------------------------------------------------------------------------
#  Helper -- Simple Sticky Notes installer
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

function Test-StickyNotesInstalled {
    # Check common install locations
    $defaultPaths = @(
        "$env:ProgramFiles\Simple Sticky Notes\SimpleSticky.exe",
        "${env:ProgramFiles(x86)}\Simple Sticky Notes\SimpleSticky.exe",
        "$env:LOCALAPPDATA\Simple Sticky Notes\SimpleSticky.exe"
    )
    foreach ($p in $defaultPaths) {
        $isPresent = Test-Path $p
        if ($isPresent) { return $true }
    }

    # Try Get-Command as fallback
    $cmd = Get-Command "SimpleSticky" -ErrorAction SilentlyContinue
    $isInPath = $null -ne $cmd
    if ($isInPath) { return $true }

    return $false
}

function Save-StickyNotesResolvedState {
    Save-ResolvedData -ScriptFolder "34-install-sticky-notes" -Data @{
        resolvedAt = (Get-Date -Format "o")
        resolvedBy = $env:USERNAME
    }
}

function Install-StickyNotes {
    <#
    .SYNOPSIS
        Installs Simple Sticky Notes via Chocolatey.
        Returns $true on success, $false on failure.
    #>
    param(
        [PSCustomObject]$StickyConfig,
        $LogMessages
    )

    $isDisabled = -not $StickyConfig.enabled
    if ($isDisabled) {
        Write-Log $LogMessages.messages.disabled -Level "info"
        return $true
    }

    Write-Log $LogMessages.messages.checking -Level "info"

    $isStickyReady = Test-StickyNotesInstalled
    if ($isStickyReady) {
        Write-Log $LogMessages.messages.found -Level "success"
        Save-StickyNotesResolvedState
        return $true
    }

    Write-Log $LogMessages.messages.notFound -Level "info"
    Write-Host ""
    Write-Log $LogMessages.messages.installing -Level "info"

    $isInstalled = Install-ChocoPackage -PackageName $StickyConfig.chocoPackage
    $hasInstallFailed = -not $isInstalled
    if ($hasInstallFailed) {
        Write-FileError -FilePath "$env:ProgramFiles\Simple Sticky Notes\SimpleSticky.exe" -Operation "resolve" -Reason "Chocolatey install returned failure for '$($StickyConfig.chocoPackage)'" -Module "Install-StickyNotes"
        Write-Log ($LogMessages.messages.installFailed -replace '\{error\}', "Install returned failure") -Level "error"
        return $false
    }

    # Refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    # Verify installation
    $verifyPaths = @(
        "$env:ProgramFiles\Simple Sticky Notes\SimpleSticky.exe",
        "${env:ProgramFiles(x86)}\Simple Sticky Notes\SimpleSticky.exe"
    )
    $installedPath = $null
    foreach ($p in $verifyPaths) {
        if (Test-Path $p) {
            $installedPath = $p
            break
        }
    }

    if ($installedPath) {
        Write-Log $LogMessages.messages.installSuccess -Level "success"
        Write-Log "Install target: $installedPath" -Level "success"
        Save-StickyNotesResolvedState

        # Save install record
        $version = "unknown"
        try { $version = (Get-Item $installedPath).VersionInfo.ProductVersion } catch { }
        Save-InstalledRecord -Name "sticky-notes" -Version $version -Method "chocolatey"
    } else {
        Write-Log $LogMessages.messages.notInPath -Level "warn"
        Save-StickyNotesResolvedState
    }

    return $true
}
