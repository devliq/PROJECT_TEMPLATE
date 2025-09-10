# Git Workflow and Commit Standards

## Branch Management

- Use feature branches for all new development
- Keep main/master branch always deployable
- Use descriptive branch names (feature/user-auth, fix/login-bug)
- Delete merged branches to keep repository clean

## Modern Integrations

- Use GitHub PR templates for standardized pull requests and code reviews
- Implement branch protection rules to enforce code quality and prevent direct pushes to main
- Integrate CI/CD pipelines with GitHub Actions for automated testing, building, and deployment
- Leverage Git hooks for pre-commit checks and automated formatting

## Commit Standards

- Make small, focused commits that represent single logical changes
- Write clear commit messages following conventional commit format
- Commit frequently - at least once per hour during active development
- Always run tests before committing
- Use interactive rebase to clean up commit history before merging

## Code Integration

- Pull latest changes before starting new work
- Resolve conflicts promptly and test thoroughly after resolution
- Use pull/merge requests for all changes to main branch
- Ensure CI/CD pipeline passes before merging
