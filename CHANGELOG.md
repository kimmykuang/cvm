# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Windows Support** - Full native Windows support via PowerShell
  - `cvm.ps1` - PowerShell version with feature parity to bash version
  - `install.ps1` - Windows installation script with PowerShell profile configuration
  - `tests/integration-test.ps1` - Complete PowerShell test suite (18 tests)
  - `docs/WINDOWS.md` - Comprehensive Windows documentation
- OS detection in `install.sh` to automatically redirect Windows users to PowerShell installer
- Developer Mode detection and setup instructions for Windows symbolic link support
- Cross-platform line ending configuration (`.gitattributes`)
- Windows-specific patterns in `.gitignore`

### Changed
- Updated `README.md` with Windows installation instructions and troubleshooting
- Updated `CONTRIBUTING.md` with Windows development guidelines
- Enhanced installation process to support Unix, macOS, WSL, and Windows

### Technical Details
- PowerShell 5.1+ support (Windows default) and PowerShell 7 (cross-platform)
- Git Bash users on Windows automatically redirected to PowerShell installer
- WSL users continue to use bash version (unaffected)
- Windows 10+ with Developer Mode required for symbolic link support
- Full feature parity between bash and PowerShell implementations

## [1.0.0] - 2026-03-15

### Added
- Initial release of cvm (Claude Version Manager)
- `install` command to install Claude CLI versions via npm
- `use` command to switch between versions using symlinks
- `list` command to show installed versions and aliases
- `current` command to display active version
- `alias` / `unalias` commands for named version aliases
- `uninstall` command to remove versions
- Comprehensive integration test suite
- Full documentation and installation guide
- MIT License

### Features
- Multiple version management with symbolic links
- Named aliases for different providers
- Shell integration (bash/zsh)
- Input validation and error handling
- Safe active version uninstallation
- Automatic directory initialization
- PATH configuration warnings

[1.0.0]: https://github.com/kimmykuang/cvm/releases/tag/v1.0.0
