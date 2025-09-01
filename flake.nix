# Nix Flake Configuration for Advanced Environment Management
# This provides modern Nix flakes support with multiple environments
# Usage: nix develop (for development shell)
#        nix build (for building)
#        nix run (for running commands)

{
  description = "Project Template with Reproducible Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/5e4fbfb";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Common development tools
        devTools = with pkgs; [
          # Core development
          git
          direnv
          nix-direnv

          # Shell environments
          bash
          zsh
          fish

          # Text editors
          vim
          neovim

          # Build tools
          gnumake
          cmake
          ninja

          # Utilities
          jq
          yq
          httpie
          curl
          wget

          # Container tools
          docker
          docker-compose

          # Database
          sqlite
          postgresql

          # Documentation
          pandoc

          # Linting and formatting
          shellcheck
          shfmt
          nixpkgs-fmt

          # Locale support
          glibcLocales
        ];

        # Python environment
        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pip
          virtualenv
          setuptools
          wheel
          black
          flake8
          mypy
        ]);

        # Node.js environment
        nodejsEnv = pkgs.nodejs;

      in
      {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            nodejsEnv
          ] ++ devTools;

          # Clear LC_ALL to prevent locale warnings
          LC_ALL = "";

          shellHook = ''
            # Clear LC_ALL immediately to prevent locale warnings
            export LC_ALL=""

            echo "🚀 Welcome to the Nix flake development environment!"
            echo "📦 System: ${system}"
            echo "🔧 Project root: $PWD"

            # Set up locale configuration to prevent warnings
            export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
            export LANG="C.utf8"
            export LC_CTYPE="C.utf8"
            export LC_COLLATE="C.utf8"
            export LC_MESSAGES="C.utf8"

            # Set up environment
            export PROJECT_ROOT="$PWD"
            export PATH="$PROJECT_ROOT/scripts:$PATH"

            # Load .env file if it exists
            if [ -f .env ]; then
              echo "📋 Loading environment variables from .env"
              # Validate .env
              if ! grep -q "^APP_ENV=" .env; then
                echo "⚠️  Warning: APP_ENV not found in .env"
              fi
              if ! grep -q "^APP_NAME=" .env; then
                echo "⚠️  Warning: APP_NAME not found in .env"
              fi
              set -a
              source .env
              set +a
            fi

            # Display environment info
            echo "🌍 APP_ENV: ''${APP_ENV:-development}"
            if [ -n "$APP_NAME" ]; then
              echo "📱 Project: $APP_NAME"
            fi

            echo "✨ Nix flake environment ready!"
          '';

          # Environment variables
          PYTHONPATH = "$PROJECT_ROOT/src";
        };

        # Alternative shells for different purposes
        devShells.python = pkgs.mkShell {
          buildInputs = [ pythonEnv ] ++ (with pkgs; [ black flake8 mypy glibcLocales ]);

          # Clear LC_ALL to prevent locale warnings
          LC_ALL = "";

          shellHook = ''
            # Clear LC_ALL immediately to prevent locale warnings
            export LC_ALL=""

            echo "🐍 Python development environment"
            # Set up locale configuration
            export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
            export LANG="C.utf8"
            export LC_CTYPE="C.utf8"
            export LC_COLLATE="C.utf8"
            export LC_MESSAGES="C.utf8"
            export PYTHONPATH="$PROJECT_ROOT/src:$PYTHONPATH"
          '';
        };

        devShells.nodejs = pkgs.mkShell {
          buildInputs = [ nodejsEnv ] ++ (with pkgs; [ yarn glibcLocales ]);

          # Clear LC_ALL to prevent locale warnings
          LC_ALL = "";

          shellHook = ''
            # Clear LC_ALL immediately to prevent locale warnings
            export LC_ALL=""

            echo "📦 Node.js development environment"
            # Set up locale configuration
            export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
            export LANG="C.utf8"
            export LC_CTYPE="C.utf8"
            export LC_COLLATE="C.utf8"
            export LC_MESSAGES="C.utf8"
          '';
        };

        # Packages (for building the project if needed)
        packages.default = pkgs.stdenv.mkDerivation {
          name = "project-template";
          src = ./.;

          buildInputs = [ pythonEnv nodejsEnv ];

          buildPhase = ''
            echo "Building project..."
            # Add build commands here
          '';

          installPhase = ''
            mkdir -p $out
            cp -r . $out/
          '';
        };

        # Apps (for running commands)
        apps.default = {
          type = "app";
          program = "${pkgs.bash}/bin/bash";
        };

        # Formatter
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}