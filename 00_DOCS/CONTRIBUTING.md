# Contributing to Project Template

Thank you for your interest in contributing to this project template! We welcome contributions from the community to help improve and maintain this template.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. By participating, you agree to:

- Be respectful and inclusive
- Focus on constructive feedback
- Accept responsibility for mistakes
- Show empathy towards other contributors
- Help create a positive community

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/your-username/project-template.git
   cd project-template
   ```
3. **Set up the development environment**:
   ```bash
   npm install
   # or with Nix
   nix develop
   ```
4. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## How to Contribute

### Types of Contributions

- **Bug fixes**: Fix issues in the template
- **Features**: Add new functionality or improve existing features
- **Documentation**: Improve documentation, add examples, or fix typos
- **Tests**: Add or improve test coverage
- **Tools**: Improve build tools, scripts, or development workflow

### Finding Issues

- Check the [Issues](../../issues) page for open tasks
- Look for issues labeled `good first issue` or `help wanted`
- Comment on an issue to indicate you're working on it

## Development Workflow

1. **Choose an issue** or create a new one describing your contribution
2. **Create a feature branch** from `main`
3. **Make your changes** following the style guidelines
4. **Write tests** for new functionality
5. **Update documentation** if needed
6. **Run the test suite**:
   ```bash
   npm test
   npm run lint
   ```
7. **Commit your changes** with descriptive commit messages
8. **Push to your fork** and create a pull request

## Pull Request Process

1. **Update the README.md** with details of changes if needed
2. **Update the CHANGELOG.md** with your changes
3. **Ensure all tests pass** and code quality checks are met
4. **Request review** from maintainers
5. **Address feedback** and make necessary changes
6. **Merge** once approved

### PR Title Format

Use the following format for pull request titles:

- `feat: add new feature`
- `fix: resolve issue with...`
- `docs: update documentation`
- `style: format code`
- `refactor: improve code structure`
- `test: add tests for...`
- `chore: update dependencies`

## Style Guidelines

### Code Style

- Follow the existing code style in the project
- Use ESLint and Prettier for JavaScript/TypeScript
- Use Black for Python code formatting
- Follow language-specific best practices

### Commit Messages

- Use clear, descriptive commit messages
- Start with a verb in imperative mood
- Keep the first line under 50 characters
- Add detailed description if needed

Example:

```
feat: add Docker multi-stage build support

- Add Dockerfile with multi-stage builds for optimization
- Update .dockerignore to exclude unnecessary files
- Add build arguments for flexible configuration
```

## Testing

- Write tests for new features
- Ensure all existing tests pass
- Add integration tests for complex features
- Test on multiple platforms if applicable

## Documentation

- Update README.md for significant changes
- Add code comments for complex logic
- Update API documentation if applicable
- Include examples for new features

## Questions?

If you have questions about contributing, feel free to:

- Open an issue with your question
- Join our community discussions
- Contact the maintainers

Thank you for contributing to make this project better! 🚀
