<#
.SYNOPSIS
  Menu launcher for testing New Bricks City. Double-click Launch.bat in the repo root,
  or run: powershell -ExecutionPolicy Bypass -File tools\launcher.ps1
#>
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$exe  = Join-Path $root "uzdoom.exe"
$iwad = "freedoom-0.13.0\freedoom2.wad"

foreach ($f in @($exe, (Join-Path $root $iwad))) {
    if (-not (Test-Path $f)) { Write-Host "Missing: $f" -ForegroundColor Red; Read-Host "Press Enter"; exit 1 }
}

$maps = [ordered]@{
    "1" = @("NBC_HUB",  "New game (Checkpoint 9 hub)")
    "2" = @("NBC_TEST", "Test room")
    "3" = @("NBC_CT01", "District: Mercer Street")
    "4" = @("NBC_CT02", "District: Wexford Row")
    "5" = @("NBC_CT03", "District: Sutter Alley")
    "6" = @("NBC_CT04", "District: Cypress Avenue")
}
$cheats = $false
$skill  = 3

function Start-Game([string]$map) {
    $a = @("-iwad", $iwad, "-file", "nbc", "-skill", $skill, "+map", $map)
    if ($cheats) { $a += @("+give", "all", "+god") }
    Write-Host "Starting $map ..." -ForegroundColor Green
    Start-Process -FilePath $exe -ArgumentList $a -WorkingDirectory $root
}

while ($true) {
    Clear-Host
    Write-Host "=== NEW BRICKS CITY - TEST LAUNCHER ===" -ForegroundColor Yellow
    Write-Host ("Cheats: {0}   Skill: {1}" -f ($(if ($cheats) { "ON (give all, god)" } else { "OFF" }), $skill))
    Write-Host ""
    foreach ($k in $maps.Keys) { Write-Host ("  {0}  {1}  ({2})" -f $k, $maps[$k][1], $maps[$k][0]) }
    Write-Host "  7  Other map..."
    Write-Host ""
    Write-Host "  C  Toggle cheats          S  Set skill (1-5)"
    Write-Host "  T  Smoke test, all maps   K  Static lump checks"
    Write-Host "  B  Build release PK3      Q  Quit"
    $c = (Read-Host "Choose").Trim().ToUpper()
    if ($maps.Contains($c)) { Start-Game $maps[$c][0]; continue }
    switch ($c) {
        "7" { $m = Read-Host "Map lump name"; if ($m) { Start-Game $m.Trim() } }
        "C" { $cheats = -not $cheats }
        "S" { $s = Read-Host "Skill 1-5"; if ($s -match '^[1-5]$') { $skill = [int]$s } }
        "T" {
            foreach ($v in $maps.Values) { & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "smoke_test.ps1") -Map $v[0] }
            Read-Host "Press Enter"
        }
        "K" { & python (Join-Path $PSScriptRoot "check_lumps.py"); Read-Host "Press Enter" }
        "B" { & python (Join-Path $PSScriptRoot "build_pk3.py"); Read-Host "Press Enter" }
        "Q" { exit 0 }
    }
}
