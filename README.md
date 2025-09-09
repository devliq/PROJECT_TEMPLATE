# Project Template

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/devliq/PROJECT_TEMPLATE/workflows/CI/badge.svg)](https://github.com/devliq/PROJECT_TEMPLATE/actions)
[![Version](https://img.shields.io/github/v/release/devliq/PROJECT_TEMPLATE)](https://github.com/devliq/PROJECT_TEMPLATE/releases)

This is a comprehensive template for new projects following the Windows 8.3 compatible directory structure. It provides a standardized organization for various types of software projects, ensuring consistency and ease of navigation.

## Table of Contents

- [Quick Start](#quick-start-guide)
- [Available Scripts](#available-scripts)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Environment Reproducibility](#environment-reproducibility)
- [Getting Started](#getting-started)
- [SSH Key Authentication and Git Setup](#ssh-key-authentication-and-git-setup)
- [Usage](#usage)
- [Development Workflow](#development-workflow)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Performance](#performance)
- [Contributing](#contributing)
- [License](#license)

## Directory Structure

- `docs/` - Documentation, README files, API references, and project specifications
- `src/` - Main source code files, organized by modules or components (includes example index.js and main.py)
- `tests/` - Unit tests, integration tests, test data, and testing utilities
- `build/` - Build outputs, compiled binaries, and generated artifacts
- `deploy/` - Deployment configurations, Docker files, and environment-specific settings
- `assets/` - Static assets like images, fonts, stylesheets, and media files
- `config/` - Configuration files for databases, APIs, logging, and application settings (includes .env)
- `scripts/` - Build scripts, automation scripts, and utility scripts
- `vendor/` - Third-party dependencies, libraries, and external tools
- `temp/` - Temporary files, cache, and files that should not be version controlled
- `package.json` - Node.js project configuration and dependencies

## Prerequisites

Before using this template, ensure you have:

- Git installed for version control
- Your preferred development environment (VS Code, IntelliJ, etc.)
- Basic knowledge of your project's technology stack
- Access to necessary development tools and dependencies

## Environment Reproducibility

This template supports reproducible development environments using **direnv** and **Nix**. These tools ensure consistent development environments across different machines and team members.

### Direnv Setup

Direnv automatically loads environment variables when you enter the project directory.

1. **Install direnv**:

```bash
# On macOS with Homebrew
brew install direnv

# On Ubuntu/Debian
sudo apt install direnv

# On NixOS or with Nix
nix-env -iA nixpkgs.direnv

# Manual installation
curl -sfL https://direnv.net/install.sh | bash
```

1. **Configure your shell**:

```bash
# Add to ~/.bashrc or ~/.zshrc
eval "$(direnv hook bash)"

# Or for zsh
eval "$(direnv hook zsh)"

# Or for fish
direnv hook fish | source
```

2. **Allow the environment**:

```bash
cd your-project-directory
direnv allow
```

### Nix Setup

Nix provides reproducible development environments with exact package versions.

1. **Install Nix**:

```bash
# Multi-user installation (recommended)
curl -L https://nixos.org/nix/install | sh

# Or single-user
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
```

1. **Enable experimental features** (for flakes):

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Using Reproducible Environments

#### Option 1: Traditional Nix Shell

```bash
# Enter the reproducible environment
nix-shell

# Or with specific shell
nix-shell --command "zsh"
```

#### Option 2: Nix Flakes (Modern)

```bash
# Enter development environment
nix develop

# Update dependencies
nix flake update

# Build the project
nix build

# Run commands
nix run
```

#### Option 3: Direnv + Nix Integration

```bash
# Install nix-direnv for better integration
nix-env -iA nixpkgs.nix-direnv

# The .envrc file will automatically use Nix when available
cd your-project-directory
direnv allow
```

### Environment Files

- **`.envrc`** - Direnv configuration for automatic environment loading
- **`shell.nix`** - Traditional Nix shell configuration
- **`flake.nix`** - Modern Nix flakes configuration
- **`.env`** - Environment variables (created from `.env.example`)
- **`.python-version`** - Python version specification (3.13.0)
- **`.nvmrc`** - Node.js LTS version specification
- **`scripts/setup-venv.sh`** - Automated virtual environment setup script

### Automatic Virtual Environment Setup

This template includes automatic Python virtual environment setup that works seamlessly with direnv:

#### How It Works

1. **Automatic Creation**: When you enter the project directory, direnv automatically creates a virtual environment if one doesn't exist
2. **Dynamic Naming**: The virtual environment is named based on your project directory
3. **Version Management**: Uses `.python-version` (3.13.0) and `.nvmrc` (LTS) for consistent tool versions
4. **Dependency Installation**: Automatically installs requirements from `requirements.txt` or `pyproject.toml`

#### Manual Setup (Alternative)

If you prefer manual control, you can use the setup script:

```bash
# Run the automated setup script
./scripts/setup-venv.sh

# Or manually create and activate
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### VSCode Integration

When opening the project in VSCode:

1. Direnv automatically loads the environment
2. Virtual environment is created if needed
3. Python and Node.js versions are set automatically
4. All dependencies are available in the integrated terminal

#### Terminal Integration

When using the terminal:

1. `cd` into the project directory
2. Run `direnv allow` (first time only)
3. Environment loads automatically on every `cd`

### Benefits

- **Consistency**: Same environment on all machines
- **Isolation**: No conflicts with system packages
- **Reproducibility**: Exact package versions and configurations
- **Portability**: Works on Linux, macOS, and Windows (WSL)
- **Caching**: Fast environment setup after initial download

### Troubleshooting

- **Direnv not loading**: Run `direnv allow` in the project directory
- **Nix slow**: Enable binary caches and use `nix-shell --pure`
- **Permission issues**: Ensure proper Nix installation and user permissions
- **Flakes not working**: Check experimental features are enabled

### Python Version Management

This template includes automated Python version management with optional auto-updates:

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

#### Optional Auto-Updates

Enable automatic Python version updates by setting an environment variable:

```bash
# Enable auto-updates in your shell profile or .env file
export PYTHON_AUTO_UPDATE=true

# Or add to .env file
echo "PYTHON_AUTO_UPDATE=true" >> .env
```

**Features:**

- **Automatic Detection**: Checks for newer stable versions on environment load
- **Non-Intrusive**: Only updates when a newer version is available
- **Safe**: Uses pyenv for version management and installation
- **Optional**: Disabled by default, must be explicitly enabled
- **Efficient**: Only runs update check when environment loads (not on every command)

**How it works:**

1. When `PYTHON_AUTO_UPDATE=true` is set, direnv checks for newer Python versions
2. Compares current `.python-version` with latest available stable version
3. If newer version exists, automatically updates and installs it
4. Virtual environment is recreated with the new Python version

**Note:** Auto-updates only occur when entering the project directory with direnv. Set `PYTHON_AUTO_UPDATE=false` or remove the variable to disable.

For detailed documentation, see the [Environment Setup Guide](docs/environment-setup.md).

## Getting Started

1. **Clone or Copy the Template**

```bash
git clone https://github.com/devliq/PROJECT_TEMPLATE.git
# or copy the template directory to your desired location
```

2. **Rename the Project**

```bash
mv project-template your-project-name
cd your-project-name
```

3. **Initialize Git Repository**

```bash
git init
git add .
git commit -m "Initial commit with project template"
```

4. **Set Up Your Source Code**

- Place your main source files in `src/`
- Organize code into subdirectories as needed (e.g., `src/main/`, `src/utils/`)

5. **Configure Your Project**

- Add configuration files to `config/`
- Set up build scripts in `scripts/`
- Add documentation to `docs/`

6. **Install Dependencies**

- Place third-party libraries in `vendor/` or use package managers
- Update dependency management files as needed

## SSH Key Authentication and Git Setup

This section addresses common authentication issues with GitHub and provides step-by-step instructions for setting up SSH key authentication.

### Setting up SSH Keys

1. **Generate a new SSH key pair**:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

2. **Add the SSH key to the SSH agent**:

```bash
# Start the SSH agent
eval "$(ssh-agent -s)"

# Add your SSH private key
ssh-add ~/.ssh/id_ed25519
```

3. **Add the public key to your GitHub account**:

- Copy the public key: `cat ~/.ssh/id_ed25519.pub`
- Go to GitHub → Settings → SSH and GPG keys → New SSH key
- Paste the public key and save

### Troubleshooting "Permission denied (publickey)" Errors

Common causes and solutions:

1. **SSH key not added to agent**:

```bash
# Check if SSH agent is running
ssh-add -l

# If no keys listed, add your key
ssh-add ~/.ssh/id_ed25519
```

2. **Wrong SSH key or key not recognized**:

```bash
# Verify the key is correct
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Test connection to GitHub
ssh -T git@github.com
```

3. **Repository URL using HTTPS instead of SSH**:

```bash
# Check current remote URL
git remote -v

# Change to SSH URL
git remote set-url origin git@github.com:username/repo.git
```

4. **SSH agent not running**:

```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519
```

### Checking SSH Agent Status with 'ssh-add -l'

```bash
# List all identities in SSH agent
ssh-add -l

# Expected output (shows loaded keys):
# 256 SHA256:... user@hostname (ED25519)

# If no keys are listed:
ssh-add ~/.ssh/id_ed25519
```

### Verifying SSH Keys in ~/.ssh/

```bash
# List SSH directory contents
ls -la ~/.ssh/

# Check public key fingerprint
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Verify private key format
head -n 5 ~/.ssh/id_ed25519

# Check file permissions (should be 600 for private key)
ls -l ~/.ssh/id_ed25519
```

### Testing Connection with 'ssh -T git@github.com'

```bash
# Test SSH connection to GitHub
ssh -T git@github.com

# Expected successful output:
# Hi username! You've successfully authenticated, but GitHub does not provide shell access.

# If connection fails, common issues:
# - SSH key not added to GitHub
# - SSH agent not running
# - Firewall blocking SSH
# - Wrong SSH key format
```

### Confirming Remote URLs with 'git remote -v'

```bash
# Check current remote repository URLs
git remote -v

# Expected output for SSH:
# origin  git@github.com:username/repo.git (fetch)
# origin  git@github.com:username/repo.git (push)

# To change from HTTPS to SSH:
git remote set-url origin git@github.com:username/repo.git

# To change from SSH to HTTPS:
git remote set-url origin https://github.com/username/repo.git
```

### Additional Tips

- **Multiple SSH keys**: Use `~/.ssh/config` to manage multiple keys
- **Key passphrase**: Consider using a passphrase for added security
- **Backup keys**: Always backup your SSH keys securely
- **Regular rotation**: Rotate SSH keys periodically for security

## Usage

### Development Workflow

1. **Daily Development**

- Work on source code in `src/`
- Write tests in `tests/`
- Use `temp/` for temporary files during development

2. **Building**

- Run build scripts from `scripts/`
- Output builds to `build/`

3. **Deployment**

- Use configurations from `deploy/`
- Reference assets from `assets/`

### File Naming Conventions

- Keep filenames concise, ideally under 8 characters with 3-character extensions
- Use descriptive names that clearly indicate file purpose
- Follow language-specific naming conventions

## Best Practices

### Organization

- Maintain the numbered directory structure for consistency
- Group related files together logically
- Use clear, descriptive names for files and directories

### Version Control & GitOps

- Commit regularly with meaningful commit messages
- Use `.gitignore` to exclude unnecessary files
- Store temporary and generated files in `temp/`
- Implement GitOps workflows for infrastructure and deployments
- Use GitHub Actions for CI/CD automation

### Configuration Management

- Keep environment-specific settings in `config/`
- Use environment variables for sensitive information
- Document configuration options in `docs/`
- Implement Infrastructure as Code with Terraform

### Documentation

- Maintain up-to-date README files
- Document APIs and interfaces
- Include setup and usage instructions
- Document deployment and operational procedures

### Testing & Quality Assurance

- Write comprehensive tests in `tests/`
- Include test data and fixtures
- Run tests regularly during development
- Implement automated testing in CI/CD pipeline
- Use ESLint and Prettier for code quality
- Perform security scanning and vulnerability checks

### Security

- Never commit sensitive information (passwords, API keys)
- Use environment variables for secrets
- Regularly audit dependencies in `vendor/`
- Implement security headers and CORS policies
- Use container security best practices
- Perform regular security scans and audits

### DevOps & Automation

- Use Docker for containerization
- Implement monitoring with Prometheus and Grafana
- Set up logging aggregation with Loki
- Use Infrastructure as Code for cloud resources
- Automate deployments with GitOps principles
- Implement health checks and auto-scaling

### Containerization & Deployment

- Use multi-stage Docker builds for optimization
- Implement proper health checks and graceful shutdown
- Use docker-compose for local development
- Implement blue-green or canary deployments
- Set up proper resource limits and requests

## Examples

### Python Project Setup

```text
src/
├── main.py
├── utils.py
└── models/
 └── user.py

tests/
├── test_main.py
└── test_utils.py

config/
├── config.py
└── requirements.txt

scripts/
├── setup.py
└── build.sh
```

### Web Application Setup

```text
src/
├── index.html
├── styles.css
└── script.js

assets/
├── images/
└── fonts/

config/
├── config.json
└── .env

scripts/
├── build.js
└── deploy.sh
```

## DevOps & Automation Features

This template includes comprehensive DevOps and automation features:

### CI/CD Pipeline

- **GitHub Actions**: Automated CI/CD pipeline with quality checks, testing, building, and deployment
- **Multi-stage pipeline**: Quality → Test → Build → Docker → Deploy
- **Security scanning**: Automated vulnerability scanning with Trivy
- **Performance testing**: Integrated performance test execution

### Containerization

- **Docker**: Multi-stage Dockerfile for optimized builds
- **Docker Compose**: Complete development environment with monitoring stack
- **Security**: Non-root containers, proper health checks, resource limits

### Infrastructure as Code

- **Terraform**: AWS infrastructure provisioning (VPC, ECS, RDS, ElastiCache)
- **Modular design**: Reusable Terraform modules for different environments
- **State management**: Remote state storage with locking

### Monitoring & Observability

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation and analysis
- **Promtail**: Log shipping from applications

### GitOps Workflows

- **Automated deployments**: GitOps-based deployment scripts
- **Kubernetes manifests**: Ready-to-use deployment configurations
- **Environment management**: Staging and production deployment workflows

### Security Features

- **Security headers**: Comprehensive HTTP security headers configuration
- **CORS policies**: Configurable cross-origin resource sharing
- **Rate limiting**: Protection against abuse and DoS attacks
- **Input validation**: XSS and SQL injection prevention
- **Audit logging**: Comprehensive security event logging

### Code Quality

- **ESLint**: JavaScript/TypeScript linting with security rules
- **Prettier**: Automated code formatting
- **Security scanning**: Dependency vulnerability checks
- **Git hooks**: Pre-commit quality checks

## Quick Start with DevOps

1. **Set up CI/CD**:

```bash
# The GitHub Actions workflow will automatically run on push/PR
# Configure secrets in GitHub repository settings
```

2. **Local Development**:

```bash
# Start full development environment
docker-compose up -d

# Access services:
# - App: http://localhost:3000
# - Grafana: http://localhost:3001
# - Prometheus: http://localhost:9090
```

3. **Deploy Infrastructure**:

```bash
cd deploy/terraform
terraform init
terraform plan
terraform apply
```

4. **GitOps Deployment**:

```bash
# Deploy to staging
./scripts/gitops-deploy.sh staging

# Deploy to production
./scripts/gitops-deploy.sh production
```

## GitHub Repository Setup

Before using the CI/CD workflows, configure the following secrets in your GitHub repository settings:

### Required Secrets for CI/CD

#### Staging Environment

- **`STAGING_DATABASE_URL`**: Database connection string for staging
- **`STAGING_HOST`**: SSH host for staging server
- **`STAGING_USER`**: SSH username for staging server
- **`STAGING_SSH_KEY`**: Private SSH key for staging server access
- **`STAGING_PORT`**: SSH port for staging server (default: 22)
- **`STAGING_URL`**: Public URL for staging environment

#### Trivy Security Scanning

- Trivy is used for comprehensive vulnerability scanning of dependencies and container images
- No API token is required - Trivy works out of the box
- Scans Node.js (package.json, package-lock.json) and Python (requirements.txt, pyproject.toml) dependencies
- Results are uploaded to GitHub Code Scanning for integration with security alerts

#### Production Environment

- **`PRODUCTION_HOST`**: SSH host for production server
- **`PRODUCTION_USER`**: SSH username for production server
- **`PRODUCTION_SSH_KEY`**: Private SSH key for production server access
- **`PRODUCTION_PORT`**: SSH port for production server (default: 22)
- **`PRODUCTION_URL`**: Public URL for production environment

#### Notifications

- **`SLACK_WEBHOOK`**: Slack webhook URL for deployment notifications

### Setting Up Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with its corresponding value

## Quick Start Guide

Get up and running in minutes:

```bash
# 1. Clone and setup
git clone https://github.com/devliq/PROJECT_TEMPLATE.git
cd PROJECT_TEMPLATE
npm install

# 2. Configure environment
cp config/.env.example config/.env
# Edit .env with your settings

# 3. Run the examples
npm start # Run JavaScript version
npm run start:ts# Run TypeScript version
python src/main.py  # Run Python version

# 4. Development with hot reload
npm run dev  # JavaScript development
npm run dev:ts  # TypeScript development
```

## Available Scripts

This template includes comprehensive scripts for development, testing, deployment, and environment management:

### Python Version Management

```bash
./scripts/update-python-version.sh          # Update to latest stable Python version
./scripts/update-python-version.sh --minor 3.12  # Update to latest patch for Python 3.12
./scripts/update-python-version.sh --version 3.13.7  # Set specific Python version
```

### Environment Setup

```bash
./scripts/setup-venv.sh                    # Set up Python virtual environment
./scripts/setup-dev.sh                     # Set up development environment
./scripts/setup-ultimate.sh                # Complete development setup
```

### Build and Deployment

```bash
./scripts/build.sh                         # Build the project
./scripts/deploy.sh                        # Deploy the application
./scripts/gitops-deploy.sh                 # GitOps-based deployment
```

This template includes comprehensive npm scripts for development, testing, and deployment:

### Development

```bash
npm start  # Run JavaScript application
npm run start:ts # Run TypeScript application
npm run dev# Development with nodemon (JS)
npm run dev:ts# Development with nodemon (TS)
```

### Code Quality

```bash
npm run lint  # Lint all JS/TS files
npm run lint:fix # Auto-fix linting issues
npm run lint:js  # Lint only JavaScript files
npm run lint:ts  # Lint only TypeScript files
npm run format# Format code with Prettier
npm run format:check# Check code formatting
npm run typecheck# TypeScript type checking
```

### Testing & Building

```bash
npm test# Run Jest tests
npm run test:watch  # Run tests in watch mode
npm run test:coverage  # Run tests with coverage
npm run build # Full build (lint + test + TS compile)
npm run build:ts # TypeScript compilation only
```

### Security

```bash
npm run security # Comprehensive security checks
npm run security:audit # NPM audit for vulnerabilities
npm run security:lint  # ESLint security rules
npm run security:fix# Auto-fix security issues
```

## Development Workflow

### JavaScript Development

```bash
# Start development server
npm run dev

# The application will restart automatically on file changes
# Access at http://localhost:3000
```

### TypeScript Development

```bash
# Start TypeScript development server
npm run dev:ts

# TypeScript files are automatically compiled and restarted
# Full type checking and IntelliSense support
```

### Code Quality Workflow

```bash
# Before committing, run quality checks
npm run lint
npm run format
npm run typecheck
npm test

# Or run the full build pipeline
npm run build
```

### Adding New Features

1. **JavaScript**: Add files to `src/` with `.js` extension
2. **TypeScript**: Add files to `src/` with `.ts` extension
3. **Python**: Add files to `src/` with `.py` extension
4. **Tests**: Add test files to `tests/` following naming convention

## Troubleshooting

### Common Issues

#### 1. Module Not Found Errors

```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

#### 2. TypeScript Compilation Errors

```bash
# Check TypeScript configuration
npm run typecheck

# Clean and rebuild
rm -rf node_modules dist
npm install
npm run build:ts
```

#### 3. Linting Errors

```bash
# Auto-fix common issues
npm run lint:fix

# Check specific file types
npm run lint:js # JavaScript only
npm run lint:ts # TypeScript only
```

#### 4. Environment Configuration Issues

```bash
# Verify .env file exists and is properly formatted
ls -la config/.env

# Check environment variables are loaded
node -e "console.log(require('dotenv').config({ path: 'config/.env' }))"
```

#### 5. Port Already in Use

```bash
# Find process using the port
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use a different port in .env
PORT=3001 npm start
```

#### 6. Permission Errors

```bash
# Fix script permissions
chmod +x scripts/*.sh

# Or run with explicit permissions
bash scripts/build.sh
```

### Development Environment Issues

#### Node.js Version Mismatch

```bash
# Check current version
node --version

# Use nvm to switch versions
nvm use 18
nvm alias default 18
```

#### Python Environment Issues

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt
```

#### Docker Issues

```bash
# Check Docker is running
docker --version
docker-compose --version

# Clean Docker system
docker system prune -a
```

### Build and Deployment Issues

#### Build Failures

```bash
# Clean build artifacts
rm -rf build/*
npm run build

# Check for TypeScript errors
npm run typecheck
```

#### Test Failures

```bash
# Run tests with verbose output
npm test -- --verbose

# Run specific test
npm test -- --testNamePattern="specific test"
```

### Performance Issues

#### Slow Development Server

```bash
# Use production build for testing
npm run build
npm start

# Or optimize development config
NODE_ENV=production npm run dev
```

#### Memory Issues

```bash
# Increase Node.js memory limit
NODE_OPTIONS="--max-old-space-size=4096" npm start

# Monitor memory usage
node --expose-gc --inspect
```

## Security

For detailed security information, see [SECURITY.md](SECURITY.md).

## Performance

### Optimization Features

#### 1. Build Optimization

```bash
# Production build with optimizations
npm run build

# Analyze bundle size
npm install -g webpack-bundle-analyzer
npx webpack-bundle-analyzer build/static/js/*.js
```

#### 2. Development Performance

```bash
# Fast refresh for React-like development
npm run dev:ts

# Parallel processing for builds
npm run build  # Uses parallel processing
```

#### 3. Code Splitting

```typescript
// Dynamic imports for better performance
const module = await import('./heavy-module');
```

#### 4. Memory Optimization

```javascript
// Proper cleanup
if (global.gc) {
  global.gc();
}

// Efficient data structures
const map = new Map(); // Better than plain objects for frequent additions/removals
```

### Monitoring Performance

#### Application Metrics

```javascript
// Basic performance monitoring
console.time('operation');
// ... your code ...
console.timeEnd('operation');

// Memory usage
const memUsage = process.memoryUsage();
console.log(`Memory: ${Math.round(memUsage.heapUsed / 1024 / 1024)} MB`);
```

#### Database Optimization

```python
# Efficient database queries
from sqlalchemy.orm import selectinload

# Use selectinload for eager loading
query = session.query(User).options(selectinload(User.posts))
```

### Performance Best Practices

1. **Code Splitting**: Split large bundles into smaller chunks
2. **Lazy Loading**: Load components only when needed
3. **Caching**: Implement proper caching strategies
4. **Database Indexing**: Ensure proper database indexes
5. **CDN Usage**: Serve static assets from CDN
6. **Compression**: Enable gzip/brotli compression
7. **Minification**: Minify code for production

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
