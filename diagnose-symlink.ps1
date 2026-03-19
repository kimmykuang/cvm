#Requires -Version 5.1

<#
.SYNOPSIS
    Windows symbolic link diagnostic tool for cvm

.DESCRIPTION
    Diagnoses symbolic link creation issues on Windows and provides solutions.

.EXAMPLE
    .\diagnose-symlink.ps1
#>

$ErrorActionPreference = 'Continue'

# Set console output encoding to UTF-8 to avoid garbled characters
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== CVM Windows Symlink Diagnostic Tool ===" -ForegroundColor Cyan
Write-Host ""

# Test results
$allTestsPassed = $true

# 1. Check Windows version
Write-Host "1. Checking Windows version..." -ForegroundColor Yellow
$osVersion = [System.Environment]::OSVersion.Version
Write-Host "   Windows: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)"

if ($osVersion.Major -lt 10) {
    Write-Host "   [X] FAIL: Windows 10+ required" -ForegroundColor Red
    $allTestsPassed = $false
} else {
    Write-Host "   [OK] PASS: Windows version OK" -ForegroundColor Green
}
Write-Host ""

# 2. Check Developer Mode
Write-Host "2. Checking Developer Mode status..." -ForegroundColor Yellow
try {
    $devMode = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction Stop).AllowDevelopmentWithoutDevLicense

    if ($devMode -eq 1) {
        Write-Host "   [OK] PASS: Developer Mode is ENABLED" -ForegroundColor Green
    } else {
        Write-Host "   [X] FAIL: Developer Mode is DISABLED (value: $devMode)" -ForegroundColor Red
        $allTestsPassed = $false
    }
} catch {
    Write-Host "   [X] FAIL: Developer Mode registry key not found" -ForegroundColor Red
    Write-Host "   Registry path: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ForegroundColor Gray
    $allTestsPassed = $false
}
Write-Host ""

# 3. Check execution context
Write-Host "3. Checking execution context..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "   [i] INFO: Running as Administrator" -ForegroundColor Cyan
} else {
    Write-Host "   [i] INFO: Running as regular user" -ForegroundColor Cyan
}
Write-Host ""

# 4. Test file symlink creation
Write-Host "4. Testing file symbolic link creation..." -ForegroundColor Yellow
$testDir = Join-Path $env:TEMP "cvm-diag-$(Get-Random)"
$testFile = Join-Path $testDir "test.txt"
$testLink = Join-Path $testDir "test-link.txt"

try {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    "test content" | Out-File -FilePath $testFile -Encoding UTF8

    New-Item -ItemType SymbolicLink -Path $testLink -Target $testFile -ErrorAction Stop | Out-Null

    $linkContent = Get-Content $testLink -Raw -ErrorAction Stop
    if ($linkContent -match "test content") {
        Write-Host "   [OK] PASS: File symlink works!" -ForegroundColor Green
    } else {
        Write-Host "   [X] FAIL: Symlink created but content wrong" -ForegroundColor Red
        $allTestsPassed = $false
    }

    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "   [X] FAIL: Cannot create file symlink" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $allTestsPassed = $false
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ""

# 5. Test directory symlink
Write-Host "5. Testing directory symbolic link creation..." -ForegroundColor Yellow
$testDir = Join-Path $env:TEMP "cvm-diag-$(Get-Random)"
$targetDir = Join-Path $testDir "target"
$linkDir = Join-Path $testDir "link"

try {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    "test" | Out-File -FilePath (Join-Path $targetDir "file.txt")

    New-Item -ItemType SymbolicLink -Path $linkDir -Target $targetDir -ErrorAction Stop | Out-Null

    if (Test-Path (Join-Path $linkDir "file.txt")) {
        Write-Host "   [OK] PASS: Directory symlink works!" -ForegroundColor Green
    } else {
        Write-Host "   [X] FAIL: Dir symlink created but files not accessible" -ForegroundColor Red
        $allTestsPassed = $false
    }

    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "   [X] FAIL: Cannot create directory symlink" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    $allTestsPassed = $false
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ""

# 6. Check privileges
Write-Host "6. Checking SeCreateSymbolicLinkPrivilege..." -ForegroundColor Yellow
try {
    $privOutput = whoami /priv 2>$null | Out-String
    if ($privOutput -match "SeCreateSymbolicLinkPrivilege") {
        Write-Host "   [OK] PASS: Privilege found" -ForegroundColor Green
        if ($privOutput -match "SeCreateSymbolicLinkPrivilege.*Enabled") {
            Write-Host "   Status: ENABLED" -ForegroundColor Green
        } else {
            Write-Host "   Status: DISABLED (but may auto-enable when needed)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   [!] WARNING: Privilege not found in whoami output" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [!] WARNING: Could not check privileges" -ForegroundColor Yellow
}
Write-Host ""

# 7. Check Node.js/npm
Write-Host "7. Checking Node.js and npm..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>$null
    $npmVersion = npm --version 2>$null

    if ($nodeVersion) {
        Write-Host "   [OK] Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "   [X] Node.js not found in PATH" -ForegroundColor Red
    }

    if ($npmVersion) {
        Write-Host "   [OK] npm: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "   [X] npm not found in PATH" -ForegroundColor Red
    }
} catch {
    Write-Host "   [!] Could not check Node.js/npm" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "           DIAGNOSTIC SUMMARY         " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

if ($allTestsPassed) {
    Write-Host "[OK] ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Symbolic links are working correctly on your system." -ForegroundColor Green
    Write-Host "If cvm still has issues, try:" -ForegroundColor Cyan
    Write-Host "  1. Restart PowerShell"
    Write-Host "  2. Clear npm cache: npm cache clean --force"
    Write-Host "  3. Run: cvm install 2.1.71"
    Write-Host ""
} else {
    Write-Host "[X] SOME TESTS FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "=== RECOMMENDED ACTIONS ===" -ForegroundColor Yellow
    Write-Host ""

    if ($devMode -ne 1) {
        Write-Host "STEP 1: Enable Developer Mode" -ForegroundColor Cyan
        Write-Host "─────────────────────────────" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Method A - Settings UI (Recommended):" -ForegroundColor White
        Write-Host "  1. Press Win + I to open Settings"
        Write-Host "  2. Go to: Update & Security > For developers"
        Write-Host "  3. Toggle 'Developer mode' to ON"
        Write-Host "  4. Click 'Yes' when prompted"
        Write-Host "  5. ** RESTART YOUR COMPUTER **"
        Write-Host ""
        Write-Host "Method B - Registry (Run as Administrator):" -ForegroundColor White
        Write-Host '  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f'
        Write-Host "  Then ** RESTART YOUR COMPUTER **"
        Write-Host ""
    }

    Write-Host "STEP 2: Restart and Verify" -ForegroundColor Cyan
    Write-Host "───────────────────────────" -ForegroundColor Gray
    Write-Host "  After enabling Developer Mode:"
    Write-Host "  1. Restart your computer (REQUIRED!)"
    Write-Host "  2. Run this script again: .\diagnose-symlink.ps1"
    Write-Host "  3. All tests should pass"
    Write-Host ""

    Write-Host "STEP 3: Alternative Solutions (if above fails)" -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Option A - Run as Administrator:" -ForegroundColor White
    Write-Host "    Right-click PowerShell > Run as Administrator"
    Write-Host "    Then try: cvm install 2.1.71"
    Write-Host ""
    Write-Host "  Option B - Check Security Software:" -ForegroundColor White
    Write-Host "    - Temporarily disable antivirus (Windows Defender, etc.)"
    Write-Host "    - Add cvm directory to whitelist"
    Write-Host ""
    Write-Host "  Option C - Enterprise Environment:" -ForegroundColor White
    Write-Host "    - Contact your IT department"
    Write-Host "    - Company policies may block Developer Mode"
    Write-Host ""
}

Write-Host "For detailed troubleshooting: https://github.com/kimmykuang/cvm/blob/main/docs/WINDOWS.md" -ForegroundColor Cyan
Write-Host ""

# Exit with appropriate code
if ($allTestsPassed) {
    exit 0
} else {
    exit 1
}
