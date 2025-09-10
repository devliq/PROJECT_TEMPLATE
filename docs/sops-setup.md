# Mozilla SOPS Setup Documentation

This document outlines the Mozilla SOPS setup implemented for secure secret management in this project.

## Overview

The project uses Mozilla SOPS with Age encryption for managing sensitive configuration data. Secrets are encrypted in `secrets.enc.yaml` and decrypted at runtime during CI/CD deployments.

## Key Components

- **SOPS**: Mozilla's Secrets OPerationS tool for encrypting/decrypting YAML files
- **Age**: Modern encryption tool used as the backend for SOPS
- **GitHub Secrets**: AGE_PRIVATE_KEY stored securely in GitHub repository secrets

## Verification Commands

### 1. Verify SOPS Installation

```bash
./sops --version
```

### 2. Verify Age Installation

```bash
./age/age --version
```

### 3. Check Encrypted Secrets File

```bash
head -20 secrets.enc.yaml
```

### 4. Decrypt Secrets Locally (for verification)

```bash
# Ensure age-key.txt contains the private key
./sops --decrypt --age age-key.txt secrets.enc.yaml
```

### 5. Validate YAML Structure

```bash
./sops --decrypt --age age-key.txt secrets.enc.yaml | python3 -c "import yaml, sys; data = yaml.safe_load(sys.stdin); print('STAGING_HOST:', data.get('STAGING_HOST')); print('STAGING_USER:', data.get('STAGING_USER'))"
```

## GitHub Actions Integration

The CI/CD pipeline automatically:

1. Downloads the AGE_PRIVATE_KEY from GitHub secrets
2. Decrypts `secrets.enc.yaml` using SOPS
3. Sets environment variables for the deployment step
4. Uses decrypted values in the SSH deployment action

## Security Notes

- The `age-key.txt` file is added to `.gitignore` to prevent accidental commits
- Private keys should never be committed to the repository
- GitHub's AGE_PRIVATE_KEY secret should be set in repository settings
- Public key is embedded in the encrypted file for verification

## Updating Secrets

To update secrets:

1. Decrypt the current file: `./sops --decrypt --age age-key.txt secrets.enc.yaml > secrets.yaml`
2. Edit `secrets.yaml` with new values
3. Re-encrypt: `./sops --encrypt --age age1e97cf60y7smxl6kv3lyq6qt5ak6hr790agccxcd4jy7klglcpecq8qrjla secrets.yaml > secrets.enc.yaml`
4. Remove temporary file: `rm secrets.yaml`

## Migration to Vercel Environment Variables

For projects deploying to Vercel, you can migrate from SOPS-encrypted secrets to Vercel's built-in environment variable management for simplified deployment and better security.

### Migration Steps

1. **Decrypt existing secrets:**

```bash
./sops --decrypt --age age-key.txt secrets.enc.yaml > secrets.yaml
```

2. **Install Vercel CLI:**

```bash
npm install -g vercel
vercel login
```

3. **Set environment variables in Vercel:**

```bash
# Read values from secrets.yaml and set them in Vercel
# For each secret in secrets.yaml:
vercel env add VARIABLE_NAME
# Follow prompts to enter the value

# Or set multiple at once for different environments:
vercel env add DATABASE_URL production
vercel env add API_KEY production
vercel env add JWT_SECRET production
```

4. **Update application code:**

```javascript
// Before (using SOPS-decrypted files):
const fs = require('fs');
const secrets = YAML.parse(fs.readFileSync('secrets.yaml', 'utf8'));
const databaseUrl = secrets.DATABASE_URL;

// After (using Vercel environment variables):
const databaseUrl = process.env.DATABASE_URL;
const apiKey = process.env.API_KEY;
const jwtSecret = process.env.JWT_SECRET;
```

5. **Update deployment configuration:**

```bash
# Remove SOPS-related files from deployment
rm secrets.enc.yaml age-key.txt sops
```

6. **Update CI/CD pipeline:**
   Remove SOPS decryption steps from GitHub Actions and rely on Vercel's environment variable management.

### Benefits of Migration

- **Simplified deployment**: No need to manage encryption keys in CI/CD
- **Better security**: Secrets managed by Vercel's secure infrastructure
- **Automatic scaling**: Environment variables automatically available across all Vercel instances
- **Version control**: No encrypted files in repository
- **Easy management**: GUI and CLI tools for environment variable management

### Rollback Plan

If you need to rollback to SOPS:

1. Keep a backup of `secrets.enc.yaml` and `age-key.txt`
2. Restore SOPS decryption in CI/CD pipeline
3. Update application code to read from decrypted files again

### Environment-Specific Variables

Vercel supports different environments:

```bash
# Production
vercel env add DATABASE_URL production

# Preview (for all preview deployments)
vercel env add DATABASE_URL preview

# Development (for local development)
vercel env add DATABASE_URL development
```

This allows different configurations for different deployment environments without code changes.
