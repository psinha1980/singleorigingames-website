# scripts/validate.ps1
#
# Run the same checks the CI runs, locally before pushing.
# Catches breakage before it leaves your machine.
#
# Usage:
#   ./scripts/validate.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$failed = $false

Write-Host '==> Checking required files exist...' -ForegroundColor Cyan
$required = @('index.html', 'app-ads.txt', 'CNAME')
foreach ($f in $required) {
    if (-not (Test-Path $f)) {
        Write-Host "    MISSING: $f" -ForegroundColor Red
        $failed = $true
    }
    else {
        Write-Host "    OK: $f"
    }
}

Write-Host ''
Write-Host '==> Validating app-ads.txt format...' -ForegroundColor Cyan
$bad = 0
$pattern = '^[a-z0-9.-]+,\s*[a-z0-9_-]+,\s*(DIRECT|RESELLER)(\s*,\s*[a-f0-9]+)?\s*$'
foreach ($line in (Get-Content 'app-ads.txt')) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrEmpty($trimmed)) { continue }
    if ($trimmed.StartsWith('#')) { continue }
    if ($trimmed -imatch $pattern) {
        Write-Host "    OK: $trimmed"
    }
    else {
        Write-Host "    MALFORMED: $trimmed" -ForegroundColor Red
        $bad++
    }
}
if ($bad -gt 0) {
    Write-Host "    $bad malformed line(s) - AdMob verification would fail" -ForegroundColor Red
    $failed = $true
}

Write-Host ''
Write-Host '==> Checking AdMob publisher ID...' -ForegroundColor Cyan
if ((Get-Content 'app-ads.txt' -Raw) -notmatch 'pub-7717083762897022') {
    Write-Host '    WARN: AdMob publisher ID pub-7717083762897022 not found' -ForegroundColor Yellow
}
else {
    Write-Host '    OK: pub-7717083762897022 present'
}

Write-Host ''
Write-Host '==> Checking CNAME...' -ForegroundColor Cyan
$cname = (Get-Content 'CNAME' -Raw).Trim()
if ($cname -ne 'singleorigingames.com') {
    Write-Host "    CNAME contains '$cname', expected 'singleorigingames.com'" -ForegroundColor Red
    $failed = $true
}
else {
    Write-Host "    OK: $cname"
}

Write-Host ''
Write-Host '==> Checking index.html for common issues...' -ForegroundColor Cyan
$html = Get-Content 'index.html' -Raw
$ok = $true
if ($html -notmatch '<!DOCTYPE html>') {
    Write-Host '    MISSING: DOCTYPE' -ForegroundColor Red
    $ok = $false; $failed = $true
}
if ($html -notmatch '<meta\s+charset=') {
    Write-Host '    MISSING: charset meta tag' -ForegroundColor Red
    $ok = $false; $failed = $true
}
if ($html -notmatch '<meta\s+name="viewport"') {
    Write-Host '    MISSING: viewport meta tag' -ForegroundColor Red
    $ok = $false; $failed = $true
}
if ($html -notmatch '<title>') {
    Write-Host '    MISSING: title' -ForegroundColor Red
    $ok = $false; $failed = $true
}
if ($ok) {
    Write-Host '    OK: DOCTYPE, charset, viewport, title all present'
}

Write-Host ''
if ($failed) {
    Write-Host 'FAILED - fix the errors above before pushing' -ForegroundColor Red
    exit 1
}
Write-Host 'All local validation checks passed' -ForegroundColor Green
Write-Host 'Push to main when ready: git push origin main'
