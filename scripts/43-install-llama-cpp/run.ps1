# --------------------------------------------------------------------------
#  Script 43 -- Install llama.cpp
#  Downloads llama.cpp binaries (CUDA/AVX2/KoboldCPP), extracts, adds to
#  PATH, and optionally downloads GGUF models.
# --------------------------------------------------------------------------
param(
    [Parameter(Position = 0)]
    [string]$Command = "all",

    [Parameter(Position = 1)]
    [string]$Path,

    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sharedDir = Join-Path (Split-Path -Parent $scriptDir) "shared"

# -- Dot-source shared helpers ------------------------------------------------
. (Join-Path $sharedDir "logging.ps1")
. (Join-Path $sharedDir "resolved.ps1")
. (Join-Path $sharedDir "git-pull.ps1")
. (Join-Path $sharedDir "help.ps1")
. (Join-Path $sharedDir "path-utils.ps1")
. (Join-Path $sharedDir "dev-dir.ps1")
. (Join-Path $sharedDir "installed.ps1")
. (Join-Path $sharedDir "download-retry.ps1")
. (Join-Path $sharedDir "disk-space.ps1")

# -- Dot-source script helpers ------------------------------------------------
. (Join-Path $scriptDir "helpers\llama-cpp.ps1")

# -- Load config & log messages -----------------------------------------------
$config       = Import-JsonConfig (Join-Path $scriptDir "config.json")
$logMessages  = Import-JsonConfig (Join-Path $scriptDir "log-messages.json")

# -- Help ---------------------------------------------------------------------
if ($Help -or $Command -eq "--help") {
    Show-ScriptHelp -LogMessages $logMessages
    return
}

# -- Banner --------------------------------------------------------------------
Write-Banner -Title $logMessages.scriptName

# -- Initialize logging --------------------------------------------------------
Initialize-Logging -ScriptName $logMessages.scriptName

try {

# -- Git pull ------------------------------------------------------------------
Invoke-GitPull

# -- Disabled check ------------------------------------------------------------
$isDisabled = -not $config.enabled
if ($isDisabled) {
    Write-Log $logMessages.messages.scriptDisabled -Level "warn"
    return
}

# -- Assert admin --------------------------------------------------------------
$hasAdminRights = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$isNotAdmin = -not $hasAdminRights
if ($isNotAdmin) {
    Write-Log $logMessages.messages.notAdmin -Level "error"
    return
}

# -- Resolve dev directory -----------------------------------------------------
$hasPathParam = -not [string]::IsNullOrWhiteSpace($Path)
if ($hasPathParam) {
    $devDir = $Path
    Write-Log "Using user-specified dev directory: $devDir" -Level "info"
} elseif ($env:DEV_DIR) {
    $devDir = $env:DEV_DIR
} else {
    $devDir = Resolve-DevDir
}

# -- Resolve base directory for llama-cpp --------------------------------------
$baseDir = Join-Path $devDir $config.devDirSubfolder
$isDirMissing = -not (Test-Path $baseDir)
if ($isDirMissing) {
    New-Item -Path $baseDir -ItemType Directory -Force | Out-Null
}
Write-Log "llama.cpp base directory: $baseDir" -Level "info"

# -- Execute subcommand --------------------------------------------------------
switch ($Command.ToLower()) {
    "all" {
        # Pre-check disk space for executables
        $exeBytes = Get-TotalDownloadSize -Items $config.executables -SizeBytesField "expectedSizeBytes"
        $isExeDiskOk = Test-DiskSpace -TargetPath $baseDir -RequiredBytes $exeBytes -Label "llama.cpp executables"
        if (-not $isExeDiskOk) { return }

        # Pre-check disk space for models
        $modelBytes = Get-TotalDownloadSize -Items $config.modelItems -SizeHintField "sizeHint"
        $modelsTarget = Join-Path $devDir $config.modelsConfig.devDirSubfolder
        $isModelDiskOk = Test-DiskSpace -TargetPath $modelsTarget -RequiredBytes $modelBytes -Label "GGUF models" -WarnOnly

        Install-LlamaCppExecutables -Config $config -LogMessages $logMessages -BaseDir $baseDir
        Install-LlamaCppModels -Config $config -LogMessages $logMessages -DevDir $devDir
    }
    "executables" {
        $exeBytes = Get-TotalDownloadSize -Items $config.executables -SizeBytesField "expectedSizeBytes"
        $isExeDiskOk = Test-DiskSpace -TargetPath $baseDir -RequiredBytes $exeBytes -Label "llama.cpp executables"
        if (-not $isExeDiskOk) { return }
        Install-LlamaCppExecutables -Config $config -LogMessages $logMessages -BaseDir $baseDir
    }
    "models" {
        $modelBytes = Get-TotalDownloadSize -Items $config.modelItems -SizeHintField "sizeHint"
        $modelsTarget = Join-Path $devDir $config.modelsConfig.devDirSubfolder
        $isModelDiskOk = Test-DiskSpace -TargetPath $modelsTarget -RequiredBytes $modelBytes -Label "GGUF models" -WarnOnly
        Install-LlamaCppModels -Config $config -LogMessages $logMessages -DevDir $devDir
    }
    "uninstall" {
        Uninstall-LlamaCpp -Config $config -LogMessages $logMessages -BaseDir $baseDir
        return
    }
    default {
        Write-Log ($logMessages.messages.unknownCommand -replace '\{command\}', $Command) -Level "error"
        return
    }
}

# -- Save resolved state -------------------------------------------------------
Write-Log $logMessages.messages.savingResolved -Level "info"

$installedSlugs = @()
foreach ($item in $config.executables) {
    $targetFolder = Join-Path $baseDir $item.targetFolderName
    $isPresent = Test-Path $targetFolder
    if ($isPresent) { $installedSlugs += $item.slug }
}

Save-ResolvedData -ScriptFolder "43-install-llama-cpp" -Data @{
    baseDir        = $baseDir
    installedSlugs = $installedSlugs
    timestamp      = (Get-Date -Format "o")
}

Write-Log $logMessages.messages.llamaSetupComplete -Level "success"

# -- Save log ------------------------------------------------------------------

} catch {
    Write-Log "Unhandled error: $_" -Level "error"
    Write-Log "Stack: $($_.ScriptStackTrace)" -Level "error"
} finally {
    # -- Save log (always runs, even on crash) --
    $hasAnyErrors = $script:_LogErrors.Count -gt 0
    Save-LogFile -Status $(if ($hasAnyErrors) { "fail" } else { "ok" })
}