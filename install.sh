#!/usr/bin/env bash

set -e

# cvm installer
# Installs cvm (Claude Version Manager) to ~/.cvm-repo

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    case "$OSTYPE" in
        msys*|mingw*|cygwin*)
            echo "windows-git-bash"
            ;;
        linux-gnu*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        darwin*)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS_TYPE=$(detect_os)

# If running in Git Bash on Windows, redirect to PowerShell installer
if [ "$OS_TYPE" = "windows-git-bash" ]; then
    echo "Windows detected. Using PowerShell installer..."
    echo ""

    # Find script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Check if PowerShell is available
    if command -v powershell.exe &> /dev/null; then
        # Execute PowerShell installer
        powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/install.ps1"
        exit $?
    else
        echo "Error: PowerShell not found."
        echo "Please install PowerShell or run install.ps1 directly from PowerShell."
        exit 1
    fi
fi

# Continue with Unix installation for Linux/macOS/WSL
echo "Installing cvm (Claude Version Manager)..."
echo ""

# Check for git
if ! command -v git &> /dev/null; then
    echo "Error: git is required but not installed."
    echo "Please install git first: https://git-scm.com/downloads"
    exit 1
fi

# Check for npm (warn but don't fail)
if ! command -v npm &> /dev/null; then
    echo "Warning: npm is not installed."
    echo "npm is required to install Claude CLI versions."
    echo "Please install Node.js (includes npm): https://nodejs.org/"
    echo ""
    echo "Continuing installation anyway..."
    echo ""
fi

# Define installation directory
CVM_DIR="${HOME}/.cvm-repo"

# Clone or update repository
if [ -d "$CVM_DIR" ]; then
    echo "Updating existing cvm installation..."
    cd "$CVM_DIR"
    git fetch --all --quiet
    git reset --hard origin/main --quiet
    echo "Updated cvm to latest version."
else
    echo "Cloning cvm repository..."
    git clone https://github.com/kimmykuang/cvm.git "$CVM_DIR"
    echo "Cloned cvm repository."
fi

# Make cvm.sh executable
chmod +x "$CVM_DIR/cvm.sh"

# Detect shell
SHELL_CONFIG=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    else
        SHELL_CONFIG="$HOME/.bashrc"
        touch "$SHELL_CONFIG"
    fi
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    if [ ! -f "$SHELL_CONFIG" ]; then
        touch "$SHELL_CONFIG"
    fi
else
    echo ""
    echo "Warning: Could not detect bash or zsh."
    echo "Please manually add the following to your shell configuration:"
    echo ""
    echo "  export PATH=\"\$HOME/.cvm/bin:\$PATH\""
    echo "  alias cvm=\"\$HOME/.cvm-repo/cvm.sh\""
    echo ""
    exit 0
fi

# Check if already configured
if grep -q "\.cvm/bin" "$SHELL_CONFIG" 2>/dev/null && grep -q "cvm-repo/cvm.sh" "$SHELL_CONFIG" 2>/dev/null; then
    echo ""
    echo "cvm is already configured in $SHELL_CONFIG"
else
    echo ""
    echo "Configuring $SHELL_CONFIG..."

    # Add configuration
    cat >> "$SHELL_CONFIG" << 'EOF'

# cvm (Claude Version Manager)
export PATH="$HOME/.cvm/bin:$PATH"
alias cvm="$HOME/.cvm-repo/cvm.sh"
EOF

    echo "Added cvm configuration to $SHELL_CONFIG"
fi

# Create ~/.cvm directory structure if it doesn't exist
mkdir -p "$HOME/.cvm/versions"
mkdir -p "$HOME/.cvm/bin"
mkdir -p "$HOME/.cvm/alias"

echo ""
echo "=========================================="
echo "cvm installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "  1. Restart your shell or run:"
echo "     source $SHELL_CONFIG"
echo ""
echo "  2. Install a Claude CLI version:"
echo "     cvm install 2.1.71"
echo ""
echo "  3. Switch to the installed version:"
echo "     cvm use 2.1.71"
echo ""
echo "  4. Verify installation:"
echo "     claude --version"
echo ""
echo "For more information, visit:"
echo "  https://github.com/kimmykuang/cvm"
echo ""
