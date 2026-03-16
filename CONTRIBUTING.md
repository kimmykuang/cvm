# Contributing to cvm

Thank you for your interest in contributing!

## Development Setup

```bash
git clone https://github.com/kimmykuang/cvm.git
cd cvm
```

## Making Changes

1. Create a branch: `git checkout -b feature-name`
2. Make your changes to `cvm.sh`
3. Test your changes: `./tests/integration-test.sh`
4. Update documentation if needed
5. Commit: `git commit -m "feat: description"`
6. Push and create a pull request

## Running Tests

```bash
# Full integration test
./tests/integration-test.sh

# Manual testing
./cvm.sh help
./cvm.sh install 2.1.63
./cvm.sh list
```

## Code Style

- Use 2 spaces for indentation
- Keep functions focused and single-purpose
- Add comments for complex logic
- Follow existing function naming: `cvm_<command>`
- Use error handling: check inputs, validate versions

## Commit Messages

Follow conventional commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test changes
- `refactor:` - Code refactoring

## Testing Guidelines

Before submitting a PR:
1. All integration tests must pass
2. Test manually with multiple versions
3. Test error cases (invalid input, missing versions)
4. Verify on both bash and zsh if possible

### Cross-platform Testing

#### Unix (macOS, Linux, WSL)

```bash
# Run integration tests
./tests/integration-test.sh

# Manual testing
./cvm.sh help
./cvm.sh install 2.1.63
./cvm.sh list
```

#### Windows

```powershell
# Run integration tests
.\tests\integration-test.ps1

# Manual testing
.\cvm.ps1 help
.\cvm.ps1 install 2.1.63
.\cvm.ps1 list
```

**Testing Checklist:**
- [ ] Bash tests pass on macOS/Linux
- [ ] PowerShell tests pass on Windows 10/11
- [ ] install.sh detects OS correctly
- [ ] Git Bash redirects to PowerShell on Windows
- [ ] WSL uses bash version (not PowerShell)
- [ ] Documentation is accurate

## Windows Development

### Requirements for Windows Development

- Windows 10+ with Developer Mode enabled
- PowerShell 5.1+ or PowerShell 7
- VS Code with PowerShell extension (recommended)
- Git for Windows

### Editing PowerShell Scripts

Use VS Code with the PowerShell extension for best experience:

```powershell
code cvm.ps1
code install.ps1
code tests/integration-test.ps1
```

Or use PowerShell ISE (included with Windows):

```powershell
ise cvm.ps1
```

### Testing Windows Changes

1. Test in clean environment:

```powershell
# Remove existing installation
Remove-Item -Recurse -Force "$env:USERPROFILE\.cvm" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$env:USERPROFILE\.cvm-repo" -ErrorAction SilentlyContinue

# Test installation
.\install.ps1

# Run tests
.\tests\integration-test.ps1
```

2. Test in different shells:
   - PowerShell 5.1 (Windows default)
   - PowerShell 7 (if available)
   - Git Bash (should redirect)

3. Test without Developer Mode to verify error messages

### Code Style for PowerShell

- Use 4 spaces for indentation (PowerShell convention)
- Use PascalCase for function names (Verb-Noun format)
- Use `$script:` prefix for script-level variables
- Use proper PowerShell cmdlets (not aliases in scripts)
- Add comment-based help for functions
- Use `$ErrorActionPreference = 'Stop'` for error handling

## Adding New Commands

1. Add function to cvm.sh (before `cvm_main`)
2. Add case to `cvm_main` switch statement
3. Update `cvm_help` with new command
4. Add tests to `tests/integration-test.sh`
5. Document in README.md

## Questions?

Open an issue for discussion before starting large changes.
