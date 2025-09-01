#!/bin/bash

# GitOps Deployment Script
# This script implements GitOps principles for automated deployments

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
DEFAULT_GITOPS_REPO="git@github.com:your-org/your-project-gitops.git"
DEFAULT_GITOPS_BRANCH="main"
DEFAULT_REPLICAS=2
DEFAULT_CONTAINER_PORT=3000
DEFAULT_SERVICE_PORT=80
DEFAULT_SERVICE_TYPE="ClusterIP"
DEFAULT_MEMORY_REQUEST="256Mi"
DEFAULT_CPU_REQUEST="100m"
DEFAULT_MEMORY_LIMIT="512Mi"
DEFAULT_CPU_LIMIT="200m"
DEFAULT_HEALTH_PATH="/health"
DEFAULT_LIVENESS_DELAY=30
DEFAULT_LIVENESS_PERIOD=10
DEFAULT_READINESS_DELAY=5
DEFAULT_READINESS_PERIOD=5
DEFAULT_INGRESS_CLASS="nginx"
DEFAULT_CERT_ISSUER="letsencrypt-prod"
DEFAULT_DEPLOYMENT_TIMEOUT=600
DEFAULT_HEALTH_CHECK_RETRIES=3

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

check_git_version() {
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed"
        return 1
    fi

    local version
    version=$(git --version | sed 's/git version //')
    local required="2.20.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_error "Git version $version is below required $required"
        return 1
    fi

    log_success "Git version: $version"
}

check_kubectl_version() {
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl not found - some features may not work"
        return 0
    fi

    local version
    version=$(kubectl version --client --short 2>/dev/null | sed 's/Client Version: v//')
    local required="1.20.0"

    if ! [ "$(printf '%s\n' "$required" "$version" | sort -V | head -n1)" = "$required" ]; then
        log_warning "kubectl version $version is below recommended $required"
    fi

    log_success "kubectl version: $version"
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

    # Load GitOps configuration
    local config_file="06_CONFIG/gitops.config"
    if [ -f "$config_file" ]; then
        log_info "Loading GitOps configuration..."
        source "$config_file"
        log_success "GitOps configuration loaded"
    else
        log_warning "GitOps config not found at $config_file. Using defaults..."
    fi

    # Set defaults for unset variables
    GITOPS_REPO=${GITOPS_REPO:-$DEFAULT_GITOPS_REPO}
    GITOPS_BRANCH=${GITOPS_BRANCH:-$DEFAULT_GITOPS_BRANCH}
    REPLICAS=${REPLICAS:-$DEFAULT_REPLICAS}
    CONTAINER_PORT=${CONTAINER_PORT:-$DEFAULT_CONTAINER_PORT}
    SERVICE_PORT=${SERVICE_PORT:-$DEFAULT_SERVICE_PORT}
    SERVICE_TYPE=${SERVICE_TYPE:-$DEFAULT_SERVICE_TYPE}
    MEMORY_REQUEST=${MEMORY_REQUEST:-$DEFAULT_MEMORY_REQUEST}
    CPU_REQUEST=${CPU_REQUEST:-$DEFAULT_CPU_REQUEST}
    MEMORY_LIMIT=${MEMORY_LIMIT:-$DEFAULT_MEMORY_LIMIT}
    CPU_LIMIT=${CPU_LIMIT:-$DEFAULT_CPU_LIMIT}
    HEALTH_PATH=${HEALTH_PATH:-$DEFAULT_HEALTH_PATH}
    LIVENESS_DELAY=${LIVENESS_DELAY:-$DEFAULT_LIVENESS_DELAY}
    LIVENESS_PERIOD=${LIVENESS_PERIOD:-$DEFAULT_LIVENESS_PERIOD}
    READINESS_DELAY=${READINESS_DELAY:-$DEFAULT_READINESS_DELAY}
    READINESS_PERIOD=${READINESS_PERIOD:-$DEFAULT_READINESS_PERIOD}
    INGRESS_CLASS=${INGRESS_CLASS:-$DEFAULT_INGRESS_CLASS}
    CERT_ISSUER=${CERT_ISSUER:-$DEFAULT_CERT_ISSUER}
    DEPLOYMENT_TIMEOUT=${DEPLOYMENT_TIMEOUT:-$DEFAULT_DEPLOYMENT_TIMEOUT}
    HEALTH_CHECK_RETRIES=${HEALTH_CHECK_RETRIES:-$DEFAULT_HEALTH_CHECK_RETRIES}
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_environment() {
    case $ENVIRONMENT in
        "staging"|"production"|"development")
            log_success "Valid environment: $ENVIRONMENT"
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            log_info "Valid environments: staging, production, development"
            return 1
            ;;
    esac
}

validate_prerequisites() {
    log_step "Validating prerequisites..."

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

    # Check Git repository
    if [ ! -d ".git" ]; then
        log_error "Not a Git repository. GitOps requires Git"
        return 1
    fi

    log_success "Prerequisites validated"
}

# =============================================================================
# GITOPS REPOSITORY FUNCTIONS
# =============================================================================

setup_gitops_repository() {
    log_step "Setting up GitOps repository..."

    if [ -d "$DEPLOYMENT_DIR/.git" ]; then
        log_info "Updating GitOps repository..."
        cd "$DEPLOYMENT_DIR"
        git pull origin "$GITOPS_BRANCH" || {
            log_error "Failed to update GitOps repository"
            cd -
            return 1
        }
        cd -
    else
        log_info "Cloning GitOps repository..."
        git clone -b "$GITOPS_BRANCH" "$GITOPS_REPO" "$DEPLOYMENT_DIR" || {
            log_error "Failed to clone GitOps repository"
            return 1
        }
    fi

    # Ensure manifests directory exists
    mkdir -p "$DEPLOYMENT_DIR/manifests"

    log_success "GitOps repository ready"
}

# =============================================================================
# MANIFEST GENERATION FUNCTIONS
# =============================================================================

generate_manifests() {
    log_step "Generating Kubernetes manifests..."

    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    DEPLOYMENT_NAME="deployment-$ENVIRONMENT-$TIMESTAMP"
    IMAGE_NAME=${IMAGE_NAME:-"myproject/app"}

    # Set environment-specific variables
    case $ENVIRONMENT in
        "production")
            DOMAIN=${DOMAIN:-"$ENVIRONMENT.yourdomain.com"}
            ;;
        "staging")
            DOMAIN=${DOMAIN:-"$ENVIRONMENT.yourdomain.com"}
            ;;
        "development")
            DOMAIN=${DOMAIN:-"$ENVIRONMENT.yourdomain.com"}
            ;;
    esac

    # Generate deployment manifest
    generate_deployment_manifest

    # Generate service manifest
    generate_service_manifest

    # Generate ingress manifest
    generate_ingress_manifest

    log_success "Manifests generated"
}

generate_deployment_manifest() {
    local manifest_file="$DEPLOYMENT_DIR/manifests/$DEPLOYMENT_NAME-deployment.yaml"

    sed -e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{DEPLOYMENT_NAME}}/$DEPLOYMENT_NAME/g" \
        -e "s/{{IMAGE_NAME}}/$IMAGE_NAME/g" \
        -e "s/{{REPLICAS}}/$REPLICAS/g" \
        -e "s/{{CONTAINER_PORT}}/$CONTAINER_PORT/g" \
        -e "s/{{MEMORY_REQUEST}}/$MEMORY_REQUEST/g" \
        -e "s/{{CPU_REQUEST}}/$CPU_REQUEST/g" \
        -e "s/{{MEMORY_LIMIT}}/$MEMORY_LIMIT/g" \
        -e "s/{{CPU_LIMIT}}/$CPU_LIMIT/g" \
        -e "s/{{HEALTH_PATH}}/$HEALTH_PATH/g" \
        -e "s/{{LIVENESS_DELAY}}/$LIVENESS_DELAY/g" \
        -e "s/{{LIVENESS_PERIOD}}/$LIVENESS_PERIOD/g" \
        -e "s/{{READINESS_DELAY}}/$READINESS_DELAY/g" \
        -e "s/{{READINESS_PERIOD}}/$READINESS_PERIOD/g" \
        "07_SCRIPT/manifests/deployment.yaml" > "$manifest_file"
}

generate_service_manifest() {
    local manifest_file="$DEPLOYMENT_DIR/manifests/$DEPLOYMENT_NAME-service.yaml"

    sed -e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{SERVICE_PORT}}/$SERVICE_PORT/g" \
        -e "s/{{CONTAINER_PORT}}/$CONTAINER_PORT/g" \
        -e "s/{{SERVICE_TYPE}}/$SERVICE_TYPE/g" \
        "07_SCRIPT/manifests/service.yaml" > "$manifest_file"
}

generate_ingress_manifest() {
    local manifest_file="$DEPLOYMENT_DIR/manifests/$DEPLOYMENT_NAME-ingress.yaml"

    sed -e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{DOMAIN}}/$DOMAIN/g" \
        -e "s/{{SERVICE_PORT}}/$SERVICE_PORT/g" \
        -e "s/{{INGRESS_CLASS}}/$INGRESS_CLASS/g" \
        -e "s/{{CERT_ISSUER}}/$CERT_ISSUER/g" \
        "07_SCRIPT/manifests/ingress.yaml" > "$manifest_file"
}

# =============================================================================
# DEPLOYMENT FUNCTIONS
# =============================================================================

copy_build_artifacts() {
    log_info "Copying build artifacts..."
    mkdir -p "$DEPLOYMENT_DIR/artifacts/$DEPLOYMENT_NAME"
    cp -r build/* "$DEPLOYMENT_DIR/artifacts/$DEPLOYMENT_NAME/" 2>/dev/null || true
    log_success "Build artifacts copied"
}

update_kustomization() {
    if [ -f "$DEPLOYMENT_DIR/kustomization.yaml" ]; then
        log_info "Updating Kustomization..."
        sed -i.bak "s|myproject/app:.*|myproject/app:$DEPLOYMENT_NAME|g" "$DEPLOYMENT_DIR/kustomization.yaml"
        log_success "Kustomization updated"
    fi
}

update_helm_values() {
    if [ -f "$DEPLOYMENT_DIR/values.yaml" ]; then
        log_info "Updating Helm values..."
        sed -i.bak "s|tag:.*|tag: \"$DEPLOYMENT_NAME\"|g" "$DEPLOYMENT_DIR/values.yaml"
        log_success "Helm values updated"
    fi
}

commit_and_push_changes() {
    log_step "Committing and pushing changes..."

    cd "$DEPLOYMENT_DIR"

    # Add all changes
    git add .

    # Create commit message
    local commit_message="Deploy $DEPLOYMENT_NAME to $ENVIRONMENT

- Deployment: $DEPLOYMENT_NAME
- Environment: $ENVIRONMENT
- Timestamp: $TIMESTAMP
- Replicas: $REPLICAS
- Image: $IMAGE_NAME:$DEPLOYMENT_NAME
- Build artifacts included"

    # Commit changes
    git commit -m "$commit_message" || {
        log_warning "No changes to commit"
        cd -
        return 0
    }

    # Push changes
    log_info "Pushing to GitOps repository..."
    git push origin "$GITOPS_BRANCH" || {
        log_error "Failed to push changes"
        cd -
        return 1
    }

    cd -
    log_success "Changes committed and pushed"
}

# =============================================================================
# HEALTH CHECK FUNCTIONS
# =============================================================================

wait_for_deployment() {
    log_step "Waiting for deployment to complete..."

    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl not available - skipping deployment verification"
        return 0
    fi

    local timeout=$DEPLOYMENT_TIMEOUT
    local start_time=$(date +%s)

    log_info "Monitoring deployment status (timeout: ${timeout}s)..."

    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        # Check if deployment exists
        if kubectl get deployment "myproject-app-$ENVIRONMENT" >/dev/null 2>&1; then
            # Check deployment status
            local ready_replicas
            ready_replicas=$(kubectl get deployment "myproject-app-$ENVIRONMENT" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

            if [ "$ready_replicas" = "$REPLICAS" ]; then
                log_success "Deployment completed successfully"
                return 0
            fi

            log_info "Waiting for deployment... ($ready_replicas/$REPLICAS ready)"
        else
            log_info "Waiting for deployment to be created..."
        fi

        sleep 10
    done

    log_error "Deployment timeout after ${timeout}s"
    return 1
}

run_post_deployment_tests() {
    log_step "Running post-deployment tests..."

    local test_url=""
    case $ENVIRONMENT in
        "production")
            test_url=${PROD_TEST_URL:-"https://$DOMAIN/health"}
            ;;
        "staging")
            test_url=${STAGING_TEST_URL:-"https://$DOMAIN/health"}
            ;;
        "development")
            test_url=${DEV_TEST_URL:-"http://$DOMAIN/health"}
            ;;
    esac

    if [ -n "$test_url" ]; then
        log_info "Testing endpoint: $test_url"

        for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
            log_info "Health check attempt $i/$HEALTH_CHECK_RETRIES"

            if curl -f -s --max-time 30 "$test_url" >/dev/null 2>&1; then
                log_success "Post-deployment health check passed"
                return 0
            fi

            if [ $i -lt $HEALTH_CHECK_RETRIES ]; then
                log_warning "Health check failed, retrying in 10 seconds..."
                sleep 10
            fi
        done

        log_error "Post-deployment health check failed"
        return 1
    else
        log_warning "No test URL configured for $ENVIRONMENT"
    fi
}

# =============================================================================
# CLEANUP FUNCTIONS
# =============================================================================

cleanup_old_deployments() {
    log_info "Cleaning up old deployments..."

    cd "$DEPLOYMENT_DIR"

    # Keep only last 10 deployment manifests
    ls -t manifests/*.yaml 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

    # Keep only last 5 artifact directories
    ls -t artifacts/ 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null || true

    cd -
    log_success "Old deployments cleaned up"
}

# =============================================================================
# NOTIFICATION FUNCTIONS
# =============================================================================

send_notification() {
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        log_info "Sending deployment notification..."

        local message="✅ Deployment $DEPLOYMENT_NAME completed successfully to $ENVIRONMENT"
        if [ -n "$DOMAIN" ]; then
            message="$message - https://$DOMAIN"
        fi

        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$SLACK_WEBHOOK" || log_warning "Failed to send notification"
    fi
}

# =============================================================================
# VERIFICATION FUNCTIONS
# =============================================================================

verify_deployment() {
    log_step "Verifying deployment..."

    local issues=0

    # Check if manifests were generated
    if [ ! -f "$DEPLOYMENT_DIR/manifests/$DEPLOYMENT_NAME-deployment.yaml" ]; then
        log_error "Deployment manifest not found"
        ((issues++))
    fi

    if [ ! -f "$DEPLOYMENT_DIR/manifests/$DEPLOYMENT_NAME-service.yaml" ]; then
        log_error "Service manifest not found"
        ((issues++))
    fi

    if [ ! -f "$DEPLOYMENT_DIR/manifests/$DEPLOYMENT_NAME-ingress.yaml" ]; then
        log_error "Ingress manifest not found"
        ((issues++))
    fi

    # Check Git status
    cd "$DEPLOYMENT_DIR"
    if [ -n "$(git status --porcelain)" ]; then
        log_warning "Git repository has uncommitted changes"
    fi
    cd -

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
    log_info "🚀 Starting GitOps deployment process..."
    echo "══════════════════════════════════════════════"

    # Parse arguments
    ENVIRONMENT=${1:-"staging"}
    DEPLOYMENT_DIR="04_DEPLOY/gitops"

    log_info "🎯 Deploying to: $ENVIRONMENT"
    log_info "📚 GitOps repository: $GITOPS_REPO"
    log_info "🌿 GitOps branch: $GITOPS_BRANCH"

    # Check if we're in the right directory
    if [ ! -f "README.MD" ]; then
        log_error "Please run this script from the project root directory"
        exit 1
    fi

    # Load configuration
    load_configuration

    # Validate environment and prerequisites
    validate_environment || exit 1
    validate_prerequisites || exit 1

    # Setup GitOps repository
    setup_gitops_repository || exit 1

    # Generate manifests
    generate_manifests

    # Copy build artifacts
    copy_build_artifacts

    # Update configuration files
    update_kustomization
    update_helm_values

    # Commit and push changes
    commit_and_push_changes || exit 1

    # Wait for deployment to complete
    wait_for_deployment

    # Run post-deployment tests
    run_post_deployment_tests

    # Verify deployment
    verify_deployment

    # Cleanup
    cleanup_old_deployments

    # Send notification
    send_notification

    echo ""
    log_success "✅ GitOps deployment to $ENVIRONMENT completed successfully!"
    echo ""
    echo "📋 Deployment details:"
    echo "  - Name: $DEPLOYMENT_NAME"
    echo "  - Environment: $ENVIRONMENT"
    echo "  - GitOps Repository: $GITOPS_REPO"
    echo "  - Branch: $GITOPS_BRANCH"
    echo "  - Domain: $DOMAIN"
    echo "  - Manifests: $DEPLOYMENT_DIR/manifests/"
    echo ""
    echo "Next steps:"
    echo "• Monitor deployment status in your GitOps dashboard"
    echo "• Check application logs and metrics"
    echo "• Update DNS/load balancer configurations if needed"
}

# Handle script arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            GITOPS_REPO="$2"
            shift 2
            ;;
        --branch)
            GITOPS_BRANCH="$2"
            shift 2
            ;;
        --replicas)
            REPLICAS="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [ENVIRONMENT] [OPTIONS]"
            echo ""
            echo "Environments:"
            echo "  staging     Deploy to staging environment (default)"
            echo "  production  Deploy to production environment"
            echo "  development Deploy to development environment"
            echo ""
            echo "Options:"
            echo "  --repo REPO       GitOps repository URL"
            echo "  --branch BRANCH   GitOps branch (default: main)"
            echo "  --replicas NUM    Number of replicas (default: 2)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            # Assume it's an environment
            ENVIRONMENT="$1"
            shift
            ;;
    esac
done

main "$@"