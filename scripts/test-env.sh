#!/bin/bash
# =============================================================================
# ENVIRONMENT TEST SCRIPT
# =============================================================================
# This script tests the automatic environment loading functionality
# Run this after setup to verify everything is working correctly

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
DEFAULT_TEST_DIRENV=true
DEFAULT_TEST_NIX=true
DEFAULT_TEST_ENVIRONMENT=true
DEFAULT_TEST_PROJECT_STRUCTURE=true
DEFAULT_TEST_DEPENDENCIES=true
DEFAULT_VERBOSE=false

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

test_pass() {
    echo -e "${GREEN}✓ PASS${NC} $1"
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC} $1"
}

test_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# =============================================================================
# VERSION CHECKING FUNCTIONS
# =============================================================================

check_bash_version() {
    local version
    version=$(bash --version | head -1 | sed 's/.*version \([0-9.]*\).*/\1/')
    local required="4.0.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_warning "Bash version $version is below recommended $required"
    fi

    log_success "Bash version: $version"
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

    # Load test configuration
    local config_file="config/test-env.config"
    if [ -f "$config_file" ]; then
        log_info "Loading test configuration..."
        source "$config_file"
        log_success "Test configuration loaded"
    else
        log_warning "Test config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    TEST_DIRENV=${TEST_DIRENV:-$DEFAULT_TEST_DIRENV}
    TEST_NIX=${TEST_NIX:-$DEFAULT_TEST_NIX}
    TEST_ENVIRONMENT=${TEST_ENVIRONMENT:-$DEFAULT_TEST_ENVIRONMENT}
    TEST_PROJECT_STRUCTURE=${TEST_PROJECT_STRUCTURE:-$DEFAULT_TEST_PROJECT_STRUCTURE}
    TEST_DEPENDENCIES=${TEST_DEPENDENCIES:-$DEFAULT_TEST_DEPENDENCIES}
    VERBOSE=${VERBOSE:-$DEFAULT_VERBOSE}
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     PLATFORM="linux" ;;
        Darwin*)    PLATFORM="macos" ;;
        CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
        *)          PLATFORM="unknown" ;;
    esac
}

# =============================================================================
# COMPREHENSIVE TEST FUNCTIONS
# =============================================================================

test_project_structure() {
    if [ "$TEST_PROJECT_STRUCTURE" != "true" ]; then
        return 0
    fi

    log_step "Testing project structure..."

    local issues=0

    # Check for README file
    if [ -f "README.MD" ] || [ -f "readme.md" ] || [ -f "README.md" ]; then
        test_pass "README file found"
    else
        test_fail "README file not found"
        ((issues++))
    fi

    # Check for .envrc file
    if [ -f ".envrc" ]; then
        test_pass ".envrc file exists"
        if [ -x ".envrc" ]; then
            test_pass ".envrc file is executable"
        else
            test_fail ".envrc file is not executable"
            test_info "Run: chmod +x .envrc"
            ((issues++))
        fi
    else
        test_fail ".envrc file not found"
        ((issues++))
    fi

    # Check for common project files
    local project_files=("package.json" "requirements.txt" "setup.py" "Cargo.toml" "Makefile")
    local found_project_file=false

    for file in "${project_files[@]}"; do
        if [ -f "$file" ]; then
            test_pass "Project file found: $file"
            found_project_file=true
            break
        fi
    done

    if [ "$found_project_file" = false ]; then
        test_warning "No common project files found"
    fi

    return $issues
}

test_direnv_setup() {
    if [ "$TEST_DIRENV" != "true" ]; then
        return 0
    fi

    log_step "Testing direnv setup..."

    local issues=0

    # Check direnv installation
    if command -v direnv &> /dev/null; then
        test_pass "direnv is installed"
        local version
        version=$(direnv --version)
        test_info "direnv version: $version"

        # Test direnv allow
        if [ -f ".envrc" ]; then
            test_info "Testing direnv allow..."
            if direnv allow 2>/dev/null; then
                test_pass "direnv allow succeeded"
            else
                test_fail "direnv allow failed"
                test_info "You may need to run 'direnv allow' manually"
                ((issues++))
            fi
        fi
    else
        test_fail "direnv is not installed"
        test_info "Install direnv: https://direnv.net/"
        ((issues++))
    fi

    return $issues
}

test_nix_setup() {
    if [ "$TEST_NIX" != "true" ]; then
        return 0
    fi

    log_step "Testing Nix setup..."

    local issues=0

    # Check Nix installation
    if command -v nix &> /dev/null; then
        test_pass "Nix is installed"
        local version
        version=$(nix --version)
        test_info "Nix version: $version"

        # Check for nix-direnv
        if nix-env -q 2>/dev/null | grep -q nix-direnv; then
            test_pass "nix-direnv is installed"
        else
            test_fail "nix-direnv is not installed"
            test_info "Install with: nix-env -iA nixpkgs.nix-direnv"
            ((issues++))
        fi

        # Check Nix files
        if [ -f "flake.nix" ]; then
            test_pass "flake.nix found"
        elif [ -f "shell.nix" ]; then
            test_pass "shell.nix found"
        else
            test_info "No Nix configuration files found"
        fi
    else
        test_fail "Nix is not installed"
        test_info "Install from: https://nixos.org/download.html"
        ((issues++))
    fi

    return $issues
}

test_environment_variables() {
    if [ "$TEST_ENVIRONMENT" != "true" ]; then
        return 0
    fi

    log_step "Testing environment variables..."

    local issues=0

    # Test PROJECT_ROOT
    if [ -n "${PROJECT_ROOT:-}" ]; then
        test_pass "PROJECT_ROOT is set: $PROJECT_ROOT"
    else
        test_fail "PROJECT_ROOT is not set"
        ((issues++))
    fi

    # Test PATH includes project scripts
    local script_dirs=("scripts" "scripts" "bin")
    local path_includes_scripts=false

    for dir in "${script_dirs[@]}"; do
        if [ -d "$dir" ] && [[ "$PATH" == *"$PWD/$dir"* ]]; then
            test_pass "Project scripts directory in PATH: $dir"
            path_includes_scripts=true
            break
        fi
    done

    if [ "$path_includes_scripts" = false ]; then
        test_warning "Project scripts directory not found in PATH"
    fi

    # Test .env file
    if [ -f ".env" ]; then
        test_pass ".env file exists"
        # Try to source .env and check for common variables
        if [ "$VERBOSE" = "true" ]; then
            test_info "Environment variables from .env:"
            grep -v '^#' .env 2>/dev/null | head -5 | while read -r line; do
                if [[ $line == *"="* ]]; then
                    var_name=$(echo "$line" | cut -d'=' -f1)
                    test_info "  $var_name"
                fi
            done
        fi
    else
        test_fail ".env file not found"
        ((issues++))
    fi

    return $issues
}

test_dependencies() {
    if [ "$TEST_DEPENDENCIES" != "true" ]; then
        return 0
    fi

    log_step "Testing dependencies..."

    local issues=0

    # Test Node.js dependencies
    if [ -f "package.json" ]; then
        if [ -d "node_modules" ]; then
            test_pass "Node.js dependencies installed"
            local dep_count
            dep_count=$(find node_modules -maxdepth 1 -type d | wc -l)
            test_info "Installed packages: $((dep_count - 1))"
        else
            test_fail "node_modules not found - run 'npm install'"
            ((issues++))
        fi
    fi

    # Test Python dependencies
    if [ -f "requirements.txt" ] && command -v python &> /dev/null; then
        if python -c "import sys; sys.exit(0)" 2>/dev/null; then
            test_pass "Python environment is working"
        else
            test_warning "Python environment may have issues"
        fi
    fi

    return $issues
}

test_shell_configuration() {
    log_step "Testing shell configuration..."

    local issues=0

    # Check shell type
    if [ -n "${BASH_VERSION:-}" ]; then
        test_pass "Running in Bash"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        test_pass "Running in Zsh"
    else
        test_info "Running in unknown shell: $SHELL"
    fi

    # Check for direnv hook in shell config
    local shell_config=""
    if [ -n "${BASH_VERSION:-}" ]; then
        shell_config="$HOME/.bashrc"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        shell_config="$HOME/.zshrc"
    fi

    if [ -n "$shell_config" ] && [ -f "$shell_config" ]; then
        if grep -q "direnv hook" "$shell_config" 2>/dev/null; then
            test_pass "direnv hook configured in $shell_config"
        else
            test_info "direnv hook not found in $shell_config"
            test_info "Add: eval \"\$(direnv hook bash)\" to $shell_config"
        fi
    fi

    return $issues
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🧪 Testing Development Environment Setup"
    echo "═══════════════════════════════════════════"
    echo ""

    # Load configuration
    load_configuration

    # Check Bash version
    check_bash_version

    # Run comprehensive tests
    local total_issues=0

    test_project_structure
    ((total_issues += $?))

    test_direnv_setup
    ((total_issues += $?))

    test_nix_setup
    ((total_issues += $?))

    test_environment_variables
    ((total_issues += $?))

    test_dependencies
    ((total_issues += $?))

    test_shell_configuration
    ((total_issues += $?))

    echo ""
    echo "🎯 Test Summary"
    echo "═══════════════"

    if [ $total_issues -eq 0 ]; then
        test_pass "All tests passed! Environment setup looks good!"
        echo ""
        test_info "Next steps:"
        echo "  1. Run 'direnv reload' to refresh the environment"
        echo "  2. Try 'cd .. && cd $(basename $(pwd))' to test automatic loading"
        echo "  3. Check that environment variables are loaded"
        if command -v nix &> /dev/null; then
            echo "  4. Try 'nix develop' for reproducible environment"
        fi
    else
        test_fail "Found $total_issues issues that need attention"
        echo ""
        test_info "Please fix the issues above and re-run this test"
    fi

    echo ""
    test_info "For help, see: docs/environment-setup.md"

    return $total_issues
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-direnv)
                TEST_DIRENV=false
                shift
                ;;
            --no-nix)
                TEST_NIX=false
                shift
                ;;
            --no-env)
                TEST_ENVIRONMENT=false
                shift
                ;;
            --no-structure)
                TEST_PROJECT_STRUCTURE=false
                shift
                ;;
            --no-deps)
                TEST_DEPENDENCIES=false
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Environment Test Script"
                echo ""
                echo "Options:"
                echo "  --no-direnv      Skip direnv tests"
                echo "  --no-nix         Skip Nix tests"
                echo "  --no-env         Skip environment variable tests"
                echo "  --no-structure   Skip project structure tests"
                echo "  --no-deps        Skip dependency tests"
                echo "  --verbose        Enable verbose output"
                echo "  --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0 --verbose"
                echo "  $0 --no-nix --no-direnv"
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

# Run main test
main