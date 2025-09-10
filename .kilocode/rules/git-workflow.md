# Git Workflow and Commit Standards

## Branch Management

- Use feature branches for all new development
- Keep main/master branch always deployable
- Use descriptive branch names (feature/user-auth, fix/login-bug)
- Delete merged branches to keep repository clean

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
