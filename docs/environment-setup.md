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

1. Run the appropriate setup script for your platform:

   **Linux/macOS:**

   ```bash
   ./scripts/setup.sh
   ```

   **Windows + WSL + Docker (Recommended):**

   ```powershell
   # For complete Windows + WSL + Docker setup:
   .\scripts\setup-windows-wsl.ps1 -InstallWSL -InstallDocker -SetupEnvironment

   # Or if you already have WSL/Docker installed:
   .\scripts\setup-windows-wsl.ps1 -SetupEnvironment
   ```

   **Windows (Basic PowerShell):**

   ```powershell
   .\scripts\setup-windows.ps1 -InstallDirenv -SetupHooks
   ```

   **Development setup (includes Docker):**

   ```bash
   ./scripts/setup-dev.sh
   ```

   **Ultimate setup (recommended for best operability):**

   ```bash
   ./scripts/setup-ultimate.sh
   ```

   # This provides the most comprehensive cross-platform setup

2. Choose your preferred environment method:

   ```bash
   # Option 1: Direnv (automatic - recommended)
   direnv allow

   # Option 2: Nix shell
   nix-shell

   # Option 3: Nix flakes
   nix develop
   ```

3. The environment will now load automatically when you enter the project directory!

## Windows WSL + Docker Development

For **Windows users who want to develop with WSL and Docker**, use this optimized workflow:

### Quick Setup for Windows + WSL + Docker:

```powershell
# One command sets up everything:
.\scripts\setup-windows-wsl.ps1 -InstallWSL -InstallDocker -SetupEnvironment

# Or if you already have WSL/Docker installed:
.\scripts\setup-windows-wsl.ps1 -SetupEnvironment
```

### What This Does:

1. **Installs WSL2** - Windows Subsystem for Linux
2. **Installs Docker CE in WSL** - Native Docker in your Linux environment
3. **Sets up WSL environment** - Auto-detects your distribution and uses appropriate package manager
4. **Configures direnv** - For automatic environment loading
5. **Creates environment files** - .envrc and .env ready to use

### Development Workflow:

```powershell
# From Windows PowerShell (RECOMMENDED - Fully Automated):
.\Enter-Project.ps1

# Alternative batch file:
.\enter-project.bat

# Manual entry (if you prefer):
wsl  # Enter WSL
cd /mnt/c/src/your-project

# SSH entry (requires SSH server setup):
ssh user@127.0.0.1 -p 2222
```

### Automated Entry Features:

When using the automated scripts (`.ps1` or `.bat`):

- ✅ **Automatic WSL Entry** - No manual `wsl` command needed
- ✅ **Project Navigation** - Automatically navigates to project directory
- ✅ **Environment Loading** - All direnv setup happens automatically
- ✅ **Dependency Installation** - First-time setup runs automatically
- ✅ **Docker Services** - Services start automatically
- ✅ **Health Checks** - System validates everything is working
- ✅ **Workspace Setup** - Optional development workspace creation

### WSL Access Methods:

**🏆 RECOMMENDED: Automated Entry Scripts**

- ✅ **Fully Automated** - One command does everything
- ✅ **No Manual Steps** - Handles WSL entry, navigation, and setup
- ✅ **Error Handling** - Validates WSL availability and provides guidance
- ✅ **Workspace Optional** - Can automatically set up development workspace

**Alternative: `wsl` command**

- ✅ Faster connection (instant)
- ✅ No SSH server required
- ✅ More reliable
- ✅ Standard Microsoft approach

**Alternative: SSH**

- ⚠️ Requires SSH server in WSL
- ⚠️ Slower connection
- ⚠️ Additional configuration needed
- ⚠️ May have network/firewall issues

**Recommendation**: Use the automated entry scripts for the best experience!

### Benefits:

- ✅ **Native Windows experience** - Use VS Code, file explorer
- ✅ **Linux development tools** - Full Linux environment (Ubuntu, Kali, Fedora, etc.)
- ✅ **Docker in WSL** - Lightweight, no Docker Desktop overhead
- ✅ **Automatic environment** - No manual setup required
- ✅ **File system sync** - Windows ↔ WSL seamless
- ✅ **No licensing concerns** - Uses open-source Docker CE
- ✅ **Multi-distro support** - Works with any WSL distribution

## Automatic Environment Features

When you enter the project directory, the environment automatically:

### 🚀 **First-Time Setup**

- **Dependency Installation**: Automatically installs Node.js dependencies
- **Directory Creation**: Creates necessary project directories (build, assets, temp)
- **Git Hooks Setup**: Configures Git hooks if available
- **Environment Files**: Creates .env from template if needed

### 🐳 **Docker Management**

- **Auto-Start Services**: Automatically starts Docker containers on directory entry
- **Service Health Checks**: Verifies database, Redis, and application services are running
- **Smart Detection**: Only starts services if they're not already running

### 🏥 **Health Monitoring**

- **Tool Verification**: Checks that all required development tools are available
- **Service Status**: Monitors Docker service health
- **Application Testing**: Runs basic connectivity tests on common ports
- **NPM Testing**: Executes test suite if available

### 🔄 **Automatic Reloading**

The environment automatically reloads when these files change:

- `.env` - Environment variables
- `docker-compose.yml` - Docker services
- `package.json` - Node.js dependencies
- `flake.nix` / `shell.nix` - Nix configuration
- `.envrc` - Environment configuration

### 📊 **Status Display**

Shows comprehensive status information:

- Platform and environment details
- Setup completion status
- Docker service status
- Available commands and tips

### Supported WSL Distributions:

- **Ubuntu/Debian-based**: Ubuntu, Kali Linux, Debian
- **Fedora/RHEL-based**: Fedora, CentOS, RHEL
- **Arch Linux**: Manjaro, EndeavourOS

## Ultimate Setup (Recommended)

For the **best cross-platform operability**, use the ultimate setup script:

```bash
./scripts/setup-ultimate.sh
```

### What the Ultimate Setup Provides

**🔧 Automatic Tool Installation:**

- Detects your platform (Linux/macOS/Windows/WSL)
- Installs direnv automatically
- Installs Nix with flakes support
- Installs nix-direnv for optimal performance

**🌐 Cross-Platform Compatibility:**

- **Linux**: Uses apt/pacman/dnf package managers
- **macOS**: Uses Homebrew
- **Windows**: Supports Scoop/Chocolatey/native installation
- **WSL**: Special handling for Windows Subsystem for Linux

**⚙️ Smart Configuration:**

- Auto-detects shell type (bash/zsh/fish/PowerShell)
- Configures appropriate shell hooks
- Creates optimized .envrc with Nix integration
- Sets up directory structures dynamically

**🛡️ Safety Features:**

- Never overwrites existing .env files
- Preserves user configuration
- Graceful fallbacks for missing tools
- Comprehensive error handling

**📊 Status & Monitoring:**

- Real-time installation progress
- Verification of all components
- Clear success/failure indicators
- Troubleshooting guidance

### Ultimate Setup Workflow

```bash
# One command sets up everything
./scripts/setup-ultimate.sh

# Output shows:
# • Platform detection
# • Tool installation progress
# • Configuration setup
# • Verification results
# • Next steps

# Then simply:
cd your-project  # Environment loads automatically
```

### Benefits of Ultimate Setup

- ✅ **Zero manual configuration** - everything automated
- ✅ **Maximum compatibility** - works on any platform
- ✅ **Optimal performance** - uses nix-direnv caching
- ✅ **Future-proof** - adapts to new tools/versions
- ✅ **Safe** - preserves existing configuration
- ✅ **Comprehensive** - handles edge cases and errors

4. **Test your setup:**

   **Linux/macOS:**

   ```bash
   ./scripts/test-env.sh
   ```

   **Windows:**

   ```batch
   .\scripts\test-env.bat
   ```

   # Or using bash directly:

   bash scripts/test-env.sh

### Python Version Management

This template includes automated Python version management with optional auto-updates for maintaining up-to-date Python environments.

#### Manual Version Updates

Use the provided script to update Python versions:

```bash
# Update to latest stable Python version
./scripts/update-python-version.sh

# Update to latest patch for Python 3.12
./scripts/update-python-version.sh --minor 3.12

# Set specific version
./scripts/update-python-version.sh --version 3.13.7
```

The script automatically:

- Uses pyenv to manage Python versions
- Installs the specified version if not available
- Updates `.python-version` file
- Sets the local pyenv version

#### Optional Auto-Updates

Enable automatic Python version updates by setting an environment variable:

```bash
# Enable auto-updates in your shell profile or .env file
export PYTHON_AUTO_UPDATE=true

# Or add to .env file
echo "PYTHON_AUTO_UPDATE=true" >> .env
```

**Auto-update features:**

- **Automatic Detection**: Checks for newer stable versions when entering the project directory
- **Non-Intrusive**: Only updates when a newer version is available
- **Safe**: Uses pyenv for version management and installation
- **Optional**: Disabled by default, must be explicitly enabled
- **Efficient**: Only runs update check when environment loads (not on every command)

**How auto-updates work:**

1. When `PYTHON_AUTO_UPDATE=true` is set, direnv checks for newer Python versions
2. Compares current `.python-version` with latest available stable version
3. If newer version exists, automatically updates and installs it
4. Virtual environment is recreated with the new Python version

**Note:** Auto-updates only occur when entering the project directory with direnv. Set `PYTHON_AUTO_UPDATE=false` or remove the variable to disable.

#### Version Management Best Practices

- **Keep versions current**: Use auto-updates or manual updates to stay on recent stable versions
- **Test after updates**: Run your test suite after Python version changes
- **Document requirements**: Specify minimum Python version in project documentation
- **Use virtual environments**: Always use virtual environments to isolate project dependencies
- **Backup before major updates**: Consider backing up your environment before major version jumps

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

**Windows:**

```powershell
# Using the provided setup script (recommended)
.\scripts\setup-windows.ps1 -InstallDirenv -SetupHooks

# Or install manually via Scoop (recommended for Windows)
scoop install direnv

# Or via Chocolatey
choco install direnv

# Or manual installation
# Download from: https://github.com/direnv/direnv/releases
# Add to PATH and setup hooks as shown below
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

**PowerShell (Windows):**

```powershell
# Add to PowerShell profile ($PROFILE)
if (Get-Command direnv -ErrorAction SilentlyContinue) {
    Invoke-Expression "$(direnv hook pwsh)"
}
```

**Windows Subsystem for Linux (WSL):**

```bash
# Add to ~/.bashrc in WSL
eval "$(direnv hook bash)"
```

**External Terminals (MobaXterm, PuTTY, PowerShell, etc.):**

For terminals that don't automatically load your shell configuration:

```bash
# Manual direnv setup for external terminals
eval "$(direnv hook bash)"

# Then navigate to your project
cd /path/to/your/project

# Allow direnv to load the environment
direnv allow
```

**PowerShell (External):**

```powershell
# For external PowerShell terminals
if (Get-Command direnv -ErrorAction SilentlyContinue) {
    Invoke-Expression "$(direnv hook pwsh)"
}

# Navigate to project
cd C:\path\to\your\project

# Allow direnv
direnv allow
```

**MobaXterm/PuTTY Setup:**

1. **Connect to your server/WSL**
2. **Run the direnv hook manually:**

   ```bash
   eval "$(direnv hook bash)"
   ```

3. **Navigate to your project:**

   ```bash
   cd /path/to/project
   direnv allow
   ```

4. **For persistent setup, add to your shell profile:**

   ```bash
   echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
   source ~/.bashrc
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
- On Windows: Ensure PowerShell execution policy allows script execution

**Nix commands not found:**

- Ensure Nix is in PATH
- Restart your shell after installation
- On Windows: Check if Nix is properly installed in WSL

**Package not found:**

- Update flake inputs: `nix flake update`
- Check package names in Nix files

### Environment File Safety

**`.env` file protection:**

- All setup scripts check for existing `.env` files before copying
- **Never overwrites** existing `.env` files
- Only creates `.env` from template if it doesn't exist
- Your custom configuration is always preserved

**Example behavior:**

```bash
# First run - creates .env from template
./setup.sh
# Output: "✅ Created .env file from config/.env.example"

# Second run - preserves existing .env
./setup.sh
# Output: "📝 .env file already exists"
```

### Windows-Specific Issues

**Direnv not working in PowerShell:**

```powershell
# Check if direnv is in PATH
Get-Command direnv

# Reload PowerShell profile
. $PROFILE

# Manually test direnv
direnv allow .
```

**WSL integration issues:**

```bash
# Ensure WSL has access to Windows PATH (if needed)
# Add to ~/.bashrc in WSL:
export PATH="$PATH:/mnt/c/Windows/System32"

# Test direnv in WSL
direnv --version
direnv allow .
```

**Direnv configuration directory issues:**

```powershell
# Create direnv config directory manually
mkdir %USERPROFILE%\.config\direnv

# Set environment variable
setx DIRENV_CONFIG %USERPROFILE%\.config\direnv

# Restart PowerShell and try again
direnv allow .
```

**PowerShell execution policy issues:**

```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set execution policy if needed
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows.ps1
```

**External Terminal Issues:**

**Direnv not loading in MobaXterm/PuTTY:**

```bash
# Check if direnv hook is loaded
echo $PROMPT_COMMAND | grep direnv

# If not loaded, run manually
eval "$(direnv hook bash)"

# Then allow the environment
direnv allow
```

**Environment not persisting in external terminals:**

```bash
# Add to your shell profile for persistence
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
echo 'eval "$(direnv hook bash)"' >> ~/.bash_profile

# Reload your shell configuration
source ~/.bashrc
```

**WSL external terminal issues:**

```bash
# If connecting via SSH/external terminal to WSL
# Ensure direnv is installed in WSL
which direnv

# Load direnv hook
eval "$(direnv hook bash)"

# Navigate to project and allow
cd /path/to/project
direnv allow
```

**PowerShell external terminal issues:**

```powershell
# Check if direnv is available
Get-Command direnv

# Load direnv hook
if (Get-Command direnv -ErrorAction SilentlyContinue) {
    Invoke-Expression "$(direnv hook pwsh)"
}

# Navigate and allow
cd C:\path\to\project
direnv allow
```

**Permission issues on Windows:**

```powershell
# Run PowerShell as Administrator
# Or set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# For WSL, ensure .envrc has correct permissions
chmod +x .envrc
```

**Path issues:**

- Windows: Use forward slashes in .envrc files
- WSL: Windows paths should use `/mnt/c/` format
- Mixed environments: Be consistent with path separators

**Nix installation issues on Windows:**

````powershell
# If Nix installation fails, try WSL approach:
wsl --install
# Then in WSL:
curl -L https://nixos.org/nix/install | sh

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
````

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

## Development Workspace (byobu/tmux)

For an enhanced development experience with multiple windows and panes:

### Setup Development Workspace:

```bash
# After entering the project directory, run:
./scripts/setup-dev-workspace.sh
```

### Workspace Layout:

```
Window 1: editor    - Main editing (split: files + editor)
Window 2: server    - Development server (split: server + logs)
Window 3: testing   - Testing & debugging (split: tests + results)
Window 4: services  - Database & services (split: db + docker)
Window 5: git       - Version control (split: status + log)
```

### Workspace Controls:

```bash
# Switch between windows: Ctrl-b + [1-5]
# Switch between panes: Ctrl-b + [arrow keys]
# Detach from session: Ctrl-b + d
# Reattach to session: tmux attach -t dev-projectname
# Or with byobu: byobu attach -t dev-projectname
```

### Benefits:

- ✅ **Organized Workflow**: Dedicated windows for different tasks
- ✅ **Persistent Sessions**: Survive terminal restarts
- ✅ **Split Screen**: Multiple views in one window
- ✅ **Session Sharing**: Can share sessions with team members
- ✅ **Customizable**: Easy to modify layout for your needs

### Requirements:

```bash
# Install byobu (recommended):
sudo apt install byobu  # Ubuntu/Debian/Kali

# Or install tmux:
sudo apt install tmux   # Ubuntu/Debian/Kali
```

### First-Time Setup:

```bash
# Enable byobu:
byobu-enable

# Or configure tmux:
tmux  # Start tmux, then Ctrl-b + : and type 'source-file ~/.tmux.conf'
```

The workspace script will automatically detect whether you have byobu or tmux installed and create the appropriate session.
