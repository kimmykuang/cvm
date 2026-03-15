# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
