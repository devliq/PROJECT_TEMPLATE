#!/bin/bash

# update-python-version.sh
# Script to update .python-version file with various options

set -e

# Function to get latest stable Python version
get_latest_version() {
    pyenv install --list 2>/dev/null | grep -E '^3\.[0-9]+\.[0-9]+$' | sort -V | tail -1 | tr -d ' '
}

# Function to get latest patch for specific minor version
get_latest_patch() {
    local minor="$1"
    pyenv install --list 2>/dev/null | grep -E "^${minor}\.[0-9]+$" | sort -V | tail -1 | tr -d ' '
}

# Function to validate version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^3\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format. Expected X.Y.Z (e.g., 3.13.7)"
        exit 1
    fi
}

# Main logic
if [ $# -eq 0 ]; then
    # Default: update to latest stable
    echo "Updating to latest stable Python version..."
    new_version=$(get_latest_version)
    if [ -z "$new_version" ]; then
        echo "Error: Could not determine latest Python version"
        exit 1
    fi
elif [ "$1" = "--minor" ] && [ $# -eq 2 ]; then
    # Update to latest patch for specific minor
    minor="$2"
    if [[ ! "$minor" =~ ^3\.[0-9]+$ ]]; then
        echo "Error: Invalid minor version format. Expected X.Y (e.g., 3.13)"
        exit 1
    fi
    echo "Updating to latest patch for Python $minor..."
    new_version=$(get_latest_patch "$minor")
    if [ -z "$new_version" ]; then
        echo "Error: Could not find latest patch for Python $minor"
        exit 1
    fi
elif [ "$1" = "--version" ] && [ $# -eq 2 ]; then
    # Set specific version
    new_version="$2"
    validate_version "$new_version"
    echo "Setting Python version to $new_version..."
else
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  (no options)    Update to latest stable Python version"
    echo "  --minor X.Y     Update to latest patch for specific minor version"
    echo "  --version X.Y.Z Set specific Python version"
    exit 1
fi

# Check if pyenv is available
if ! command -v pyenv &> /dev/null; then
    echo "Error: pyenv is not installed or not in PATH"
    exit 1
fi

# Update .python-version file
echo "$new_version" > .python-version

# Install the version if not already installed
if ! pyenv versions --bare | grep -q "^${new_version}$"; then
    echo "Installing Python $new_version..."
    pyenv install "$new_version"
fi

# Set local version
pyenv local "$new_version"

echo "Python version updated to $new_version"