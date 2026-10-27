<#
.SYNOPSIS
  Boot UZDoom with nbc/, load each map, and fail on any script or asset error.
.DESCRIPTION
  Runs uzdoom.exe with -stdout (its console goes to build\smoke_<map>.txt), waits, then kills it.
  It uses its own config (build\smoke.ini), so your own UZDoom settings are never touched.
  A map PASSES when: the engine is still running at the end (a fatal error leaves a "Fatal Error"
  window), the log has "Init complete." and "<MAP> - <title>", and no line looks like an error.
  A UZDoom window opens for a few seconds per map; that's expected.
.EXAMPLE
  powershell -File tools\smoke_test.ps1
.EXAMPLE
  powershell -File tools\smoke_test.ps1 -Map NBC_TEST,NBC_HUB -Seconds 15
#>
param(
    [string[]]$Map = @("NBC_TEST"),
    [int]$Seconds = 12,
    [string[]]$Extra = @()
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$build = Join-Path $root "build"
New-Item -ItemType Directory -Force $build | Out-Null

# Lines matching any of these fail the run (case-insensitive). Learned from UZDoom 5.0.3 output:
# script errors look like "<file>, line N: <message>".
$errorPatterns = @(
    ', line \d+:', 'script error', 'error', 'unknown', 'not found', 'bad state', 'could not',
    'missing', 'invalid', 'warning', 'failed', "can't", 'cannot'
)
$failedMaps = @()

foreach ($m in $Map) {
    $out = Join-Path $build "smoke_$m.txt"
    $err = Join-Path $build "smoke_$m.err.txt"
    Remove-Item $out, $err -ErrorAction SilentlyContinue
    $argLine = "-iwad freedoom-0.13.0/freedoom2.wad -file nbc -nosound -stdout -config build/smoke.ini " +
               "+vid_fullscreen 0 +map $m " + ($Extra -join " ")
    $p = Start-Process -FilePath (Join-Path $root "uzdoom.exe") -ArgumentList $argLine -WorkingDirectory $root `
        -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
    $exited = $p.WaitForExit($Seconds * 1000)
    $title = ""
    if (-not $exited) {
        $title = (Get-Process -Id $p.Id -ErrorAction SilentlyContinue).MainWindowTitle
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
    }
    $log = @()
    if (Test-Path $out) { $log = Get-Content $out }

    $reasons = @()
    if ($exited) { $reasons += "engine exited by itself (code $($p.ExitCode))" }
    if ($title -like "Fatal Error*") { $reasons += "engine shows a Fatal Error window" }
    if (-not ($log -match '^Init complete\.')) { $reasons += "never reached 'Init complete.'" }
    if (-not ($log -match ("^" + [regex]::Escape($m) + " - "))) { $reasons += "map $m never loaded" }
    $bad = $log | Where-Object { $line = $_; $errorPatterns | Where-Object { $line -match $_ } }
    foreach ($b in $bad) { $reasons += "log: $b" }

    if ($reasons.Count -eq 0) {
        Write-Host "PASS  $m  ($($log.Count) log lines, build\smoke_$m.txt)"
    } else {
        Write-Host "FAIL  $m  (build\smoke_$m.txt)" -ForegroundColor Red
        $reasons | Select-Object -First 25 | ForEach-Object { Write-Host "      $_" }
        $failedMaps += $m
    }
}

if ($failedMaps.Count) { exit 1 }
exit 0
