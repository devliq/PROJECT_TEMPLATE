#!/bin/bash

# Project Setup Script
# This script sets up the development environment for the project

set -e  # Exit on any error

echo "🚀 Starting project setup..."

# Check if we're in the right directory
if [ ! -f "README.MD" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Create necessary directories if they don't exist
echo "📁 Creating project directories..."
mkdir -p src
mkdir -p tests
mkdir -p build
mkdir -p deploy
mkdir -p assets
mkdir -p config
mkdir -p scripts
mkdir -p vendor
mkdir -p temp
mkdir -p logs

# Check for package manager and install dependencies
if [ -f "package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    if command -v npm &> /dev/null; then
        npm install
    else
        echo "⚠️  npm not found. Please install Node.js and npm"
    fi
elif [ -f "requirements.txt" ]; then
    echo "🐍 Installing Python dependencies..."
    if command -v pip &> /dev/null; then
        pip install -r requirements.txt
    else
        echo "⚠️  pip not found. Please install Python and pip"
    fi
elif [ -f "pom.xml" ]; then
    echo "☕ Installing Java dependencies..."
    if command -v mvn &> /dev/null; then
        mvn dependency:resolve
    else
        echo "⚠️  Maven not found. Please install Maven"
    fi
fi

# Copy environment template if it exists
if [ -f "config/.env.example" ] && [ ! -f ".env" ]; then
    echo "📋 Copying environment template..."
    cp config/.env.example .env
    echo "✅ Created .env file. Please update it with your configuration"
fi

# Check for direnv and provide setup instructions
if [ -f ".envrc" ]; then
    echo "🔧 Checking direnv setup..."
    if command -v direnv &> /dev/null; then
        echo "✅ direnv found. Environment will be loaded automatically."
        echo "   Run 'direnv allow' to approve the .envrc file."
    else
        echo "⚠️  direnv not found. For automatic environment loading:"
        echo "   - Install direnv: https://direnv.net/"
        echo "   - Add 'eval \"\$(direnv hook bash)\"' to your ~/.bashrc"
        echo "   - Run 'direnv allow' in this directory"
    fi
fi

# Check for Nix and provide setup instructions
if [ -f "shell.nix" ] || [ -f "flake.nix" ]; then
    echo "🔧 Checking Nix setup..."
    if command -v nix &> /dev/null; then
        echo "✅ Nix found. You can use reproducible environments:"
        echo "   - nix-shell (for shell.nix)"
        echo "   - nix develop (for flake.nix)"
        if [ -f "flake.nix" ]; then
            echo "   - nix flake update (to update dependencies)"
        fi
    else
        echo "ℹ️  Nix not found. For reproducible environments:"
        echo "   - Install Nix: https://nixos.org/download.html"
        echo "   - Or use nix-shell/flake commands when available"
    fi
fi

# Set up git hooks if .git exists
if [ -d ".git" ]; then
    echo "🔗 Setting up git hooks..."
    # Add any git hooks setup here
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh
chmod +x scripts/*.py 2>/dev/null || true

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Update your .env file with project-specific configuration"
if [ -f ".envrc" ]; then
    echo "2. Run 'direnv allow' to enable automatic environment loading"
fi
if [ -f "shell.nix" ] || [ -f "flake.nix" ]; then
    echo "3. Try 'nix-shell' or 'nix develop' for reproducible environment"
fi
echo "4. Add your source code to src/"
echo "5. Run 'scripts/build.sh' to build the project"
echo "6. Run 'scripts/deploy.sh' to deploy (if applicable)"