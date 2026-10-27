<#
.SYNOPSIS
  Build New Bricks City levels with Obsidian in batch mode (no GUI).
.DESCRIPTION
  Starts from Obsidian's own CONFIG.txt (whatever the GUI last saved), then sets the
  New Bricks City theme from addons/NewBricksCity, switches off modules that add
  their own textures, and builds into out\. Then export_maps.py copies each map into
  nbc\maps\NBC_CT01.wad, NBC_CT02.wad ... (replacing the previous set), with their titles and
  city sky in nbc\mapinfo\city_maps.txt. Play one:
    uzdoom.exe -iwad freedoom-0.13.0\freedoom2.wad -file nbc +map NBC_CT01
  -NoExport keeps the build in out\ only.
.EXAMPLE
  powershell -File tools\Obsidian\make_bricks.ps1
.EXAMPLE
  powershell -File tools\Obsidian\make_bricks.ps1 -Name test -Length single -Seed 42
#>
param(
    [string]$Name = "bricks",
    [ValidateSet("single", "few", "episode", "game")] [string]$Length = "few",
    [int]$Seed = 0,
    [switch]$NoExport    # keep the build in out\ only; don't replace the maps in nbc\maps
)
$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$out = Join-Path $here "out"
New-Item -ItemType Directory -Force $out | Out-Null

# setting -> value, applied to the matching "key = value" lines of CONFIG.txt
$set = [ordered]@{
    "game" = "doom2"; "port" = "zdoom"; "theme" = "nbc_bricks"; "length" = $Length
    "@new_bricks_city" = "1"
    "@armaetus_epic_textures" = "0"   # injects its own textures and Urban room themes
    "@sky_generator" = "0"            # paints its own sky graphics
    "@procedural_gotcha" = "0"; "@procedural_gotcha_zdoom" = "0"; "@iwad_mode" = "0"
    "@compress_output" = "0"          # plain WAD, not a zip
    "float_overall_lighting_mult" = "1.3"   # Obsidian's interiors are very dark at 1.0
    # The GUI saves fixed choices (steepness = none ...) that override the theme: hand them back to it.
    "outdoors" = "mixed"; "caves" = "mixed"; "liquids" = "mixed"; "hallways" = "mixed"; "teleporters" = "mixed"
    "steepness" = "mixed"; "parks" = "mixed"; "park_detail" = "mixed"; "porches" = "mixed"; "cages" = "mixed"
    "natural_parks" = "none"          # nature parks are caves with trees, not city parks
    "traps" = "none"                  # monster closets: the game places its own gangs
    "room_heights" = "tall-ish"       # room for split levels, balconies and stair runs
    "float_mons" = "0.6"              # a light layer: the game replaces it with the gang (only its spots count)
}
$lines = Get-Content (Join-Path $here "CONFIG.txt")
$seen = @{}
$lines = $lines | ForEach-Object {
    if ($_ -match '^(\s*)(@?[A-Za-z_0-9]+)\s*=') {
        $k = $Matches[2]
        if ($set.Contains($k)) { $seen[$k] = $true; return "$($Matches[1])$k = $($set[$k])" }
        if ($k -eq "seed") { return $null }
    }
    $_
}
$missing = $set.Keys | Where-Object { -not $seen[$_] }
if ($missing) {
    $end = [array]::IndexOf($lines, "-- END --")
    $add = $missing | ForEach-Object { "$_ = $($set[$_])" }
    $lines = if ($end -ge 0) { $lines[0..($end - 1)] + $add + $lines[$end..($lines.Count - 1)] } else { $lines + $add }
}
if ($Seed) { $lines = @("seed = $Seed") + $lines }
$settings = Join-Path $out "$Name.settings.txt"
Set-Content -Path $settings -Value $lines -Encoding ascii

$keep = if ($Seed) { "-k " } else { "" }
$p = Start-Process -FilePath (Join-Path $here "obsidian.exe") -WorkingDirectory $here -NoNewWindow -PassThru `
    -ArgumentList "-b out/$Name.wad -l out/$Name.settings.txt -a NewBricksCity $keep-v" `
    -RedirectStandardOutput (Join-Path $out "$Name.log.txt") -RedirectStandardError (Join-Path $out "$Name.err.txt")
# On a script error Obsidian logs "FAILED!" but stays open, so watch the log as well.
$logFile = Join-Path $out "$Name.log.txt"
$deadline = (Get-Date).AddMinutes(15)
while (-not $p.HasExited) {
    if ((Get-Date) -gt $deadline) { Stop-Process -Id $p.Id -Force; Write-Host "TIMED OUT" -ForegroundColor Red; exit 1 }
    if (Select-String -Path $logFile -Pattern "ERROR: FAILED|Unable to load script" -Quiet -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 2
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        break
    }
    Start-Sleep -Seconds 1
}

$log = Get-Content (Join-Path $out "$Name.log.txt")
$wad = Join-Path $out "$Name.wad"
$errors = $log | Select-String -Pattern "ERROR OCCURRED|ERROR MESSAGE|Script Error|ERROR: FAILED|Unable to load script|Unknown theme|No rooms themes" | Select-Object -First 10
if ($errors -or -not (Test-Path $wad)) {
    Write-Host "FAILED (see out\$Name.log.txt)" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "Built out\$Name.wad ($([math]::Round((Get-Item $wad).Length / 1MB, 1)) MB)"
$log | Select-String -Pattern "^Theme for level|Streets Mode activated|New Bricks City:" | ForEach-Object { Write-Host "  $($_.Line)" }

if (-not $NoExport) {
    # one WAD per map in nbc\maps (NBC_CT01...), their MAPINFO in nbc\mapinfo\city_maps.txt
    python (Join-Path $here "export_maps.py") $wad
    if ($LASTEXITCODE) { Write-Host "EXPORT FAILED" -ForegroundColor Red; exit 1 }
}
