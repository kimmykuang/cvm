#!/usr/bin/env bash

set -e

# ============================================================================
# cvm - Claude Version Manager
# Version: 1.0.0
# ============================================================================

CVM_DIR="${CVM_DIR:-$HOME/.cvm}"
CVM_VERSIONS_DIR="$CVM_DIR/versions"
CVM_BIN_DIR="$CVM_DIR/bin"
CVM_ALIAS_DIR="$CVM_DIR/alias"
CVM_VERSION="1.0.0"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# Utility Functions
# ============================================================================

cvm_echo() {
  echo -e "${GREEN}[cvm]${NC} $1"
}

cvm_error() {
  echo -e "${RED}[cvm ERROR]${NC} $1" >&2
}

cvm_warn() {
  echo -e "${YELLOW}[cvm WARN]${NC} $1"
}

# ============================================================================
# Initialization
# ============================================================================

cvm_init() {
  mkdir -p "$CVM_VERSIONS_DIR"
  mkdir -p "$CVM_BIN_DIR"
  mkdir -p "$CVM_ALIAS_DIR"
}

# ============================================================================
# Validation
# ============================================================================

cvm_validate_version() {
  local version="$1"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    cvm_error "Invalid version format: $version"
    echo "Expected format: X.Y.Z (e.g., 2.1.71)"
    return 1
  fi
  return 0
}

cvm_check_npm() {
  if ! command -v npm &> /dev/null; then
    cvm_error "npm is not installed or not in PATH"
    echo "Please install Node.js and npm first:"
    echo "  https://nodejs.org/"
    return 1
  fi
  return 0
}

# ============================================================================
# Core Commands
# ============================================================================

cvm_install() {
  local version="$1"

  if [ -z "$version" ]; then
    cvm_error "Version number required"
    echo "Usage: cvm install <version>"
    return 1
  fi

  if ! cvm_validate_version "$version"; then
    return 1
  fi

  if ! cvm_check_npm; then
    return 1
  fi

  local version_dir="$CVM_VERSIONS_DIR/$version"

  if [ -d "$version_dir" ]; then
    cvm_warn "Version $version is already installed"
    return 0
  fi

  cvm_echo "Installing Claude CLI version $version..."

  mkdir -p "$version_dir"
  local temp_dir
  temp_dir=$(mktemp -d) || { cvm_error "Failed to create temp directory"; return 1; }
  cd "$temp_dir" || { cvm_error "Failed to enter temp directory"; rm -rf "$temp_dir"; return 1; }

  # Add trap for cleanup
  trap 'cd - > /dev/null 2>&1; rm -rf "$temp_dir"' EXIT INT TERM

  cat > package.json << EOF_JSON
{
  "name": "cvm-temp-install",
  "private": true,
  "dependencies": {
    "@anthropic-ai/claude-code": "$version"
  }
}
EOF_JSON

  if npm install --production --no-audit --no-fund --loglevel error 2>&1; then
    cp -r node_modules "$version_dir/"
    mkdir -p "$version_dir/bin"
    ln -sf "../node_modules/@anthropic-ai/claude-code/cli.js" "$version_dir/bin/claude"
    chmod +x "$version_dir/bin/claude"

    cvm_echo "Successfully installed Claude CLI $version"
    trap - EXIT INT TERM
    cd - > /dev/null
    rm -rf "$temp_dir"
    return 0
  else
    cvm_error "Failed to install version $version"
    cvm_error "Check that version exists: npm view @anthropic-ai/claude-code versions"
    rm -rf "$version_dir"
    trap - EXIT INT TERM
    cd - > /dev/null
    rm -rf "$temp_dir"
    return 1
  fi
}

cvm_use() {
  local version="$1"

  if [ -z "$version" ]; then
    cvm_error "Version number or alias required"
    echo "Usage: cvm use <version>"
    return 1
  fi

  local alias_file="$CVM_ALIAS_DIR/$version"
  if [ -f "$alias_file" ]; then
    version=$(cat "$alias_file")
    cvm_echo "Using alias '$1' -> version $version"
  fi

  local version_dir="$CVM_VERSIONS_DIR/$version"

  if [ ! -d "$version_dir" ]; then
    cvm_error "Version $version is not installed"
    echo "Run 'cvm install $version' first"
    return 1
  fi

  mkdir -p "$CVM_BIN_DIR"
  rm -f "$CVM_BIN_DIR/claude"
  ln -sf "$version_dir/bin/claude" "$CVM_BIN_DIR/claude"

  cvm_echo "Now using Claude CLI version $version"

  if [[ ":$PATH:" != *":$CVM_BIN_DIR:"* ]]; then
    cvm_warn "Warning: $CVM_BIN_DIR is not in your PATH"
    echo "Add to your shell config (~/.zshrc or ~/.bashrc):"
    echo "  export PATH=\"\$HOME/.cvm/bin:\$PATH\""
  fi
}

cvm_list() {
  cvm_echo "Installed Claude CLI versions:"
  echo

  if [ ! -d "$CVM_VERSIONS_DIR" ] || [ -z "$(ls -A "$CVM_VERSIONS_DIR" 2>/dev/null)" ]; then
    echo "  (none installed)"
    echo
    echo "Install a version with: cvm install <version>"
    return 0
  fi

  local current_version=""
  if [ -L "$CVM_BIN_DIR/claude" ]; then
    local target=$(readlink "$CVM_BIN_DIR/claude")
    current_version=$(echo "$target" | sed -n 's|.*/versions/\([^/]*\)/.*|\1|p')
  fi

  for version_dir in "$CVM_VERSIONS_DIR"/*; do
    if [ -d "$version_dir" ]; then
      local version=$(basename "$version_dir")
      if [ "$version" = "$current_version" ]; then
        echo -e "  * ${GREEN}$version${NC} (currently active)"
      else
        echo "    $version"
      fi
    fi
  done

  echo

  if [ -d "$CVM_ALIAS_DIR" ] && [ -n "$(ls -A "$CVM_ALIAS_DIR" 2>/dev/null)" ]; then
    echo "Aliases:"
    for alias_file in "$CVM_ALIAS_DIR"/*; do
      if [ -f "$alias_file" ]; then
        local alias_name=$(basename "$alias_file")
        local alias_version=$(cat "$alias_file")
        echo "  $alias_name -> $alias_version"
      fi
    done
    echo
  fi
}

cvm_current() {
  if [ ! -L "$CVM_BIN_DIR/claude" ]; then
    cvm_warn "No active Claude CLI version"
    echo "Run 'cvm use <version>' to activate a version"
    return 1
  fi

  local target=$(readlink "$CVM_BIN_DIR/claude")
  local current_version=$(echo "$target" | sed -n 's|.*/versions/\([^/]*\)/.*|\1|p')

  if [ -n "$current_version" ]; then
    cvm_echo "Current version: ${GREEN}$current_version${NC}"
    if [ -x "$CVM_BIN_DIR/claude" ]; then
      local claude_version=$("$CVM_BIN_DIR/claude" --version 2>/dev/null || echo "")
      if [ -n "$claude_version" ]; then
        echo "  ($claude_version)"
      fi
    fi
  else
    cvm_error "Could not determine current version"
    return 1
  fi
}

cvm_alias() {
  local alias_name="$1"
  local version="$2"

  if [ -z "$alias_name" ] || [ -z "$version" ]; then
    cvm_error "Alias name and version required"
    echo "Usage: cvm alias <name> <version>"
    return 1
  fi

  local version_dir="$CVM_VERSIONS_DIR/$version"
  if [ ! -d "$version_dir" ]; then
    cvm_error "Version $version is not installed"
    echo "Run 'cvm install $version' first"
    return 1
  fi

  mkdir -p "$CVM_ALIAS_DIR"
  local alias_file="$CVM_ALIAS_DIR/$alias_name"
  echo "$version" > "$alias_file"

  cvm_echo "Created alias: $alias_name -> $version"
}

cvm_unalias() {
  local alias_name="$1"

  if [ -z "$alias_name" ]; then
    cvm_error "Alias name required"
    echo "Usage: cvm unalias <name>"
    return 1
  fi

  local alias_file="$CVM_ALIAS_DIR/$alias_name"

  if [ ! -f "$alias_file" ]; then
    cvm_error "Alias '$alias_name' does not exist"
    return 1
  fi

  rm -f "$alias_file"
  cvm_echo "Removed alias: $alias_name"
}

cvm_uninstall() {
  local version="$1"

  if [ -z "$version" ]; then
    cvm_error "Version number required"
    echo "Usage: cvm uninstall <version>"
    return 1
  fi

  local version_dir="$CVM_VERSIONS_DIR/$version"

  if [ ! -d "$version_dir" ]; then
    cvm_error "Version $version is not installed"
    return 1
  fi

  if [ -L "$CVM_BIN_DIR/claude" ]; then
    local target=$(readlink "$CVM_BIN_DIR/claude")
    local current_version=$(echo "$target" | sed -n 's|.*/versions/\([^/]*\)/.*|\1|p')

    if [ "$version" = "$current_version" ]; then
      cvm_warn "This is the currently active version"
      echo -n "Continue with uninstall? [y/N] "
      read -r response
      if [[ ! "$response" =~ ^[Yy]$ ]]; then
        cvm_echo "Uninstall cancelled"
        return 0
      fi
      rm -f "$CVM_BIN_DIR/claude"
      cvm_echo "Deactivated version $version"
    fi
  fi

  rm -rf "$version_dir"
  cvm_echo "Uninstalled Claude CLI version $version"

  if [ -d "$CVM_ALIAS_DIR" ]; then
    for alias_file in "$CVM_ALIAS_DIR"/*; do
      if [ -f "$alias_file" ] && [ "$(cat "$alias_file")" = "$version" ]; then
        local alias_name=$(basename "$alias_file")
        rm -f "$alias_file"
        cvm_warn "Removed alias '$alias_name' (was pointing to $version)"
      fi
    done
  fi
}

cvm_help() {
  cat << 'HELP_EOF'
Usage: cvm <command> [args]

Commands:
  install <version>     Install a specific Claude CLI version
  use <version|alias>   Switch to a specific version or alias
  list, ls              List installed versions
  current               Show current active version
  alias <name> <ver>    Create a named alias for a version
  unalias <name>        Remove an alias
  uninstall <version>   Remove an installed version
  version, -v, --version  Show cvm version
  help, -h, --help      Show this help message

Examples:
  cvm install 2.1.71
  cvm install 2.1.63
  cvm use 2.1.71
  cvm alias provider-a 2.1.71
  cvm use provider-a
  cvm list
  cvm current
  cvm uninstall 2.1.63

Integration with cc-switch:
  1. Install required versions: cvm install 2.1.71 && cvm install 2.1.63
  2. Create provider aliases: cvm alias provider-a 2.1.71
  3. Switch before using provider: cvm use provider-a

Documentation: https://github.com/<your-username>/cvm
HELP_EOF
}

# ============================================================================
# Main Entry Point
# ============================================================================

cvm_main() {
  local command="${1:-help}"

  # Initialize directories if needed
  if [ ! -d "$CVM_DIR" ]; then
    cvm_init
  fi

  case "$command" in
    install)
      cvm_install "$2"
      ;;
    use)
      cvm_use "$2"
      ;;
    list|ls)
      cvm_list
      ;;
    current)
      cvm_current
      ;;
    alias)
      cvm_alias "$2" "$3"
      ;;
    unalias)
      cvm_unalias "$2"
      ;;
    uninstall|remove)
      cvm_uninstall "$2"
      ;;
    version|--version|-v)
      echo "cvm $CVM_VERSION"
      ;;
    help|--help|-h)
      cvm_help
      ;;
    *)
      cvm_error "Unknown command: $command"
      echo
      cvm_help
      exit 1
      ;;
  esac
}

# Execute main function
cvm_main "$@"
