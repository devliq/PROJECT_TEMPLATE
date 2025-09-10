#!/bin/bash

# Script to set environment variables on Vercel via API
# Usage: ./set-vercel-env.sh

set -e

# Configuration
VERCEL_API_URL="https://api.vercel.com"
PROJECT_ID="${VERCEL_PROJECT_ID}"
TOKEN="${VERCEL_TOKEN}"
ENVIRONMENT="${ENVIRONMENT:-production}"

# Function to set environment variable
set_env_var() {
    local key="$1"
    local value="$2"
    local type="${3:-plain}"
    local target="${4:-[\"$ENVIRONMENT\"]}"

    echo "Setting environment variable: $key"

    # Check if env var already exists
    existing_env=$(curl -s -H "Authorization: Bearer $TOKEN" \
        "$VERCEL_API_URL/v9/projects/$PROJECT_ID/env" | \
        jq -r ".envs[] | select(.key == \"$key\") | .id")

    if [ -n "$existing_env" ]; then
        echo "Updating existing environment variable: $key"
        curl -X PATCH \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"value\": \"$value\", \"type\": \"$type\"}" \
            "$VERCEL_API_URL/v9/projects/$PROJECT_ID/env/$existing_env"
    else
        echo "Creating new environment variable: $key"
        curl -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"key\": \"$key\", \"value\": \"$value\", \"type\": \"$type\", \"target\": $target}" \
            "$VERCEL_API_URL/v10/projects/$PROJECT_ID/env"
    fi

    echo ""
}

# Function to load environment variables from file
load_env_from_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Loading environment variables from $file"
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue

            # Remove quotes from value
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")

            set_env_var "$key" "$value"
        done < "$file"
    else
        echo "Environment file $file not found"
    fi
}

# Function to load environment variables from GitHub secrets
load_env_from_secrets() {
    echo "Loading environment variables from GitHub secrets"

    # Common environment variables from secrets
    # Add your specific env vars here
    if [ -n "${DATABASE_URL:-}" ]; then
        set_env_var "DATABASE_URL" "$DATABASE_URL"
    fi

    if [ -n "${API_KEY:-}" ]; then
        set_env_var "API_KEY" "$API_KEY"
    fi

    if [ -n "${JWT_SECRET:-}" ]; then
        set_env_var "JWT_SECRET" "$JWT_SECRET" "secret"
    fi

    if [ -n "${REDIS_URL:-}" ]; then
        set_env_var "REDIS_URL" "$REDIS_URL"
    fi

    # Add more as needed
}

# Main execution
echo "🚀 Setting up Vercel environment variables for $ENVIRONMENT environment"

# Validate required variables
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: VERCEL_PROJECT_ID is required"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    echo "❌ Error: VERCEL_TOKEN is required"
    exit 1
fi

# Load environment variables
if [ -f ".env.$ENVIRONMENT" ]; then
    load_env_from_file ".env.$ENVIRONMENT"
elif [ -f ".env" ]; then
    load_env_from_file ".env"
else
    echo "No .env file found, loading from environment variables"
    load_env_from_secrets
fi

echo "✅ Environment variables setup complete"