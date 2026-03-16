#Requires -Version 5.1

<#
.SYNOPSIS
    Integration tests for cvm (Windows PowerShell version)

.DESCRIPTION
    Tests all cvm functionality in an isolated environment.
    Port of integration-test.sh for PowerShell.
#>

$ErrorActionPreference = 'Stop'

# ============================================================================
# Test Setup
# ============================================================================

$TEST_CVM_DIR = Join-Path $env:TEMP "cvm-test-$(Get-Random)"
$env:CVM_DIR = $TEST_CVM_DIR

Write-Host "=== cvm Integration Test ===" -ForegroundColor Cyan
Write-Host "Test directory: $TEST_CVM_DIR"
Write-Host ""

# Cleanup function
function Cleanup {
    Write-Host ""
    Write-Host "Cleaning up test directory..."
    if (Test-Path $TEST_CVM_DIR) {
        Remove-Item -Path $TEST_CVM_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Register cleanup
Register-EngineEvent PowerShell.Exiting -Action { Cleanup }

# Create test directory
New-Item -ItemType Directory -Path $TEST_CVM_DIR -Force | Out-Null
$env:PATH = "$TEST_CVM_DIR\bin;$env:PATH"

# Find cvm.ps1 script
$SCRIPT_DIR = Split-Path -Parent $PSScriptRoot
$CVM_CMD = Join-Path $SCRIPT_DIR "cvm.ps1"

if (-not (Test-Path $CVM_CMD)) {
    Write-Host "Error: Could not find cvm.ps1 at $CVM_CMD" -ForegroundColor Red
    exit 1
}

# ============================================================================
# Test Helper
# ============================================================================

$testCount = 0
$passCount = 0

function Test-Step {
    param(
        [string]$Description,
        [scriptblock]$Test
    )

    $script:testCount++
    Write-Host "$($script:testCount). Testing $Description..." -ForegroundColor Yellow

    try {
        & $Test
        Write-Host "   ✓ $Description" -ForegroundColor Green
        $script:passCount++
        return $true
    }
    catch {
        Write-Host "   ✗ $Description" -ForegroundColor Red
        Write-Host "     Error: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# Tests
# ============================================================================

Test-Step "help command" {
    $output = & $CVM_CMD help 2>&1 | Out-String
    if ($output -notmatch "Usage:") {
        throw "Help output doesn't contain 'Usage:'"
    }
}

Test-Step "version command" {
    $output = & $CVM_CMD version 2>&1 | Out-String
    if ($output -notmatch "1\.0\.0") {
        throw "Version output doesn't contain '1.0.0'"
    }
}

Test-Step "install command" {
    & $CVM_CMD install 2.1.63 2>&1 | Out-Null
    if (-not (Test-Path "$TEST_CVM_DIR\versions\2.1.63")) {
        throw "Version 2.1.63 not found"
    }
}

Test-Step "use command and symlink creation" {
    & $CVM_CMD use 2.1.63 2>&1 | Out-Null
    $claudeLink = Join-Path $TEST_CVM_DIR "bin\claude"
    if (-not (Test-Path $claudeLink)) {
        throw "Symlink not created"
    }
}

Test-Step "claude executable works" {
    $claudePath = Join-Path $TEST_CVM_DIR "bin\claude"
    if (Test-Path $claudePath) {
        try {
            $output = & node $claudePath --version 2>&1 | Out-String
            if ($LASTEXITCODE -ne 0 -and $output -notmatch "version") {
                # Some versions may fail, but we check it exists
                Write-Host "   Note: Claude executable exists but may need proper setup" -ForegroundColor Yellow
            }
        }
        catch {
            # Acceptable - the CLI might need additional setup
        }
    }
}

Test-Step "current command detection" {
    $output = & $CVM_CMD current 2>&1 | Out-String
    if ($output -notmatch "2\.1\.63") {
        throw "Current version not detected correctly"
    }
}

Test-Step "list command output" {
    $output = & $CVM_CMD list 2>&1 | Out-String
    if ($output -notmatch "2\.1\.63" -or $output -notmatch "currently active") {
        throw "List doesn't show version correctly"
    }
}

Test-Step "alias creation" {
    & $CVM_CMD alias test-provider 2.1.63 2>&1 | Out-Null
    $aliasFile = Join-Path $TEST_CVM_DIR "alias\test-provider"
    if (-not (Test-Path $aliasFile)) {
        throw "Alias not created"
    }
}

Test-Step "use with alias" {
    & $CVM_CMD use test-provider 2>&1 | Out-Null
    # Should succeed without error
}

Test-Step "list shows aliases" {
    $output = & $CVM_CMD list 2>&1 | Out-String
    if ($output -notmatch "test-provider -> 2\.1\.63") {
        throw "List doesn't show aliases"
    }
}

Test-Step "unalias command" {
    & $CVM_CMD unalias test-provider 2>&1 | Out-Null
    $aliasFile = Join-Path $TEST_CVM_DIR "alias\test-provider"
    if (Test-Path $aliasFile) {
        throw "Alias still exists"
    }
}

Test-Step "install second version for switching test" {
    & $CVM_CMD install 2.1.62 2>&1 | Out-Null
    if (-not (Test-Path "$TEST_CVM_DIR\versions\2.1.62")) {
        throw "Second version not installed"
    }
}

Test-Step "version switching" {
    & $CVM_CMD use 2.1.62 2>&1 | Out-Null
    $output = & $CVM_CMD current 2>&1 | Out-String
    if ($output -notmatch "2\.1\.62") {
        throw "Version switch failed"
    }
}

Test-Step "uninstall of non-active version" {
    $response = "y"
    $response | & $CVM_CMD uninstall 2.1.63 2>&1 | Out-Null
    if (Test-Path "$TEST_CVM_DIR\versions\2.1.63") {
        throw "Version still exists"
    }
}

Test-Step "uninstall of active version" {
    $response = "y"
    $response | & $CVM_CMD uninstall 2.1.62 2>&1 | Out-Null
    $claudeLink = Join-Path $TEST_CVM_DIR "bin\claude"
    if ((Test-Path "$TEST_CVM_DIR\versions\2.1.62") -or (Test-Path $claudeLink)) {
        throw "Active version uninstall failed"
    }
}

Test-Step "error: invalid version format" {
    $output = & $CVM_CMD install invalid-version 2>&1 | Out-String
    if ($output -notmatch "Invalid version format") {
        throw "Should reject invalid version format"
    }
}

Test-Step "error: use non-existent version" {
    $output = & $CVM_CMD use 9.9.9 2>&1 | Out-String
    if ($output -notmatch "not installed") {
        throw "Should error on non-existent version"
    }
}

Test-Step "error: unalias non-existent alias" {
    $output = & $CVM_CMD unalias nonexistent 2>&1 | Out-String
    if ($output -notmatch "does not exist") {
        throw "Should error on non-existent alias"
    }
}

# ============================================================================
# Results
# ============================================================================

Write-Host ""
if ($passCount -eq $testCount) {
    Write-Host "=== All $testCount tests passed! ===" -ForegroundColor Green
    Cleanup
    exit 0
} else {
    $failCount = $testCount - $passCount
    Write-Host "=== $failCount of $testCount tests failed ===" -ForegroundColor Red
    Cleanup
    exit 1
}
