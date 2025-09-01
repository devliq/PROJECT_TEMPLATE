#!/bin/bash

# Development Environment Setup Script
# This script sets up the complete development environment

set -euo pipefail  # Exit on any error, undefined variables, or pipe failures

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
DEFAULT_NODE_VERSION="18.0.0"
DEFAULT_DOCKER_COMPOSE_VERSION="1.25.0"
DEFAULT_SKIP_DOCKER=false
DEFAULT_SKIP_DATABASE_SETUP=false
DEFAULT_AUTO_OPEN_BROWSER=true
DEFAULT_SETUP_WORKSPACE=true

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
# VERSION CHECKING FUNCTIONS
# =============================================================================

check_node_version() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not installed"
        return 1
    fi

    local version
    version=$(node --version | sed 's/v//')
    local required=${NODE_VERSION:-$DEFAULT_NODE_VERSION}

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Node.js version $version is below required $required"
        return 1
    fi

    log_success "Node.js version: $version"
}

check_npm_version() {
    if ! command -v npm &> /dev/null; then
        log_error "npm is required but not installed"
        return 1
    fi

    local version
    version=$(npm --version)
    local required="6.0.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "npm version $version is below required $required"
        return 1
    fi

    log_success "npm version: $version"
}

check_docker_version() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is required but not installed"
        return 1
    fi

    local version
    version=$(docker --version | sed 's/Docker version \([0-9.]*\).*/\1/')
    local required="20.0.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Docker version $version is below required $required"
        return 1
    fi

    log_success "Docker version: $version"
}

check_docker_compose_version() {
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is required but not installed"
        return 1
    fi

    local version
    if command -v docker-compose &> /dev/null; then
        version=$(docker-compose --version | sed 's/.*version \([0-9.]*\).*/\1/')
    else
        version=$(docker compose version | sed 's/.*version \([0-9.]*\).*/\1/')
    fi

    local required=${DOCKER_COMPOSE_VERSION:-$DEFAULT_DOCKER_COMPOSE_VERSION}
    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Docker Compose version $version is below required $required"
        return 1
    fi

    log_success "Docker Compose version: $version"
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
    local config_file="config/setup.config"
    if [ -f "$config_file" ]; then
        log_info "Loading setup configuration..."
        source "$config_file"
        log_success "Setup configuration loaded"
    else
        log_warning "Setup config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    NODE_VERSION=${NODE_VERSION:-$DEFAULT_NODE_VERSION}
    DOCKER_COMPOSE_VERSION=${DOCKER_COMPOSE_VERSION:-$DEFAULT_DOCKER_COMPOSE_VERSION}
    SKIP_DOCKER=${SKIP_DOCKER:-$DEFAULT_SKIP_DOCKER}
    SKIP_DATABASE_SETUP=${SKIP_DATABASE_SETUP:-$DEFAULT_SKIP_DATABASE_SETUP}
    AUTO_OPEN_BROWSER=${AUTO_OPEN_BROWSER:-$DEFAULT_AUTO_OPEN_BROWSER}
    SETUP_WORKSPACE=${SETUP_WORKSPACE:-$DEFAULT_SETUP_WORKSPACE}
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_environment() {
    log_step "Validating environment..."

    # Check if we're in the right directory
    if [ ! -f "README.MD" ]; then
        log_error "Please run this script from the project root directory"
        return 1
    fi

    # Check if required files exist
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. This setup is designed for Node.js projects"
        return 1
    fi

    log_success "Environment validation passed"
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
# PREREQUISITE CHECKING FUNCTIONS
# =============================================================================

check_prerequisites() {
    log_step "Checking prerequisites..."

    # Check Node.js and npm
    check_node_version || return 1
    check_npm_version || return 1

    # Check Docker (unless skipped)
    if [ "$SKIP_DOCKER" != "true" ]; then
        check_docker_version || return 1
        check_docker_compose_version || return 1
    else
        log_info "Skipping Docker checks (--skip-docker)"
    fi

    log_success "Prerequisites check passed!"
}

# Setup direnv and Nix integration
log_info "🔧 Setting up direnv and Nix integration..."

# Check for .envrc file
if [ ! -f ".envrc" ]; then
    log_info "Creating .envrc file for automatic environment loading..."
    cp .envrc .envrc 2>/dev/null || {
        # Create basic .envrc if copy fails
        cat > .envrc << 'EOF'
#!/usr/bin/env bash
echo "🔧 Loading development environment..."

# Load .env file if it exists
if [ -f ".env" ]; then
    echo "📋 Loading environment variables from .env"
    set -a
    source .env
    set +a
fi

# Set basic project paths
export PROJECT_ROOT="$(pwd)"
export PATH="$PROJECT_ROOT/scripts:$PATH"

echo "✅ Environment loaded!"
EOF
        chmod +x .envrc
    }
    log_success ".envrc file created"
else
    log_info ".envrc file already exists"
fi

# Setup direnv hooks based on platform
setup_direnv_hooks() {
    local shell_config=""

    case "$PLATFORM" in
        "linux"|"macos")
            # Try to detect shell and setup hooks
            if [ -n "$ZSH_VERSION" ]; then
                shell_config="$HOME/.zshrc"
                hook_cmd='eval "$(direnv hook zsh)"'
            elif [ -n "$BASH_VERSION" ]; then
                shell_config="$HOME/.bashrc"
                hook_cmd='eval "$(direnv hook bash)"'
            else
                log_warning "Unknown shell, direnv hooks not configured automatically"
                return 1
            fi
            ;;
        "windows")
            # Windows-specific setup
            if [ -f "/etc/bash.bashrc" ]; then
                shell_config="/etc/bash.bashrc"
                hook_cmd='eval "$(direnv hook bash)"'
            elif [ -f "$HOME/.bashrc" ]; then
                shell_config="$HOME/.bashrc"
                hook_cmd='eval "$(direnv hook bash)"'
            else
                log_warning "Windows shell configuration not found"
                log_info "For Windows, add this to your shell profile:"
                log_info '  eval "$(direnv hook bash)"'
                return 1
            fi
            ;;
    esac

    if [ -n "$shell_config" ] && [ -n "$hook_cmd" ]; then
        if ! grep -q "direnv hook" "$shell_config" 2>/dev/null; then
            echo "" >> "$shell_config"
            echo "# direnv hook" >> "$shell_config"
            echo "$hook_cmd" >> "$shell_config"
            log_success "Added direnv hook to $shell_config"
            log_info "Restart your shell or run: source $shell_config"
        else
            log_info "Direnv hook already configured in $shell_config"
        fi
    fi
}

# Check and setup direnv
if command -v direnv &> /dev/null; then
    log_success "direnv is installed"
    setup_direnv_hooks

    # Allow .envrc if it exists
    if [ -f ".envrc" ]; then
        log_info "Allowing .envrc file..."
        direnv allow . 2>/dev/null || log_warning "Could not automatically allow .envrc - run 'direnv allow' manually"
    fi
else
    log_warning "direnv not found - install for automatic environment loading"
    case "$PLATFORM" in
        "linux")
            log_info "Install with: sudo apt install direnv (Ubuntu/Debian)"
            log_info "Or: sudo pacman -S direnv (Arch)"
            ;;
        "macos")
            log_info "Install with: brew install direnv"
            ;;
        "windows")
            log_info "Install with: scoop install direnv (via Scoop)"
            log_info "Or use WSL and install via Linux package manager"
            ;;
    esac
fi

# Check Nix setup
if command -v nix &> /dev/null; then
    log_success "Nix is installed"

    # Check for nix-direnv
    if ! nix-env -q | grep -q nix-direnv; then
        log_info "Installing nix-direnv for optimized environment loading..."
        nix-env -iA nixpkgs.nix-direnv
        log_success "nix-direnv installed"
    else
        log_success "nix-direnv is available"
    fi

    # Enable experimental features if needed
    if [ -f "flake.nix" ]; then
        log_info "Flake configuration detected"
        if ! nix show-config | grep -q "experimental-features.*nix-command.*flakes"; then
            log_info "Enabling Nix flakes support..."
            mkdir -p ~/.config/nix
            echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
            log_success "Nix flakes enabled"
        fi
    fi
else
    log_warning "Nix not found - install for reproducible environments"
    log_info "Visit: https://nixos.org/download.html"
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    # Find config directory dynamically
    config_dir=""
    for dir in */; do
        if [[ -f "${dir}.env.example" ]]; then
            config_dir="${dir%/}"
            break
        fi
    done

    if [ -n "$config_dir" ] && [ -f "$config_dir/.env.example" ]; then
        log_info "📝 Creating .env file from template..."
        cp "$config_dir/.env.example" .env
        log_success ".env file created from $config_dir/.env.example. Please update the values as needed."
    else
        log_warning "Could not find .env.example template file. Please create .env manually."
    fi
else
    log_info "📝 .env file already exists"
fi

# Install dependencies
log_info "📦 Installing Node.js dependencies..."
npm install
log_success "Dependencies installed!"

# Set up Git hooks
log_info "🔗 Setting up Git hooks..."
npm run prepare
log_success "Git hooks configured!"

# Create necessary directories
log_info "📁 Creating necessary directories..."
mkdir -p build
mkdir -p assets
mkdir -p temp
log_success "Directories created!"

# Initialize Docker environment
log_info "🐳 Setting up Docker environment..."

# Stop any existing containers
log_info "Stopping existing containers..."
docker-compose down --remove-orphans 2>/dev/null || true

# Build and start services
log_info "Building and starting Docker services..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d --build
else
    docker compose up -d --build
fi

# Wait for services to be healthy
log_info "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
log_info "🏥 Checking service health..."

# Check database
if docker-compose ps db | grep -q "Up"; then
    log_success "PostgreSQL database is running"
else
    log_warning "PostgreSQL database may not be ready yet"
fi

# Check Redis
if docker-compose ps redis | grep -q "Up"; then
    log_success "Redis cache is running"
else
    log_warning "Redis cache may not be ready yet"
fi

# Check application
if docker-compose ps app | grep -q "Up"; then
    log_success "Application is running"
else
    log_warning "Application may not be ready yet"
fi

# Run initial setup tasks
log_info "🔧 Running initial setup tasks..."

# Run database migrations/initialization
log_info "Setting up database..."
sleep 5  # Give database more time to be ready

# Check if we can connect to the database
if docker-compose exec -T db pg_isready -U user -d myproject_db >/dev/null 2>&1; then
    log_success "Database connection successful"
else
    log_warning "Database may not be fully ready yet. It will continue initializing in the background."
fi

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_setup() {
    log_step "Verifying setup..."

    local issues=0

    # Check if .env file exists
    if [ ! -f ".env" ]; then
        log_error ".env file not found"
        ((issues++))
    fi

    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        log_error "node_modules directory not found"
        ((issues++))
    fi

    # Check if Docker services are running (if not skipped)
    if [ "$SKIP_DOCKER" != "true" ] && [ -f "docker-compose.yml" ]; then
        if ! docker-compose ps | grep -q "Up"; then
            log_warning "No Docker services are running"
        else
            log_success "Docker services are running"
        fi
    fi

    # Check if application is accessible
    if curl -f -s http://localhost:3000/health >/dev/null 2>&1; then
        log_success "Application health check passed"
    else
        log_warning "Application health check failed"
    fi

    if [ $issues -eq 0 ]; then
        log_success "Setup verification passed"
        return 0
    else
        log_error "Setup verification failed with $issues issues"
        return 1
    fi
}

# =============================================================================
# POST-SETUP FUNCTIONS
# =============================================================================

display_completion_message() {
    log_success "🎉 Development environment setup completed!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update the .env file with your specific configuration"
    echo "2. Access your application at: http://localhost:3000"
    echo "3. Access Grafana at: http://localhost:3001 (admin/admin)"
    echo "4. Access Prometheus at: http://localhost:9090"
    echo "5. View logs with: docker-compose logs -f"
    echo ""
    echo "📚 Useful commands:"
    echo "• Start services: docker-compose up -d"
    echo "• Stop services: docker-compose down"
    echo "• View logs: docker-compose logs -f [service-name]"
    echo "• Run tests: npm test"
    echo "• Start development server: npm run dev"
    echo ""
    echo "🔧 Development tools:"
    echo "• ESLint: npm run lint"
    echo "• Prettier: npm run format"
    echo "• TypeScript check: npm run typecheck"
    echo ""
}

open_browser() {
    if [ "$AUTO_OPEN_BROWSER" != "true" ]; then
        return 0
    fi

    log_info "🌐 Opening application in browser..."
    sleep 2

    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:3000 >/dev/null 2>&1 &
    elif command -v open &> /dev/null; then
        open http://localhost:3000 >/dev/null 2>&1 &
    elif [ "$PLATFORM" = "windows" ] && command -v start &> /dev/null; then
        start http://localhost:3000 >/dev/null 2>&1 &
    else
        log_info "Please open http://localhost:3000 in your browser"
    fi
}

setup_workspace() {
    if [ "$SETUP_WORKSPACE" != "true" ]; then
        return 0
    fi

    if [ -f "scripts/setup-dev-workspace.sh" ]; then
        log_info "Setting up development workspace..."
        bash scripts/setup-dev-workspace.sh --no-attach
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🚀 Starting development environment setup..."
    echo "══════════════════════════════════════════════"

    # Load configuration
    load_configuration

    # Detect platform
    detect_platform

    # Validate environment
    validate_environment || exit 1

    # Check prerequisites
    check_prerequisites || exit 1

    # Setup workspace
    setup_workspace

    # Verify setup
    verify_setup

    # Display completion message
    display_completion_message

    # Open browser
    open_browser

    log_success "Setup complete! Happy coding! 🚀"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-docker)
                SKIP_DOCKER=true
                shift
                ;;
            --skip-db)
                SKIP_DATABASE_SETUP=true
                shift
                ;;
            --no-browser)
                AUTO_OPEN_BROWSER=false
                shift
                ;;
            --no-workspace)
                SETUP_WORKSPACE=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Development Environment Setup Script"
                echo ""
                echo "Options:"
                echo "  --skip-docker     Skip Docker setup and checks"
                echo "  --skip-db         Skip database setup"
                echo "  --no-browser      Don't auto-open browser"
                echo "  --no-workspace    Don't setup development workspace"
                echo "  --help            Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --skip-docker"
                echo "  $0 --no-browser --no-workspace"
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

# Run main function
main