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
