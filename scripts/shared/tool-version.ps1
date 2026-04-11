# --------------------------------------------------------------------------
#  Assert-ToolVersion -- Shared helper for version detection + tracking
#  Extracts the repeated pattern of "run --version, guard empty, check tracking"
#  into a reusable function.
# --------------------------------------------------------------------------

function Assert-ToolVersion {
    <#
    .SYNOPSIS
        Runs a tool's version command, guards against empty output, checks
        .installed/ tracking, and returns a result object.

    .DESCRIPTION
        Consolidates the repeated pattern across all install helpers:
        1. Run `<command> <versionFlag>` (e.g. `python --version`)
        2. Guard against empty/null output
        3. Check .installed/ tracking via Test-AlreadyInstalled
        4. Return a structured result

    .PARAMETER Name
        The tracking name (e.g. "python", "nodejs", "git"). Used for .installed/<name>.json.

    .PARAMETER Command
        The executable command to run (e.g. "python", "node", "git").

    .PARAMETER VersionFlag
        The flag to get version output (default: "--version").

    .PARAMETER ParseScript
        Optional scriptblock to parse the raw version output.
        Receives the raw string and should return a cleaned version string.
        Example: { param($raw) $raw -replace 'Python ', '' }

    .OUTPUTS
        Hashtable with:
          - Exists    [bool]   : Whether the command was found in PATH
          - Version   [string] : The detected version string (or $null)
          - HasVersion [bool]  : Whether a non-empty version was detected
          - IsTracked [bool]   : Whether this exact version is already tracked
          - Raw       [string] : The raw output from the version command

    .EXAMPLE
        $result = Assert-ToolVersion -Name "python" -Command "python"
        if ($result.IsTracked) { Write-Log "Already installed"; return }

    .EXAMPLE
        $result = Assert-ToolVersion -Name "nodejs" -Command "node" -ParseScript {
            param($raw) ($raw -replace 'v', '').Trim()
        }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Command,

        [string]$VersionFlag = "--version",

        [scriptblock]$ParseScript = $null
    )

    $result = @{
        Exists     = $false
        Version    = $null
        HasVersion = $false
        IsTracked  = $false
        Raw        = $null
    }

    # Check if command exists
    $cmdInfo = Get-Command $Command -ErrorAction SilentlyContinue
    $isCommandMissing = -not $cmdInfo
    if ($isCommandMissing) {
        return $result
    }

    $result.Exists = $true

    # Get version output with defensive try/catch
    $rawOutput = $null
    try {
        $rawOutput = & $Command $VersionFlag 2>$null
    } catch {
        # Command exists but version flag failed
    }

    $result.Raw = $rawOutput

    # Parse version
    $version = $rawOutput
    $hasParseScript = $null -ne $ParseScript
    if ($hasParseScript -and $rawOutput) {
        try {
            $version = & $ParseScript $rawOutput
        } catch {
            $version = $rawOutput
        }
    }

    # Clean up
    $isVersionEmpty = [string]::IsNullOrWhiteSpace($version)
    if ($isVersionEmpty) {
        return $result
    }

    $result.Version = "$version".Trim()
    $result.HasVersion = $true

    # Check tracking
    $result.IsTracked = Test-AlreadyInstalled -Name $Name -CurrentVersion $result.Version

    return $result
}


function Refresh-EnvPath {
    <#
    .SYNOPSIS
        Refreshes $env:Path from Machine + User registry values.
        Call after installs/upgrades so newly installed tools are discoverable.
    #>
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}
