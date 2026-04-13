# --------------------------------------------------------------------------
#  llama.cpp helper functions
# --------------------------------------------------------------------------

# -- Bootstrap shared helpers --------------------------------------------------
$_sharedDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "shared"
$_loggingPath = Join-Path $_sharedDir "logging.ps1"
if ((Test-Path $_loggingPath) -and -not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    . $_loggingPath
}


function Get-FileSize {
    <#
    .SYNOPSIS
        Returns file size in MB, or -1 if file doesn't exist.
    #>
    param([string]$FilePath)
    $isFilePresent = Test-Path $FilePath
    if (-not $isFilePresent) { return -1 }
    $info = Get-Item $FilePath
    return [math]::Round($info.Length / (1024 * 1024), 2)
}

function Test-ZipIntegrity {
    <#
    .SYNOPSIS
        Validates a ZIP file by checking the magic header bytes (PK\x03\x04)
        and optionally comparing against an expected file size.
        Returns $true if the file appears valid.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [long]$ExpectedSizeBytes = 0,

        [double]$SizeTolerancePercent = 10
    )

    $isFilePresent = Test-Path $FilePath
    if (-not $isFilePresent) { return $false }

    $fileInfo = Get-Item $FilePath
    $isFileEmpty = $fileInfo.Length -eq 0
    if ($isFileEmpty) { return $false }

    # Check ZIP magic bytes: PK\x03\x04
    try {
        $header = [byte[]]::new(4)
        $stream = [System.IO.File]::OpenRead($FilePath)
        try {
            $bytesRead = $stream.Read($header, 0, 4)
            $hasEnoughBytes = $bytesRead -eq 4
            if (-not $hasEnoughBytes) { return $false }
        } finally {
            $stream.Close()
        }

        $isValidHeader = ($header[0] -eq 0x50) -and ($header[1] -eq 0x4B) -and ($header[2] -eq 0x03) -and ($header[3] -eq 0x04)
        if (-not $isValidHeader) { return $false }
    } catch {
        return $false
    }

    # Check expected size if provided
    $hasExpectedSize = $ExpectedSizeBytes -gt 0
    if ($hasExpectedSize) {
        $tolerance = $ExpectedSizeBytes * ($SizeTolerancePercent / 100)
        $minSize = $ExpectedSizeBytes - $tolerance
        $isTooSmall = $fileInfo.Length -lt $minSize
        if ($isTooSmall) { return $false }
    }

    return $true
}

function Install-LlamaCppExecutables {
    <#
    .SYNOPSIS
        Downloads all llama.cpp executable variants, extracts ZIPs, and adds bin
        folders to user PATH.
    #>
    param(
        $Config,
        $LogMessages,
        [string]$BaseDir
    )

    $executables = $Config.executables
    $pathConfig = $Config.path

    foreach ($item in $executables) {
        Write-Log ($LogMessages.messages.processingExecutable -replace '\{slug\}', $item.slug -replace '\{displayName\}', $item.displayName) -Level "info"
        Write-Log ($LogMessages.messages.downloading -replace '\{url\}', $item.downloadUrl) -Level "info"

        # Resolve target folder
        $targetFolder = Join-Path $BaseDir $item.targetFolderName
        $isDirMissing = -not (Test-Path $targetFolder)
        if ($isDirMissing) {
            New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
        }

        # Determine output path
        $outputPath = Join-Path $BaseDir $item.outputFileName
        Write-Log ($LogMessages.messages.downloadingTo -replace '\{path\}', $outputPath) -Level "info"

        # Check if already downloaded
        $fileSize = Get-FileSize -FilePath $outputPath
        $isAlreadyDownloaded = $fileSize -gt 0
        if ($isAlreadyDownloaded) {
            # For ZIPs, also check if extraction target exists
            $isZip = $item.isZip
            if ($isZip) {
                $binSubfolder = $item.relativeBinSubfolder
                $binPath = if ($binSubfolder) { Join-Path $targetFolder $binSubfolder } else { $targetFolder }
                $isBinPresent = Test-Path $binPath
                if ($isBinPresent) {
                    Write-Log ($LogMessages.messages.downloadSkipped -replace '\{path\}', $outputPath -replace '\{size\}', $fileSize) -Level "info"
                    # Still ensure PATH
                    Ensure-BinInPath -Config $pathConfig -LogMessages $LogMessages -BinPath $binPath
                    continue
                }
            } else {
                Write-Log ($LogMessages.messages.downloadSkipped -replace '\{path\}', $outputPath -replace '\{size\}', $fileSize) -Level "info"
                Ensure-BinInPath -Config $pathConfig -LogMessages $LogMessages -BinPath $targetFolder
                continue
            }
        }

        # Download
        $isDownloadOk = Invoke-DownloadWithRetry -Uri $item.downloadUrl -OutFile $outputPath -Label $item.displayName
        if (-not $isDownloadOk) {
            Write-Log ($LogMessages.messages.downloadFailed -replace '\{slug\}', $item.slug -replace '\{error\}', "All download attempts failed") -Level "error"
            Write-FileError -FilePath $outputPath -Operation "download" -Reason "Download failed after retries" -Module "Install-LlamaCppExecutables"
            continue
        }
        Write-Log ($LogMessages.messages.downloadSuccess -replace '\{fileName\}', $item.outputFileName) -Level "success"

        # Extract if ZIP
        $isZip = $item.isZip
        if ($isZip) {
            Write-Log ($LogMessages.messages.extracting -replace '\{path\}', $targetFolder) -Level "info"
            try {
                Expand-Archive -Path $outputPath -DestinationPath $targetFolder -Force
                Write-Log ($LogMessages.messages.extractSuccess -replace '\{path\}', $targetFolder) -Level "success"
            } catch {
                Write-Log ($LogMessages.messages.extractFailed -replace '\{slug\}', $item.slug -replace '\{error\}', $_) -Level "error"
                Write-FileError -FilePath $outputPath -Operation "extract" -Reason "$_" -Module "Install-LlamaCppExecutables"
                continue
            }
        }

        # Verify executable exists
        $binSubfolder = $item.relativeBinSubfolder
        $binPath = if ($binSubfolder) { Join-Path $targetFolder $binSubfolder } else { $targetFolder }
        $verifyExePath = Join-Path $binPath $item.verifyExe
        $isExePresent = Test-Path $verifyExePath
        if ($isExePresent) {
            Write-Log ($LogMessages.messages.verifyExeFound -replace '\{exe\}', $verifyExePath) -Level "success"
        } else {
            # For ZIPs that extract with a nested folder, search for the exe
            $foundExe = Get-ChildItem -Path $targetFolder -Recurse -Filter $item.verifyExe -ErrorAction SilentlyContinue | Select-Object -First 1
            $hasFoundExe = $null -ne $foundExe
            if ($hasFoundExe) {
                $binPath = $foundExe.DirectoryName
                Write-Log ($LogMessages.messages.verifyExeFound -replace '\{exe\}', $foundExe.FullName) -Level "success"
            } else {
                Write-Log ($LogMessages.messages.verifyExeMissing -replace '\{exe\}', $item.verifyExe) -Level "warn"
            }
        }

        # Add to PATH
        $isAddToPath = $item.addToPath
        if ($isAddToPath) {
            Ensure-BinInPath -Config $pathConfig -LogMessages $LogMessages -BinPath $binPath
        }

        # Track install
        Save-InstalledRecord -Name "llama-cpp-$($item.slug)" -Version $item.slug
    }

    # Refresh PATH for current session
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Log $LogMessages.messages.sessionRefreshed -Level "success"
    Write-Log $LogMessages.messages.allExecutablesComplete -Level "success"
}

function Ensure-BinInPath {
    param(
        $Config,
        $LogMessages,
        [string]$BinPath
    )

    $isUpdateDisabled = -not $Config.updateUserPath
    if ($isUpdateDisabled) { return }

    $isAlreadyInPath = Test-InPath -Directory $BinPath
    if ($isAlreadyInPath) {
        Write-Log ($LogMessages.messages.pathAlreadySet -replace '\{path\}', $BinPath) -Level "info"
    } else {
        Write-Log ($LogMessages.messages.pathAdding -replace '\{path\}', $BinPath) -Level "info"
        Add-ToUserPath -Directory $BinPath
    }
}

function Install-LlamaCppModels {
    <#
    .SYNOPSIS
        Downloads GGUF model files to the models directory.
    #>
    param(
        $Config,
        $LogMessages,
        [string]$DevDir
    )

    Write-Log $LogMessages.messages.processingModels -Level "info"

    # Resolve models directory
    $defaultModelsDir = if ($DevDir) {
        Join-Path $DevDir $Config.modelsConfig.devDirSubfolder
    } else {
        Join-Path (Get-SafeDevDirFallback) $Config.modelsConfig.devDirSubfolder
    }

    $modelsDir = $defaultModelsDir

    # Prompt user if configured (skip under orchestrator)
    $isOrchestratorRun = $env:SCRIPTS_ROOT_RUN -eq "1"
    $isPromptEnabled = $Config.modelsConfig.promptForDirectory
    if ($isPromptEnabled -and -not $isOrchestratorRun) {
        Write-Host ""
        Write-Host "  Default models directory: $defaultModelsDir" -ForegroundColor Cyan
        $userInput = Read-Host -Prompt "  $($LogMessages.messages.modelsDirPrompt) [$defaultModelsDir]"
        $hasUserInput = -not [string]::IsNullOrWhiteSpace($userInput)
        if ($hasUserInput) {
            $modelsDir = $userInput.Trim()
        }
    } elseif ($isOrchestratorRun) {
        Write-Log "Orchestrator mode: using default models directory: $defaultModelsDir" -Level "info"
    }

    # Create directory
    $isDirMissing = -not (Test-Path $modelsDir)
    if ($isDirMissing) {
        New-Item -Path $modelsDir -ItemType Directory -Force | Out-Null
    }

    Write-Log ($LogMessages.messages.modelsDirConfigured -replace '\{path\}', $modelsDir) -Level "info"

    # Process each model
    $models = $Config.modelItems
    foreach ($model in $models) {
        $outputPath = Join-Path $modelsDir $model.fileName

        # Check if already exists
        $fileSize = Get-FileSize -FilePath $outputPath
        $isAlreadyDownloaded = $fileSize -gt 0
        if ($isAlreadyDownloaded) {
            Write-Log ($LogMessages.messages.modelExists -replace '\{name\}', $model.displayName -replace '\{size\}', $fileSize) -Level "info"
            continue
        }

        Write-Log ($LogMessages.messages.modelDownloading -replace '\{name\}', $model.displayName -replace '\{size\}', $model.sizeHint) -Level "info"

        $isDownloadOk = Invoke-DownloadWithRetry -Uri $model.downloadUrl -OutFile $outputPath -Label $model.displayName
        if ($isDownloadOk) {
            Write-Log ($LogMessages.messages.modelDownloadSuccess -replace '\{name\}', $model.displayName) -Level "success"
        } else {
            Write-Log ($LogMessages.messages.modelDownloadFailed -replace '\{name\}', $model.displayName -replace '\{error\}', "All download attempts failed") -Level "error"
            Write-FileError -FilePath $outputPath -Operation "download" -Reason "$_" -Module "Install-LlamaCppModels"
        }
    }

    Write-Log $LogMessages.messages.allModelsComplete -Level "success"
    return $modelsDir
}

function Uninstall-LlamaCpp {
    <#
    .SYNOPSIS
        Removes all llama.cpp binaries, cleans PATH entries, purges tracking.
    #>
    param(
        $Config,
        $LogMessages,
        [string]$BaseDir
    )

    Write-Log ($LogMessages.messages.uninstalling -replace '\{name\}', "llama.cpp") -Level "info"

    foreach ($item in $Config.executables) {
        $targetFolder = Join-Path $BaseDir $item.targetFolderName
        $binSubfolder = $item.relativeBinSubfolder
        $binPath = if ($binSubfolder) { Join-Path $targetFolder $binSubfolder } else { $targetFolder }

        # Remove from PATH
        Remove-FromUserPath -Directory $binPath

        # Remove folder
        $isFolderPresent = Test-Path $targetFolder
        if ($isFolderPresent) {
            Write-Log "Removing: $targetFolder" -Level "info"
            Remove-Item -Path $targetFolder -Recurse -Force
        }

        # Remove downloaded file
        $outputPath = Join-Path $BaseDir $item.outputFileName
        $isFilePresent = Test-Path $outputPath
        if ($isFilePresent) {
            Remove-Item -Path $outputPath -Force
        }

        # Remove tracking
        Remove-InstalledRecord -Name "llama-cpp-$($item.slug)"
    }

    Remove-ResolvedData -ScriptFolder "43-install-llama-cpp"

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    Write-Log $LogMessages.messages.uninstallComplete -Level "success"
}