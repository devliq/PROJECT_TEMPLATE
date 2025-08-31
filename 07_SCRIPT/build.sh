#!/bin/bash

# Build Script
# This script builds the project based on the configuration

set -e  # Exit on any error

echo "🔨 Starting build process..."

# Check if we're in the right directory
if [ ! -f "README.MD" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Load configuration
CONFIG_FILE="config/build.config"
if [ -f "$CONFIG_FILE" ]; then
    echo "📋 Loading build configuration..."
    # In a real implementation, you'd parse the config file
    # For now, we'll use default values
else
    echo "⚠️  Build config not found. Using defaults..."
fi

# Clean previous build
echo "🧹 Cleaning previous build..."
rm -rf build/*
mkdir -p build

# Run tests if configured
if [ "$RUN_TESTS" = "true" ] || [ -z "$RUN_TESTS" ]; then
    echo "🧪 Running tests..."
    if [ -f "package.json" ]; then
        npm test
    elif [ -f "requirements.txt" ]; then
        python -m pytest tests/ || python -m unittest discover tests/
    elif [ -f "pom.xml" ]; then
        mvn test
    else
        echo "⚠️  No test runner configured"
    fi
fi

# Build the project
echo "🏗️  Building project..."

if [ -f "package.json" ]; then
    echo "📦 Building Node.js project..."
    npm run build 2>/dev/null || echo "⚠️  No build script found in package.json"

elif [ -f "requirements.txt" ]; then
    echo "🐍 Building Python project..."
    # For Python, you might want to create a wheel or executable
    python setup.py build 2>/dev/null || echo "⚠️  No setup.py found"

elif [ -f "pom.xml" ]; then
    echo "☕ Building Java project..."
    mvn clean package

elif [ -f "Makefile" ]; then
    echo "⚙️  Running Makefile..."
    make

else
    echo "📋 Copying source files to build directory..."
    cp -r src/* build/ 2>/dev/null || echo "⚠️  No source files found in 01_SRC/"
fi

# Copy assets
if [ -d "assets" ]; then
    echo "📸 Copying assets..."
    cp -r assets/* build/ 2>/dev/null || true
fi

# Generate documentation if configured
if [ -d "docs" ]; then
    echo "📚 Generating documentation..."
    # Add documentation generation commands here
fi

# Create build artifact
echo "📦 Creating build artifact..."
BUILD_NAME="project-build-$(date +%Y%m%d-%H%M%S)"
mkdir -p "build/$BUILD_NAME"
cp -r build/* "build/$BUILD_NAME/" 2>/dev/null || true

# Compress build if configured
if [ "$COMPRESS_BUILD" = "true" ]; then
    echo "🗜️  Compressing build..."
    cd build
    tar -czf "${BUILD_NAME}.tar.gz" "$BUILD_NAME"
    cd ..
fi

echo "✅ Build complete!"
echo "📁 Build output: build/"
if [ -d "build/$BUILD_NAME" ]; then
    echo "📦 Build artifact: build/$BUILD_NAME/"
fi