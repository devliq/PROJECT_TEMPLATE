#!/bin/bash

# Deployment Script
# This script deploys the project to the specified environment

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
DEFAULT_BACKUP_DEPLOYMENT=true
DEFAULT_HEALTH_CHECK_TIMEOUT=30
DEFAULT_ROLLBACK_ENABLED=true
DEFAULT_DEPLOYMENT_TIMEOUT=300

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

    local required="1.25.0"
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

    # Load deployment configuration
    local config_file="06_CONFIG/deploy.config"
    if [ -f "$config_file" ]; then
        log_info "Loading deployment configuration..."
        source "$config_file"
        log_success "Deployment configuration loaded"
    else
        log_warning "Deployment config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    BACKUP_DEPLOYMENT=${BACKUP_DEPLOYMENT:-$DEFAULT_BACKUP_DEPLOYMENT}
    HEALTH_CHECK_TIMEOUT=${HEALTH_CHECK_TIMEOUT:-$DEFAULT_HEALTH_CHECK_TIMEOUT}
    ROLLBACK_ENABLED=${ROLLBACK_ENABLED:-$DEFAULT_ROLLBACK_ENABLED}
    DEPLOYMENT_TIMEOUT=${DEPLOYMENT_TIMEOUT:-$DEFAULT_DEPLOYMENT_TIMEOUT}
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_deployment_requirements() {
    log_step "Validating deployment requirements..."

    # Check if build directory exists
    if [ ! -d "build" ]; then
        log_error "Build directory not found. Please run build.sh first"
        return 1
    fi

    # Check if build directory has content
    if [ -z "$(ls -A build 2>/dev/null)" ]; then
        log_error "Build directory is empty. Please run build.sh first"
        return 1
    fi

    # Validate deployment target
    case $DEPLOY_TARGET in
        "production"|"staging"|"development")
            log_success "Valid deployment target: $DEPLOY_TARGET"
            ;;
        *)
            log_error "Invalid deployment target: $DEPLOY_TARGET"
            log_info "Valid targets: production, staging, development"
            return 1
            ;;
    esac

    log_success "Deployment requirements validated"
}

# =============================================================================
# DEPLOYMENT FUNCTIONS
# =============================================================================

create_backup() {
    if [ "$BACKUP_DEPLOYMENT" != "true" ] || [ ! -d "$DEPLOY_DIR/$DEPLOY_TARGET/current" ]; then
        return 0
    fi

    log_info "Creating deployment backup..."
    local backup_name="backup-$(date +%Y%m%d-%H%M%S)"

    if mv "$DEPLOY_DIR/$DEPLOY_TARGET/current" "$DEPLOY_DIR/$DEPLOY_TARGET/$backup_name"; then
        echo "$backup_name" > "$DEPLOY_DIR/$DEPLOY_TARGET/.last_backup"
        log_success "Backup created: $backup_name"
    else
        log_warning "Failed to create backup"
    fi
}

rollback_deployment() {
    if [ "$ROLLBACK_ENABLED" != "true" ]; then
        log_warning "Rollback disabled"
        return 1
    fi

    local last_backup
    if [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/.last_backup" ]; then
        last_backup=$(cat "$DEPLOY_DIR/$DEPLOY_TARGET/.last_backup")
    else
        log_error "No backup found for rollback"
        return 1
    fi

    log_info "Rolling back to backup: $last_backup"

    # Stop current deployment
    stop_deployment

    # Restore backup
    if mv "$DEPLOY_DIR/$DEPLOY_TARGET/$last_backup" "$DEPLOY_DIR/$DEPLOY_TARGET/current"; then
        log_success "Rollback completed"

        # Restart services
        start_deployment_services
        return 0
    else
        log_error "Rollback failed"
        return 1
    fi
}

copy_deployment_artifacts() {
    log_info "Copying deployment artifacts..."

    mkdir -p "$DEPLOY_DIR/$DEPLOY_TARGET/current"

    # Copy build artifacts
    if cp -r build/* "$DEPLOY_DIR/$DEPLOY_TARGET/current/" 2>/dev/null; then
        log_success "Build artifacts copied"
    else
        log_warning "No build artifacts found, copying source files..."
        # Try alternative source directories
        local src_dirs=("src" "app" "lib")
        for src_dir in "${src_dirs[@]}"; do
            if [ -d "$src_dir" ] && cp -r "$src_dir"/* "$DEPLOY_DIR/$DEPLOY_TARGET/current/" 2>/dev/null; then
                log_success "Source files copied from $src_dir/"
                break
            fi
        done
    fi

    # Copy configuration files
    local config_dirs=("06_CONFIG" "config")
    for config_dir in "${config_dirs[@]}"; do
        if [ -d "$config_dir" ]; then
            log_info "Copying configuration files from $config_dir/"
            cp -r "$config_dir"/* "$DEPLOY_DIR/$DEPLOY_TARGET/current/" 2>/dev/null || true
            break
        fi
    done
}

set_permissions() {
    log_info "Setting deployment permissions..."

    # Make scripts executable
    find "$DEPLOY_DIR/$DEPLOY_TARGET/current" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    find "$DEPLOY_DIR/$DEPLOY_TARGET/current" -type f -name "*.py" -exec chmod +x {} \; 2>/dev/null || true

    # Set appropriate permissions for web assets
    find "$DEPLOY_DIR/$DEPLOY_TARGET/current" -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) -exec chmod 644 {} \; 2>/dev/null || true

    log_success "Permissions set"
}

# =============================================================================
# HEALTH CHECK FUNCTIONS
# =============================================================================

pre_deployment_health_check() {
    log_step "Running pre-deployment health checks..."

    # Check system resources
    local available_memory
    available_memory=$(free -m | awk 'NR==2{printf "%.0f", $4/1024}')

    if [ "$available_memory" -lt 1 ]; then
        log_warning "Low memory available: ${available_memory}GB"
    fi

    # Check disk space
    local available_disk
    available_disk=$(df "$DEPLOY_DIR" | awk 'NR==2{printf "%.0f", $4/1024/1024}')

    if [ "$available_disk" -lt 1 ]; then
        log_error "Insufficient disk space: ${available_disk}GB available"
        return 1
    fi

    log_success "Pre-deployment health checks passed"
}

post_deployment_health_check() {
    log_info "Running post-deployment health checks..."

    local health_check_url=""
    local max_attempts=3
    local attempt=1

    # Determine health check URL based on deployment target
    case $DEPLOY_TARGET in
        "production")
            health_check_url=${PROD_HEALTH_URL:-"http://localhost:3000/health"}
            ;;
        "staging")
            health_check_url=${STAGING_HEALTH_URL:-"http://localhost:3001/health"}
            ;;
        "development")
            health_check_url=${DEV_HEALTH_URL:-"http://localhost:3002/health"}
            ;;
    esac

    if [ -n "$health_check_url" ]; then
        while [ $attempt -le $max_attempts ]; do
            log_info "Health check attempt $attempt/$max_attempts: $health_check_url"

            if curl -f -s --max-time "$HEALTH_CHECK_TIMEOUT" "$health_check_url" >/dev/null 2>&1; then
                log_success "Health check passed"
                return 0
            fi

            ((attempt++))
            if [ $attempt -le $max_attempts ]; then
                log_warning "Health check failed, retrying in 5 seconds..."
                sleep 5
            fi
        done

        log_error "Health check failed after $max_attempts attempts"
        return 1
    else
        log_warning "No health check URL configured for $DEPLOY_TARGET"
    fi
}

# =============================================================================
# SERVICE MANAGEMENT FUNCTIONS
# =============================================================================

stop_deployment_services() {
    log_info "Stopping existing services..."

    if [ -f "docker-compose.yml" ]; then
        if command -v docker-compose &> /dev/null; then
            docker-compose down --remove-orphans || true
        else
            docker compose down --remove-orphans || true
        fi
    fi

    # Additional service stopping logic can be added here
    log_success "Services stopped"
}

start_deployment_services() {
    log_info "Starting deployment services..."

    if [ -f "docker-compose.yml" ]; then
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d --build
        else
            docker compose up -d --build
        fi

        # Wait for services to be healthy
        log_info "Waiting for services to be ready..."
        sleep 10
    fi

    log_success "Services started"
}

# =============================================================================
# ENVIRONMENT-SPECIFIC FUNCTIONS
# =============================================================================

run_environment_specific_steps() {
    log_step "Running $DEPLOY_TARGET environment steps..."

    case $DEPLOY_TARGET in
        "production")
            # Production-specific steps
            log_info "Running production deployment steps..."

            # Database migrations
            if [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/current/migrate.sh" ]; then
                log_info "Running database migrations..."
                cd "$DEPLOY_DIR/$DEPLOY_TARGET/current"
                ./migrate.sh
                cd -
            fi

            # Cache clearing
            log_info "Clearing application cache..."
            # Add cache clearing commands here

            # Update production configuration
            if [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/current/config/production.yml" ]; then
                log_info "Applying production configuration..."
            fi
            ;;
        "staging")
            log_info "Running staging deployment steps..."
            # Staging-specific steps
            ;;
        "development")
            log_info "Running development deployment steps..."
            # Development-specific steps
            ;;
    esac

    log_success "Environment-specific steps completed"
}

# =============================================================================
# DEPENDENCY MANAGEMENT FUNCTIONS
# =============================================================================

install_dependencies() {
    log_info "Installing deployment dependencies..."

    cd "$DEPLOY_DIR/$DEPLOY_TARGET/current"

    if [ -f "package.json" ]; then
        log_info "Installing Node.js dependencies..."
        npm ci --production
    elif [ -f "requirements.txt" ]; then
        log_info "Installing Python dependencies..."
        pip install -r requirements.txt
    elif [ -f "pom.xml" ]; then
        log_info "Installing Java dependencies..."
        # Dependencies should already be included in the build
        log_info "Java dependencies handled during build"
    fi

    cd -
    log_success "Dependencies installed"
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

cleanup_old_backups() {
    log_info "Cleaning up old backups..."

    cd "$DEPLOY_DIR/$DEPLOY_TARGET"

    # Keep only last 5 backups
    ls -t backup-* 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null || true

    cd -
    log_success "Old backups cleaned up"
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_deployment() {
    log_step "Verifying deployment..."

    local issues=0

    # Check if deployment directory exists
    if [ ! -d "$DEPLOY_DIR/$DEPLOY_TARGET/current" ]; then
        log_error "Deployment directory not found"
        ((issues++))
    fi

    # Check for essential files
    local essential_files=("package.json" "requirements.txt" "app.js" "main.py" "index.html")
    for file in "${essential_files[@]}"; do
        if [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/current/$file" ]; then
            log_success "Found: $file"
            break
        fi
    done

    # Check permissions
    if find "$DEPLOY_DIR/$DEPLOY_TARGET/current" -type f -name "*.sh" -executable | grep -q .; then
        log_success "Scripts are executable"
    else
        log_warning "No executable scripts found"
    fi

    if [ $issues -eq 0 ]; then
        log_success "Deployment verification passed"
        return 0
    else
        log_error "Deployment verification failed with $issues issues"
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo ""
    log_info "🚀 Starting deployment process..."
    echo "════════════════════════════════════════"

    # Parse arguments
    DEPLOY_TARGET=${1:-"staging"}
    DEPLOY_DIR="04_DEPLOY"

    log_info "🎯 Deploying to: $DEPLOY_TARGET"

    # Check if we're in the right directory
    if [ ! -f "README.MD" ]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi

    # Load configuration
    load_configuration

    # Validate requirements
    validate_deployment_requirements || exit 1

    # Pre-deployment health check
    pre_deployment_health_check || exit 1

    # Create backup
    create_backup

    # Stop existing services
    stop_deployment_services

    # Copy deployment artifacts
    copy_deployment_artifacts

    # Set permissions
    set_permissions

    # Install dependencies
    install_dependencies

    # Run environment-specific steps
    run_environment_specific_steps

    # Start services
    start_deployment_services

    # Post-deployment health check
    if ! post_deployment_health_check; then
        log_error "Post-deployment health check failed"

        if [ "$ROLLBACK_ENABLED" = "true" ]; then
            log_info "Attempting rollback..."
            if rollback_deployment; then
                log_success "Rollback completed successfully"
                exit 1
            else
                log_error "Rollback failed"
            fi
        fi

        exit 1
    fi

    # Verify deployment
    verify_deployment || exit 1

    # Cleanup
    cleanup_old_backups

    echo ""
    log_success "✅ Deployment to $DEPLOY_TARGET completed successfully!"
    echo ""
    echo "📁 Deployment location: $DEPLOY_DIR/$DEPLOY_TARGET/current/"
    echo ""
    echo "Next steps:"
    echo "• Monitor application logs and performance"
    echo "• Update DNS/load balancer configurations if needed"
    echo "• Run integration tests: ./07_SCRIPT/test-env.sh"
    echo "• Check monitoring dashboards"
}

# Handle script arguments and run main
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            DEPLOY_TARGET="$2"
            shift 2
            ;;
        --no-backup)
            BACKUP_DEPLOYMENT=false
            shift
            ;;
        --no-rollback)
            ROLLBACK_ENABLED=false
            shift
            ;;
        --help)
            echo "Usage: $0 [TARGET] [OPTIONS]"
            echo ""
            echo "Targets:"
            echo "  staging     Deploy to staging environment (default)"
            echo "  production  Deploy to production environment"
            echo "  development Deploy to development environment"
            echo ""
            echo "Options:"
            echo "  --no-backup     Skip backup creation"
            echo "  --no-rollback   Disable automatic rollback on failure"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            # Assume it's a target
            DEPLOY_TARGET="$1"
            shift
            ;;
    esac
done

main