#!/bin/bash

# setup-venv.sh - Virtual Environment Setup Script
# This script sets up a Python virtual environment for the project

set -e  # Exit on any error

# Get project name from current directory
PROJECT_NAME="${PWD##*/}"

echo "Setting up virtual environment for project: $PROJECT_NAME"

# Check if Python is available
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "Error: Python is not installed or not in PATH"
    exit 1
fi

# Use python3 if available, otherwise python
PYTHON_CMD="python"
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
fi

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | grep -oP '\d+\.\d+')
echo "Using Python version: $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    $PYTHON_CMD -m venv venv
    echo "Virtual environment created successfully"
else
    echo "Virtual environment already exists"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    pip install -r requirements.txt
    echo "Requirements installed successfully"
elif [ -f "pyproject.toml" ]; then
    echo "Installing from pyproject.toml..."
    pip install -e .
    echo "Package installed in development mode"
else
    echo "No requirements.txt or pyproject.toml found. Installing basic development packages..."
    pip install wheel setuptools
fi

echo ""
echo "Virtual environment setup complete!"
echo "To activate the environment manually, run: source venv/bin/activate"
echo "To deactivate, run: deactivate"

# Show current environment status
echo ""
echo "Current environment:"
echo "- Python: $($PYTHON_CMD --version)"
echo "- Pip: $(pip --version)"
echo "- Virtual environment: $(which python)"

# Keep the environment activated for the current session
exec $SHELL