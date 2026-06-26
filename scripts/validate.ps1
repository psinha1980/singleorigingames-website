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
$required = @('index.html', 'app-ads.txt', 'CNAME', 'about.html', 'privacy.html', 'support.html', '404.html', 'css/style.css')
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
Write-Host '==> Checking Unity Ads Org Core ID...' -ForegroundColor Cyan
if ((Get-Content 'app-ads.txt' -Raw) -notmatch 'unity3d\.com,\s*13469858174961') {
    Write-Host '    WARN: Unity Ads org core ID 13469858174961 not found' -ForegroundColor Yellow
}
else {
    Write-Host '    OK: unity3d.com 13469858174961 present'
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
Write-Host '==> Checking HTML pages for required tags...' -ForegroundColor Cyan
$htmlFiles = @(Get-ChildItem -Path . -Filter '*.html' -Recurse | Where-Object { $_.FullName -notlike '*node_modules*' })
foreach ($file in $htmlFiles) {
    $html = Get-Content $file.FullName -Raw
    $relPath = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    $issues = @()
    if ($html -notmatch '<!DOCTYPE html>') { $issues += 'DOCTYPE' }
    if ($html -notmatch '<meta\s+charset=') { $issues += 'charset' }
    if ($html -notmatch '<meta\s+name="viewport"') { $issues += 'viewport' }
    if ($html -notmatch '<title>') { $issues += 'title' }
    if ($html -notmatch '<meta\s+name="description"' -and $file.Name -ne '404.html') { $issues += 'description' }
    if ($issues.Count -eq 0) {
        Write-Host "    OK: $relPath"
    }
    else {
        Write-Host "    $relPath -- missing: $($issues -join ', ')" -ForegroundColor Red
        $failed = $true
    }
}

Write-Host ''
Write-Host '==> Checking internal links resolve to files...' -ForegroundColor Cyan
$brokenLinks = 0
foreach ($file in $htmlFiles) {
    $html = Get-Content $file.FullName -Raw
    $matches = [regex]::Matches($html, 'href="(/[^"#?]+)"')
    foreach ($match in $matches) {
        $link = $match.Groups[1].Value
        # Strip query/fragment, normalize
        $target = Join-Path $root $link.TrimStart('/').Replace('/', '\')
        # Directory-style links get treated as /index.html implicitly
        if ($link.EndsWith('/')) { $target = Join-Path $target 'index.html' }
        if (-not (Test-Path $target)) {
            $relPath = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
            Write-Host "    $relPath -> $link -- TARGET MISSING" -ForegroundColor Red
            $brokenLinks++
        }
    }
}
if ($brokenLinks -eq 0) {
    Write-Host '    OK: all internal links resolve'
}
else {
    Write-Host "    $brokenLinks broken link(s)" -ForegroundColor Red
    $failed = $true
}

Write-Host ''
if ($failed) {
    Write-Host 'FAILED - fix the errors above before pushing' -ForegroundColor Red
    exit 1
}
Write-Host 'All local validation checks passed' -ForegroundColor Green
Write-Host 'Push to main when ready: git push origin main'
