#Requires -Version 5.1

<#
.SYNOPSIS
    cvm installer for Windows

.DESCRIPTION
    Installs cvm (Claude Version Manager) to $env:USERPROFILE\.cvm-repo
    and configures PowerShell profile.

.NOTES
    Version: 1.0.0
#>

$ErrorActionPreference = 'Stop'

Write-Host "Installing cvm (Claude Version Manager) for Windows..."
Write-Host ""

# ============================================================================
# Check Prerequisites
# ============================================================================

# Check for git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Error: git is required but not installed." -ForegroundColor Red
    Write-Host "Please install git first: https://git-scm.com/downloads"
    exit 1
}

# Check for npm (warn but don't fail)
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Warning: npm is not installed." -ForegroundColor Yellow
    Write-Host "npm is required to install Claude CLI versions."
    Write-Host "Please install Node.js (includes npm): https://nodejs.org/"
    Write-Host ""
    Write-Host "Continuing installation anyway..."
    Write-Host ""
}

# ============================================================================
# Test Symlink Support
# ============================================================================

Write-Host "Testing symbolic link support..."
$testDir = Join-Path $env:TEMP "cvm-symlink-test-$(Get-Random)"
$testFile = Join-Path $testDir "test.txt"
$testLink = Join-Path $testDir "test-link.txt"

try {
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    "test" | Out-File -FilePath $testFile
    New-Item -ItemType SymbolicLink -Path $testLink -Target $testFile -ErrorAction Stop | Out-Null
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "✓ Symbolic links supported" -ForegroundColor Green
    Write-Host ""
}
catch {
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "WARNING: Symbolic links are not supported!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "cvm requires Windows Developer Mode to be enabled for symbolic link support."
    Write-Host ""
    Write-Host "To enable Developer Mode:" -ForegroundColor Cyan
    Write-Host "  1. Open Settings"
    Write-Host "  2. Go to Update & Security > For developers"
    Write-Host "  3. Toggle 'Developer mode' to ON"
    Write-Host ""
    Write-Host "Or run as administrator:" -ForegroundColor Cyan
    Write-Host '  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f'
    Write-Host ""
    Write-Host "After enabling, restart PowerShell and run this installer again."
    Write-Host ""

    $continue = Read-Host "Continue installation anyway? (y/N)"
    if ($continue -notmatch '^[Yy]$') {
        Write-Host "Installation cancelled."
        exit 1
    }
    Write-Host ""
}

# ============================================================================
# Clone/Update Repository
# ============================================================================

$CVM_DIR = Join-Path $env:USERPROFILE ".cvm-repo"

if (Test-Path $CVM_DIR) {
    Write-Host "Updating existing cvm installation..."
    Push-Location $CVM_DIR
    try {
        git fetch --all --quiet 2>&1 | Out-Null
        git reset --hard origin/main --quiet 2>&1 | Out-Null
        Write-Host "Updated cvm to latest version."
    }
    catch {
        Write-Host "Warning: Could not update repository: $_" -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "Cloning cvm repository..."
    try {
        git clone https://github.com/kimmykuang/cvm.git $CVM_DIR 2>&1 | Out-Null
        Write-Host "Cloned cvm repository."
    }
    catch {
        Write-Host "Error: Failed to clone repository: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# ============================================================================
# Configure PowerShell Profile
# ============================================================================

# Get profile path
$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    Write-Host "Creating PowerShell profile at: $profilePath"
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
}

# Check if already configured
$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
$alreadyConfigured = $false

if ($profileContent -match '\.cvm\\bin' -and $profileContent -match 'cvm-repo\\cvm\.ps1') {
    $alreadyConfigured = $true
}

if ($alreadyConfigured) {
    Write-Host "cvm is already configured in your PowerShell profile"
} else {
    Write-Host "Configuring PowerShell profile..."

    # Add configuration
    $cvmConfig = @"

# cvm (Claude Version Manager)
`$env:PATH = "`$env:USERPROFILE\.cvm\bin;`$env:PATH"
function cvm { & "`$env:USERPROFILE\.cvm-repo\cvm.ps1" @args }
"@

    Add-Content -Path $profilePath -Value $cvmConfig
    Write-Host "Added cvm configuration to $profilePath"
}

Write-Host ""

# ============================================================================
# Create Directory Structure
# ============================================================================

$cvmDataDir = Join-Path $env:USERPROFILE ".cvm"
$cvmVersionsDir = Join-Path $cvmDataDir "versions"
$cvmBinDir = Join-Path $cvmDataDir "bin"
$cvmAliasDir = Join-Path $cvmDataDir "alias"

New-Item -ItemType Directory -Path $cvmVersionsDir -Force | Out-Null
New-Item -ItemType Directory -Path $cvmBinDir -Force | Out-Null
New-Item -ItemType Directory -Path $cvmAliasDir -Force | Out-Null

Write-Host "Created directory structure at $cvmDataDir"

# ============================================================================
# Final Message
# ============================================================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "cvm installation complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Restart PowerShell or run:"
Write-Host "     . `$PROFILE"
Write-Host ""
Write-Host "  2. Install a Claude CLI version:"
Write-Host "     cvm install 2.1.71"
Write-Host ""
Write-Host "  3. Switch to the installed version:"
Write-Host "     cvm use 2.1.71"
Write-Host ""
Write-Host "  4. Verify installation:"
Write-Host "     claude --version"
Write-Host ""
Write-Host "For more information, visit:" -ForegroundColor Cyan
Write-Host "  https://github.com/kimmykuang/cvm"
Write-Host ""

# Check if current session has cvm in PATH
$pathParts = $env:PATH -split ';'
$cvmBinInPath = $pathParts | Where-Object { $_ -eq $cvmBinDir }

if (-not $cvmBinInPath) {
    Write-Host "Note: You'll need to restart PowerShell for cvm to be available." -ForegroundColor Yellow
    Write-Host ""
}
