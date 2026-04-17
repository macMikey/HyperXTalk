@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$winnt = 'C:\Program Files (x86)\Windows Kits\10\include\10.0.26100.0\um\winnt.h';" ^
  "if (Test-Path $winnt) {" ^
  "  Write-Host 'Lines 24170-24185 of winnt.h (SDK 26100):';" ^
  "  Write-Host '------------------------------------------';" ^
  "  $lines = Get-Content $winnt;" ^
  "  for ($i=24169; $i -le 24184; $i++) { Write-Host ('{0,5}: {1}' -f ($i+1), $lines[$i]) };" ^
  "  Write-Host '------------------------------------------'" ^
  "} else { Write-Host 'winnt.h not found at expected path' };" ^
  "Write-Host '';" ^
  "Write-Host 'Checking for older SDKs:';" ^
  "$sdkBase = 'C:\Program Files (x86)\Windows Kits\10\include';" ^
  "foreach ($v in @('10.0.22621.0','10.0.22000.0','10.0.19041.0','10.0.18362.0','10.0.17763.0')) {" ^
  "  $p = Join-Path $sdkBase $v 'um\winnt.h';" ^
  "  if (Test-Path $p) { Write-Host ('  FOUND: ' + $v) } else { Write-Host ('  not found: ' + $v) }" ^
  "}"
