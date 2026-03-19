#Requires -Version 5.1

<#
.SYNOPSIS
    Fix broken symlinks for cvm on Windows

.DESCRIPTION
    Diagnoses and fixes symlink issues after installation

.EXAMPLE
    .\fix-symlink.ps1
#>

param(
    [string]$Version = ""
)

$ErrorActionPreference = 'Stop'

Write-Host "=== CVM Symlink Fix Tool ===" -ForegroundColor Cyan
Write-Host ""

# Detect installed versions
$cvmVersionsDir = "$env:USERPROFILE\.cvm\versions"
$cvmBinDir = "$env:USERPROFILE\.cvm\bin"

Write-Host "Step 1: Checking installed versions..." -ForegroundColor Yellow

if (-not (Test-Path $cvmVersionsDir)) {
    Write-Host "[X] No versions directory found at: $cvmVersionsDir" -ForegroundColor Red
    Write-Host "Please run: cvm install 2.1.63" -ForegroundColor Cyan
    exit 1
}

$installedVersions = Get-ChildItem $cvmVersionsDir -Directory
if ($installedVersions.Count -eq 0) {
    Write-Host "[X] No versions installed" -ForegroundColor Red
    Write-Host "Please run: cvm install 2.1.63" -ForegroundColor Cyan
    exit 1
}

Write-Host "[OK] Found $($installedVersions.Count) installed version(s):" -ForegroundColor Green
$installedVersions | ForEach-Object {
    Write-Host "   - $($_.Name)"
}
Write-Host ""

# Determine which version to fix
if (-not $Version) {
    if ($installedVersions.Count -eq 1) {
        $Version = $installedVersions[0].Name
        Write-Host "Auto-selecting only installed version: $Version" -ForegroundColor Cyan
    } else {
        Write-Host "Multiple versions installed. Please specify which one:" -ForegroundColor Yellow
        $installedVersions | ForEach-Object { Write-Host "   $($_.Name)" }
        Write-Host ""
        $Version = Read-Host "Enter version to activate (e.g., 2.1.63)"
    }
}

Write-Host ""
Write-Host "Step 2: Checking version $Version..." -ForegroundColor Yellow

$versionDir = "$cvmVersionsDir\$Version"
if (-not (Test-Path $versionDir)) {
    Write-Host "[X] Version $Version not found at: $versionDir" -ForegroundColor Red
    exit 1
}

# Find the cli.js file
$cliPath = "$versionDir\node_modules\@anthropic-ai\claude-code\cli.js"
if (-not (Test-Path $cliPath)) {
    Write-Host "[X] cli.js not found at: $cliPath" -ForegroundColor Red
    Write-Host "The version may be corrupted. Try reinstalling:" -ForegroundColor Yellow
    Write-Host "  cvm uninstall $Version"
    Write-Host "  cvm install $Version"
    exit 1
}

Write-Host "[OK] Found cli.js" -ForegroundColor Green
Write-Host ""

# Step 3: Fix version bin symlink
Write-Host "Step 3: Creating version bin symlink..." -ForegroundColor Yellow
$versionBinDir = "$versionDir\bin"
$versionClaudeLink = "$versionBinDir\claude"

New-Item -ItemType Directory -Path $versionBinDir -Force | Out-Null

# Remove old link if exists
if (Test-Path $versionClaudeLink) {
    Remove-Item $versionClaudeLink -Force
}

try {
    New-Item -ItemType SymbolicLink -Path $versionClaudeLink -Target $cliPath -Force -ErrorAction Stop | Out-Null
    Write-Host "[OK] Created version symlink" -ForegroundColor Green
    Write-Host "   $versionClaudeLink -> $cliPath"
}
catch {
    Write-Host "[X] Failed to create symlink: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Creating .cmd wrapper as fallback..." -ForegroundColor Yellow

    # Create .cmd wrapper instead
    $wrapperCmd = "$versionBinDir\claude.cmd"
    @"
@echo off
node "$cliPath" %*
"@ | Out-File -FilePath $wrapperCmd -Encoding ASCII

    # Update the link path to point to .cmd
    $versionClaudeLink = $wrapperCmd
    Write-Host "[OK] Created wrapper: $wrapperCmd" -ForegroundColor Green
}

Write-Host ""

# Step 4: Fix main bin symlink
Write-Host "Step 4: Creating main bin symlink..." -ForegroundColor Yellow
$mainClaudeLink = "$cvmBinDir\claude"

New-Item -ItemType Directory -Path $cvmBinDir -Force | Out-Null

# Remove old link if exists
if (Test-Path $mainClaudeLink) {
    Remove-Item $mainClaudeLink -Force
}

try {
    New-Item -ItemType SymbolicLink -Path $mainClaudeLink -Target $versionClaudeLink -Force -ErrorAction Stop | Out-Null
    Write-Host "[OK] Created main symlink" -ForegroundColor Green
    Write-Host "   $mainClaudeLink -> $versionClaudeLink"
}
catch {
    Write-Host "[X] Failed to create symlink: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Creating .cmd wrapper as fallback..." -ForegroundColor Yellow

    # Create .cmd wrapper instead
    $mainCmd = "$cvmBinDir\claude.cmd"
    @"
@echo off
node "$cliPath" %*
"@ | Out-File -FilePath $mainCmd -Encoding ASCII

    Write-Host "[OK] Created wrapper: $mainCmd" -ForegroundColor Green
}

Write-Host ""

# Step 5: Verify
Write-Host "Step 5: Verifying installation..." -ForegroundColor Yellow

# Check if .cvm\bin is in PATH
$pathParts = $env:PATH -split ';'
$cvmBinInPath = $pathParts | Where-Object { $_ -eq $cvmBinDir }

if (-not $cvmBinInPath) {
    Write-Host "[!] WARNING: $cvmBinDir is not in PATH" -ForegroundColor Yellow
    Write-Host "Add it to your profile:" -ForegroundColor Cyan
    Write-Host "  `$env:PATH = `"$cvmBinDir;`$env:PATH`""
    Write-Host ""
}

# Test claude command
Write-Host "Testing claude command..." -ForegroundColor Gray
try {
    # Try with node first (most reliable)
    $testOutput = node "$cliPath" --version 2>&1 | Out-String
    if ($testOutput) {
        Write-Host "[OK] Claude CLI works!" -ForegroundColor Green
        Write-Host "   Version output: $($testOutput.Trim())"
    } else {
        Write-Host "[!] Claude CLI responded but no version output" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[X] Failed to run claude: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "           FIX COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Close and reopen PowerShell"
Write-Host "  2. Try: claude --version"
Write-Host "  3. Or: cvm current"
Write-Host ""

if ($cvmBinInPath) {
    Write-Host "You can now use 'claude' command directly!" -ForegroundColor Green
} else {
    Write-Host "After adding to PATH, you can use 'claude' command!" -ForegroundColor Yellow
}

Write-Host ""
