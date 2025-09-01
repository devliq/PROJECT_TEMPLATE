#!/bin/bash

# Build Script
# This script builds the project based on the configuration

set -euo pipefail  # Exit on any error, undefined variables, or pipe failures

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
DEFAULT_RUN_TESTS=true
DEFAULT_COMPRESS_BUILD=false
DEFAULT_BUILD_TYPE="auto"

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
    local required="18.0.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Node.js version $version is below required $required"
        return 1
    fi

    log_success "Node.js version: $version"
}

check_python_version() {
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        log_error "Python is required but not installed"
        return 1
    fi

    local python_cmd="python3"
    if ! command -v python3 &> /dev/null; then
        python_cmd="python"
    fi

    local version
    version=$($python_cmd --version 2>&1 | sed 's/Python //')
    local required="3.8.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Python version $version is below required $required"
        return 1
    fi

    log_success "Python version: $version"
}

check_java_version() {
    if ! command -v mvn &> /dev/null; then
        log_error "Maven is required but not installed"
        return 1
    fi

    local version
    version=$(mvn --version | head -1 | sed 's/.*Apache Maven \([0-9.]*\).*/\1/')
    local required="3.6.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Maven version $version is below required $required"
        return 1
    fi

    log_success "Maven version: $version"
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

    # Load build configuration
    local config_file="config/build.config"
    if [ -f "$config_file" ]; then
        log_info "Loading build configuration..."
        source "$config_file"
        log_success "Build configuration loaded"
    else
        log_warning "Build config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    RUN_TESTS=${RUN_TESTS:-$DEFAULT_RUN_TESTS}
    COMPRESS_BUILD=${COMPRESS_BUILD:-$DEFAULT_COMPRESS_BUILD}
    BUILD_TYPE=${BUILD_TYPE:-$DEFAULT_BUILD_TYPE}
}

# =============================================================================
# BUILD FUNCTIONS
# =============================================================================

detect_project_type() {
    if [ -f "package.json" ]; then
        echo "nodejs"
    elif [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        echo "python"
    elif [ -f "pom.xml" ]; then
        echo "java"
    elif [ -f "Makefile" ]; then
        echo "makefile"
    else
        echo "generic"
    fi
}

run_tests() {
    local project_type=$1

    if [ "$RUN_TESTS" != "true" ]; then
        log_info "Tests skipped (RUN_TESTS=false)"
        return 0
    fi

    log_info "Running tests..."

    case $project_type in
        "nodejs")
            if [ -f "package.json" ] && grep -q '"test"' package.json; then
                npm test
                log_success "Node.js tests completed"
            else
                log_warning "No test script found in package.json"
            fi
            ;;
        "python")
            if command -v pytest &> /dev/null; then
                python -m pytest tests/ -v || python -m unittest discover tests/ -v
            else
                python -m unittest discover tests/ -v
            fi
            log_success "Python tests completed"
            ;;
        "java")
            mvn test
            log_success "Java tests completed"
            ;;
        *)
            log_warning "No test runner configured for project type: $project_type"
            ;;
    esac
}

build_nodejs() {
    log_info "Building Node.js project..."

    check_node_version || return 1

    if [ -f "package.json" ]; then
        if grep -q '"build"' package.json; then
            npm run build
        else
            log_warning "No build script found in package.json"
        fi
    fi

    log_success "Node.js build completed"
}

build_python() {
    log_info "Building Python project..."

    check_python_version || return 1

    if [ -f "setup.py" ]; then
        python setup.py build
    elif [ -f "pyproject.toml" ]; then
        # Modern Python packaging
        if command -v build &> /dev/null; then
            python -m build
        else
            log_warning "python-build not available, install with: pip install build"
        fi
    else
        log_warning "No Python build configuration found"
    fi

    log_success "Python build completed"
}

build_java() {
    log_info "Building Java project..."

    check_java_version || return 1

    mvn clean package -DskipTests
    log_success "Java build completed"
}

build_makefile() {
    log_info "Running Makefile build..."
    make
    log_success "Makefile build completed"
}

build_generic() {
    log_info "Building generic project..."

    # Copy source files
    local src_dirs=("src" "lib" "app")
    for src_dir in "${src_dirs[@]}"; do
        if [ -d "$src_dir" ]; then
            log_info "Copying source files from $src_dir/"
            cp -r "$src_dir"/* build/ 2>/dev/null || true
            break
        fi
    done

    log_success "Generic build completed"
}

copy_assets() {
    local asset_dirs=("assets" "assets" "public" "static")
    for asset_dir in "${asset_dirs[@]}"; do
        if [ -d "$asset_dir" ]; then
            log_info "Copying assets from $asset_dir/"
            mkdir -p "build/assets"
            cp -r "$asset_dir"/* "build/assets/" 2>/dev/null || true
            log_success "Assets copied"
            return 0
        fi
    done
    log_info "No assets directory found"
}

generate_documentation() {
    if [ -d "docs" ] || [ -d "docs" ]; then
        log_info "Generating documentation..."

        # Check for common documentation tools
        if command -v mkdocs &> /dev/null && [ -f "mkdocs.yml" ]; then
            mkdocs build
        elif command -v sphinx-build &> /dev/null && [ -d "docs" ]; then
            sphinx-build docs build/docs
        else
            log_info "No documentation generator configured"
        fi

        log_success "Documentation generation completed"
    fi
}

create_build_artifact() {
    log_info "Creating build artifact..."

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    BUILD_NAME="project-build-${timestamp}"

    mkdir -p "build/$BUILD_NAME"
    cp -r build/* "build/$BUILD_NAME/" 2>/dev/null || true

    if [ "$COMPRESS_BUILD" = "true" ]; then
        log_info "Compressing build artifact..."
        cd build
        tar -czf "${BUILD_NAME}.tar.gz" "$BUILD_NAME"
        cd ..
        log_success "Build compressed: build/${BUILD_NAME}.tar.gz"
    fi

    log_success "Build artifact created: build/$BUILD_NAME/"
}

verify_build() {
    log_info "Verifying build..."

    if [ ! -d "build" ]; then
        log_error "Build directory not found"
        return 1
    fi

    local build_size
    build_size=$(du -sh build | cut -f1)
    log_info "Build size: $build_size"

    # Check for common build artifacts
    local artifacts_found=0
    if [ -f "build/index.js" ] || [ -f "build/main.js" ] || [ -f "build/app.js" ]; then
        ((artifacts_found++))
    fi
    if [ -f "build/main.py" ] || [ -f "build/__main__.py" ]; then
        ((artifacts_found++))
    fi
    if [ -f "build/target/*.jar" ] || [ -f "build/*.jar" ]; then
        ((artifacts_found++))
    fi

    if [ $artifacts_found -eq 0 ]; then
        log_warning "No common build artifacts found"
    else
        log_success "Build artifacts verified"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🔨 Starting build process..."
    echo "═══════════════════════════════════════"

    # Check if we're in the right directory
    if [ ! -f "README.MD" ]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi

    # Load configuration
    load_configuration

    # Clean previous build
    log_info "Cleaning previous build..."
    rm -rf build/*
    mkdir -p build

    # Detect project type
    PROJECT_TYPE=$(detect_project_type)
    log_info "Detected project type: $PROJECT_TYPE"

    # Run tests
    run_tests "$PROJECT_TYPE"

    # Build the project
    case $PROJECT_TYPE in
        "nodejs")
            build_nodejs
            ;;
        "python")
            build_python
            ;;
        "java")
            build_java
            ;;
        "makefile")
            build_makefile
            ;;
        *)
            build_generic
            ;;
    esac

    # Copy assets
    copy_assets

    # Generate documentation
    generate_documentation

    # Create build artifact
    create_build_artifact

    # Verify build
    verify_build

    echo ""
    log_success "✅ Build process completed successfully!"
    echo ""
    echo "📁 Build output: build/"
    if [ -d "build/$BUILD_NAME" ]; then
        echo "📦 Build artifact: build/$BUILD_NAME/"
    fi
    echo ""
    echo "Next steps:"
    echo "• Run deployment: ./scripts/deploy.sh [environment]"
    echo "• Run tests: ./scripts/test-env.sh"
}

# Run main function
main "$@"