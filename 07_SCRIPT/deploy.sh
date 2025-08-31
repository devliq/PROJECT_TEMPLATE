#!/bin/bash

# Deployment Script
# This script deploys the project to the specified environment

set -e  # Exit on any error

echo "🚀 Starting deployment process..."

# Check if we're in the right directory
if [ ! -f "README.MD" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Default deployment target
DEPLOY_TARGET=${1:-"staging"}
DEPLOY_DIR="deploy"

echo "🎯 Deploying to: $DEPLOY_TARGET"

# Load environment variables
if [ -f ".env" ]; then
    echo "📋 Loading environment configuration..."
    export $(grep -v '^#' .env | xargs)
fi

# Validate deployment requirements
echo "🔍 Validating deployment requirements..."

if [ ! -d "build" ]; then
    echo "❌ Error: Build directory not found. Please run build.sh first"
    exit 1
fi

# Create deployment directory
mkdir -p "$DEPLOY_DIR/$DEPLOY_TARGET"

# Backup current deployment if it exists
if [ -d "$DEPLOY_DIR/$DEPLOY_TARGET/current" ] && [ "$BACKUP_DEPLOYMENT" = "true" ]; then
    echo "💾 Creating backup..."
    BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
    mv "$DEPLOY_DIR/$DEPLOY_TARGET/current" "$DEPLOY_DIR/$DEPLOY_TARGET/$BACKUP_NAME"
fi

# Copy build artifacts to deployment directory
echo "📤 Copying build artifacts..."
cp -r build/* "$DEPLOY_DIR/$DEPLOY_TARGET/current/" 2>/dev/null || {
    echo "⚠️  No build artifacts found, copying source files..."
    cp -r src/* "$DEPLOY_DIR/$DEPLOY_TARGET/current/" 2>/dev/null || echo "❌ No source files found"
}

# Copy configuration files
if [ -d "config" ]; then
    echo "⚙️  Copying configuration files..."
    cp -r config/* "$DEPLOY_DIR/$DEPLOY_TARGET/current/" 2>/dev/null || true
fi

# Set permissions
echo "🔒 Setting permissions..."
find "$DEPLOY_DIR/$DEPLOY_TARGET/current" -type f -name "*.sh" -exec chmod +x {} \;
find "$DEPLOY_DIR/$DEPLOY_TARGET/current" -type f -name "*.py" -exec chmod +x {} \; 2>/dev/null || true

# Environment-specific deployment steps
case $DEPLOY_TARGET in
    "production")
        echo "🏭 Production deployment steps..."
        # Add production-specific steps here
        # e.g., database migrations, cache clearing, etc.
        ;;
    "staging")
        echo "🧪 Staging deployment steps..."
        # Add staging-specific steps here
        ;;
    "development")
        echo "💻 Development deployment steps..."
        # Add development-specific steps here
        ;;
    *)
        echo "⚠️  Unknown deployment target: $DEPLOY_TARGET"
        ;;
esac

# Post-deployment tasks
echo "🔧 Running post-deployment tasks..."

# Install dependencies in deployment environment
if [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/current/package.json" ]; then
    cd "$DEPLOY_DIR/$DEPLOY_TARGET/current"
    npm ci --production
    cd -
elif [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/current/requirements.txt" ]; then
    cd "$DEPLOY_DIR/$DEPLOY_TARGET/current"
    pip install -r requirements.txt
    cd -
fi

# Run database migrations if applicable
if [ -f "$DEPLOY_DIR/$DEPLOY_TARGET/current/migrate.sh" ]; then
    echo "🗃️  Running database migrations..."
    cd "$DEPLOY_DIR/$DEPLOY_TARGET/current"
    ./migrate.sh
    cd -
fi

# Health check
echo "🏥 Running health check..."
# Add health check commands here
# e.g., curl http://localhost:3000/health

# Clean up old backups (keep last 5)
echo "🧹 Cleaning up old backups..."
cd "$DEPLOY_DIR/$DEPLOY_TARGET"
ls -t backup-* 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null || true
cd -

echo "✅ Deployment to $DEPLOY_TARGET complete!"
echo "📁 Deployment location: $DEPLOY_DIR/$DEPLOY_TARGET/current/"
echo ""
echo "Next steps:"
echo "1. Verify the deployment is working correctly"
echo "2. Update any necessary DNS or load balancer configurations"
echo "3. Monitor application logs and performance"