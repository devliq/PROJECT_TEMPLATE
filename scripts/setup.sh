#!/bin/bash

# Project Setup Script
# This script sets up the development environment for the project

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
NC='\033[0m'

# Default configuration
DEFAULT_AUTO_DETECT=true
DEFAULT_SETUP_DIRS=true
DEFAULT_SETUP_ENV=true
DEFAULT_SETUP_SCRIPTS=true
DEFAULT_VERIFY_SETUP=true

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
        return 0  # Node.js not required for all projects
    fi

    local version
    version=$(node --version | sed 's/v//')
    local required="14.0.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_warning "Node.js version $version is below recommended $required"
    fi

    log_success "Node.js version: $version"
}

check_python_version() {
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        return 0  # Python not required for all projects
    fi

    local python_cmd="python3"
    if ! command -v python3 &> /dev/null; then
        python_cmd="python"
    fi

    local version
    version=$($python_cmd --version 2>&1 | sed 's/Python //')
    local required="3.6.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_warning "Python version $version is below recommended $required"
    fi

    log_success "Python version: $version"
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
    AUTO_DETECT=${AUTO_DETECT:-$DEFAULT_AUTO_DETECT}
    SETUP_DIRS=${SETUP_DIRS:-$DEFAULT_SETUP_DIRS}
    SETUP_ENV=${SETUP_ENV:-$DEFAULT_SETUP_ENV}
    SETUP_SCRIPTS=${SETUP_SCRIPTS:-$DEFAULT_SETUP_SCRIPTS}
    VERIFY_SETUP=${VERIFY_SETUP:-$DEFAULT_VERIFY_SETUP}
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_environment() {
    log_step "Validating environment..."

    # Check if we're in the right directory
    if [ ! -f "README.MD" ] && [ ! -f "readme.md" ] && [ ! -f "README.md" ]; then
        log_error "Please run this script from a project root directory"
        log_info "Look for README.MD, readme.md, or README.md"
        return 1
    fi

    log_success "Environment validation passed"
}

# =============================================================================
# PROJECT DETECTION FUNCTIONS
# =============================================================================

detect_project_type() {
    log_info "Detecting project type..."

    if [ -f "package.json" ]; then
        echo "nodejs"
        return
    fi

    if [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        echo "python"
        return
    fi

    if [ -f "pom.xml" ]; then
        echo "java"
        return
    fi

    if [ -f "Cargo.toml" ]; then
        echo "rust"
        return
    fi

    if [ -f "Makefile" ]; then
        echo "makefile"
        return
    fi

    echo "generic"
}

# =============================================================================
# SETUP FUNCTIONS
# =============================================================================

setup_directories() {
    if [ "$SETUP_DIRS" != "true" ]; then
        return 0
    fi

    log_step "Setting up project directories..."

    # Create standard directories
    local dirs=("src" "tests" "build" "deploy" "assets" "config" "scripts" "vendor" "temp" "logs" "docs")

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "Created directory: $dir"
        fi
    done

    log_success "Project directories setup complete"
}

setup_environment() {
    if [ "$SETUP_ENV" != "true" ]; then
        return 0
    fi

    log_step "Setting up environment files..."

    # Find and copy environment template
    local env_template_found=false
    for dir in */; do
        if [ -f "${dir}.env.example" ]; then
            if [ ! -f ".env" ]; then
                log_info "Creating .env file from ${dir%/}/.env.example..."
                cp "${dir}.env.example" .env
                log_success ".env file created. Please update it with your configuration."
                env_template_found=true
                break
            fi
        fi
    done

    if [ "$env_template_found" = false ] && [ ! -f ".env" ]; then
        log_warning "No .env.example template found. Please create .env manually."
    fi

    # Setup direnv if available
    if [ -f ".envrc" ]; then
        log_info "Checking direnv setup..."
        if command -v direnv &> /dev/null; then
            log_success "direnv found. Environment will be loaded automatically."
            log_info "Run 'direnv allow' to approve the .envrc file."
        else
            log_warning "direnv not found. For automatic environment loading:"
            log_info "Install direnv: https://direnv.net/"
        fi
    fi

    log_success "Environment setup complete"
}

setup_scripts() {
    if [ "$SETUP_SCRIPTS" != "true" ]; then
        return 0
    fi

    log_step "Setting up scripts..."

    # Make scripts executable
    local script_dirs=("scripts" "scripts" "bin")
    for dir in "${script_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_info "Making scripts executable in $dir/"
            chmod +x "$dir"/*.sh 2>/dev/null || true
            chmod +x "$dir"/*.py 2>/dev/null || true
            chmod +x "$dir"/*.js 2>/dev/null || true
        fi
    done

    log_success "Scripts setup complete"
}

install_dependencies() {
    local project_type=$1

    log_step "Installing dependencies for $project_type project..."

    case $project_type in
        "nodejs")
            if command -v npm &> /dev/null; then
                log_info "Installing Node.js dependencies..."
                npm install
                log_success "Node.js dependencies installed"
            else
                log_warning "npm not found. Please install Node.js and npm"
            fi
            ;;
        "python")
            if command -v pip &> /dev/null; then
                log_info "Installing Python dependencies..."
                pip install -r requirements.txt 2>/dev/null || log_info "No requirements.txt found"
                log_success "Python dependencies installed"
            else
                log_warning "pip not found. Please install Python and pip"
            fi
            ;;
        "java")
            if command -v mvn &> /dev/null; then
                log_info "Installing Java dependencies..."
                mvn dependency:resolve
                log_success "Java dependencies installed"
            else
                log_warning "Maven not found. Please install Maven"
            fi
            ;;
        *)
            log_info "No dependency manager detected for project type: $project_type"
            ;;
    esac
}

setup_git_hooks() {
    if [ -d ".git" ]; then
        log_info "Setting up Git hooks..."
        # Check for package.json prepare script
        if [ -f "package.json" ] && command -v npm &> /dev/null; then
            npm run prepare 2>/dev/null || log_info "No prepare script found"
        fi
        log_success "Git hooks configured"
    fi
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_setup() {
    if [ "$VERIFY_SETUP" != "true" ]; then
        return 0
    fi

    log_step "Verifying setup..."

    local issues=0

    # Check essential files
    if [ ! -f ".env" ]; then
        log_warning ".env file not found"
    fi

    # Check project structure
    local essential_dirs=("src" "tests")
    for dir in "${essential_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log_warning "Directory not found: $dir"
        fi
    done

    # Check dependencies
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        log_warning "node_modules not found - run 'npm install'"
        ((issues++))
    fi

    if [ $issues -eq 0 ]; then
        log_success "Setup verification passed"
        return 0
    else
        log_warning "Setup verification found $issues issues"
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🚀 Starting project setup..."
    echo "══════════════════════════════════════"

    # Load configuration
    load_configuration

    # Validate environment
    validate_environment || exit 1

    # Detect project type
    PROJECT_TYPE=$(detect_project_type)
    log_info "Detected project type: $PROJECT_TYPE"

    # Check tool versions
    check_node_version
    check_python_version

    # Setup components
    setup_directories
    setup_environment
    setup_scripts
    install_dependencies "$PROJECT_TYPE"
    setup_git_hooks

    # Verify setup
    verify_setup

    echo ""
    log_success "✅ Project setup completed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update your .env file with project-specific configuration"
    if [ -f ".envrc" ]; then
        echo "2. Run 'direnv allow' to enable automatic environment loading"
    fi
    echo "3. Add your source code to src/"
    echo "4. Run build scripts from scripts/"
    echo "5. Run test scripts to verify everything works"
    echo ""
    echo "📚 Useful commands:"
    echo "• Build: ./scripts/build.sh"
    echo "• Deploy: ./scripts/deploy.sh [environment]"
    echo "• Test: ./scripts/test-env.sh"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-dirs)
                SETUP_DIRS=false
                shift
                ;;
            --no-env)
                SETUP_ENV=false
                shift
                ;;
            --no-scripts)
                SETUP_SCRIPTS=false
                shift
                ;;
            --no-verify)
                VERIFY_SETUP=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Project Setup Script"
                echo ""
                echo "Options:"
                echo "  --no-dirs      Skip directory creation"
                echo "  --no-env       Skip environment setup"
                echo "  --no-scripts   Skip script setup"
                echo "  --no-verify    Skip setup verification"
                echo "  --help         Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --no-verify"
                echo "  $0 --no-env --no-scripts"
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