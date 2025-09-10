# Changelog and Version Management Rules

## Changelog Requirements

- ALWAYS update CHANGELOG.md when making changes that affect functionality
- Follow conventional commit format for all commits: `type(scope): description`
- Use these commit types:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `style:` for formatting changes
  - `refactor:` for code refactoring
  - `test:` for test additions/modifications
  - `chore:` for maintenance tasks

## Changelog Format

- Group changes by version with release date
- Categorize changes as: Added, Changed, Deprecated, Removed, Fixed, Security
- Include links to relevant issues or pull requests
- Write changelog entries from user perspective, not technical implementation
- Keep entries concise but descriptive

## Version Control

- Update version numbers in package.json, setup.py, or equivalent files
- Tag releases appropriately using semantic versioning (MAJOR.MINOR.PATCH)
- Ensure changelog is updated before any version bump
