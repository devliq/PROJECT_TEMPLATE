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

## Automation Tools

- Use semantic-release for automated versioning and changelog generation based on commit messages
- Integrate with GitHub Actions or GitLab CI for automated changelog updates on releases
- Leverage tools like conventional-changelog or auto-changelog for generating changelogs from git history
- Implement commitizen for interactive commit message formatting to ensure consistency

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
