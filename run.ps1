<#
.SYNOPSIS
    Root-level script dispatcher. Runs a numbered script after pulling latest changes.

.DESCRIPTION
    Performs a git pull via the shared helper, sets $env:SCRIPTS_ROOT_RUN = "1"
    so child scripts skip their own git pull, then delegates to
    scripts/<NN>-*/run.ps1 based on the -I parameter.

    When run with no parameters, performs a git pull and shows help.
    Use -Install to run scripts by keyword (e.g. -Install vscode,python,go).
    Use -Clean to wipe all .resolved/ data before running, forcing fresh detection.
    Use -CleanOnly to wipe .resolved/ without running any script.
    Use -Help to see all available scripts and usage information.
    Use 'update' command to upgrade all Chocolatey packages.

.PARAMETER I
    The script number to run (e.g. 1, 2, 3). Maps to folders like 01-*, 02-*, etc.

.PARAMETER Install
    Comma-separated keywords to install (e.g. vscode, nodejs, python, go, git).
    See install-keywords.json for the full mapping.

.PARAMETER Clean
    Wipe all .resolved/ data before running the script.

.PARAMETER CleanOnly
    Wipe all .resolved/ data and exit without running any script.

.PARAMETER Help
    Show usage information and list all available scripts.

.EXAMPLE
    .\run.ps1                        # git pull, show help
    .\run.ps1 -Install vscode        # install VS Code
    .\run.ps1 -Install nodejs,pnpm   # install Node.js + pnpm
    .\run.ps1 -Install python        # install Python + pip
    .\run.ps1 -Install go,git,cpp    # install Go, Git, and C++
    .\run.ps1 -Install all-dev       # interactive dev tools menu
    .\run.ps1 update                 # upgrade all Chocolatey packages
    .\run.ps1 path D:\devtools       # set default dev directory
    .\run.ps1 path                   # show current dev directory
    .\run.ps1 path --reset           # clear saved path, use smart detection
    .\run.ps1 -d                     # shortcut for -I 12 (interactive menu)
    .\run.ps1 -I 1                   # run scripts/01-*/run.ps1
    .\run.ps1 -I 1 -Clean           # wipe .resolved/, then run script 01
    .\run.ps1 -CleanOnly             # wipe .resolved/ and exit
    .\run.ps1 -Help                  # show all available scripts

.NOTES
    Author : Lovable AI
    Version: 7.2.0
#>

param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Install,

    [int]$I,

    [switch]$d,

    [switch]$a,

    [switch]$h,

    [switch]$v,

    [switch]$w,

    [switch]$t,

    [switch]$Defaults,

    [switch]$Y,

    [switch]$Merge,

    [switch]$Clean,

    [switch]$CleanOnly,

    [switch]$List,

    [switch]$Help
)

$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# ── Read project version ─────────────────────────────────────────────
function Get-ScriptVersion {
    $vf = Join-Path (Join-Path $RootDir "scripts") "version.json"
    $isPresent = Test-Path $vf
    if ($isPresent) {
        $data = Get-Content $vf -Raw | ConvertFrom-Json
        return $data.version
    }
    return $null
}

function Show-VersionHeader {
    $ver = Get-ScriptVersion
    $hasVersion = -not [string]::IsNullOrWhiteSpace($ver)
    if ($hasVersion) {
        Write-Host ""
        Write-Host "  Scripts Fixer v$ver" -ForegroundColor Magenta
    }
}

# ── Help function ────────────────────────────────────────────────────
function Show-RootHelp {
    Show-VersionHeader
    Write-Host ""
    Write-Host "  Dev Tools Setup Scripts" -ForegroundColor Cyan
    Write-Host "  =======================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Usage:" -ForegroundColor Yellow
    Write-Host ""
    $col = 42
    Write-Host "    $(".\run.ps1 install <keywords>".PadRight($col))" -NoNewline; Write-Host "Install by keyword (bare command)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -Install <keywords>".PadRight($col))" -NoNewline; Write-Host "Install by keyword (named parameter)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 update".PadRight($col))" -NoNewline; Write-Host "Upgrade all Chocolatey packages" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 path <dir>".PadRight($col))" -NoNewline; Write-Host "Set default dev directory" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 path".PadRight($col))" -NoNewline; Write-Host "Show current dev directory" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 path --reset".PadRight($col))" -NoNewline; Write-Host "Clear saved path, use smart detection" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -I <number>".PadRight($col))" -NoNewline; Write-Host "Run a specific script by ID" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -d".PadRight($col))" -NoNewline; Write-Host "Shortcut for -I 12 (interactive menu)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -a".PadRight($col))" -NoNewline; Write-Host "Shortcut for -I 13 (audit mode)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -h".PadRight($col))" -NoNewline; Write-Host "Shortcut for -I 13 -Report (health check)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -v".PadRight($col))" -NoNewline; Write-Host "Shortcut for -I 1  (install VS Code)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -w".PadRight($col))" -NoNewline; Write-Host "Shortcut for -I 14 (install Winget)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -t".PadRight($col))" -NoNewline; Write-Host "Shortcut for -I 15 (Windows tweaks)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -Defaults".PadRight($col))" -NoNewline; Write-Host "Use all defaults, prompt to confirm" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -Defaults -Y".PadRight($col))" -NoNewline; Write-Host "Use all defaults, skip confirmation" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -I <number> -Merge".PadRight($col))" -NoNewline; Write-Host "Run with merge flag (script 02)" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -I <number> -Clean".PadRight($col))" -NoNewline; Write-Host "Wipe cache, then run" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -CleanOnly".PadRight($col))" -NoNewline; Write-Host "Wipe all cached data" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -Help".PadRight($col))" -NoNewline; Write-Host "Show this help" -ForegroundColor DarkGray
    Write-Host "    $(".\run.ps1 -List".PadRight($col))" -NoNewline; Write-Host "Show keyword table only" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Install by Keyword:" -ForegroundColor Yellow
    Write-Host ""
    $kc = 42
    Write-Host "    $("install vscode".PadRight($kc))" -NoNewline; Write-Host "Install Visual Studio Code" -ForegroundColor DarkGray
    Write-Host "    $("install nodejs".PadRight($kc))" -NoNewline; Write-Host "Install Node.js + Yarn + Bun" -ForegroundColor DarkGray
    Write-Host "    $("install pnpm".PadRight($kc))" -NoNewline; Write-Host "Install Node.js + pnpm (auto-chains)" -ForegroundColor DarkGray
    Write-Host "    $("install python".PadRight($kc))" -NoNewline; Write-Host "Install Python + pip" -ForegroundColor DarkGray
    Write-Host "    $("install go".PadRight($kc))" -NoNewline; Write-Host "Install Go + configure GOPATH" -ForegroundColor DarkGray
    Write-Host "    $("install git".PadRight($kc))" -NoNewline; Write-Host "Install Git + LFS + GitHub CLI" -ForegroundColor DarkGray
    Write-Host "    $("install cpp".PadRight($kc))" -NoNewline; Write-Host "Install C++ MinGW-w64 compiler" -ForegroundColor DarkGray
    Write-Host "    $("install php".PadRight($kc))" -NoNewline; Write-Host "Install PHP via Chocolatey" -ForegroundColor DarkGray
    Write-Host "    $("install powershell".PadRight($kc))" -NoNewline; Write-Host "Install latest PowerShell" -ForegroundColor DarkGray
    Write-Host "    $("install winget".PadRight($kc))" -NoNewline; Write-Host "Install Winget package manager" -ForegroundColor DarkGray
    Write-Host "    $("install settingssync".PadRight($kc))" -NoNewline; Write-Host "Sync VSCode settings + extensions" -ForegroundColor DarkGray
    Write-Host "    $("install contextmenu".PadRight($kc))" -NoNewline; Write-Host "Fix VSCode right-click context menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Database installs:" -ForegroundColor Magenta
    Write-Host "    $("install databases".PadRight($kc))" -NoNewline; Write-Host "Open the interactive database installer menu" -ForegroundColor DarkGray
    Write-Host "    $("install mysql".PadRight($kc))" -NoNewline; Write-Host "Install MySQL database" -ForegroundColor DarkGray
    Write-Host "    $("install postgresql".PadRight($kc))" -NoNewline; Write-Host "Install PostgreSQL database" -ForegroundColor DarkGray
    Write-Host "    $("install sqlite".PadRight($kc))" -NoNewline; Write-Host "Install SQLite + DB Browser for SQLite" -ForegroundColor DarkGray
    Write-Host "    $("install mongodb,redis".PadRight($kc))" -NoNewline; Write-Host "Install MongoDB + Redis" -ForegroundColor DarkGray
    Write-Host "    $("install alldev".PadRight($kc))" -NoNewline; Write-Host "Interactive dev tools menu (pick what to install)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Combine keywords:" -ForegroundColor Magenta
    Write-Host "    $("install nodejs,pnpm".PadRight($kc))" -NoNewline; Write-Host "Install Node.js + pnpm" -ForegroundColor DarkGray
    Write-Host "    $("install go,git,cpp".PadRight($kc))" -NoNewline; Write-Host "Install Go, Git, and C++" -ForegroundColor DarkGray
    Write-Host "    $("install python,php".PadRight($kc))" -NoNewline; Write-Host "Install Python + PHP" -ForegroundColor DarkGray
    Write-Host "    $("install vscode,nodejs,git".PadRight($kc))" -NoNewline; Write-Host "Install VS Code, Node.js, and Git" -ForegroundColor DarkGray
    Write-Host "    $("install alldev,mysql".PadRight($kc))" -NoNewline; Write-Host "Run the alldev menu, then install MySQL" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Available Keywords:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    Keyword              Maps to                         Script ID" -ForegroundColor DarkGray
    Write-Host "    -------------------  ------------------------------  ---------" -ForegroundColor DarkGray
    Write-Host "    vscode, vs-code      VS Code                         01"
    Write-Host "    choco, chocolatey    Chocolatey                      02"
    Write-Host "    nodejs, node         Node.js + Yarn + Bun            03"
    Write-Host "    pnpm                 Node.js + pnpm                  03, 04"
    Write-Host "    python, pip          Python + pip                    05"
    Write-Host "    go, golang           Go                              06"
    Write-Host "    git, gh              Git + LFS + GitHub CLI          07"
    Write-Host "    github-desktop       GitHub Desktop                  08"
    Write-Host "    cpp, c++, gcc        C++ (MinGW-w64)                 09"
    Write-Host "    context-menu         VSCode context menu fix         10"
    Write-Host "    settings-sync        VSCode settings sync            11"
    Write-Host "    all-dev, all         Interactive dev tools menu      12"
    Write-Host "    audit                Audit mode                      13"
    Write-Host "    health, healthcheck  Health check (audit + report)   13"
    Write-Host "    winget               Winget package manager          14"
    Write-Host "    tweaks               Windows tweaks                  15"
    Write-Host "    php, php+phpmyadmin  PHP + phpMyAdmin (default)      16"
    Write-Host "    php-only             PHP only                        16"
    Write-Host "    phpmyadmin           phpMyAdmin only                 16"
    Write-Host "    powershell, pwsh     PowerShell (latest)             17"
    Write-Host "    mysql                MySQL                           18"
    Write-Host "    mariadb              MariaDB                         19"
    Write-Host "    postgresql, postgres PostgreSQL                      20"
    Write-Host "    sqlite               SQLite + DB Browser            21"
    Write-Host "    mongodb, mongo       MongoDB                         22"
    Write-Host "    couchdb              CouchDB                         23"
    Write-Host "    redis                Redis                           24"
    Write-Host "    cassandra            Apache Cassandra                25"
    Write-Host "    neo4j                Neo4j                           26"
    Write-Host "    elasticsearch        Elasticsearch                   27"
    Write-Host "    duckdb               DuckDB                          28"
    Write-Host "    litedb               LiteDB                          29"
    Write-Host "    databases, db        Database installer menu         30"
    Write-Host "    notepad++, npp       NPP + Settings (install + sync)  33"
    Write-Host "    npp+settings         NPP + Settings (explicit)       33"
    Write-Host "    npp-settings         NPP Settings (settings only)    33"
    Write-Host "    install-npp          Install NPP (install only)      33"
    Write-Host "    sticky-notes, sticky  Simple Sticky Notes             34"
    Write-Host "    gitmap, git-map      GitMap CLI                      35"
    Write-Host "    obs, obs+settings    OBS + Settings (install + sync)  36"
    Write-Host "    obs-settings         OBS Settings (settings only)    36"
    Write-Host "    install-obs          Install OBS (install only)      36"
    Write-Host "    wt, windows-terminal WT + Settings (install + sync)  37"
    Write-Host "    wt+settings          WT + Settings (explicit)        37"
    Write-Host "    wt-settings          WT Settings (settings only)     37"
    Write-Host "    install-wt           Install WT (install only)       37"
    Write-Host ""
    Write-Host "  Combo Shortcuts:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    vscode+settings, vscode+s   VSCode + Settings Sync        01, 11"
    Write-Host "    vscode+menu+settings, vms   VSCode + Menu Fix + Sync      01, 10, 11"
    Write-Host "    git+desktop, git+gh         Git + GitHub Desktop           07, 08"
    Write-Host "    node+pnpm                   Node.js + pnpm                03, 04"
    Write-Host "    frontend                    VSCode + Node + pnpm + Sync   01, 03, 04, 11"
    Write-Host "    backend                     Python + Go + PHP + Postgres  05, 06, 16, 20"
    Write-Host "    web-dev, webdev             VSCode + Node + pnpm + Git    01, 03, 04, 07, 11"
    Write-Host "    essentials                  VSCode + Choco + Node + Git   01, 02, 03, 07, 11"
    Write-Host "    full-stack, fullstack       Everything for full-stack dev 01-09, 11, 16"
    Write-Host ""
    Write-Host "  Available Scripts:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    ID  Name                          Description" -ForegroundColor DarkGray
    Write-Host "    --  ----------------------------  ------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Core Tools" -ForegroundColor Magenta
    Write-Host "    01  Install VS Code               " -NoNewline; Write-Host "Install Visual Studio Code (Stable/Insiders)" -ForegroundColor DarkGray
    Write-Host "    02  Chocolatey                    " -NoNewline; Write-Host "Install Chocolatey package manager" -ForegroundColor DarkGray
    Write-Host "    03  Node.js + Yarn + Bun          " -NoNewline; Write-Host "Install Node.js LTS, Yarn, Bun, verify npx" -ForegroundColor DarkGray
    Write-Host "    04  pnpm                          " -NoNewline; Write-Host "Install pnpm, configure global store" -ForegroundColor DarkGray
    Write-Host "    05  Python                        " -NoNewline; Write-Host "Install Python, configure pip user site" -ForegroundColor DarkGray
    Write-Host "    06  Golang                        " -NoNewline; Write-Host "Install Go, configure GOPATH and go env" -ForegroundColor DarkGray
    Write-Host "    07  Git + LFS + gh                " -NoNewline; Write-Host "Install Git, Git LFS, GitHub CLI, configure settings" -ForegroundColor DarkGray
    Write-Host "    08  GitHub Desktop                " -NoNewline; Write-Host "Install GitHub Desktop via Chocolatey" -ForegroundColor DarkGray
    Write-Host "    09  C++ (MinGW-w64)               " -NoNewline; Write-Host "Install MinGW-w64 C++ compiler, verify g++/gcc/make" -ForegroundColor DarkGray
    Write-Host "    16  PHP                           " -NoNewline; Write-Host "Install PHP via Chocolatey" -ForegroundColor DarkGray
    Write-Host "    17  PowerShell (latest)           " -NoNewline; Write-Host "Install latest PowerShell via Winget/Chocolatey" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Optional" -ForegroundColor Magenta
    Write-Host "    10  VSCode Context Menu Fix       " -NoNewline; Write-Host "Add/repair VSCode right-click context menu entries" -ForegroundColor DarkGray
    Write-Host "    11  VSCode Settings Sync          " -NoNewline; Write-Host "Sync VSCode settings, keybindings, and extensions" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Orchestrator" -ForegroundColor Magenta
    Write-Host "    12  Install All Dev Tools         " -NoNewline; Write-Host "Interactive grouped menu: pick tools or install everything" -ForegroundColor DarkGray
    Write-Host "    30  Install Databases             " -NoNewline; Write-Host "Interactive database installer (SQL, NoSQL, file-based)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Utilities" -ForegroundColor Magenta
    Write-Host "    13  Audit Mode                    " -NoNewline; Write-Host "Scan configs, specs, suggestions for stale IDs" -ForegroundColor DarkGray
    Write-Host "    14  Install Winget                " -NoNewline; Write-Host "Install/verify Winget package manager (standalone)" -ForegroundColor DarkGray
    Write-Host "    15  Windows Tweaks                " -NoNewline; Write-Host "Chris Titus Windows Utility (tweaks and debloating)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Database Tools" -ForegroundColor Magenta
    Write-Host "    32  DBeaver Community              " -NoNewline; Write-Host "Universal database visualization and management tool" -ForegroundColor DarkGray
    Write-Host "    33  Notepad++ (NPP)                " -NoNewline; Write-Host "Install NPP, NPP Settings, or NPP + Settings" -ForegroundColor DarkGray
    Write-Host "    34  Simple Sticky Notes           " -NoNewline; Write-Host "Install Simple Sticky Notes via Chocolatey" -ForegroundColor DarkGray
    Write-Host "    35  GitMap                         " -NoNewline; Write-Host "Git repository navigator CLI tool" -ForegroundColor DarkGray
    Write-Host "    36  OBS Studio                     " -NoNewline; Write-Host "Install OBS, OBS Settings, or OBS + Settings" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Script 12 (Install All Dev Tools):" -ForegroundColor Yellow
    Write-Host "    .\run.ps1 -I 12                         " -NoNewline; Write-Host "Interactive menu -- pick what to install" -ForegroundColor DarkGray
    Write-Host "    .\run.ps1 -I 12 -- -All                 " -NoNewline; Write-Host "Install everything without prompting" -ForegroundColor DarkGray
    Write-Host "    .\run.ps1 -I 12 -- -Skip 04,06          " -NoNewline; Write-Host "Skip pnpm and Go" -ForegroundColor DarkGray
    Write-Host "    .\run.ps1 -I 12 -- -Only 02,03          " -NoNewline; Write-Host "Run only Package Managers + Node.js" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Defaults Mode:" -ForegroundColor Yellow
    Write-Host "    .\run.ps1 -d -Defaults                  " -NoNewline; Write-Host "All-dev with defaults, prompt to confirm" -ForegroundColor DarkGray
    Write-Host "    .\run.ps1 -d -Defaults -Y               " -NoNewline; Write-Host "All-dev with defaults, auto-confirm" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Default dev directory: " -NoNewline -ForegroundColor DarkGray; Write-Host "E:\dev-tool (smart detection: E: > D: > best drive)" -ForegroundColor White
    Write-Host "    Override with: " -NoNewline -ForegroundColor DarkGray; Write-Host ".\run.ps1 -I 12 -- -Path F:\dev-tool" -ForegroundColor White
    Write-Host "    Default VS Code edition: " -NoNewline -ForegroundColor DarkGray; Write-Host "Stable" -ForegroundColor White
    Write-Host "    Default sync mode: " -NoNewline -ForegroundColor DarkGray; Write-Host "Overwrite" -ForegroundColor White
    Write-Host ""
    Write-Host "  Per-script help:" -ForegroundColor Yellow
    Write-Host "    .\run.ps1 -I <number> -- -Help          " -NoNewline; Write-Host "Show help for a specific script" -ForegroundColor DarkGray
    Write-Host ""
}

# ── Keyword table (compact view) ────────────────────────────────────
function Show-KeywordTable {
    Write-Host ""
    Write-Host "  Available Keywords" -ForegroundColor Cyan
    Write-Host "  ==================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Keyword              Maps to                         Script ID" -ForegroundColor DarkGray
    Write-Host "    -------------------  ------------------------------  ---------" -ForegroundColor DarkGray
    Write-Host "    vscode, vs-code      VS Code                         01"
    Write-Host "    choco, chocolatey    Chocolatey                      02"
    Write-Host "    nodejs, node         Node.js + Yarn + Bun            03"
    Write-Host "    pnpm                 Node.js + pnpm                  03, 04"
    Write-Host "    python, pip          Python + pip                    05"
    Write-Host "    go, golang           Go                              06"
    Write-Host "    git, gh              Git + LFS + GitHub CLI          07"
    Write-Host "    github-desktop       GitHub Desktop                  08"
    Write-Host "    cpp, c++, gcc        C++ (MinGW-w64)                 09"
    Write-Host "    context-menu         VSCode context menu fix         10"
    Write-Host "    settings-sync        VSCode settings sync            11"
    Write-Host "    all-dev, all         Interactive dev tools menu      12"
    Write-Host "    audit                Audit mode                      13"
    Write-Host "    health, healthcheck  Health check (audit + report)   13"
    Write-Host "    winget               Winget package manager          14"
    Write-Host "    tweaks               Windows tweaks                  15"
    Write-Host "    php, php+phpmyadmin  PHP + phpMyAdmin (default)      16"
    Write-Host "    php-only             PHP only                        16"
    Write-Host "    phpmyadmin           phpMyAdmin only                 16"
    Write-Host "    powershell, pwsh     PowerShell (latest)             17"
    Write-Host "    mysql                MySQL                           18"
    Write-Host "    mariadb              MariaDB                         19"
    Write-Host "    postgresql, postgres PostgreSQL                      20"
    Write-Host "    sqlite               SQLite + DB Browser            21"
    Write-Host "    mongodb, mongo       MongoDB                         22"
    Write-Host "    couchdb              CouchDB                         23"
    Write-Host "    redis                Redis                           24"
    Write-Host "    cassandra            Apache Cassandra                25"
    Write-Host "    neo4j                Neo4j                           26"
    Write-Host "    elasticsearch        Elasticsearch                   27"
    Write-Host "    duckdb               DuckDB                          28"
    Write-Host "    litedb               LiteDB                          29"
    Write-Host "    databases, db        Database installer menu         30"
    Write-Host "    pwsh-menu            PowerShell context menu         31"
    Write-Host "    notepad++, npp       NPP + Settings (install + sync)  33"
    Write-Host "    npp+settings         NPP + Settings (explicit)       33"
    Write-Host "    npp-settings         NPP Settings (settings only)    33"
    Write-Host "    install-npp          Install NPP (install only)      33"
    Write-Host "    sticky-notes, sticky  Simple Sticky Notes             34"
    Write-Host "    gitmap, git-map      GitMap CLI                      35"
    Write-Host "    obs, obs+settings    OBS + Settings (install + sync)  36"
    Write-Host "    obs-settings         OBS Settings (settings only)    36"
    Write-Host "    install-obs          Install OBS (install only)      36"
    Write-Host "    wt, windows-terminal WT + Settings (install + sync)  37"
    Write-Host "    wt+settings          WT + Settings (explicit)        37"
    Write-Host "    wt-settings          WT Settings (settings only)     37"
    Write-Host "    install-wt           Install WT (install only)       37"
    Write-Host ""
    Write-Host "  Combo Shortcuts:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    vscode+settings, vscode+s   VSCode + Settings Sync        01, 11"
    Write-Host "    vscode+menu+settings, vms   VSCode + Menu Fix + Sync      01, 10, 11"
    Write-Host "    git+desktop, git+gh         Git + GitHub Desktop           07, 08"
    Write-Host "    node+pnpm                   Node.js + pnpm                03, 04"
    Write-Host "    frontend                    VSCode + Node + pnpm + Sync   01, 03, 04, 11"
    Write-Host "    backend                     Python + Go + PHP + Postgres  05, 06, 16, 20"
    Write-Host "    web-dev, webdev             VSCode + Node + pnpm + Git    01, 03, 04, 07, 11"
    Write-Host "    essentials                  VSCode + Choco + Node + Git   01, 02, 03, 07, 11"
    Write-Host "    full-stack, fullstack       Everything for full-stack dev 01-09, 11, 16"
    Write-Host ""
    Write-Host "  Usage: " -NoNewline -ForegroundColor Yellow; Write-Host ".\run.ps1 install <keyword>[,<keyword>,...]"
    Write-Host ""
}

function Resolve-InstallKeywords {
    param(
        [string[]]$Keywords
    )

    $keywordsFile = Join-Path $RootDir "scripts\shared\install-keywords.json"
    $isKeywordsFileMissing = -not (Test-Path $keywordsFile)
    if ($isKeywordsFileMissing) {
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "Keyword mapping not found: $keywordsFile"
        return $null
    }

    $keywordData = Get-Content $keywordsFile -Raw | ConvertFrom-Json
    $keywordMap = $keywordData.keywords
    $modesMap  = $keywordData.modes

    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($keywordGroup in $Keywords) {
        $isKeywordGroupMissing = [string]::IsNullOrWhiteSpace($keywordGroup)
        if ($isKeywordGroupMissing) {
            continue
        }

        $parts = $keywordGroup -split '[,\s]+' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_.Length -gt 0 }
        foreach ($part in $parts) {
            $tokens.Add($part)
        }
    }

    # Mode priority: install+settings > install-only / settings-only > null
    # When multiple keywords target the same script, merge to the highest mode.
    $modePriority = @{
        "install+settings" = 3
        "install-only"     = 2
        "settings-only"    = 1
    }

    $entries = [ordered]@{}   # key = script ID, value = best mode string (or $null)
    $hasError = $false

    foreach ($token in $tokens) {
        # Try exact match first, then try without hyphens
        $ids = $keywordMap.$token
        if ($null -eq $ids) {
            $stripped = $token -replace '-', ''
            $ids = $keywordMap.$stripped
        }
        $isUnknown = $null -eq $ids
        if ($isUnknown) {
            Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
            Write-Host "Unknown keyword: '$token'"
            $hasError = $true
            continue
        }

        # Determine mode override for this token (if any)
        $tokenModes = $modesMap.$token
        foreach ($id in $ids) {
            $mode = $null
            if ($null -ne $tokenModes) {
                $mode = $tokenModes."$id"
            }

            $key = "$id"
            $isNewEntry = -not $entries.Contains($key)
            if ($isNewEntry) {
                $entries[$key] = $mode
            } else {
                # Merge: keep the higher-priority mode
                $existingMode = $entries[$key]
                $existingPri  = if ($null -ne $existingMode -and $modePriority.ContainsKey($existingMode)) { $modePriority[$existingMode] } else { 0 }
                $newPri       = if ($null -ne $mode -and $modePriority.ContainsKey($mode)) { $modePriority[$mode] } else { 0 }
                $isNewHigher  = $newPri -gt $existingPri
                if ($isNewHigher) {
                    $entries[$key] = $mode
                }
            }
        }
    }

    if ($hasError) {
        Write-Host ""
        Write-Host "  Run .\run.ps1 -Help to see all available keywords" -ForegroundColor Cyan
        return $null
    }

    # Convert to list of {Id, Mode} sorted by ID
    $sorted = $entries.GetEnumerator() | ForEach-Object {
        @{ Id = [int]$_.Key; Mode = $_.Value }
    } | Sort-Object { [int]$_.Id }
    return $sorted
}

# ── Run a single script by ID ───────────────────────────────────────
function Invoke-ScriptById {
    param(
        [int]$ScriptId,
        [hashtable]$ExtraArgs = @{}
    )

    $prefix = "{0:D2}" -f $ScriptId
    $registryPath = Join-Path $RootDir "scripts\registry.json"
    $isRegistryAvailable = Test-Path $registryPath

    $scriptDir = $null
    if ($isRegistryAvailable) {
        $registry = Get-Content $registryPath -Raw | ConvertFrom-Json
        $folderName = $registry.scripts.$prefix

        $isRegistered = [bool]$folderName
        if ($isRegistered) {
            $scriptDir = Get-Item (Join-Path $RootDir "scripts\$folderName") -ErrorAction SilentlyContinue
        }
    } else {
        $pattern = Join-Path $RootDir "scripts/$prefix-*"
        $scriptDir = @(Get-Item $pattern -ErrorAction SilentlyContinue |
            Where-Object { $_.PSIsContainer -and (Test-Path (Join-Path $_.FullName "run.ps1")) }) |
            Select-Object -First 1
    }

    $isScriptMissing = -not $scriptDir -or -not (Test-Path $scriptDir.FullName)
    if ($isScriptMissing) {
        Write-Host ""
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "No script folder found for ID $prefix"
        return $false
    }

    $scriptFile = Join-Path $scriptDir.FullName "run.ps1"
    $isRunFileMissing = -not (Test-Path $scriptFile)
    if ($isRunFileMissing) {
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "run.ps1 not found in $($scriptDir.Name)"
        return $false
    }

    # Clean & create logs folder
    $logsDir = Join-Path $scriptDir.FullName "logs"
    if (Test-Path $logsDir) {
        Remove-Item -Path $logsDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null

    Write-Host ""
    Write-Host "  [ RUN   ] " -ForegroundColor Magenta -NoNewline
    Write-Host "Executing: $($scriptDir.Name)\run.ps1"
    Write-Host ""

    & $scriptFile @ExtraArgs
    return $true
}

# ── Choco Update function ────────────────────────────────────────────
function Invoke-ChocoUpdate {
    <#
    .SYNOPSIS
        Lists all installed Chocolatey packages, confirms with user, then
        runs choco upgrade all.
    #>

    # Ensure Chocolatey is available
    $chocoCmd = Get-Command choco.exe -ErrorAction SilentlyContinue
    $isChocoMissing = -not $chocoCmd
    if ($isChocoMissing) {
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "Chocolatey is not installed. Run .\run.ps1 install choco first."
        return
    }

    Write-Host ""
    Write-Host "  Chocolatey Package Update" -ForegroundColor Cyan
    Write-Host "  =========================" -ForegroundColor DarkGray
    Write-Host ""

    # List installed packages
    Write-Host "  [ INFO ] " -ForegroundColor Cyan -NoNewline
    Write-Host "Listing installed Chocolatey packages..."
    Write-Host ""

    $installedRaw = & choco.exe list --local-only 2>&1
    $packageLines = @($installedRaw | Where-Object {
        $line = $_.ToString().Trim()
        $isNotEmpty = $line.Length -gt 0
        $isNotSummary = $line -notmatch '^\d+ packages installed'
        $isNotHeader = $line -notmatch '^Chocolatey v'
        $isNotEmpty -and $isNotSummary -and $isNotHeader
    })

    $packageCount = $packageLines.Count
    if ($packageCount -eq 0) {
        Write-Host "  [ INFO ] " -ForegroundColor Cyan -NoNewline
        Write-Host "No Chocolatey packages found."
        return
    }

    Write-Host "    Package                              Version" -ForegroundColor DarkGray
    Write-Host "    -------------------------------------  --------------------" -ForegroundColor DarkGray
    foreach ($line in $packageLines) {
        $parts = $line.ToString().Trim() -split '\s+'
        $pkgName = if ($parts.Count -ge 1) { $parts[0] } else { $line }
        $pkgVer  = if ($parts.Count -ge 2) { $parts[1] } else { "" }
        Write-Host "    $($pkgName.PadRight(41))" -NoNewline
        Write-Host "$pkgVer" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  [ INFO ] " -ForegroundColor Cyan -NoNewline
    Write-Host "$packageCount package(s) installed"
    Write-Host ""

    # Confirm
    $confirm = Read-Host "  Do you want to upgrade ALL packages? [Y/n]"
    $isAborted = $confirm.Trim().ToUpper() -eq "N"
    if ($isAborted) {
        Write-Host "  [ SKIP ] Update cancelled by user." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  [ INFO ] " -ForegroundColor Cyan -NoNewline
    Write-Host "Running: choco upgrade all -y"
    Write-Host ""

    try {
        & choco.exe upgrade all -y
        $hasUpgradeFailed = $LASTEXITCODE -ne 0
        if ($hasUpgradeFailed) {
            Write-Host ""
            Write-Host "  [ WARN ] " -ForegroundColor Yellow -NoNewline
            Write-Host "Some packages may have failed to upgrade (exit code: $LASTEXITCODE)"
        } else {
            Write-Host ""
            Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline
            Write-Host "All packages upgraded successfully"
        }
    } catch {
        Write-Host ""
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "Upgrade failed: $_"
    }
}

# ── Path command function ─────────────────────────────────────────────
function Invoke-PathCommand {
    param([string[]]$Args)

    # Load dev-dir helper
    $devDirHelper = Join-Path $RootDir "scripts\shared\dev-dir.ps1"
    $isHelperMissing = -not (Test-Path $devDirHelper)
    if ($isHelperMissing) {
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "Shared helper not found: $devDirHelper"
        return
    }
    . $devDirHelper

    $firstArg = if ($Args -and $Args.Count -gt 0) { $Args[0].Trim() } else { "" }
    $isReset = $firstArg -eq "--reset" -or $firstArg -eq "reset"
    $isShowOnly = [string]::IsNullOrWhiteSpace($firstArg)

    if ($isReset) {
        Remove-SavedDevPath
        Write-Host ""
        Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline
        Write-Host "Saved dev directory cleared. Smart detection will be used."
        Write-Host ""
        return
    }

    if ($isShowOnly) {
        $savedPath = Get-SavedDevPath
        $hasSavedPath = $null -ne $savedPath
        Write-Host ""
        if ($hasSavedPath) {
            Write-Host "  Current dev directory: " -NoNewline -ForegroundColor DarkGray
            Write-Host "$savedPath" -ForegroundColor White
        } else {
            Write-Host "  No saved dev directory. Using smart detection (E:\dev-tool > D:\dev-tool > best drive)." -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "  Usage:" -ForegroundColor Yellow
        Write-Host "    .\run.ps1 path D:\devtools          " -NoNewline; Write-Host "Set default dev directory" -ForegroundColor DarkGray
        Write-Host "    .\run.ps1 path                      " -NoNewline; Write-Host "Show current dev directory" -ForegroundColor DarkGray
        Write-Host "    .\run.ps1 path --reset              " -NoNewline; Write-Host "Clear saved path, use smart detection" -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    # Validate the path
    $targetPath = $firstArg
    $isValidFormat = $targetPath -match '^[A-Za-z]:\\'
    if (-not $isValidFormat) {
        Write-Host ""
        Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
        Write-Host "Invalid path format. Use a full path like D:\devtools or F:\dev-tool"
        Write-Host ""
        return
    }

    Set-SavedDevPath -Path $targetPath
    Write-Host ""
    Write-Host "  [  OK  ] " -ForegroundColor Green -NoNewline
    Write-Host "Default dev directory set to: $targetPath"
    Write-Host ""
    Write-Host "  All scripts will now use this path. Use '.\run.ps1 path --reset' to revert to smart detection." -ForegroundColor DarkGray
    Write-Host ""
}

# ── Normalize positional command mode ────────────────────────────────
# Supports:  .\run.ps1 install alldev,mysql
#             .\run.ps1 install alldev mysql
#             .\run.ps1 -Install alldev,mysql
#             .\run.ps1 update
#             .\run.ps1 path D:\devtools
$normalizedCommand = ""
$hasCommand = -not [string]::IsNullOrWhiteSpace($Command)
if ($hasCommand) {
    $normalizedCommand = $Command.Trim().ToLower()
    $isBareInstallCommand = $normalizedCommand -eq "install"
    $isBareUpdateCommand  = $normalizedCommand -eq "update" -or $normalizedCommand -eq "choco-update" -or $normalizedCommand -eq "upgrade"
    $isBarePathCommand    = $normalizedCommand -eq "path"
    $isBareScriptId = $normalizedCommand -match '^\d+$'

    if ($isBareInstallCommand) {
        # Merge positional remaining args into $Install
        $hasRemainingArgs = $null -ne $Install -and $Install.Count -gt 0
        $isNoRemainingArgs = -not $hasRemainingArgs
        if ($isNoRemainingArgs) {
            Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
            Write-Host "No keywords provided after 'install'. Usage: .\run.ps1 install <keywords>"
            Write-Host ""
            Write-Host "  Run .\run.ps1 -Help to see all available keywords" -ForegroundColor Cyan
            exit 1
        }
    } elseif ($isBarePathCommand) {
        Show-VersionHeader
        Invoke-PathCommand -Args $Install
        exit 0
    } elseif ($isBareUpdateCommand) {
        Show-VersionHeader

        # Self-update: pull latest script changes first
        Remove-Item Env:\SCRIPTS_ROOT_RUN -ErrorAction SilentlyContinue
        $sharedGitPull = Join-Path $RootDir "scripts\shared\git-pull.ps1"
        $isHelperAvailable = Test-Path $sharedGitPull
        if ($isHelperAvailable) {
            . $sharedGitPull
            Invoke-GitPull -RepoRoot $RootDir
        }

        # Then update Chocolatey packages
        Invoke-ChocoUpdate
        exit 0
    } elseif ($isBareScriptId) {
        $I = [int]$normalizedCommand
    } else {
        # Treat unknown bare command as a keyword (e.g. .\run.ps1 vscode)
        $Install = @($normalizedCommand) + @($Install | Where-Object { $_ })
    }
}

# ── No params = git pull + help ──────────────────────────────────────
$hasInstallKeywords = $null -ne $Install -and $Install.Count -gt 0
$hasNoParams = -not $hasCommand -and -not $I -and -not $hasInstallKeywords -and -not $d -and -not $a -and -not $h -and -not $v -and -not $w -and -not $t -and -not $Help -and -not $List -and -not $CleanOnly -and -not $Clean -and -not $Defaults
if ($hasNoParams) {
    Remove-Item Env:\SCRIPTS_ROOT_RUN -ErrorAction SilentlyContinue
    $sharedGitPull = Join-Path $RootDir "scripts\shared\git-pull.ps1"
    $isHelperAvailable = Test-Path $sharedGitPull
    if ($isHelperAvailable) {
        . $sharedGitPull
        Invoke-GitPull -RepoRoot $RootDir
    }
    Show-RootHelp
    exit 0
}

# ── List (keyword table only) ────────────────────────────────────────
if ($List) {
    Show-KeywordTable
    exit 0
}

# ── Help ─────────────────────────────────────────────────────────────
if ($Help) {
    Show-RootHelp
    exit 0
}

# ── Handle -CleanOnly (no -I required) ───────────────────────────────
if ($CleanOnly) {
    $resolvedDir = Join-Path $RootDir ".resolved"
    if (Test-Path $resolvedDir) {
        Get-ChildItem -Path $resolvedDir -Recurse -Force | Remove-Item -Recurse -Force
        Write-Host "  [ CLEAN ] " -ForegroundColor Green -NoNewline
        Write-Host "All .resolved/ data wiped"
    } else {
        Write-Host "  [ SKIP  ] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Nothing to clean -- .resolved/ does not exist"
    }
    exit 0
}

# ── Handle -Clean ────────────────────────────────────────────────────
if ($Clean) {
    $resolvedDir = Join-Path $RootDir ".resolved"
    if (Test-Path $resolvedDir) {
        Get-ChildItem -Path $resolvedDir -Recurse -Force | Remove-Item -Recurse -Force
        Write-Host "  [ CLEAN ] " -ForegroundColor Green -NoNewline
        Write-Host "All .resolved/ data wiped -- fresh detection will run"
    } else {
        Write-Host "  [ SKIP  ] " -ForegroundColor DarkGray -NoNewline
        Write-Host "Nothing to clean -- .resolved/ does not exist"
    }
    Write-Host ""
}

# ── Load shared git-pull helper ──────────────────────────────────────
$sharedGitPull = Join-Path $RootDir "scripts\shared\git-pull.ps1"
$isHelperMissing = -not (Test-Path $sharedGitPull)
if ($isHelperMissing) {
    Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
    Write-Host "Shared helper not found: $sharedGitPull"
    exit 1
}
. $sharedGitPull

# ── Git Pull ─────────────────────────────────────────────────────────
Invoke-GitPull -RepoRoot $RootDir

# ── Set flag so child scripts skip git pull ──────────────────────────
$env:SCRIPTS_ROOT_RUN = "1"

# ── Handle install keyword mode (bare or named) ─────────────────────
$hasInstallKeywords = $null -ne $Install -and $Install.Count -gt 0
if ($hasInstallKeywords) {
    $resolvedEntries = Resolve-InstallKeywords -Keywords $Install

    $isResolveFailed = $null -eq $resolvedEntries
    if ($isResolveFailed) { exit 1 }

    $totalSteps = @($resolvedEntries).Count
    $idList = ($resolvedEntries | ForEach-Object { $_.Id }) -join ', '
    Write-Host ""
    Write-Host "  [ INFO ] " -ForegroundColor Cyan -NoNewline
    Write-Host "Installing $totalSteps tool(s): $idList"
    Write-Host ""

    $successCount = 0
    $failCount    = 0

    # Map script IDs to their mode env var names
    $modeEnvVars = @{
        33 = "NPP_MODE"
        16 = "PHP_MODE"
        36 = "OBS_MODE"
        37 = "WT_MODE"
    }

    foreach ($entry in $resolvedEntries) {
        $id      = $entry.Id
        $modeKey = $entry.Mode
        $hasModeOverride = -not [string]::IsNullOrWhiteSpace($modeKey)
        $envVarName = $modeEnvVars[$id]
        $hasEnvVar  = $null -ne $envVarName
        if ($hasModeOverride -and $hasEnvVar) {
            Set-Item "Env:\$envVarName" $modeKey
        }
        $result = Invoke-ScriptById -ScriptId $id
        if ($hasModeOverride -and $hasEnvVar) {
            Remove-Item "Env:\$envVarName" -ErrorAction SilentlyContinue
        }
        if ($result) { $successCount++ } else { $failCount++ }
    }

    Write-Host ""
    Write-Host "  ======================================" -ForegroundColor DarkGray
    Write-Host "  [ DONE ] " -ForegroundColor Green -NoNewline
    Write-Host "$successCount of $totalSteps completed successfully"
    if ($failCount -gt 0) {
        Write-Host "  [ WARN ] " -ForegroundColor Yellow -NoNewline
        Write-Host "$failCount script(s) failed"
    }

    Remove-Item Env:\SCRIPTS_ROOT_RUN -ErrorAction SilentlyContinue
    exit 0
}

# ── Expand shortcuts ──────────────────────────────────────────────────
if ($d) { $I = 12 }
if ($a) { $I = 13 }
if ($v) { $I = 1 }
if ($w) { $I = 14 }
if ($t) { $I = 15 }
if ($h) { $I = 13; $scriptArgs = @{ "Report" = $true } }
# -Defaults without -I defaults to all-dev (script 12)
if ($Defaults -and -not $I) { $I = 12 }

# ── Validate -I is provided ──────────────────────────────────────────
$isMissingParam = -not $I
if ($isMissingParam) {
    Write-Host "  [ FAIL ] " -ForegroundColor Red -NoNewline
    Write-Host "Missing -I parameter. Usage: .\run.ps1 -I <number>"
    Write-Host ""
    Write-Host "  Run .\run.ps1 -Help to see all available scripts" -ForegroundColor Cyan
    exit 1
}

# ── Delegate to single script ────────────────────────────────────────
$isScriptArgsUndefined = -not (Test-Path variable:scriptArgs) -or $null -eq $scriptArgs
if ($isScriptArgsUndefined) { $scriptArgs = @{} }
if ($Merge) { $scriptArgs["Merge"] = $true }
if ($Defaults) { $scriptArgs["Defaults"] = $true }

# ── -Defaults -Y confirmation logic ──────────────────────────────────
if ($Defaults -and -not $Y) {
    Write-Host ""
    Write-Host "  Defaults Mode" -ForegroundColor Cyan
    Write-Host "  =============" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Dev directory     : " -NoNewline -ForegroundColor DarkGray; Write-Host "auto (E:\dev-tool -- smart detection)" -ForegroundColor White
    Write-Host "    VS Code edition   : " -NoNewline -ForegroundColor DarkGray; Write-Host "Stable" -ForegroundColor White
    Write-Host "    Settings sync     : " -NoNewline -ForegroundColor DarkGray; Write-Host "Overwrite" -ForegroundColor White
    Write-Host ""
    $confirm = Read-Host "  Proceed with these defaults? [Y/n]"
    $isAborted = $confirm.Trim().ToUpper() -eq "N"
    if ($isAborted) {
        Write-Host "  [ SKIP ] Aborted by user." -ForegroundColor Yellow
        exit 0
    }
}

$result = Invoke-ScriptById -ScriptId $I -ExtraArgs $scriptArgs

$isScriptFailed = -not $result
if ($isScriptFailed) { exit 1 }

# ── Clean up env flag ────────────────────────────────────────────────
Remove-Item Env:\SCRIPTS_ROOT_RUN -ErrorAction SilentlyContinue
