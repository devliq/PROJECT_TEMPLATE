# Testing and Quality Assurance Rules

## Testing Requirements

- Write unit tests for all new functions and classes
- Maintain minimum 80% test coverage for critical business logic
- Include integration tests for API endpoints and database operations
- Write descriptive test names that explain what is being tested
- Use arrange-act-assert pattern in test structure

## Pre-commit Checks

- All tests must pass before committing
- Code must pass linting and formatting checks
- No console.log, print(), or debug statements in production code
- Check for trailing whitespace and proper line endings
- Validate that all imports are used and properly organized

## Code Review Standards

- All code changes require review before merging
- Check for security vulnerabilities and potential performance issues
- Verify that new code follows established patterns and conventions
- Ensure proper documentation for public APIs and complex logic
