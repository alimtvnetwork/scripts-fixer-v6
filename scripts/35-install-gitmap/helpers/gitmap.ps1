# --------------------------------------------------------------------------
#  Helper -- GitMap CLI installer
#  Uses the remote install.ps1 from GitHub to install gitmap.
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers --------------------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
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
    foreach ($p in $defaultPaths) {
        $isPresent = Test-Path $p
        if ($isPresent) { return $true }
    }

    return $false
}

function Save-GitmapResolvedState {
    Save-ResolvedData -ScriptFolder "35-install-gitmap" -Data @{
        resolvedAt = (Get-Date -Format "o")
        resolvedBy = $env:USERNAME
    }
}

function Install-Gitmap {
    <#
    .SYNOPSIS
        Installs GitMap CLI via the remote install.ps1 from GitHub.
        Returns $true on success, $false on failure.
    #>
    param(
        [PSCustomObject]$GitmapConfig,
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

    Write-Log $LogMessages.messages.notFound -Level "warn"
    Write-Log $LogMessages.messages.downloadingInstaller -Level "info"

    try {
        # Build install arguments
        $installArgs = @{}
        $hasInstallDir = -not [string]::IsNullOrWhiteSpace($GitmapConfig.installDir)
        if ($hasInstallDir) {
            $installArgs["InstallDir"] = $GitmapConfig.installDir
        }

        Write-Log $LogMessages.messages.runningInstaller -Level "info"

        # Download and execute the remote installer
        $installerScript = Invoke-RestMethod -Uri $GitmapConfig.installUrl -UseBasicParsing
        $scriptBlock = [ScriptBlock]::Create($installerScript)
        & $scriptBlock @installArgs

    } catch {
        Write-Log ($LogMessages.messages.installFailed -replace '\{error\}', $_.Exception.Message) -Level "error"
        return $false
    }

    # Refresh PATH
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    $isGitmapReady = Test-GitmapInstalled
    if ($isGitmapReady) {
        Write-Log $LogMessages.messages.installSuccess -Level "success"
        Save-GitmapResolvedState
    } else {
        Write-Log $LogMessages.messages.notInPath -Level "warn"
        # Still mark as success -- binary may need shell restart to appear in PATH
        Save-GitmapResolvedState
    }

    return $true
}
