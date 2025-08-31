# Environment Setup Guide

This guide provides detailed instructions for setting up and using reproducible development environments with direnv and Nix in this project template.

## Overview

This project template supports multiple approaches to environment management:

1. **Traditional**: Manual environment setup with `.env` files
2. **Direnv**: Automatic environment loading when entering directories
3. **Nix Shell**: Reproducible environments with exact package versions
4. **Nix Flakes**: Modern, declarative environment management

## Quick Start

### For New Projects

1. Run the setup script:

   ```bash
   ./scripts/setup.sh
   ```

2. Choose your preferred environment method:

   ```bash
   # Option 1: Direnv (automatic)
   direnv allow

   # Option 2: Nix shell
   nix-shell

   # Option 3: Nix flakes
   nix develop
   ```

## Detailed Setup Instructions

### Direnv Configuration

#### Installation

**macOS (Homebrew):**

```bash
brew install direnv
```

**Ubuntu/Debian:**

```bash
sudo apt update
sudo apt install direnv
```

**Arch Linux:**

```bash
sudo pacman -S direnv
```

**Nix/NixOS:**

```bash
nix-env -iA nixpkgs.direnv
```

**Manual Installation:**

```bash
curl -sfL https://direnv.net/install.sh | bash
```

#### Shell Integration

Add the direnv hook to your shell configuration:

**Bash (~/.bashrc):**

```bash
eval "$(direnv hook bash)"
```

**Zsh (~/.zshrc):**

```bash
eval "$(direnv hook zsh)"
```

**Fish (~/.config/fish/config.fish):**

```bash
direnv hook fish | source
```

#### Project Setup

1. Enter the project directory
2. Allow direnv to load the environment:

   ```bash
   direnv allow
   ```

The `.envrc` file will automatically:

- Load environment variables from `.env` files
- Set up project-specific paths
- Configure language-specific environments
- Display environment status

### Nix Environment Setup

#### Installation

**Multi-user Installation (Recommended):**

```bash
curl -L https://nixos.org/nix/install | sh
```

**Single-user Installation:**

```bash
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
```

**For NixOS:**
Nix is already installed and configured.

#### Enable Experimental Features

For Nix flakes support, enable experimental features:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

Or create/edit `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## Environment Usage

### Direnv Workflow

Direnv automatically manages your environment:

```bash
# Enter project directory (environment loads automatically)
cd your-project

# Environment variables are now available
echo $APP_ENV
echo $PROJECT_ROOT

# Exit directory (environment unloads automatically)
cd ..
```

### Nix Shell Workflow

#### Traditional Nix Shell

```bash
# Enter the reproducible environment
nix-shell

# All tools and dependencies are available
python --version
node --version
git --version

# Exit the shell
exit
```

#### With Specific Command

```bash
# Run a command in the Nix environment
nix-shell --command "python main.py"

# Use a different shell
nix-shell --command "zsh"
```

#### Pure Environment

```bash
# Isolated environment (no system packages)
nix-shell --pure
```

### Nix Flakes Workflow

#### Development Environment

```bash
# Enter development environment
nix develop

# Or specify a specific shell
nix develop .#python  # Python-focused environment
nix develop .#nodejs  # Node.js-focused environment
```

#### Update Dependencies

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

#### Build and Run

```bash
# Build the project
nix build

# Run the project
nix run

# Build for different systems
nix build .#package-name
```

## Configuration Files

### .envrc (Direnv)

The `.envrc` file:

- Loads environment variables from `.env` files
- Sets up project paths
- Configures language-specific environments
- Provides status information

Key features:

```bash
# Load .env file
dotenv_if_exists

# Set project paths
export PROJECT_ROOT="$(pwd)"
export PATH="$PROJECT_ROOT/scripts:$PATH"

# Language-specific setup
export PYTHONPATH="$PROJECT_ROOT/src"
```

### shell.nix (Traditional Nix)

Provides a basic Nix shell with common development tools:

```nix
# Available tools
pythonEnv, nodejsEnv, devTools

# Environment setup
shellHook = ''
  export PROJECT_ROOT="$PWD"
  # ... setup commands
'';
```

### flake.nix (Modern Nix)

Advanced configuration with multiple environments:

```nix
# Multiple development shells
devShells.default    # General development
devShells.python     # Python-focused
devShells.nodejs     # Node.js-focused

# Build outputs
packages.default

# Applications
apps.default
```

## Integration Options

### Direnv + Nix Integration

For the best experience, combine direnv with Nix:

1. Install `nix-direnv`:

   ```bash
   nix-env -iA nixpkgs.nix-direnv
   ```

2. The `.envrc` file will automatically use Nix when available

3. Benefits:
   - Fast environment switching
   - Automatic Nix shell activation
   - Cached environments

### IDE Integration

#### VS Code

1. Install Nix Environment Selector extension
2. Configure workspace settings:

   ```json
   {
     "nixEnvSelector.nixFile": "${workspaceFolder}/shell.nix"
   }
   ```

#### Emacs

Add to your Emacs configuration:

```elisp
(use-package direnv
  :config
  (direnv-mode))
```

### CI/CD Integration

#### GitHub Actions

```yaml
- name: Install Nix
  uses: cachix/install-nix-action@v18

- name: Enter Nix environment
  run: nix develop --command "your-build-command"
```

#### GitLab CI

```yaml
nix:
  image: nixos/nix:latest
  script:
    - nix-shell --command "your-build-command"
```

## Troubleshooting

### Direnv Issues

**Environment not loading:**

```bash
# Check if direnv is allowed
direnv allow

# Check .envrc syntax
direnv check
```

**Permission denied:**

```bash
# Ensure .envrc is executable
chmod +x .envrc
```

### Nix Issues

**Slow initial setup:**

- Enable binary caches
- Use `nix-shell --pure` for faster subsequent runs

**Permission issues:**

```bash
# Fix Nix store permissions
sudo chown -R $(whoami) ~/.nix-profile
```

**Flakes not working:**

```bash
# Check experimental features
nix show-config | grep experimental-features

# Update Nix
nix upgrade-nix
```

### Common Problems

**Environment variables not set:**

- Check `.env` file exists and has correct format
- Run `direnv reload` to refresh

**Nix commands not found:**

- Ensure Nix is in PATH
- Restart your shell after installation

**Package not found:**

- Update flake inputs: `nix flake update`
- Check package names in Nix files

## Advanced Configuration

### Custom Nix Packages

Add custom packages to `shell.nix`:

```nix
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Your custom packages
    your-package
    another-tool
  ];
}
```

### Environment-Specific Configurations

Create multiple `.envrc` files:

```bash
# .envrc.development
export APP_ENV=development
dotenv_if_exists .env.development

# .envrc.production
export APP_ENV=production
dotenv_if_exists .env.production
```

### Nix Overlays

For custom package modifications:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    overlays.default = final: prev: {
      # Your package modifications
    };
  };
}
```

## Best Practices

### Environment Management

1. **Commit environment templates**: Include `.envrc`, `shell.nix`, `flake.nix`
2. **Don't commit secrets**: Use `.env` files for sensitive data
3. **Document requirements**: Update README with setup instructions
4. **Test environments**: Verify setups work on different systems

### Performance Optimization

1. **Use binary caches**: Enable Nix binary caches for faster downloads
2. **Cache dependencies**: Let Nix handle dependency caching
3. **Minimize environments**: Only include necessary packages
4. **Use flakes**: Modern flakes provide better caching

### Team Collaboration

1. **Standardize setup**: Use the same environment across team
2. **Document processes**: Keep setup instructions current
3. **Review changes**: Check environment configuration changes
4. **Test regularly**: Ensure environments work for all team members

## Migration Guide

### From Manual Setup

1. Add `.envrc` file to project
2. Test direnv integration
3. Optionally add Nix files
4. Update documentation

### From Other Tools

**From virtualenv:**

- Keep existing virtualenv for Python
- Use direnv to activate automatically
- Add Nix for system dependencies

**From Docker:**

- Use Nix for development environment
- Keep Docker for deployment/containerization
- Combine with direnv for convenience

## Resources

- [Direnv Documentation](https://direnv.net/)
- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Nixpkgs](https://search.nixos.org/packages)
- [NixOS Wiki](https://nixos.wiki/)

## Support

For issues with environment setup:

1. Check this documentation
2. Review error messages carefully
3. Test with minimal configuration
4. Check community resources
5. Create issue with reproduction steps
