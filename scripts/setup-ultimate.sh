#!/bin/bash
# =============================================================================
# ULTIMATE DEVELOPMENT ENVIRONMENT SETUP
# =============================================================================
# The most comprehensive, cross-platform setup for Nix + direnv + .envrc
# Supports Linux, macOS, Windows, and WSL with maximum operability

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default configuration
DEFAULT_PROFILE="full"
DEFAULT_SKIP_DEPENDENCIES=false
DEFAULT_SKIP_VERIFICATION=false
DEFAULT_FORCE_REINSTALL=false

# Setup profiles
declare -A PROFILES
PROFILES=(
    ["minimal"]="Basic setup with direnv and .envrc"
    ["standard"]="Standard setup with Nix and direnv"
    ["full"]="Complete setup with all tools and features"
    ["ci"]="CI/CD optimized setup"
    ["docker"]="Docker-focused development setup"
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# =============================================================================
# CONFIGURATION FUNCTIONS
# =============================================================================

load_configuration() {
    # Load environment variables safely
    if [ -f ".env" ]; then
        log_info "Loading environment configuration..."
        set -a
        source .env
        set +a
        log_success "Environment variables loaded"
    fi

    # Load setup configuration
    local config_file="config/ultimate-setup.config"
    if [ -f "$config_file" ]; then
        log_info "Loading ultimate setup configuration..."
        source "$config_file"
        log_success "Setup configuration loaded"
    else
        log_warning "Setup config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    PROFILE=${PROFILE:-$DEFAULT_PROFILE}
    SKIP_DEPENDENCIES=${SKIP_DEPENDENCIES:-$DEFAULT_SKIP_DEPENDENCIES}
    SKIP_VERIFICATION=${SKIP_VERIFICATION:-$DEFAULT_SKIP_VERIFICATION}
    FORCE_REINSTALL=${FORCE_REINSTALL:-$DEFAULT_FORCE_REINSTALL}
}

# =============================================================================
# PROFILE FUNCTIONS
# =============================================================================

validate_profile() {
    if [ -z "${PROFILES[$PROFILE]:-}" ]; then
        log_error "Invalid profile: $PROFILE"
        log_info "Available profiles:"
        for profile in "${!PROFILES[@]}"; do
            log_info "  $profile - ${PROFILES[$profile]}"
        done
        return 1
    fi

    log_success "Selected profile: $PROFILE - ${PROFILES[$PROFILE]}"
}

get_profile_components() {
    case $PROFILE in
        "minimal")
            echo "direnv envrc"
            ;;
        "standard")
            echo "direnv nix envrc"
            ;;
        "full")
            echo "direnv nix envrc verification"
            ;;
        "ci")
            echo "direnv envrc"
            ;;
        "docker")
            echo "direnv envrc docker"
            ;;
        *)
            echo "direnv envrc"
            ;;
    esac
}

# =============================================================================
# PLATFORM DETECTION
# =============================================================================

detect_platform() {
    case "$(uname -s)" in
        Linux*)
            if [ -f "/proc/version" ] && grep -q "Microsoft" "/proc/version" 2>/dev/null; then
                PLATFORM="wsl"
                WSL_DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
            else
                PLATFORM="linux"
            fi
            ;;
        Darwin*)    PLATFORM="macos" ;;
        CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
        *)          PLATFORM="unknown" ;;
    esac

    log_info "Detected platform: $PLATFORM"
    if [ "$PLATFORM" = "wsl" ]; then
        log_info "WSL Distribution: $WSL_DISTRO"
    fi
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

check_dependencies() {
    log_step "Checking system dependencies..."

    local missing_deps=()

    # Check for required tools
    for tool in curl wget git; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        case "$PLATFORM" in
            "linux"|"wsl")
                log_info "Install with: sudo apt update && sudo apt install -y ${missing_deps[*]}"
                ;;
            "macos")
                log_info "Install with: brew install ${missing_deps[*]}"
                ;;
            "windows")
                log_info "Install Git for Windows which includes these tools"
                ;;
        esac
        exit 1
    fi

    log_success "All required dependencies found"
}

# =============================================================================
# DIRENV INSTALLATION
# =============================================================================

install_direnv() {
    if command -v direnv &> /dev/null; then
        log_success "direnv is already installed"
        return 0
    fi

    log_step "Installing direnv..."

    case "$PLATFORM" in
        "linux"|"wsl")
            if command -v apt &> /dev/null; then
                log_info "Installing via apt..."
                sudo apt update && sudo apt install -y direnv
            elif command -v pacman &> /dev/null; then
                log_info "Installing via pacman..."
                sudo pacman -S --noconfirm direnv
            elif command -v dnf &> /dev/null; then
                log_info "Installing via dnf..."
                sudo dnf install -y direnv
            else
                install_direnv_manual
            fi
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                log_info "Installing via Homebrew..."
                brew install direnv
            else
                install_direnv_manual
            fi
            ;;
        "windows")
            install_direnv_windows
            ;;
    esac

    if command -v direnv &> /dev/null; then
        log_success "direnv installed successfully"
    else
        log_error "Failed to install direnv"
        return 1
    fi
}

install_direnv_manual() {
    log_info "Installing direnv manually..."
    local temp_dir
    temp_dir=$(mktemp -d)

    curl -sS https://webi.sh/direnv | sh
    source ~/.config/envman/PATH.env

    rm -rf "$temp_dir"
}

install_direnv_windows() {
    log_info "Installing direnv for Windows..."

    # Try Scoop first
    if command -v scoop &> /dev/null; then
        scoop install direnv
        return
    fi

    # Try Chocolatey
    if command -v choco &> /dev/null; then
        choco install direnv -y
        return
    fi

    # Manual installation
    log_info "Manual installation for Windows..."
    local temp_dir
    temp_dir=$(mktemp -d)

    # Get latest release
    local api_url="https://api.github.com/repos/direnv/direnv/releases/latest"
    local download_url
    download_url=$(curl -s "$api_url" | grep "browser_download_url.*windows.*amd64" | head -1 | cut -d '"' -f 4)

    if [ -n "$download_url" ]; then
        curl -L "$download_url" -o "$temp_dir/direnv.zip"
        unzip "$temp_dir/direnv.zip" -d "$temp_dir"

        # Add to PATH
        mkdir -p ~/bin
        mv "$temp_dir/direnv.exe" ~/bin/
        export PATH="$HOME/bin:$PATH"

        log_info "Add $HOME/bin to your PATH environment variable"
    fi

    rm -rf "$temp_dir"
}

# =============================================================================
# NIX INSTALLATION
# =============================================================================

install_nix() {
    if command -v nix &> /dev/null; then
        log_success "Nix is already installed"
        return 0
    fi

    log_step "Installing Nix..."

    case "$PLATFORM" in
        "linux"|"wsl")
            log_info "Installing Nix for Linux/WSL..."
            curl -L https://nixos.org/nix/install | sh

            # Source nix
            if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
                . ~/.nix-profile/etc/profile.d/nix.sh
            fi
            ;;
        "macos")
            log_info "Installing Nix for macOS..."
            curl -L https://nixos.org/nix/install | sh
            ;;
        "windows")
            log_warning "Nix on native Windows is experimental"
            log_info "Consider using WSL for better Nix support"
            return 1
            ;;
    esac

    if command -v nix &> /dev/null; then
        log_success "Nix installed successfully"

        # Enable flakes
        mkdir -p ~/.config/nix
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

        # Install nix-direnv
        log_info "Installing nix-direnv..."
        nix-env -iA nixpkgs.nix-direnv
    
        # Install direnv plugins for nvm and pyenv
        log_info "Installing direnv plugins..."
        if nix-env -q | grep -q nix-direnv; then
            # Try to install direnv plugins via nix if available
            nix-env -iA nixpkgs.direnv 2>/dev/null || log_info "direnv already available"
        fi

        log_success "Nix setup complete"
    else
        log_error "Failed to install Nix"
        return 1
    fi
}

# =============================================================================
# SHELL HOOKS SETUP
# =============================================================================

setup_shell_hooks() {
    log_step "Setting up shell hooks..."

    local shell_config=""
    local hook_cmd=""

    # Detect shell and set config file
    case "$PLATFORM" in
        "linux"|"wsl"|"macos")
            if [ -n "${ZSH_VERSION:-}" ]; then
                shell_config="$HOME/.zshrc"
                hook_cmd='eval "$(direnv hook zsh)"'
            elif [ -n "${BASH_VERSION:-}" ]; then
                if [ "$PLATFORM" = "macos" ]; then
                    shell_config="$HOME/.bash_profile"
                else
                    shell_config="$HOME/.bashrc"
                fi
                hook_cmd='eval "$(direnv hook bash)"'
            elif [ -n "${FISH_VERSION:-}" ]; then
                shell_config="$HOME/.config/fish/config.fish"
                hook_cmd='direnv hook fish | source'
            fi
            ;;
        "windows")
            # PowerShell
            setup_powershell_hooks
            return
            ;;
    esac

    if [ -n "$shell_config" ] && [ -n "$hook_cmd" ]; then
        if ! grep -q "direnv hook" "$shell_config" 2>/dev/null; then
            log_info "Adding direnv hook to $shell_config"
            echo "" >> "$shell_config"
            echo "# direnv hook" >> "$shell_config"
            echo "$hook_cmd" >> "$shell_config"
            log_success "Shell hooks configured"
            log_info "Restart your shell or run: source $shell_config"
        else
            log_success "Shell hooks already configured"
        fi
    else
        log_warning "Could not detect shell type automatically"
        log_info "Add this to your shell config:"
        echo '  eval "$(direnv hook bash)"  # for bash'
        echo '  eval "$(direnv hook zsh)"   # for zsh'
    fi
}

setup_powershell_hooks() {
    log_info "Setting up PowerShell hooks..."

    # Detect PowerShell executable
    local ps_cmd=""
    if command -v pwsh &> /dev/null; then
        ps_cmd="pwsh"
    elif command -v powershell.exe &> /dev/null; then
        ps_cmd="powershell.exe"
    else
        log_error "PowerShell not found"
        return 1
    fi

    # Execute PowerShell commands
    $ps_cmd -Command "
        \$profilePath = \$PROFILE
        if (!(Test-Path \$profilePath)) {
            New-Item -ItemType File -Path \$profilePath -Force | Out-Null
        }

        \$profileContent = Get-Content \$profilePath -Raw
        if (\$profileContent -notlike '*direnv hook pwsh*') {
            Add-Content -Path \$profilePath -Value ''
            Add-Content -Path \$profilePath -Value '# direnv hook'
            Add-Content -Path \$profilePath -Value 'if (Get-Command direnv -ErrorAction SilentlyContinue) {'
            Add-Content -Path \$profilePath -Value '    Invoke-Expression \"\$(direnv hook pwsh)\"'
            Add-Content -Path \$profilePath -Value '}'
            Write-Host 'PowerShell hooks configured'
            Write-Host 'Restart PowerShell to load hooks'
        } else {
            Write-Host 'PowerShell hooks already configured'
        }
    "

    if [ $? -eq 0 ]; then
        log_success "PowerShell hooks configured"
    else
        log_error "Failed to configure PowerShell hooks"
    fi
}

# =============================================================================
# ENVIRONMENT FILES SETUP
# =============================================================================

setup_environment_files() {
    log_step "Setting up environment files..."

    # Create .envrc if it doesn't exist
    if [ ! -f ".envrc" ]; then
        log_info "Creating .envrc file..."
        cp .envrc .envrc 2>/dev/null || create_default_envrc
        chmod +x .envrc
        log_success ".envrc created"
    else
        log_success ".envrc already exists"
    fi

    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        # Find config directory dynamically
        local config_dir=""
        for dir in */; do
            if [[ -f "${dir}.env.example" ]]; then
                config_dir="${dir%/}"
                break
            fi
        done

        if [ -n "$config_dir" ] && [ -f "$config_dir/.env.example" ]; then
            log_info "Creating .env from $config_dir/.env.example..."
            cp "$config_dir/.env.example" .env
            log_success ".env created - please update with your values"
        else
            log_warning "No .env.example found - create .env manually"
        fi
    else
        log_success ".env already exists (preserved existing file)"
    fi

    # Allow .envrc
    if command -v direnv &> /dev/null && [ -f ".envrc" ]; then
        log_info "Allowing .envrc..."
        direnv allow . 2>/dev/null || log_warning "Run 'direnv allow .' manually"
    fi
}

create_default_envrc() {
    cat > .envrc << 'EOF'
#!/usr/bin/env bash
# Ultimate .envrc configuration with Nix + direnv integration

# Enable strict mode
set -euo pipefail

# Color codes for status
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

show_status() {
    echo -e "${BLUE}[ENV]${NC} $1"
}

show_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Detect platform
case "$(uname -s)" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="macos" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *)          PLATFORM="unknown" ;;
esac

show_status "Loading environment for $PLATFORM..."

# Load .env file if it exists
if [ -f ".env" ]; then
    show_status "Loading .env file..."
    set -a
    source .env
    set +a
    show_success "Environment variables loaded"
fi

# Set project root
export PROJECT_ROOT="$(pwd)"

# Try Nix environment first (if available)
if has nix_direnv_version && [ -f "flake.nix" ]; then
    show_status "Using Nix flakes environment..."
    use flake
elif has nix_direnv_version && [ -f "shell.nix" ]; then
    show_status "Using Nix shell environment..."
    use nix
elif has nix && [ -f "flake.nix" ]; then
    show_status "Nix available - run 'nix develop' manually"
elif has nix && [ -f "shell.nix" ]; then
    show_status "Nix available - run 'nix-shell' manually"
fi

# Find and setup project paths dynamically
setup_paths() {
    # Scripts directory
    for dir in */; do
        if [[ "${dir%/}" =~ _SCRIPT ]] || [[ -f "${dir}setup.sh" ]] || [[ -f "${dir}build.sh" ]]; then
            export PATH="$PROJECT_ROOT/${dir%/}:$PATH"
            show_success "Scripts: ${dir%/}"
            break
        fi
    done

    # Source directory
    for dir in */; do
        if [[ "${dir%/}" =~ _SRC ]] || [[ -f "${dir}main.py" ]] || [[ -f "${dir}index.js" ]]; then
            export PYTHONPATH="$PROJECT_ROOT/${dir%/}:$PYTHONPATH"
            export NODE_PATH="$PROJECT_ROOT/${dir%/}:$NODE_PATH"
            show_success "Source: ${dir%/}"
            break
        fi
    done

    # Common fallbacks
    if [ -d "scripts" ]; then
        export PATH="$PROJECT_ROOT/scripts:$PATH"
    fi
    if [ -d "src" ]; then
        export PYTHONPATH="$PROJECT_ROOT/src:$PYTHONPATH"
        export NODE_PATH="$PROJECT_ROOT/src:$NODE_PATH"
    fi
}

setup_paths

show_success "Environment ready!"
echo "💡 Tip: Run 'direnv reload' to refresh"
EOF
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_setup() {
    log_step "Verifying setup..."

    local issues=0

    # Check direnv
    if command -v direnv &> /dev/null; then
        log_success "✓ direnv installed"
    else
        log_error "✗ direnv not found"
        ((issues++))
    fi

    # Check Nix
    if command -v nix &> /dev/null; then
        log_success "✓ Nix installed"
    else
        log_warning "⚠ Nix not found (optional but recommended)"
    fi

    # Check .envrc
    if [ -f ".envrc" ] && [ -x ".envrc" ]; then
        log_success "✓ .envrc exists and is executable"
    else
        log_error "✗ .envrc missing or not executable"
        ((issues++))
    fi

    # Check .env
    if [ -f ".env" ]; then
        log_success "✓ .env exists"
    else
        log_warning "⚠ .env not found (create from template)"
    fi

    if [ $issues -eq 0 ]; then
        log_success "🎉 Setup verification passed!"
        return 0
    else
        log_error "Setup verification failed with $issues issues"
        return 1
    fi
}

# =============================================================================
# MODULAR EXECUTION FUNCTIONS
# =============================================================================

run_component() {
    local component=$1

    case $component in
        "direnv")
            install_direnv
            ;;
        "nix")
            install_nix
            ;;
        "envrc")
            setup_environment_files
            ;;
        "docker")
            setup_docker_environment
            ;;
        "verification")
            if [ "$SKIP_VERIFICATION" != "true" ]; then
                verify_setup
            fi
            ;;
        *)
            log_warning "Unknown component: $component"
            ;;
    esac
}

setup_docker_environment() {
    log_step "Setting up Docker environment..."

    if command -v docker &> /dev/null; then
        log_success "Docker is available"
    else
        log_warning "Docker not found - install Docker for containerized development"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo
    echo "🚀 Ultimate Development Environment Setup"
    echo "═══════════════════════════════════════════"
    echo

    # Load configuration
    load_configuration

    # Validate profile
    validate_profile || exit 1

    detect_platform

    # Check dependencies unless skipped
    if [ "$SKIP_DEPENDENCIES" != "true" ]; then
        check_dependencies
    fi

    # Get components for the selected profile
    local components
    components=$(get_profile_components)

    # Run each component
    for component in $components; do
        run_component "$component"
    done

    # Setup shell hooks (always run)
    setup_shell_hooks

    # Final verification
    if [ "$SKIP_VERIFICATION" != "true" ]; then
        if verify_setup; then
            display_success_message
        fi
    else
        display_success_message
    fi
}

display_success_message() {
    echo
    log_success "🎉 Ultimate setup complete!"
    echo
    echo "📋 What you now have:"
    echo "• ✅ direnv for automatic environment loading"
    if [[ " $(get_profile_components) " =~ " nix " ]]; then
        echo "• ✅ Nix for reproducible environments"
    fi
    echo "• ✅ Cross-platform compatibility"
    echo "• ✅ Automatic .envrc and .env setup"
    echo "• ✅ Shell hooks configured"
    echo
    echo "🔧 Next steps:"
    echo "1. Restart your shell"
    echo "2. cd into this directory (environment loads automatically)"
    echo "3. Update .env with your configuration"
    echo "4. Run 'direnv reload' if needed"
    echo
    echo "📚 Useful commands:"
    echo "• direnv allow .     - Allow .envrc changes"
    echo "• direnv reload      - Reload environment"
    if [[ " $(get_profile_components) " =~ " nix " ]]; then
        echo "• nix develop        - Enter Nix environment"
        echo "• nix flake update   - Update dependencies"
    fi
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --skip-deps)
                SKIP_DEPENDENCIES=true
                shift
                ;;
            --skip-verification)
                SKIP_VERIFICATION=true
                shift
                ;;
            --force)
                FORCE_REINSTALL=true
                shift
                ;;
            --list-profiles)
                echo "Available setup profiles:"
                echo
                for profile in "${!PROFILES[@]}"; do
                    echo "  $profile - ${PROFILES[$profile]}"
                done
                echo
                echo "Usage: $0 --profile <profile-name>"
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Ultimate Development Environment Setup"
                echo ""
                echo "Options:"
                echo "  --profile NAME       Setup profile (default: full)"
                echo "  --skip-deps          Skip dependency checks"
                echo "  --skip-verification  Skip final verification"
                echo "  --force              Force reinstallation of tools"
                echo "  --list-profiles      List available profiles"
                echo "  --help               Show this help message"
                echo ""
                echo "Available profiles:"
                for profile in "${!PROFILES[@]}"; do
                    echo "  $profile - ${PROFILES[$profile]}"
                done
                echo ""
                echo "Examples:"
                echo "  $0 --profile minimal"
                echo "  $0 --profile full --force"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Parse command line arguments
parse_arguments "$@"

# Run main setup
main