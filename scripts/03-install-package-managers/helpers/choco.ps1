<#
.SYNOPSIS
    Chocolatey install/update helpers for script 03.
#>

function Install-Chocolatey {
    param([PSCustomObject]$Config)

    if (-not $Config.enabled) {
        Write-Log "Chocolatey is disabled in config -- skipping" "skip"
        return $true
    }

    $chocoOk = Assert-Choco
    if (-not $chocoOk) { return $false }

    if ($Config.upgradeOnRun) {
        Write-Log "Upgrading Chocolatey itself to latest..." "info"
        try {
            $output = & choco.exe upgrade chocolatey -y 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Chocolatey self-upgrade had issues: $output" "warn"
            } else {
                Write-Log "Chocolatey is up to date" "ok"
            }
        } catch {
            Write-Log "Failed to upgrade Chocolatey: $_" "warn"
        }
    }

    # Save resolved info
    $version = & choco.exe --version 2>&1
    Save-ResolvedData -ScriptDir $script:ScriptDir -Data @{
        chocolatey = @{
            version    = "$version".Trim()
            resolvedAt = (Get-Date -Format "o")
            resolvedBy = $env:USERNAME
        }
    }

    return $true
}
