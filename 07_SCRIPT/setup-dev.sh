#!/bin/bash

# Development Environment Setup Script
# This script sets up the complete development environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Check if we're in the right directory
if [ ! -f "README.MD" ]; then
    log_error "Please run this script from the project root directory"
    exit 1
fi

log_info "🚀 Starting development environment setup..."

# Check prerequisites
log_info "📋 Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | sed 's/v//')
REQUIRED_NODE_VERSION="18.0.0"
if ! [ "$(printf '%s\n' "$REQUIRED_NODE_VERSION" "$NODE_VERSION" | sort -V | head -n1)" = "$REQUIRED_NODE_VERSION" ]; then
    log_error "Node.js version $NODE_VERSION is not supported. Please upgrade to Node.js $REQUIRED_NODE_VERSION or higher."
    exit 1
fi

log_success "Prerequisites check passed!"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    log_info "📝 Creating .env file from template..."
    cp 06_CONFIG/.env.example .env
    log_success ".env file created. Please update the values as needed."
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
mkdir -p 03_BUILD
mkdir -p 05_ASSETS
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

# Display setup completion message
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

# Optional: Open browser
if command -v xdg-open &> /dev/null; then
    log_info "🌐 Opening application in browser..."
    sleep 2
    xdg-open http://localhost:3000 >/dev/null 2>&1 &
elif command -v open &> /dev/null; then
    log_info "🌐 Opening application in browser..."
    sleep 2
    open http://localhost:3000 >/dev/null 2>&1 &
fi

log_success "Setup complete! Happy coding! 🚀"