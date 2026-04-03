<#
.SYNOPSIS
    Winget verification and install helpers for script 03.
#>

function Install-Winget {
    param([PSCustomObject]$Config)

    if (-not $Config.enabled) {
        Write-Log "Winget is disabled in config -- skipping" "skip"
        return $true
    }

    Write-Log "Checking for Winget..." "info"
    $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue

    if ($wingetCmd) {
        $version = & winget.exe --version 2>&1
        Write-Log "Winget found: $version" "ok"

        Save-ResolvedData -ScriptDir $script:ScriptDir -Data @{
            winget = @{
                version    = "$version".Trim()
                resolvedAt = (Get-Date -Format "o")
                resolvedBy = $env:USERNAME
            }
        }

        return $true
    }

    if (-not $Config.installIfMissing) {
        Write-Log "Winget not found and installIfMissing is false -- skipping" "warn"
        return $false
    }

    Write-Log "Winget not found -- attempting install..." "warn"

    # Try via Add-AppxPackage (Microsoft.DesktopAppInstaller)
    try {
        Write-Log "Downloading App Installer from: $($Config.msStoreUrl)" "info"
        $installerPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $Config.msStoreUrl -OutFile $installerPath -UseBasicParsing

        Write-Log "Installing App Installer package..." "info"
        Add-AppxPackage -Path $installerPath -ErrorAction Stop

        # Refresh PATH
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

        $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            $version = & winget.exe --version 2>&1
            Write-Log "Winget installed successfully: $version" "ok"

            Save-ResolvedData -ScriptDir $script:ScriptDir -Data @{
                winget = @{
                    version    = "$version".Trim()
                    resolvedAt = (Get-Date -Format "o")
                    resolvedBy = $env:USERNAME
                }
            }

            return $true
        } else {
            Write-Log "Winget install completed but winget.exe not found in PATH" "fail"
            Write-Log "Try installing manually from the Microsoft Store" "info"
            return $false
        }
    } catch {
        Write-Log "Failed to install Winget: $_" "fail"
        Write-Log "Install manually: Microsoft Store -> 'App Installer'" "info"
        return $false
    } finally {
        if (Test-Path $installerPath -ErrorAction SilentlyContinue) {
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        }
    }
}
