<#
.SYNOPSIS
    Installs and updates Chocolatey and Winget package managers.

.DESCRIPTION
    Ensures both Chocolatey and Winget are installed and up to date.
    Supports subcommands to target a specific package manager.

.PARAMETER Command
    Subcommand: "all" (default), "choco", "winget".

.PARAMETER Help
    Show available commands and usage.

.NOTES
    Author : Lovable AI
    Version: 1.0.0
#>

param(
    [string]$Command = "all",
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ── Load shared helpers ──────────────────────────────────────────────
. (Join-Path $script:ScriptDir "..\shared\logging.ps1")
. (Join-Path $script:ScriptDir "..\shared\choco-utils.ps1")

$sharedHelp = Join-Path $script:ScriptDir "..\shared\help.ps1"
if (Test-Path $sharedHelp) { . $sharedHelp }

$sharedResolved = Join-Path $script:ScriptDir "..\shared\resolved.ps1"
if (Test-Path $sharedResolved) { . $sharedResolved }

# ── Load script-specific helpers ─────────────────────────────────────
. (Join-Path $script:ScriptDir "helpers\choco.ps1")
. (Join-Path $script:ScriptDir "helpers\winget.ps1")

# ── Handle --help ────────────────────────────────────────────────────
if ($Help) {
    Show-ScriptHelp `
        -Name "Install Package Managers" `
        -Version "1.0.0" `
        -Description "Installs and updates Chocolatey and Winget package managers." `
        -Commands @(
            @{ Name = "all";    Description = "Install both Chocolatey and Winget (default)" },
            @{ Name = "choco";  Description = "Install/update Chocolatey only" },
            @{ Name = "winget"; Description = "Install/verify Winget only" }
        ) `
        -Flags @(
            @{ Name = "-Help"; Description = "Show this help message" }
        ) `
        -Examples @(
            ".\run.ps1                # Install both (default)",
            ".\run.ps1 choco          # Chocolatey only",
            ".\run.ps1 winget         # Winget only",
            ".\run.ps1 -Help          # Show this help"
        )
    exit 0
}

Write-Host "  [ INFO ] Script directory: $($script:ScriptDir)" -ForegroundColor Cyan

# ── Git pull ─────────────────────────────────────────────────────────
$sharedGitPull = Join-Path $script:ScriptDir "..\shared\git-pull.ps1"
if (Test-Path $sharedGitPull) {
    . $sharedGitPull
    $repoRoot = Split-Path -Parent (Split-Path -Parent $script:ScriptDir)
    Invoke-GitPull -RepoRoot $repoRoot
}

# ── Start logging ────────────────────────────────────────────────────
$logFile = Initialize-Logging -ScriptDir $script:ScriptDir

try {
    # Load log messages
    $logPath = Join-Path $script:ScriptDir "log-messages.json"
    $script:LogMessages = Import-JsonConfig -FilePath $logPath -Label "log-messages.json"
    if (-not $script:LogMessages) { exit 1 }

    Write-Banner $script:LogMessages.banner

    # Check admin
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log $script:LogMessages.errors.notAdmin "fail"
        Write-Host ""
        Write-Host "  Tip: Right-click PowerShell -> 'Run as Administrator'" -ForegroundColor Yellow
        exit 1
    }
    Write-Log "Running as Administrator: $($identity.Name)" "ok"

    # Load config
    $cfgPath = Join-Path $script:ScriptDir "config.json"
    $Config = Import-JsonConfig -FilePath $cfgPath -Label "config.json"
    if (-not $Config) { exit 1 }

    $totalSuccess = $true

    # Execute based on command
    switch ($Command.ToLower()) {
        "choco" {
            Write-Log "Command: choco -- Chocolatey only" "info"
            $ok = Install-Chocolatey -Config $Config.chocolatey
            if (-not $ok) { $totalSuccess = $false }
        }
        "winget" {
            Write-Log "Command: winget -- Winget only" "info"
            $ok = Install-Winget -Config $Config.winget
            if (-not $ok) { $totalSuccess = $false }
        }
        default {
            Write-Log "Command: all -- Installing both package managers" "info"

            $ok = Install-Chocolatey -Config $Config.chocolatey
            if (-not $ok) { $totalSuccess = $false }

            $ok = Install-Winget -Config $Config.winget
            if (-not $ok) { $totalSuccess = $false }
        }
    }

    # Summary
    Write-Host ""
    if ($totalSuccess) {
        Write-Log $script:LogMessages.steps.done "ok"
    } else {
        Write-Log "Completed with some warnings -- check output above." "warn"
    }

    Write-Banner $script:LogMessages.footer "Green"

} catch {
    Write-Host ""
    Write-Log "Unhandled error: $_" "fail"
    Write-Log "Stack: $($_.ScriptStackTrace)" "fail"
    Write-Host ""
    Write-Log "Log saved to: $logFile" "info"
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    Write-Host "  [ LOG  ] Transcript saved: $logFile" -ForegroundColor DarkGray
}
