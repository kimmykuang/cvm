# cvm - Claude Version Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-blue)](https://www.gnu.org/software/bash/)

A version manager for Claude Code CLI, inspired by nvm for Node.js.

## Why cvm?

Different model providers may require specific versions of Claude CLI:
- **Provider A** requires version 2.1.71 (older, no effort parameter)
- **Provider B** works with latest version (includes effort parameter)
- **Official Anthropic** may require specific versions

cvm lets you manage multiple versions and switch between them seamlessly.

## Features

- Install multiple Claude CLI versions side-by-side
- Switch between versions instantly
- Create named aliases for different providers
- Works with cc-switch for multi-provider management
- Clean uninstallation
- Zero external dependencies (uses npm to install Claude CLI)

## Requirements

### Unix (macOS, Linux, WSL)

- **Bash or Zsh** shell
- **npm** (comes with Node.js)
- **Git** (for installation)

### Windows

- **Windows 10+** with Developer Mode enabled ([setup guide](docs/WINDOWS.md#enabling-developer-mode))
- **PowerShell 5.1+** (included with Windows)
- **npm** (comes with Node.js) - [Download](https://nodejs.org/)
- **Git for Windows** - [Download](https://git-scm.com/download/win)

## Installation

### Unix (macOS, Linux, WSL)

**Quick Install:**

```bash
curl -o- https://raw.githubusercontent.com/kimmykuang/cvm/main/install.sh | bash
# Then restart your shell or run: source ~/.zshrc
```

**Manual Install:**

```bash
git clone https://github.com/kimmykuang/cvm.git ~/.cvm-repo
cd ~/.cvm-repo
chmod +x cvm.sh

# Add to shell config
echo 'export PATH="$HOME/.cvm/bin:$PATH"' >> ~/.zshrc
echo 'alias cvm="$HOME/.cvm-repo/cvm.sh"' >> ~/.zshrc
source ~/.zshrc
```

### Windows

**Quick Install (PowerShell):**

```powershell
# Run in PowerShell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/kimmykuang/cvm/main/install.ps1 -OutFile install.ps1
.\install.ps1
# Then restart PowerShell or run: . $PROFILE
```

**Quick Install (Git Bash):**

```bash
# Run in Git Bash (auto-redirects to PowerShell)
curl -o- https://raw.githubusercontent.com/kimmykuang/cvm/main/install.sh | bash
```

**📖 For detailed Windows setup including Developer Mode, see [Windows Guide](docs/WINDOWS.md)**

## Quick Start

**Unix (Bash/Zsh):**

```bash
# Install versions you need
cvm install 2.1.71
cvm install 2.1.63

# Switch to a version
cvm use 2.1.71

# Verify
claude --version

# Create provider aliases
cvm alias provider-a 2.1.71
cvm alias provider-b 2.1.63

# Switch using alias
cvm use provider-a
```

**Windows (PowerShell):**

```powershell
# Install versions you need
cvm install 2.1.71
cvm install 2.1.63

# Switch to a version
cvm use 2.1.71

# Verify
claude --version

# Create provider aliases
cvm alias provider-a 2.1.71
cvm alias provider-b 2.1.63

# Switch using alias
cvm use provider-a
```

## Usage

### Install a Version

```bash
cvm install 2.1.71
```

This downloads and installs the specified Claude CLI version to `~/.cvm/versions/`.

### Switch Versions

```bash
cvm use 2.1.71
```

Updates the symlink at `~/.cvm/bin/claude` to point to the selected version.

### List Installed Versions

```bash
cvm list
```

Example output:
```
Installed Claude CLI versions:

  * 2.1.71 (currently active)
    2.1.63
    2.1.60

Aliases:
  provider-a -> 2.1.71
  provider-restricted -> 2.1.63
```

### Check Current Version

```bash
cvm current
```

Shows which version is currently active.

### Create Aliases

```bash
cvm alias provider-a 2.1.71
cvm alias provider-b 2.1.63

# Now use aliases instead of version numbers
cvm use provider-a
```

### Remove Aliases

```bash
cvm unalias provider-a
```

### Uninstall Versions

```bash
cvm uninstall 2.1.63
```

If uninstalling the active version, you'll be prompted to confirm.

## Integration with cc-switch

If you use [cc-switch](https://github.com/YOUR_CC_SWITCH_REPO) to manage multiple Claude providers:

```bash
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

## Directory Structure

```
~/.cvm/
├── versions/
│   ├── 2.1.71/
│   │   ├── node_modules/
│   │   └── bin/claude -> ../node_modules/@anthropic-ai/claude-code/cli.js
│   └── 2.1.63/
│       └── ...
├── bin/
│   └── claude -> ../versions/2.1.71/bin/claude
└── alias/
    ├── provider-a (contains: "2.1.71")
    └── provider-b (contains: "2.1.63")
```

## Troubleshooting

### Unix/macOS/WSL

#### "command not found: cvm"

Make sure the alias is in your shell config:

```bash
grep cvm ~/.zshrc
```

If missing, add:

```bash
echo 'alias cvm="$HOME/.cvm-repo/cvm.sh"' >> ~/.zshrc
source ~/.zshrc
```

#### "command not found: claude"

Make sure `~/.cvm/bin` is in your PATH:

```bash
echo $PATH | grep cvm
```

If missing, add:

```bash
echo 'export PATH="$HOME/.cvm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Windows

#### "cvm : The term 'cvm' is not recognized"

Restart PowerShell or reload your profile:

```powershell
. $PROFILE
```

Check if configured:

```powershell
Get-Content $PROFILE
```

#### "Cannot create symbolic link" Error

Enable Windows Developer Mode (see [Windows Guide](docs/WINDOWS.md#enabling-developer-mode)), then restart PowerShell.

#### "claude : The term 'claude' is not recognized"

Check PATH configuration:

```powershell
$env:PATH -split ';' | Select-String ".cvm"
```

Should show your .cvm\bin directory.

**For complete Windows troubleshooting, see [Windows Guide](docs/WINDOWS.md#troubleshooting)**

### Version install fails

1. Check npm is installed: `npm --version`
2. Check version exists: `npm view @anthropic-ai/claude-code versions`
3. Try clearing npm cache: `npm cache clean --force`

### Wrong version after switching

If `claude --version` shows wrong version:
1. Check which claude: `which claude`
2. Should point to: `~/.cvm/bin/claude`
3. If not, check PATH order: `echo $PATH`

## Commands Reference

| Command | Description |
|---------|-------------|
| `cvm install <version>` | Install a specific version |
| `cvm use <version\|alias>` | Switch to a version or alias |
| `cvm list` | List all installed versions |
| `cvm current` | Show current active version |
| `cvm alias <name> <version>` | Create an alias |
| `cvm unalias <name>` | Remove an alias |
| `cvm uninstall <version>` | Uninstall a version |
| `cvm doctor` | Run system diagnostics |
| `cvm update` | Update cvm to latest version |
| `cvm version` | Show cvm version |
| `cvm help` | Show help message |

## Uninstalling cvm

```bash
# Remove all installed versions and data
rm -rf ~/.cvm

# Remove from shell config (edit these files)
nano ~/.zshrc  # Remove cvm lines
```

## Development

### Running Tests

```bash
cd ~/.cvm-repo
./tests/integration-test.sh
```

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT - See [LICENSE](LICENSE) for details.

## Credits

Inspired by [nvm](https://github.com/nvm-sh/nvm) - Node Version Manager.
