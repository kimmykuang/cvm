# Contributing to cvm

Thank you for your interest in contributing!

## Development Setup

```bash
git clone https://github.com/YOUR_USERNAME/cvm.git
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

## Adding New Commands

1. Add function to cvm.sh (before `cvm_main`)
2. Add case to `cvm_main` switch statement
3. Update `cvm_help` with new command
4. Add tests to `tests/integration-test.sh`
5. Document in README.md

## Questions?

Open an issue for discussion before starting large changes.
