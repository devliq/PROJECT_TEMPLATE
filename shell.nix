# Nix Shell Configuration for Reproducible Development Environment
# This file defines a Nix shell with common development tools
# Usage: nix-shell
# Or with direnv: automatically loaded when entering directory

{ pkgs ? import <nixpkgs> {} }:

let
  # Python environment with common packages
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    pip
    virtualenv
    setuptools
    wheel
    # Add project-specific packages here as needed
  ]);

  # Node.js environment
  nodejsEnv = pkgs.nodejs;

  # Common development tools
  devTools = with pkgs; [
    # Version control
    git
    git-lfs

    # Shell and terminal tools
    direnv
    zsh
    fish
    bash

    # Text editors and tools
    vim
    neovim
    emacs
    nano

    # Build tools
    make
    cmake
    ninja

    # Development utilities
    jq
    yq
    httpie
    curl
    wget

    # Container tools
    docker
    docker-compose

    # Cloud tools (optional)
    # awscli2
    # google-cloud-sdk
    # azure-cli

    # Database tools
    sqlite
    postgresql

    # Documentation
    pandoc
    texlive.combined.scheme-basic

    # Security and linting
    shellcheck
    shfmt
  ];

in
pkgs.mkShell {
  # Shell packages
  buildInputs = [
    pythonEnv
    nodejsEnv
  ] ++ devTools;

  # Environment variables
  shellHook = ''
    echo "🚀 Welcome to the reproducible development environment!"
    echo "📦 Available tools: Python, Node.js, Git, Docker, and more"
    echo "🔧 Project root: $PWD"

    # Set up environment
    export PROJECT_ROOT="$PWD"
    export PATH="$PROJECT_ROOT/scripts:$PATH"

    # Load .env file if it exists (fallback for when direnv isn't available)
    if [ -f .env ]; then
      echo "📋 Loading environment variables from .env"
      set -a
      source .env
      set +a
    fi

    # Display current environment info
    echo "🌍 APP_ENV: ''${APP_ENV:-development}"
    if [ -n "$APP_NAME" ]; then
      echo "📱 Project: $APP_NAME"
    fi

    # Change to project directory if not already there
    cd "$PROJECT_ROOT"

    echo "✨ Environment ready! Type 'exit' to leave the Nix shell."
  '';

  # Additional environment setup
  PYTHONPATH = "$PROJECT_ROOT/src";

  # Git configuration (optional)
  GIT_CONFIG_GLOBAL = pkgs.writeText "gitconfig" ''
    [core]
      editor = vim
    [init]
      defaultBranch = main
    [pull]
      rebase = true
  '';
}