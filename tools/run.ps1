<#
.SYNOPSIS
  Play New Bricks City from the nbc/ folder (no packing needed).
.EXAMPLE
  powershell -File tools\run.ps1
.EXAMPLE
  powershell -File tools\run.ps1 -Map NBC_TEST -Extra "+give all"
#>
param(
    [string]$Map = "NBC_TEST",
    [string[]]$Extra = @()
)
$root = Split-Path -Parent $PSScriptRoot
$argList = @("-iwad", "freedoom-0.13.0\freedoom2.wad", "-file", "nbc", "+map", $Map) + $Extra
Start-Process -FilePath (Join-Path $root "uzdoom.exe") -ArgumentList $argList -WorkingDirectory $root
