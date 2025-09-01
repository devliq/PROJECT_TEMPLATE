# Project Makefile
# Cross-platform development tasks

.PHONY: help install build test clean deploy setup lint format docker-build docker-run validate

# Configurable paths
SCRIPT_DIR = scripts
BUILD_DIR = build
DEPLOY_DIR = deploy
SRC_DIR = src
TEST_DIR = test

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

validate: ## Validate required files
	@if [ ! -f "README.MD" ]; then \
		echo "README.MD not found"; exit 1; \
	fi
	@if [ ! -f "package.json" ] && [ ! -f "requirements.txt" ] && [ ! -f "pom.xml" ]; then \
		echo "No dependency file found"; exit 1; \
	fi
	@echo "Validation passed"

# Setup and installation
setup: ## Set up development environment
	@echo "Setting up development environment..."
	@if [ -f "$(SCRIPT_DIR)/setup/setup.sh" ]; then \
		bash $(SCRIPT_DIR)/setup/setup.sh || { echo "Setup failed"; exit 1; }; \
	else \
		echo "Setup script not found"; exit 1; \
	fi

install: ## Install dependencies
	@echo "Installing dependencies..."
	@if [ -f "package.json" ]; then \
		npm install || exit 1; \
	elif [ -f "requirements.txt" ]; then \
		pip install -r requirements.txt || exit 1; \
	elif [ -f "pom.xml" ]; then \
		mvn dependency:resolve || exit 1; \
	else \
		echo "No dependency file found"; exit 1; \
	fi

# Development tasks
build: ## Build the project
	@echo "Building project..."
	@if [ -f "$(SCRIPT_DIR)/build/build.sh" ]; then \
		bash $(SCRIPT_DIR)/build/build.sh || { echo "Build failed"; exit 1; }; \
	else \
		echo "Build script not found"; exit 1; \
	fi

test: ## Run tests
	@echo "Running tests..."
	@if [ -f "package.json" ]; then \
		npm test || exit 1; \
	elif [ -f "requirements.txt" ]; then \
		python -m pytest tests/ || python -m unittest discover tests/ || exit 1; \
	else \
		echo "No test runner configured"; exit 1; \
	fi

lint: ## Run linting
	@echo "Running linter..."
	@if [ -f "package.json" ]; then \
		npm run lint || exit 1; \
	else \
		echo "No linter configured"; exit 1; \
	fi

format: ## Format code
	@echo "Formatting code..."
	@if [ -f "package.json" ]; then \
		npm run format || exit 1; \
	else \
		echo "No formatter configured"; exit 1; \
	fi

# Docker tasks
docker-build: ## Build Docker image
	@echo "Building Docker image..."
	@if [ -f "Dockerfile" ]; then \
		docker build -t $(shell basename $(CURDIR)) .; \
	else \
		echo "Dockerfile not found"; \
	fi

docker-run: ## Run Docker container
	@echo "Running Docker container..."
	@if [ -f "Dockerfile" ]; then \
		docker run -p 3000:3000 $(shell basename $(CURDIR)); \
	else \
		echo "Dockerfile not found"; \
	fi

# Deployment
deploy: ## Deploy to staging
	@echo "Deploying to staging..."
	@if [ -f "$(SCRIPT_DIR)/deploy/deploy.sh" ]; then \
		bash $(SCRIPT_DIR)/deploy/deploy.sh staging || { echo "Deploy failed"; exit 1; }; \
	else \
		echo "Deploy script not found"; exit 1; \
	fi

deploy-prod: ## Deploy to production
	@echo "Deploying to production..."
	@if [ -f "scripts/deploy/deploy.sh" ]; then \
		bash scripts/deploy/deploy.sh production; \
	else \
		echo "Deploy script not found"; \
	fi

# GitOps deployment
gitops-deploy: ## GitOps deploy to staging
	@echo "GitOps deploying to staging..."
	@if [ -f "scripts/deploy/gitops-deploy.sh" ]; then \
		bash scripts/deploy/gitops-deploy.sh staging; \
	else \
		echo "GitOps deploy script not found"; \
	fi

gitops-deploy-prod: ## GitOps deploy to production
	@echo "GitOps deploying to production..."
	@if [ -f "scripts/deploy/gitops-deploy.sh" ]; then \
		bash scripts/deploy/gitops-deploy.sh production; \
	else \
		echo "GitOps deploy script not found"; \
	fi

# Cleanup
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf dist/
	@rm -rf target/
	@rm -rf .next/
	@rm -rf .nuxt/
	@rm -rf temp/
	@find . -name "*.pyc" -delete 2>/dev/null || true
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

clean-all: clean ## Clean all artifacts including dependencies
	@echo "Cleaning all artifacts..."
	@rm -rf node_modules/
	@rm -rf vendor/
	@rm -rf .venv/
	@rm -rf venv/

# Development server
dev: ## Start development server
	@echo "Starting development server..."
	@if [ -f "package.json" ]; then \
		npm run dev; \
	else \
		echo "No development server configured"; \
	fi

# CI/CD simulation
ci: validate install lint test build ## Run full CI pipeline locally

# Utility
info: ## Show project information
	@echo "Project: $(shell basename $(CURDIR))"
	@echo "Directory: $(CURDIR)"
	@echo "Node version: $(shell node --version 2>/dev/null || echo 'Not installed')"
	@echo "NPM version: $(shell npm --version 2>/dev/null || echo 'Not installed')"
	@echo "Python version: $(shell python --version 2>/dev/null || echo 'Not installed')"
	@echo "Docker version: $(shell docker --version 2>/dev/null || echo 'Not installed')"

# Windows compatibility
ifeq ($(OS),Windows_NT)
    RM = del /Q
    RMDIR = rmdir /S /Q
else
    RM = rm -f
    RMDIR = rm -rf
endif