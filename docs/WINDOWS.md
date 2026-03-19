# cvm for Windows

Complete guide to using cvm (Claude Version Manager) on Windows.

## System Requirements

- **Windows 10** (version 1607 or later) or **Windows 11**
- **PowerShell 5.1 or later** (included with Windows)
- **npm** (Node.js 14+ recommended) - [Download here](https://nodejs.org/)
- **Git for Windows** - [Download here](https://git-scm.com/download/win)

**Note:** Developer Mode is **NOT required** anymore! cvm now uses `.cmd` wrapper files instead of symbolic links on Windows.

## What is Developer Mode?

Windows requires Developer Mode to be enabled for applications to create symbolic links without administrator privileges. This is a Windows security feature that cvm needs to work properly.

### Enabling Developer Mode

#### Method 1: Via Settings (Recommended)

1. Open **Windows Settings** (Win + I)
2. Go to **Update & Security**
3. Click **For developers** in the left sidebar
4. Toggle **Developer Mode** to **ON**
5. Click **Yes** when prompted to confirm
6. Restart your computer (recommended)

#### Method 2: Via Registry (Administrator Required)

Run PowerShell as Administrator and execute:

```powershell
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense /t REG_DWORD /d 1 /f
```

Then restart your computer.

#### Verifying Developer Mode

Run this in PowerShell:

```powershell
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
```

If it returns `1`, Developer Mode is enabled.

## Installation

### Option 1: Install via PowerShell (Recommended)

1. Open **PowerShell** (you don't need admin privileges)

2. Download and run the installer:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/kimmykuang/cvm/main/install.ps1 -OutFile install.ps1
.\install.ps1
```

3. Restart PowerShell or reload your profile:

```powershell
. $PROFILE
```

4. Verify installation:

```powershell
cvm version
```

### Option 2: Install via Git Bash

If you're using Git Bash, the installer will automatically detect Windows and redirect to the PowerShell installer:

```bash
curl -o- https://raw.githubusercontent.com/kimmykuang/cvm/main/install.sh | bash
```

This will launch PowerShell to complete the installation.

### Option 3: Manual Installation

1. Clone the repository:

```powershell
git clone https://github.com/kimmykuang/cvm.git "$env:USERPROFILE\.cvm-repo"
```

2. Edit your PowerShell profile:

```powershell
notepad $PROFILE
```

3. Add these lines:

```powershell
$env:PATH = "$env:USERPROFILE\.cvm\bin;$env:PATH"
function cvm { & "$env:USERPROFILE\.cvm-repo\cvm.ps1" @args }
```

4. Save and restart PowerShell.

## Usage

### Installing Claude CLI Versions

```powershell
# Install specific version
cvm install 2.1.71

# Install another version
cvm install 2.1.63
```

### Switching Versions

```powershell
# Switch to a version
cvm use 2.1.71

# Verify
claude --version
```

### Listing Installed Versions

```powershell
cvm list
```

Output example:
```
[cvm] Installed Claude CLI versions:

  * 2.1.71 (currently active)
    2.1.63
    2.1.60

Aliases:
  provider-a -> 2.1.71
  provider-restricted -> 2.1.63
```

### Creating Aliases

```powershell
# Create named aliases for providers
cvm alias provider-a 2.1.71
cvm alias provider-b 2.1.63

# Switch using alias
cvm use provider-a
```

### Checking Current Version

```powershell
cvm current
```

### Uninstalling Versions

```powershell
# Uninstall a version
cvm uninstall 2.1.63

# If it's the active version, you'll be prompted to confirm
```

### Removing Aliases

```powershell
cvm unalias provider-a
```

## Working in Different Shells

### PowerShell

cvm works natively in PowerShell:

```powershell
cvm list
claude --version
```

### Command Prompt (CMD)

In Command Prompt, you need to call PowerShell:

```cmd
powershell cvm list
powershell claude --version
```

Or better yet, just use PowerShell!

### Git Bash

Git Bash users are automatically redirected to use the PowerShell version during installation. After installation, you can use cvm from PowerShell.

### Windows Terminal

cvm works great with [Windows Terminal](https://aka.ms/terminal). Just use the PowerShell tab.

## Troubleshooting

### "cvm : The term 'cvm' is not recognized"

**Problem:** PowerShell doesn't recognize the `cvm` command.

**Solution:**

1. Make sure you've restarted PowerShell after installation
2. Or reload your profile: `. $PROFILE`
3. Check if profile is configured:

```powershell
Get-Content $PROFILE
```

Should contain the cvm configuration lines.

### "Cannot create symbolic link" Error

**Problem:** You get an error when running `cvm use`:

```
Failed to create symbolic link. Developer Mode may not be enabled.
```

**Solution:** Enable Developer Mode (see instructions above), then restart PowerShell and try again.

### "claude : The term 'claude' is not recognized"

**Problem:** After `cvm use`, the `claude` command doesn't work.

**Solution:**

1. Check if PATH is configured:

```powershell
$env:PATH -split ';' | Select-String ".cvm"
```

Should show `C:\Users\YourName\.cvm\bin`

2. Verify the symlink exists:

```powershell
Test-Path "$env:USERPROFILE\.cvm\bin\claude"
```

3. Check current version:

```powershell
cvm current
```

### npm Install Fails

**Problem:** `cvm install 2.1.71` fails with npm errors.

**Solutions:**

1. Check npm is installed: `npm --version`
2. Update npm: `npm install -g npm@latest`
3. Clear npm cache: `npm cache clean --force`
4. Check version exists: `npm view @anthropic-ai/claude-code versions`

### Execution Policy Errors

**Problem:** PowerShell won't run scripts due to execution policy.

```
install.ps1 cannot be loaded because running scripts is disabled
```

**Solution:**

For just this script:
```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

Or change your execution policy (requires admin):
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PATH Not Persisting

**Problem:** `cvm` works in one PowerShell session but not after restart.

**Solution:**

1. Check your profile file exists:

```powershell
Test-Path $PROFILE
```

2. Check profile loads automatically:

```powershell
$PROFILE
Get-Content $PROFILE
```

3. Make sure the cvm configuration is in your profile.

### Version Switching Doesn't Work

**Problem:** `cvm use` succeeds but `claude --version` shows wrong version.

**Solution:**

1. Check what `claude` command is being used:

```powershell
(Get-Command claude).Source
```

Should point to: `C:\Users\YourName\.cvm\bin\claude`

2. If it points elsewhere, you may have another Claude installation in PATH that takes precedence.

3. Check PATH order:

```powershell
$env:PATH -split ';'
```

The `.cvm\bin` directory should be near the beginning.

## Uninstalling cvm

### Complete Removal

1. Remove all installed versions and data:

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.cvm"
Remove-Item -Recurse -Force "$env:USERPROFILE\.cvm-repo"
```

2. Edit your PowerShell profile:

```powershell
notepad $PROFILE
```

3. Remove these lines:

```powershell
$env:PATH = "$env:USERPROFILE\.cvm\bin;$env:PATH"
function cvm { & "$env:USERPROFILE\.cvm-repo\cvm.ps1" @args }
```

4. Restart PowerShell.

## Advanced Topics

### Using with WSL

If you're using Windows Subsystem for Linux (WSL), you should use the bash version of cvm inside WSL, not the PowerShell version.

Inside WSL:
```bash
curl -o- https://raw.githubusercontent.com/kimmykuang/cvm/main/install.sh | bash
```

The installer will detect WSL and use the bash version automatically.

### Custom Installation Directory

You can customize the installation directory with the `$env:CVM_DIR` environment variable:

```powershell
$env:CVM_DIR = "D:\tools\cvm"
cvm install 2.1.71
```

Note: You'll need to set this in your profile to persist across sessions.

### Integration with cc-switch

If you use [cc-switch](https://github.com/YOUR_CC_SWITCH_REPO) to manage multiple Claude providers:

```powershell
# Step 1: Install required Claude CLI versions
cvm install 2.1.71  # For restricted provider
cvm install 2.1.63  # For other providers

# Step 2: Create meaningful aliases
cvm alias anthropic-official 2.1.63
cvm alias provider-restricted 2.1.71

# Step 3: Switch before changing providers
cvm use provider-restricted
# Now use cc-switch to select that provider

cvm use anthropic-official
# Now use cc-switch to select official provider
```

## Getting Help

### Documentation

- Main README: [README.md](../README.md)
- Contributing: [CONTRIBUTING.md](../CONTRIBUTING.md)
- Changelog: [CHANGELOG.md](../CHANGELOG.md)

### Command Help

```powershell
cvm help
```

### Report Issues

If you encounter issues with the Windows version:

1. Check this troubleshooting guide first
2. Search [existing issues](https://github.com/kimmykuang/cvm/issues)
3. Open a new issue with:
   - Windows version (`winver`)
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Error messages and steps to reproduce

## FAQ

### Q: Do I need administrator privileges?

**A:** No, as long as Developer Mode is enabled. The installation and all operations work with regular user privileges.

### Q: Can I use this on Windows Server?

**A:** Yes! Windows Server 2016+ supports Developer Mode and PowerShell 5.1+.

### Q: Does this work with PowerShell 7 (PowerShell Core)?

**A:** Yes! cvm works with both PowerShell 5.1 (Windows default) and PowerShell 7 (cross-platform).

### Q: What about Windows 10 LTSC/Enterprise?

**A:** cvm works on all Windows 10 and 11 editions that support Developer Mode (version 1607+).

### Q: Can I use this without enabling Developer Mode?

**A:** Unfortunately no. Symbolic links are core to how cvm works, and Windows requires Developer Mode for non-admin users to create symlinks.

### Q: Will this conflict with a global Claude CLI installation?

**A:** cvm adds its bin directory to the front of PATH, so it will take precedence. Your global installation will be ignored while cvm is active.

### Q: Can I use both bash and PowerShell versions?

**A:** It's not recommended. Choose PowerShell for native Windows or WSL for Linux-style environment. They manage different directory structures.

## Version History

- **1.0.0** - Initial Windows support with PowerShell implementation
