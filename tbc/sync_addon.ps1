# sync_addon.ps1 - sync an addon from this repo's tbc/Addons into the TBC client
#
# Removes every addon dir in <wow_tbc_dir>/Interface/AddOns whose name matches the addon (old
# versions and leftover companion addons such as SkadaImprovement), then copies the matching
# dirs from the source. SavedVariables in WTF are left alone, so the addon keeps its settings.
# The client dir comes from the env var wow_tbc_dir unless -WowDir is given.
# -Reverse (or sync_addon_reverse.ps1) syncs the other way: client -> repo, for testing an
# addon changed in the client; git shows what changed and restores the repo copy.
#
# Usage examples:
# sync Skada (default) into $env:wow_tbc_dir/Interface/AddOns:
#   .\sync_addon.ps1
# another addon, prefix match (every DBM-* dir):
#   .\sync_addon.ps1 DBM-
# only the dir named exactly Skada (other Skada* dirs in the client are kept):
#   .\sync_addon.ps1 Skada -Exact
# other repo AddOns dir (positional or named; the source, or the destination with -Reverse):
#   .\sync_addon.ps1 Skada C:\tmp\Skada-TBC
#   .\sync_addon.ps1 -Addon Skada -Source C:\tmp\Skada-TBC
# other client dir than $env:wow_tbc_dir:
#   .\sync_addon.ps1 -WowDir D:\games\wow243
# preview, change nothing:
#   .\sync_addon.ps1 -DryRun
# print the equivalent PowerShell commands instead of running them:
#   .\sync_addon.ps1 -ShowCmd
# case sensitive name match:
#   .\sync_addon.ps1 Skada -CaseSensitive
# reverse: copy the client's Skada* dirs back into the repo (preview first):
#   .\sync_addon.ps1 -Reverse -DryRun
#   .\sync_addon.ps1 -Reverse

[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string]$Addon = 'Skada',
    [Parameter(Position = 1)] [string]$Source = (Join-Path $PSScriptRoot 'Addons'),
    [string]$WowDir = $env:wow_tbc_dir,
    [switch]$Exact,
    [switch]$CaseSensitive,
    [switch]$DryRun,
    [switch]$ShowCmd,
    [switch]$Reverse
)

$ErrorActionPreference = 'Stop'

function Write-Ok     ([string]$m) { Write-Host $m -ForegroundColor Green }
function Write-Err    ([string]$m) { Write-Host $m -ForegroundColor Red }
function Write-Warn   ([string]$m) { Write-Host $m -ForegroundColor DarkYellow }
function Write-Info   ([string]$m) { Write-Host $m -ForegroundColor Cyan }
function Write-InfoAlt([string]$m) { Write-Host $m -ForegroundColor Magenta }

$WOW_DIR_ENV = 'wow_tbc_dir'

function Test-AddonName([string]$name) {
    if ($Exact) {
        if ($CaseSensitive) { return $name -ceq $Addon }
        return $name -ieq $Addon
    }
    $pattern = [WildcardPattern]::Escape($Addon) + '*'
    if ($CaseSensitive) { return $name -clike $pattern }
    return $name -ilike $pattern
}

function Get-AddonDirs([string]$root) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { return @() }
    return @(Get-ChildItem -LiteralPath $root -Directory |
        Where-Object { Test-AddonName $_.Name } | Sort-Object Name)
}

# "## Version:" of <dir>/<dir name>.toc, '?' when there is none
function Get-TocVersion([string]$dir) {
    $toc = Join-Path $dir ((Split-Path $dir -Leaf) + '.toc')
    if (-not (Test-Path -LiteralPath $toc)) { return '?' }
    $line = Get-Content -LiteralPath $toc | Where-Object { $_ -match '^##\s*Version:\s*(.+)$' } | Select-Object -First 1
    if ($line -match '^##\s*Version:\s*(.+)$') { return $Matches[1].Trim() }
    return '?'
}

function Format-Literal([string]$s) { return "'" + $s.Replace("'", "''") + "'" }

# --- checks ------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($Addon)) {
    Write-Err 'Addon name is empty - an empty prefix would match every addon.'
    exit 1
}
if ([string]::IsNullOrWhiteSpace($WowDir)) {
    Write-Err "Env var '$WOW_DIR_ENV' is not set - set it to the TBC client dir or pass -WowDir."
    exit 1
}
if (-not (Test-Path -LiteralPath $WowDir -PathType Container)) {
    Write-Err "Client dir not found: $WowDir"
    exit 1
}
if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    Write-Err "Source dir not found: $Source"
    exit 1
}

$WowDir = (Resolve-Path -LiteralPath $WowDir).Path
$Source = (Resolve-Path -LiteralPath $Source).Path
$clientAddOns = Join-Path (Join-Path $WowDir 'Interface') 'AddOns'
if ($Reverse) { $fromDir = $clientAddOns; $toDir = $Source } else { $fromDir = $Source; $toDir = $clientAddOns }
$matchDesc = if ($Exact) { "'$Addon'" } else { "'$Addon*'" }
$matchDesc += if ($CaseSensitive) { ' (case sensitive)' } else { ' (case insensitive)' }

$srcDirs = Get-AddonDirs $fromDir
if ($srcDirs.Count -eq 0) {
    Write-Err "No addon dir matching $matchDesc in $fromDir - nothing removed."
    exit 1
}
$oldDirs = Get-AddonDirs $toDir
$destMissing = -not (Test-Path -LiteralPath $toDir -PathType Container)

foreach ($d in $srcDirs) {
    if (-not (Test-Path -LiteralPath (Join-Path $d.FullName ($d.Name + '.toc')))) {
        Write-Warn "warning: $($d.Name) has no $($d.Name).toc - the client will not load it"
    }
}

# --- show the commands only --------------------------------------------------
if ($ShowCmd) {
    $given = foreach ($p in $PSBoundParameters.GetEnumerator()) {
        if ($p.Value -is [switch]) { "-$($p.Key)" } else { "-$($p.Key) $(Format-Literal ([string]$p.Value))" }
    }
    Write-Host "# $PSCommandPath $($given -join ' ')"
    foreach ($d in $oldDirs) { Write-Host "Remove-Item -LiteralPath $(Format-Literal $d.FullName) -Recurse -Force" }
    if ($destMissing) { Write-Host "New-Item -ItemType Directory -Force -Path $(Format-Literal $toDir) | Out-Null" }
    foreach ($d in $srcDirs) {
        Write-Host "Copy-Item -LiteralPath $(Format-Literal $d.FullName) -Destination $(Format-Literal $toDir) -Recurse"
    }
    exit 0
}

# --- sync --------------------------------------------------------------------
$prefix = if ($DryRun) { '[dry run] ' } else { '' }
Write-Info "${prefix}Syncing $matchDesc"
Write-Info "  from $fromDir"
Write-Info "  to   $toDir"

$oldVersions = @{}
foreach ($d in $oldDirs) {
    $oldVersions[$d.Name.ToLowerInvariant()] = Get-TocVersion $d.FullName
    if (-not $DryRun) { Remove-Item -LiteralPath $d.FullName -Recurse -Force }
    Write-Warn "${prefix}removed $($d.Name) ($($oldVersions[$d.Name.ToLowerInvariant()]))"
}

if ($destMissing) {
    Write-Warn "${prefix}creating missing $toDir"
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $toDir | Out-Null }
}

$fileCount = 0
foreach ($d in $srcDirs) {
    $newVersion = Get-TocVersion $d.FullName
    $files = @(Get-ChildItem -LiteralPath $d.FullName -Recurse -File).Count
    $fileCount += $files
    if (-not $DryRun) { Copy-Item -LiteralPath $d.FullName -Destination $toDir -Recurse }
    $key = $d.Name.ToLowerInvariant()
    $change = if ($oldVersions.ContainsKey($key)) { "$($oldVersions[$key]) -> $newVersion" } else { "new, $newVersion" }
    Write-Ok "${prefix}copied  $($d.Name) ($change, $files files)"
}

$leftover = @($oldDirs | Where-Object { $n = $_.Name; -not ($srcDirs | Where-Object { $_.Name -ieq $n }) })
Write-Host ''
Write-InfoAlt "${prefix}Done: removed $($oldDirs.Count) dir(s), copied $($srcDirs.Count) dir(s) / $fileCount files."
if ($leftover.Count -gt 0) {
    Write-InfoAlt "  cleaned up, not in the source: $(($leftover | ForEach-Object Name) -join ', ')"
}
if (-not $DryRun) {
    if ($Reverse) { Write-Info "Review with: git -C $(Format-Literal $toDir) status --short . (git restore / git clean -fd . undoes it)" }
    else { Write-Info 'Restart the client (or /reload if only files changed) to load it.' }
}
