#Requires -Version 5.1

<#
.SYNOPSIS
    cvm - Claude Version Manager for Windows

.DESCRIPTION
    A version manager for Claude Code CLI on Windows, inspired by nvm for Node.js.
    Manages multiple Claude CLI versions side-by-side.

.NOTES
    Version: 1.0.0
    Author: cvm team
    License: MIT
#>

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# Global Variables
# ============================================================================

$script:CVM_VERSION = "1.0.0"
$script:CVM_DIR = if ($env:CVM_DIR) { $env:CVM_DIR } else { Join-Path $env:USERPROFILE ".cvm" }
$script:CVM_VERSIONS_DIR = Join-Path $script:CVM_DIR "versions"
$script:CVM_BIN_DIR = Join-Path $script:CVM_DIR "bin"
$script:CVM_ALIAS_DIR = Join-Path $script:CVM_DIR "alias"

# ============================================================================
# Utility Functions
# ============================================================================

function Write-CvmEcho {
    param([string]$Message)
    Write-Host "[cvm] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-CvmError {
    param([string]$Message)
    Write-Host "[cvm ERROR] " -ForegroundColor Red -NoNewline
    Write-Error $Message -ErrorAction Continue
}

function Write-CvmWarn {
    param([string]$Message)
    Write-Host "[cvm WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

# ============================================================================
# Validation Functions
# ============================================================================

function Test-CvmVersion {
    param([string]$Version)

    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-CvmError "Invalid version format: $Version"
        Write-Host "Expected format: X.Y.Z (e.g., 2.1.71)"
        return $false
    }
    return $true
}

function Test-Npm {
    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-CvmError "npm is not installed or not in PATH"
        Write-Host "Please install Node.js and npm first:"
        Write-Host "  https://nodejs.org/"
        return $false
    }
    return $true
}

function Test-SymlinkSupport {
    $testDir = Join-Path $env:TEMP "cvm-symlink-test-$(Get-Random)"
    $testFile = Join-Path $testDir "test.txt"
    $testLink = Join-Path $testDir "test-link.txt"

    try {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        "test" | Out-File -FilePath $testFile
        New-Item -ItemType SymbolicLink -Path $testLink -Target $testFile -ErrorAction Stop | Out-Null
        Remove-Item -Path $testDir -Recurse -Force
        return $true
    }
    catch {
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        return $false
    }
}

# ============================================================================
# Initialization
# ============================================================================

function Initialize-Cvm {
    New-Item -ItemType Directory -Path $script:CVM_VERSIONS_DIR -Force | Out-Null
    New-Item -ItemType Directory -Path $script:CVM_BIN_DIR -Force | Out-Null
    New-Item -ItemType Directory -Path $script:CVM_ALIAS_DIR -Force | Out-Null
}

# ============================================================================
# Core Commands
# ============================================================================

function Invoke-CvmInstall {
    param([string]$Version)

    if (-not $Version) {
        Write-CvmError "Version number required"
        Write-Host "Usage: cvm install <version>"
        return 1
    }

    if (-not (Test-CvmVersion $Version)) {
        return 1
    }

    if (-not (Test-Npm)) {
        return 1
    }

    $versionDir = Join-Path $script:CVM_VERSIONS_DIR $Version

    if (Test-Path $versionDir) {
        Write-CvmWarn "Version $Version is already installed"
        return 0
    }

    Write-CvmEcho "Installing Claude CLI version $Version..."

    # Create temp directory
    $tempDir = Join-Path $env:TEMP "cvm-install-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        Push-Location $tempDir

        # Create package.json
        $packageJson = @{
            name = "cvm-temp-install"
            private = $true
            dependencies = @{
                "@anthropic-ai/claude-code" = $Version
            }
        } | ConvertTo-Json

        Set-Content -Path "package.json" -Value $packageJson

        # Install with npm
        Write-Host "Running npm install (this may take a moment)..."
        $npmOutput = npm install --production --no-audit --no-fund --loglevel error 2>&1

        if ($LASTEXITCODE -eq 0) {
            # Copy to version directory
            New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
            Copy-Item -Path "node_modules" -Destination $versionDir -Recurse -Force

            # Create bin directory with .cmd wrapper (Windows needs extension)
            $binDir = Join-Path $versionDir "bin"
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null

            $cliPath = Join-Path $versionDir "node_modules\@anthropic-ai\claude-code\cli.js"
            $claudeCmd = Join-Path $binDir "claude.cmd"

            # Create .cmd wrapper for Windows
            @"
@echo off
node "$cliPath" %*
"@ | Out-File -FilePath $claudeCmd -Encoding ASCII

            Write-CvmEcho "Successfully installed Claude CLI $Version"
            Pop-Location
            Remove-Item -Path $tempDir -Recurse -Force
            return 0
        } else {
            Write-CvmError "Failed to install version $Version"
            Write-Host "Check that version exists: npm view @anthropic-ai/claude-code versions"

            if (Test-Path $versionDir) {
                Remove-Item $versionDir -Recurse -Force
            }
            Pop-Location
            Remove-Item -Path $tempDir -Recurse -Force
            return 1
        }
    }
    catch {
        Write-CvmError "Installation failed: $($_.Exception.Message)"
        if (Test-Path $versionDir) {
            Remove-Item $versionDir -Recurse -Force
        }
        Pop-Location
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        return 1
    }
}

function Invoke-CvmUse {
    param([string]$Version)

    if (-not $Version) {
        Write-CvmError "Version number or alias required"
        Write-Host "Usage: cvm use <version|alias>"
        return 1
    }

    # Check if it's an alias
    $aliasFile = Join-Path $script:CVM_ALIAS_DIR $Version
    if (Test-Path $aliasFile) {
        $actualVersion = Get-Content $aliasFile -Raw
        $actualVersion = $actualVersion.Trim()
        Write-CvmEcho "Using alias '$Version' -> version $actualVersion"
        $Version = $actualVersion
    }

    $versionDir = Join-Path $script:CVM_VERSIONS_DIR $Version

    if (-not (Test-Path $versionDir)) {
        Write-CvmError "Version $Version is not installed"
        Write-Host "Run 'cvm install $Version' first"
        return 1
    }

    # Create main bin directory
    New-Item -ItemType Directory -Path $script:CVM_BIN_DIR -Force | Out-Null

    # Path to the version's wrapper
    $versionClaudeCmd = Join-Path $versionDir "bin\claude.cmd"
    $mainClaudeCmd = Join-Path $script:CVM_BIN_DIR "claude.cmd"

    # Remove old files
    Remove-Item "$script:CVM_BIN_DIR\claude" -Force -ErrorAction SilentlyContinue
    Remove-Item "$script:CVM_BIN_DIR\claude.cmd" -Force -ErrorAction SilentlyContinue

    # Get the cli.js path for the wrapper
    $cliPath = Join-Path $versionDir "node_modules\@anthropic-ai\claude-code\cli.js"

    if (-not (Test-Path $cliPath)) {
        Write-CvmError "cli.js not found for version $Version"
        Write-Host "Version may be corrupted. Try reinstalling:"
        Write-Host "  cvm uninstall $Version"
        Write-Host "  cvm install $Version"
        return 1
    }

    # Create .cmd wrapper in main bin directory
    @"
@echo off
node "$cliPath" %*
"@ | Out-File -FilePath $mainClaudeCmd -Encoding ASCII

    Write-CvmEcho "Now using Claude CLI version $Version"

    # Check if CVM_BIN_DIR is in PATH
    $pathParts = $env:PATH -split ';'
    $cvmBinInPath = $pathParts | Where-Object { $_ -eq $script:CVM_BIN_DIR }

    if (-not $cvmBinInPath) {
        Write-CvmWarn "Warning: $($script:CVM_BIN_DIR) is not in your PATH"
        Write-Host "Add to your PowerShell profile:"
        Write-Host "  `$env:PATH = `"$($script:CVM_BIN_DIR);`$env:PATH`""
    }

    return 0
}

function Invoke-CvmList {
    Write-CvmEcho "Installed Claude CLI versions:"
    Write-Host ""

    if (-not (Test-Path $script:CVM_VERSIONS_DIR) -or
        (Get-ChildItem $script:CVM_VERSIONS_DIR -Directory -ErrorAction SilentlyContinue).Count -eq 0) {
        Write-Host "  (none installed)"
        Write-Host ""
        Write-Host "Install a version with: cvm install <version>"
        return 0
    }

    # Get current version
    $currentVersion = $null
    $claudeCmd = Join-Path $script:CVM_BIN_DIR "claude.cmd"
    if (Test-Path $claudeCmd) {
        try {
            $cmdContent = Get-Content $claudeCmd -Raw
            if ($cmdContent -match 'versions[/\\]([^/\\]+)[/\\]') {
                $currentVersion = $matches[1]
            }
        }
        catch {
            # Ignore errors reading cmd file
        }
    }

    # List versions
    Get-ChildItem $script:CVM_VERSIONS_DIR -Directory | ForEach-Object {
        $version = $_.Name
        if ($version -eq $currentVersion) {
            Write-Host "  * " -NoNewline
            Write-Host $version -ForegroundColor Green -NoNewline
            Write-Host " (currently active)"
        } else {
            Write-Host "    $version"
        }
    }

    Write-Host ""

    # List aliases
    if ((Test-Path $script:CVM_ALIAS_DIR) -and
        (Get-ChildItem $script:CVM_ALIAS_DIR -File -ErrorAction SilentlyContinue).Count -gt 0) {
        Write-Host "Aliases:"
        Get-ChildItem $script:CVM_ALIAS_DIR -File | ForEach-Object {
            $aliasName = $_.Name
            $aliasVersion = (Get-Content $_.FullName -Raw).Trim()
            Write-Host "  $aliasName -> $aliasVersion"
        }
        Write-Host ""
    }

    return 0
}

function Invoke-CvmCurrent {
    $claudeCmd = Join-Path $script:CVM_BIN_DIR "claude.cmd"

    if (-not (Test-Path $claudeCmd)) {
        Write-CvmWarn "No active Claude CLI version"
        Write-Host "Run 'cvm use <version>' to activate a version"
        return 1
    }

    # Read the .cmd file to extract version
    try {
        $cmdContent = Get-Content $claudeCmd -Raw
        if ($cmdContent -match 'versions[/\\]([^/\\]+)[/\\]') {
            $version = $matches[1]
            Write-CvmEcho "Current version: " -NoNewline
            Write-Host $version -ForegroundColor Green

            # Try to get actual claude version
            try {
                $claudeVersion = & $claudeCmd --version 2>$null
                if ($claudeVersion) {
                    Write-Host "  ($claudeVersion)"
                }
            }
            catch {
                # Ignore if claude command fails
            }

            return 0
        } else {
            Write-CvmError "Could not parse version from claude.cmd"
            return 1
        }
    }
    catch {
        Write-CvmError "Could not determine current version: $($_.Exception.Message)"
        return 1
    }
}

function Invoke-CvmAlias {
    param(
        [string]$AliasName,
        [string]$Version
    )

    if (-not $AliasName -or -not $Version) {
        Write-CvmError "Alias name and version required"
        Write-Host "Usage: cvm alias <name> <version>"
        return 1
    }

    $versionDir = Join-Path $script:CVM_VERSIONS_DIR $Version
    if (-not (Test-Path $versionDir)) {
        Write-CvmError "Version $Version is not installed"
        Write-Host "Run 'cvm install $Version' first"
        return 1
    }

    New-Item -ItemType Directory -Path $script:CVM_ALIAS_DIR -Force | Out-Null
    $aliasFile = Join-Path $script:CVM_ALIAS_DIR $AliasName
    Set-Content -Path $aliasFile -Value $Version

    Write-CvmEcho "Created alias: $AliasName -> $Version"
    return 0
}

function Invoke-CvmUnalias {
    param([string]$AliasName)

    if (-not $AliasName) {
        Write-CvmError "Alias name required"
        Write-Host "Usage: cvm unalias <name>"
        return 1
    }

    $aliasFile = Join-Path $script:CVM_ALIAS_DIR $AliasName

    if (-not (Test-Path $aliasFile)) {
        Write-CvmError "Alias '$AliasName' does not exist"
        return 1
    }

    Remove-Item $aliasFile -Force
    Write-CvmEcho "Removed alias: $AliasName"
    return 0
}

function Invoke-CvmUninstall {
    param([string]$Version)

    if (-not $Version) {
        Write-CvmError "Version number required"
        Write-Host "Usage: cvm uninstall <version>"
        return 1
    }

    $versionDir = Join-Path $script:CVM_VERSIONS_DIR $Version

    if (-not (Test-Path $versionDir)) {
        Write-CvmError "Version $Version is not installed"
        return 1
    }

    # Check if this is the active version
    $claudeCmd = Join-Path $script:CVM_BIN_DIR "claude.cmd"
    if (Test-Path $claudeCmd) {
        try {
            $cmdContent = Get-Content $claudeCmd -Raw
            if ($cmdContent -match 'versions[/\\]([^/\\]+)[/\\]') {
                $currentVersion = $matches[1]

                if ($Version -eq $currentVersion) {
                    Write-CvmWarn "This is the currently active version"
                    $response = Read-Host "Continue with uninstall? [y/N]"
                    if ($response -notmatch '^[Yy]$') {
                        Write-CvmEcho "Uninstall cancelled"
                        return 0
                    }
                    Remove-Item $claudeCmd -Force
                    Write-CvmEcho "Deactivated version $Version"
                }
            }
        }
        catch {
            # Ignore errors
        }
    }

    # Remove version directory
    Remove-Item $versionDir -Recurse -Force
    Write-CvmEcho "Uninstalled Claude CLI version $Version"

    # Remove any aliases pointing to this version
    if (Test-Path $script:CVM_ALIAS_DIR) {
        Get-ChildItem $script:CVM_ALIAS_DIR -File | ForEach-Object {
            $aliasVersion = (Get-Content $_.FullName -Raw).Trim()
            if ($aliasVersion -eq $Version) {
                $aliasName = $_.Name
                Remove-Item $_.FullName -Force
                Write-CvmWarn "Removed alias '$aliasName' (was pointing to $Version)"
            }
        }
    }

    return 0
}

function Invoke-CvmFix {
    param([string]$Version = "")

    Write-Host "=== CVM Auto-Fix Tool ===" -ForegroundColor Cyan
    Write-Host ""

    # Check installed versions
    Write-Host "Checking installed versions..." -ForegroundColor Yellow

    if (-not (Test-Path $script:CVM_VERSIONS_DIR)) {
        Write-CvmError "No versions directory found"
        Write-Host "Please run: cvm install 2.1.63" -ForegroundColor Cyan
        return 1
    }

    $installedVersions = Get-ChildItem $script:CVM_VERSIONS_DIR -Directory -ErrorAction SilentlyContinue
    if ($installedVersions.Count -eq 0) {
        Write-CvmError "No versions installed"
        Write-Host "Please run: cvm install 2.1.63" -ForegroundColor Cyan
        return 1
    }

    Write-Host "[OK] Found $($installedVersions.Count) installed version(s)" -ForegroundColor Green
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
            Write-Host "Multiple versions installed. Specify which one to activate:" -ForegroundColor Yellow
            $Version = Read-Host "Enter version (e.g., 2.1.63)"
        }
    }

    if (-not $Version) {
        Write-CvmError "No version specified"
        return 1
    }

    Write-Host ""
    Write-Host "Fixing symlinks for version $Version..." -ForegroundColor Yellow

    $versionDir = Join-Path $script:CVM_VERSIONS_DIR $Version
    if (-not (Test-Path $versionDir)) {
        Write-CvmError "Version $Version not found"
        return 1
    }

    # Find cli.js
    $cliPath = Join-Path $versionDir "node_modules\@anthropic-ai\claude-code\cli.js"
    if (-not (Test-Path $cliPath)) {
        Write-CvmError "cli.js not found at: $cliPath"
        Write-Host "Version may be corrupted. Try reinstalling:" -ForegroundColor Yellow
        Write-Host "  cvm uninstall $Version"
        Write-Host "  cvm install $Version"
        return 1
    }

    Write-Host "[OK] Found cli.js" -ForegroundColor Green
    Write-Host ""

    # Fix version bin wrapper
    Write-Host "Creating version bin wrapper..." -ForegroundColor Yellow
    $versionBinDir = Join-Path $versionDir "bin"
    $versionClaudeCmd = Join-Path $versionBinDir "claude.cmd"

    New-Item -ItemType Directory -Path $versionBinDir -Force | Out-Null

    if (Test-Path $versionClaudeCmd) {
        Remove-Item $versionClaudeCmd -Force
    }

    # Create .cmd wrapper
    @"
@echo off
node "$cliPath" %*
"@ | Out-File -FilePath $versionClaudeCmd -Encoding ASCII

    Write-Host "[OK] Created version wrapper" -ForegroundColor Green

    Write-Host ""

    # Fix main bin wrapper
    Write-Host "Creating main bin wrapper..." -ForegroundColor Yellow
    $mainClaudeCmd = Join-Path $script:CVM_BIN_DIR "claude.cmd"

    New-Item -ItemType Directory -Path $script:CVM_BIN_DIR -Force | Out-Null

    # Remove old files
    Remove-Item "$script:CVM_BIN_DIR\claude" -Force -ErrorAction SilentlyContinue
    Remove-Item "$script:CVM_BIN_DIR\claude.cmd" -Force -ErrorAction SilentlyContinue

    # Create .cmd wrapper
    @"
@echo off
node "$cliPath" %*
"@ | Out-File -FilePath $mainClaudeCmd -Encoding ASCII

    Write-Host "[OK] Created main wrapper" -ForegroundColor Green

    Write-Host ""

    # Verify
    Write-Host "Verifying installation..." -ForegroundColor Yellow

    # Check PATH
    $pathParts = $env:PATH -split ';'
    $cvmBinInPath = $pathParts | Where-Object { $_ -eq $script:CVM_BIN_DIR }

    if (-not $cvmBinInPath) {
        Write-Host "[!] WARNING: $($script:CVM_BIN_DIR) is not in PATH" -ForegroundColor Yellow
        Write-Host "Add it to your profile:" -ForegroundColor Cyan
        Write-Host "  `$env:PATH = `"$($script:CVM_BIN_DIR);`$env:PATH`""
        Write-Host ""
    }

    # Test claude command
    try {
        $testOutput = node "$cliPath" --version 2>&1 | Out-String
        if ($testOutput) {
            Write-Host "[OK] Claude CLI works!" -ForegroundColor Green
            Write-Host "   Version: $($testOutput.Trim())"
        }
    }
    catch {
        Write-Host "[X] Failed to run claude: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "         FIX COMPLETE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Close and reopen PowerShell"
    Write-Host "  2. Try: claude --version"
    Write-Host "  3. Verify: cvm current"
    Write-Host ""

    return 0
}

function Invoke-CvmDoctor {
    Write-Host "=== CVM Doctor - System Diagnostic ===" -ForegroundColor Cyan
    Write-Host ""

    $allHealthy = $true

    # 1. Platform check
    Write-Host "1. Platform Check" -ForegroundColor Yellow
    Write-Host "   OS: Windows"
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Host "   Version: $($osVersion.Major).$($osVersion.Minor).$($osVersion.Build)"
    if ($osVersion.Major -lt 10) {
        Write-Host "   [X] Windows 10+ required" -ForegroundColor Red
        $allHealthy = $false
    } else {
        Write-Host "   [OK] Version compatible" -ForegroundColor Green
    }
    Write-Host ""

    # 2. Developer Mode check
    Write-Host "2. Developer Mode Check" -ForegroundColor Yellow
    try {
        $devMode = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction Stop).AllowDevelopmentWithoutDevLicense
        if ($devMode -eq 1) {
            Write-Host "   [OK] Developer Mode enabled" -ForegroundColor Green
        } else {
            Write-Host "   [X] Developer Mode disabled" -ForegroundColor Red
            Write-Host "   Fix: Settings > Update & Security > For developers" -ForegroundColor Yellow
            $allHealthy = $false
        }
    } catch {
        Write-Host "   [X] Developer Mode not configured" -ForegroundColor Red
        $allHealthy = $false
    }
    Write-Host ""

    # 3. Symlink capability test
    Write-Host "3. Symbolic Link Test" -ForegroundColor Yellow
    $testDir = Join-Path $env:TEMP "cvm-doctor-$(Get-Random)"
    try {
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $testFile = Join-Path $testDir "test.txt"
        $testLink = Join-Path $testDir "link.txt"
        "test" | Out-File $testFile
        New-Item -ItemType SymbolicLink -Path $testLink -Target $testFile -ErrorAction Stop | Out-Null
        Write-Host "   [OK] Can create symbolic links" -ForegroundColor Green
        Remove-Item -Path $testDir -Recurse -Force
    } catch {
        Write-Host "   [X] Cannot create symbolic links" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host "   Fix: Enable Developer Mode and restart" -ForegroundColor Yellow
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
        $allHealthy = $false
    }
    Write-Host ""

    # 4. Node.js and npm check
    Write-Host "4. Dependencies Check" -ForegroundColor Yellow
    $nodeVersion = node --version 2>$null
    $npmVersion = npm --version 2>$null

    if ($nodeVersion) {
        Write-Host "   [OK] Node.js: $nodeVersion" -ForegroundColor Green
    } else {
        Write-Host "   [X] Node.js not found" -ForegroundColor Red
        Write-Host "   Install: https://nodejs.org/" -ForegroundColor Yellow
        $allHealthy = $false
    }

    if ($npmVersion) {
        Write-Host "   [OK] npm: $npmVersion" -ForegroundColor Green
    } else {
        Write-Host "   [X] npm not found" -ForegroundColor Red
        $allHealthy = $false
    }
    Write-Host ""

    # 5. cvm directory structure
    Write-Host "5. CVM Installation Check" -ForegroundColor Yellow
    $dirs = @(
        @{Path="$script:CVM_DIR"; Name="cvm directory"},
        @{Path="$script:CVM_VERSIONS_DIR"; Name="versions directory"},
        @{Path="$script:CVM_BIN_DIR"; Name="bin directory"},
        @{Path="$script:CVM_ALIAS_DIR"; Name="alias directory"}
    )

    foreach ($dir in $dirs) {
        if (Test-Path $dir.Path) {
            Write-Host "   [OK] $($dir.Name)" -ForegroundColor Green
        } else {
            Write-Host "   [!] $($dir.Name) missing (will be created on first use)" -ForegroundColor Yellow
        }
    }
    Write-Host ""

    # 6. PATH configuration
    Write-Host "6. PATH Configuration" -ForegroundColor Yellow
    $pathParts = $env:PATH -split ';'
    $cvmBinInPath = $pathParts | Where-Object { $_ -eq $script:CVM_BIN_DIR }

    if ($cvmBinInPath) {
        Write-Host "   [OK] cvm bin directory in PATH" -ForegroundColor Green
    } else {
        Write-Host "   [X] cvm bin directory NOT in PATH" -ForegroundColor Red
        Write-Host "   Add to profile: `$env:PATH = `"$($script:CVM_BIN_DIR);`$env:PATH`"" -ForegroundColor Yellow
        $allHealthy = $false
    }
    Write-Host ""

    # 7. Installed versions check
    Write-Host "7. Installed Versions" -ForegroundColor Yellow
    if (Test-Path $script:CVM_VERSIONS_DIR) {
        $versions = Get-ChildItem $script:CVM_VERSIONS_DIR -Directory -ErrorAction SilentlyContinue
        if ($versions.Count -gt 0) {
            Write-Host "   [OK] $($versions.Count) version(s) installed:" -ForegroundColor Green
            foreach ($v in $versions) {
                $cliPath = Join-Path $v.FullName "node_modules\@anthropic-ai\claude-code\cli.js"
                if (Test-Path $cliPath) {
                    Write-Host "       - $($v.Name) [OK]" -ForegroundColor Gray
                } else {
                    Write-Host "       - $($v.Name) [CORRUPTED]" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "   [!] No versions installed yet" -ForegroundColor Yellow
            Write-Host "   Run: cvm install 2.1.71" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   [!] No versions installed yet" -ForegroundColor Yellow
    }
    Write-Host ""

    # 8. Current version check
    Write-Host "8. Active Version Check" -ForegroundColor Yellow
    $claudeCmd = Join-Path $script:CVM_BIN_DIR "claude.cmd"
    if (Test-Path $claudeCmd) {
        try {
            $cmdContent = Get-Content $claudeCmd -Raw
            Write-Host "   [OK] claude.cmd exists" -ForegroundColor Green

            if ($cmdContent -match 'versions[/\\]([^/\\]+)[/\\]') {
                $version = $matches[1]
                Write-Host "   Version: $version" -ForegroundColor Gray

                $cliPath = Join-Path $script:CVM_VERSIONS_DIR "$version\node_modules\@anthropic-ai\claude-code\cli.js"
                if (Test-Path $cliPath) {
                    Write-Host "   [OK] Target cli.js is valid" -ForegroundColor Green
                } else {
                    Write-Host "   [X] Target cli.js does not exist!" -ForegroundColor Red
                    Write-Host "   Fix: cvm fix" -ForegroundColor Yellow
                    $allHealthy = $false
                }
            } else {
                Write-Host "   [X] Cannot parse version from claude.cmd" -ForegroundColor Red
                $allHealthy = $false
            }
        } catch {
            Write-Host "   [X] Error reading claude.cmd: $($_.Exception.Message)" -ForegroundColor Red
            $allHealthy = $false
        }
    } else {
        Write-Host "   [!] No active version" -ForegroundColor Yellow
        Write-Host "   Run: cvm use <version>" -ForegroundColor Cyan
    }
    Write-Host ""

    # Summary
    Write-Host "========================================" -ForegroundColor Cyan
    if ($allHealthy) {
        Write-Host "[OK] All checks passed!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Your cvm installation is healthy." -ForegroundColor Green
    } else {
        Write-Host "[!] Some issues detected" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please fix the issues above." -ForegroundColor Yellow
        Write-Host "For detailed help, see:" -ForegroundColor Cyan
        Write-Host "  https://github.com/kimmykuang/cvm/blob/main/docs/WINDOWS.md"
    }
    Write-Host ""

    if ($allHealthy) {
        return 0
    } else {
        return 1
    }
}

function Invoke-CvmUpdate {
    Write-Host "=== CVM Self-Update ===" -ForegroundColor Cyan
    Write-Host ""

    # Check if we're in a git repository
    $cvmRepoDir = "$env:USERPROFILE\.cvm-repo"

    if (-not (Test-Path $cvmRepoDir)) {
        Write-CvmError "CVM repository not found at: $cvmRepoDir"
        Write-Host "Please reinstall cvm using install.ps1"
        return 1
    }

    Push-Location $cvmRepoDir

    try {
        # Check if git is available
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-CvmError "git is not installed"
            Write-Host "Please install git: https://git-scm.com/"
            return 1
        }

        # Check if it's a git repository
        $isGitRepo = Test-Path (Join-Path $cvmRepoDir ".git")
        if (-not $isGitRepo) {
            Write-CvmError "Not a git repository"
            Write-Host "Please reinstall cvm using install.ps1"
            return 1
        }

        # Get current commit
        $currentCommit = git rev-parse --short HEAD 2>$null
        Write-Host "Current version: $currentCommit" -ForegroundColor Gray
        Write-Host ""

        # Fetch updates
        Write-Host "Fetching updates from GitHub..." -ForegroundColor Yellow
        git fetch origin 2>&1 | Out-Null

        if ($LASTEXITCODE -ne 0) {
            Write-CvmError "Failed to fetch updates"
            return 1
        }

        # Check if updates available
        $localCommit = git rev-parse HEAD
        $remoteCommit = git rev-parse origin/main

        if ($localCommit -eq $remoteCommit) {
            Write-Host "[OK] Already up to date!" -ForegroundColor Green
            return 0
        }

        # Show what will be updated
        Write-Host "Updates available:" -ForegroundColor Cyan
        git log --oneline HEAD..origin/main | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        Write-Host ""

        # Confirm update
        $response = Read-Host "Update to latest version? [Y/n]"
        if ($response -match '^[Nn]$') {
            Write-Host "Update cancelled."
            return 0
        }

        # Pull updates
        Write-Host ""
        Write-Host "Updating..." -ForegroundColor Yellow
        $output = git pull origin main 2>&1

        if ($LASTEXITCODE -eq 0) {
            $newCommit = git rev-parse --short HEAD
            Write-Host ""
            Write-Host "[OK] Successfully updated!" -ForegroundColor Green
            Write-Host "Old version: $currentCommit" -ForegroundColor Gray
            Write-Host "New version: $newCommit" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Please restart PowerShell for changes to take effect." -ForegroundColor Cyan
            return 0
        } else {
            Write-CvmError "Update failed"
            Write-Host $output
            return 1
        }
    }
    finally {
        Pop-Location
    }
}

function Show-CvmHelp {
    @"
Usage: cvm <command> [args]

Commands:
  install <version>     Install a specific Claude CLI version
  use <version|alias>   Switch to a specific version or alias
  list, ls              List installed versions
  current               Show current active version
  alias <name> <ver>    Create a named alias for a version
  unalias <name>        Remove an alias
  uninstall <version>   Remove an installed version
  doctor                Run system diagnostics
  fix [version]         Auto-fix symlink issues
  update                Update cvm to the latest version
  version, -v, --version  Show cvm version
  help, -h, --help      Show this help message

Examples:
  cvm install 2.1.71
  cvm use 2.1.71
  cvm list
  cvm current
  cvm doctor            # Diagnose issues
  cvm fix               # Auto-fix symlink problems
  cvm fix 2.1.71        # Fix specific version
  cvm update            # Update cvm itself
  cvm alias stable 2.1.71
  cvm uninstall 2.1.63

Troubleshooting workflow:
  1. cvm doctor         # Identify problems
  2. cvm fix            # Auto-fix symlink issues
  3. cvm doctor         # Verify fixes

Documentation: https://github.com/kimmykuang/cvm
"@
}

# ============================================================================
# Main Entry Point
# ============================================================================

# Initialize directories if needed
if (-not (Test-Path $script:CVM_DIR)) {
    Initialize-Cvm
}

# Parse command
$cmd = if ($Command) { $Command.ToLower() } else { "help" }

switch ($cmd) {
    "install" {
        $version = $Arguments[0]
        exit (Invoke-CvmInstall $version)
    }
    "use" {
        $version = $Arguments[0]
        exit (Invoke-CvmUse $version)
    }
    { $_ -in "list", "ls" } {
        exit (Invoke-CvmList)
    }
    "current" {
        exit (Invoke-CvmCurrent)
    }
    "alias" {
        $aliasName = $Arguments[0]
        $version = $Arguments[1]
        exit (Invoke-CvmAlias $aliasName $version)
    }
    "unalias" {
        $aliasName = $Arguments[0]
        exit (Invoke-CvmUnalias $aliasName)
    }
    { $_ -in "uninstall", "remove" } {
        $version = $Arguments[0]
        exit (Invoke-CvmUninstall $version)
    }
    "doctor" {
        exit (Invoke-CvmDoctor)
    }
    "fix" {
        $version = $Arguments[0]
        exit (Invoke-CvmFix $version)
    }
    "update" {
        exit (Invoke-CvmUpdate)
    }
    { $_ -in "version", "--version", "-v" } {
        Write-Host "cvm $($script:CVM_VERSION)"
        exit 0
    }
    { $_ -in "help", "--help", "-h" } {
        Show-CvmHelp
        exit 0
    }
    default {
        Write-CvmError "Unknown command: $cmd"
        Write-Host ""
        Show-CvmHelp
        exit 1
    }
}
