# --------------------------------------------------------------------------
#  Installation tracking helpers
#  Tracks installed tool versions in .installed/ at project root.
#  Auto-loaded by logging.ps1 -- no manual sourcing needed.
# --------------------------------------------------------------------------

# Resolve .installed/ directory at project root
$script:_InstalledDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) ".installed"

function Get-InstalledRecord {
    <#
    .SYNOPSIS
        Reads the .installed/<name>.json tracking file for a tool.
        Returns $null if no record exists.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $filePath = Join-Path $script:_InstalledDir "$Name.json"
    $isFileMissing = -not (Test-Path $filePath)
    if ($isFileMissing) { return $null }

    return Get-Content $filePath -Raw | ConvertFrom-Json
}

function Test-AlreadyInstalled {
    <#
    .SYNOPSIS
        Returns $true if the tool was previously installed at exactly this version.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$CurrentVersion
    )

    $record = Get-InstalledRecord -Name $Name
    $hasNoRecord = -not $record
    if ($hasNoRecord) { return $false }

    $isVersionMatch = $record.version -eq $CurrentVersion
    return $isVersionMatch
}

function Save-InstalledRecord {
    <#
    .SYNOPSIS
        Writes a tracking file to .installed/<name>.json after successful installation.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Version,

        [string]$Method = "chocolatey"
    )

    $isDirMissing = -not (Test-Path $script:_InstalledDir)
    if ($isDirMissing) {
        New-Item -Path $script:_InstalledDir -ItemType Directory -Force | Out-Null
    }

    $data = @{
        name        = $Name
        version     = $Version
        method      = $Method
        installedAt = (Get-Date -Format "o")
        installedBy = $env:USERNAME
    }

    $filePath = Join-Path $script:_InstalledDir "$Name.json"
    $data | ConvertTo-Json -Depth 3 | Set-Content -Path $filePath -Encoding UTF8

    Write-Log "Saved install record: .installed/$Name.json ($Version)" -Level "info"
}
