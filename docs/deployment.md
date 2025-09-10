# Deployment Guide

This guide covers deployment strategies and procedures for the project template.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Deployment Strategies](#deployment-strategies)
- [CI/CD Pipeline](#cicd-pipeline)
- [Manual Deployment](#manual-deployment)
- [Monitoring & Rollback](#monitoring--rollback)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying, ensure you have:

- Docker and Docker Compose installed
- Access to target servers
- SSH keys configured
- Environment-specific configuration files
- SSL certificates (for production)

## Environment Setup

### 1. Server Requirements

**Minimum Requirements:**

- 2 CPU cores
- 4GB RAM
- 20GB storage
- Ubuntu 20.04+ or similar Linux distribution

**Recommended for Production:**

- 4 CPU cores
- 8GB RAM
- 50GB SSD storage
- Ubuntu 22.04 LTS

### 2. Security Setup

```bash
# Create deployment user
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# Setup SSH keys
sudo -u deploy mkdir -p /home/deploy/.ssh
sudo -u deploy chmod 700 /home/deploy/.ssh
# Add your public key to /home/deploy/.ssh/authorized_keys

# Setup firewall
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable
```

### 3. Directory Structure

```bash
/opt/myproject/
├── app/                    # Application code
├── docker-compose.yml      # Service definitions
├── .env                    # Environment variables
├── logs/                   # Application logs
└── backups/               # Database backups
```

## Deployment Strategies

### Blue-Green Deployment

The template supports blue-green deployment for zero-downtime updates:

```bash
# Deploy to blue environment
docker-compose up -d blue

# Test blue environment
curl -f http://localhost:3000/health

# Switch traffic to blue
docker-compose up -d nginx

# Stop green environment
docker-compose stop green
```

### Rolling Deployment

For databases and stateful services:

```bash
# Update with rolling restart
docker-compose up -d --scale app=2

# Wait for new instances to be healthy
sleep 30

# Scale down old instances
docker-compose up -d --scale app=1
```

### Canary Deployment

Gradual rollout with traffic splitting:

```bash
# Deploy canary version
docker-compose up -d app-canary

# Route 10% traffic to canary
# (Configure in nginx/load balancer)

# Monitor metrics and errors
# If successful, promote to full deployment
```

## Vercel Deployment

Vercel provides a modern platform for deploying web applications with automatic scaling, global CDN, and serverless functions.

### Prerequisites for Vercel

- Vercel account (free or paid)
- Node.js application ready for deployment
- Environment variables configured

### Vercel Setup and Configuration

1. **Install Vercel CLI:**

```bash
npm install -g vercel
```

2. **Login to Vercel:**

```bash
vercel login
```

3. **Deploy to Vercel:**

```bash
# First deployment (will prompt for configuration)
vercel

# Or deploy directly
vercel --prod
```

4. **Link project to Vercel:**

```bash
vercel link
```

### Required Environment Variables for Vercel

Configure environment variables in Vercel's dashboard or via CLI:

```bash
# Set environment variables
vercel env add DATABASE_URL
vercel env add API_KEY
vercel env add JWT_SECRET

# For production
vercel env add DATABASE_URL production
vercel env add API_KEY production
vercel env add JWT_SECRET production
```

### Vercel-Specific Deployment Commands

```bash
# Deploy to preview environment
vercel

# Deploy to production
vercel --prod

# Check deployment status
vercel ls

# View logs
vercel logs

# Remove deployment
vercel rm <deployment-url>
```

### Vercel Workflows

#### Automatic Deployments

Vercel automatically deploys on:

- Push to main/master branch (production)
- Push to other branches (preview deployments)
- Pull requests (preview deployments)

#### Custom Domain Setup

```bash
# Add custom domain
vercel domains add yourdomain.com

# Verify domain ownership
# Follow Vercel's DNS configuration instructions
```

#### Environment Management

```bash
# List environments
vercel env ls

# Update environment variable
vercel env pull .env.local  # Pull from Vercel to local
vercel env push .env.local  # Push local to Vercel
```

### Migration from SOPS to Vercel Environment Variables

If migrating from SOPS-encrypted secrets:

1. **Decrypt existing secrets:**

```bash
./sops --decrypt --age age-key.txt secrets.enc.yaml > secrets.yaml
```

2. **Extract values and set in Vercel:**

```bash
# Read values from secrets.yaml and set them via Vercel CLI
vercel env add STAGING_HOST
vercel env add PRODUCTION_HOST
# ... add other required variables
```

3. **Update application code:**

```javascript
// Instead of loading from SOPS-decrypted files
const databaseUrl = process.env.DATABASE_URL; // From Vercel env vars
const apiKey = process.env.API_KEY; // From Vercel env vars
```

4. **Remove SOPS dependencies:**

```bash
rm secrets.enc.yaml age-key.txt
```

### Vercel Best Practices

- Use preview deployments for testing
- Configure proper build commands in `vercel.json`
- Set up proper error pages and redirects
- Use Vercel's analytics for monitoring
- Configure rate limiting for API routes
- Use serverless functions for API endpoints

## Automated Deployment with GitHub Actions and Vercel API

The project now supports automated deployment using GitHub Actions integrated with Vercel's API. This workflow provides:

- **Automated deployments** on push to main branch and pull requests
- **Environment variable management** via Vercel API
- **Deployment verification** with smoke tests
- **Automatic rollback** on deployment failures
- **Manual deployment triggers** via workflow dispatch

### Workflow Overview

The automated workflow (`.github/workflows/vercel-deploy.yml`) performs the following steps:

1. **Checkout code** and setup Node.js environment
2. **Install dependencies** and Vercel CLI
3. **Pull Vercel environment configuration**
4. **Set environment variables** using the `set-vercel-env.sh` script
5. **Build the application**
6. **Deploy to Vercel** (preview for PRs, production for main branch)
7. **Verify deployment** with health checks
8. **Run smoke tests** to ensure functionality
9. **Rollback automatically** if deployment fails

### Environment Variables Setup

The workflow uses the following environment variables from GitHub secrets:

- `VERCEL_TOKEN`: Vercel API token for authentication
- `VERCEL_ORG_ID`: Vercel organization ID
- `VERCEL_PROJECT_ID`: Vercel project ID
- `DATABASE_URL`: Database connection string
- `API_KEY`: API authentication key
- `JWT_SECRET`: JWT signing secret
- `REDIS_URL`: Redis connection URL

## Instructions for Storing Vercel Token as GitHub Secret

To enable automated deployments, you need to configure GitHub secrets with your Vercel credentials:

### 1. Generate Vercel Token

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Navigate to **Settings** > **Tokens**
3. Click **Create Token**
4. Give it a name (e.g., "GitHub Actions Deployment")
5. Copy the generated token

### 2. Get Vercel Project Information

```bash
# Install Vercel CLI if not already installed
npm install -g vercel

# Login to Vercel
vercel login

# Link your project
vercel link

# Get project information
vercel project ls
```

This will show your `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID`.

### 3. Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** > **Secrets and variables** > **Actions**
3. Add the following secrets:

| Secret Name         | Value             | Description                         |
| ------------------- | ----------------- | ----------------------------------- |
| `VERCEL_TOKEN`      | Your Vercel token | API token for Vercel authentication |
| `VERCEL_ORG_ID`     | Your org ID       | Vercel organization identifier      |
| `VERCEL_PROJECT_ID` | Your project ID   | Vercel project identifier           |
| `DATABASE_URL`      | Database URL      | Production database connection      |
| `API_KEY`           | API key           | Application API key                 |
| `JWT_SECRET`        | JWT secret        | Secret for JWT token signing        |
| `REDIS_URL`         | Redis URL         | Redis connection string             |

### 4. Environment Protection (Optional)

For production deployments, you can add environment protection:

1. Go to **Settings** > **Environments**
2. Create a `production` environment
3. Add required reviewers for production deployments
4. The workflow will wait for approval before deploying to production

## How to Use the New Workflow and Scripts

### Automated Triggers

The workflow runs automatically on:

- **Push to main branch**: Deploys to production
- **Pull requests**: Creates preview deployments
- **Manual trigger**: Via GitHub Actions UI

### Manual Deployment

To trigger a manual deployment:

1. Go to **Actions** tab in your GitHub repository
2. Select "Vercel Deployment with Environment Variables" workflow
3. Click **Run workflow**
4. Choose environment (production or preview)
5. Click **Run workflow**

### Using the Environment Setup Script

The `scripts/set-vercel-env.sh` script manages environment variables via Vercel API:

```bash
# Make script executable
chmod +x scripts/set-vercel-env.sh

# Run script (typically called by CI/CD)
./scripts/set-vercel-env.sh
```

The script can:

- Load variables from `.env` files
- Set variables from GitHub secrets
- Update existing variables
- Create new variables

### Smoke Testing

The `scripts/smoke-test.js` script verifies deployment health:

```bash
# Run smoke tests against a deployment URL
node scripts/smoke-test.js https://your-app.vercel.app

# Or via npm script
npm run test:smoke https://your-app.vercel.app
```

Tests include:

- Health check endpoint
- API status endpoint
- Root endpoint accessibility

### Monitoring Deployments

Monitor deployments through:

- **GitHub Actions logs**: Detailed workflow execution
- **Vercel dashboard**: Deployment status and logs
- **Workflow notifications**: Success/failure notifications

## Migration Guide from Manual to Automated Deployment

### Step 1: Backup Current Setup

Before migrating, ensure you have backups:

```bash
# Backup current environment variables
vercel env pull .env.backup

# Backup deployment configuration
cp vercel.json vercel.json.backup
```

### Step 2: Configure GitHub Secrets

Follow the "Instructions for Storing Vercel Token as GitHub Secret" section above.

### Step 3: Update Environment Variables

Move environment variables from local `.env` files to GitHub secrets:

```bash
# Instead of local .env file
# DATABASE_URL=postgresql://...
# API_KEY=your-api-key

# Use GitHub secrets
# Set DATABASE_URL and API_KEY as repository secrets
```

### Step 4: Test the Workflow

1. Create a test branch
2. Push changes to trigger preview deployment
3. Verify the deployment works correctly
4. Check that environment variables are set properly

### Step 5: Enable Production Deployment

1. Merge changes to main branch
2. Monitor the production deployment
3. Verify all functionality works as expected

### Step 6: Update Documentation

Update your team's documentation to reflect the new automated process:

- Remove manual deployment instructions
- Add references to automated workflow
- Update troubleshooting guides for CI/CD issues

### Step 7: Clean Up

After successful migration:

```bash
# Remove local environment files if no longer needed
rm .env.local .env.production

# Update deployment scripts to reference automated workflow
# Remove manual deployment commands from package.json
```

### Benefits of Migration

- **Consistency**: Automated deployments reduce human error
- **Speed**: Faster deployment cycles
- **Reliability**: Built-in testing and rollback mechanisms
- **Security**: Secrets managed centrally in GitHub
- **Visibility**: Clear deployment history and logs

### Rollback Plan

If issues arise after migration:

1. **Immediate rollback**: Use Vercel's rollback feature
2. **Manual deployment**: Temporarily use `vercel --prod` commands
3. **Environment restoration**: Restore from `.env.backup` if needed

## CI/CD Pipeline

### GitHub Actions Setup

1. **Configure Secrets:**

   ```bash
   # Repository Settings > Secrets and variables > Actions
   STAGING_HOST=your-staging-server.com
   STAGING_USER=deploy
   STAGING_SSH_KEY=your-private-key
   PRODUCTION_HOST=your-production-server.com
   PRODUCTION_USER=deploy
   PRODUCTION_SSH_KEY=your-private-key
   SLACK_WEBHOOK=https://hooks.slack.com/...
   ```

2. **Security Scanning Setup:**

   The CI/CD pipeline uses Trivy for vulnerability scanning of dependencies and container images. Unlike Snyk, Trivy does not require an API token and works out of the box. It automatically scans:
   - Node.js dependencies (package.json, package-lock.json)
   - Python dependencies (requirements.txt, pyproject.toml)
   - Container images for OS-level vulnerabilities

   Scan results are uploaded to GitHub Code Scanning for integrated security monitoring.

3. **Environment Protection:**
   ```yaml
   # .github/workflows/deploy.yml
   environment: production
   # Requires manual approval for production deployments
   ```

### Pipeline Stages

1. **Quality Checks:** Linting, formatting, type checking
2. **Testing:** Unit tests, integration tests, coverage
3. **Security:** Vulnerability scanning, dependency checks
4. **Build:** Docker image creation, artifact generation
5. **Deploy:** Automated deployment to staging/production

## Manual Deployment

### Quick Deployment

```bash
# Clone repository
git clone https://github.com/your-org/your-project.git
cd your-project

# Setup environment
cp .env.example .env
# Edit .env with your values

# Deploy
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

### Production Deployment

```bash
# Update code
git pull origin main

# Build and deploy
docker-compose build --no-cache
docker-compose up -d

# Run migrations
docker-compose exec app npm run migrate

# Health check
curl -f http://localhost:3000/health
```

## Monitoring & Rollback

### Health Checks

```bash
# Application health
curl -f http://localhost:3000/health

# Database connectivity
docker-compose exec db pg_isready -U user -d myproject_db

# Redis connectivity
docker-compose exec redis redis-cli ping
```

### Monitoring Dashboards

- **Grafana:** http://localhost:3001 (admin/admin)
- **Prometheus:** http://localhost:9090
- **Application Metrics:** http://localhost:3000/metrics

### Rollback Procedures

```bash
# Quick rollback to previous version
docker-compose down
docker-compose pull  # Pull previous image
docker-compose up -d

# Rollback with backup
docker-compose exec db pg_restore -U user -d myproject_db /backups/backup.sql

# Emergency rollback
git reset --hard HEAD~1
docker-compose build --no-cache
docker-compose up -d
```

## Troubleshooting

### Common Issues

#### Application Won't Start

```bash
# Check logs
docker-compose logs app

# Check environment variables
docker-compose exec app env

# Test database connection
docker-compose exec app npm run db:test
```

#### Database Connection Issues

```bash
# Check database status
docker-compose ps db

# Test connection
docker-compose exec db psql -U user -d myproject_db -c "SELECT 1;"

# Reset database
docker-compose exec db dropdb -U user myproject_db
docker-compose exec db createdb -U user myproject_db
```

#### High Memory Usage

```bash
# Check container resource usage
docker stats

# Adjust resource limits in docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

#### SSL Certificate Issues

```bash
# Check certificate validity
openssl x509 -in /etc/ssl/certs/cert.pem -text -noout

# Renew certificate
certbot renew

# Reload nginx
docker-compose exec nginx nginx -s reload
```

### Performance Optimization

#### Database Tuning

```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';

-- Add indexes for slow queries
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### Application Optimization

```javascript
// Enable gzip compression
app.use(compression());

// Cache static assets
app.use(express.static('public', { maxAge: '1y' }));

// Database connection pooling
const pool = new Pool({
  max: 20,
  idleTimeoutMillis: 30000,
});
```

### Backup Strategy

#### Automated Backups

```bash
# Database backup script
#!/bin/bash
BACKUP_DIR="/opt/myproject/backups"
DATE=$(date +%Y%m%d_%H%M%S)

docker-compose exec db pg_dump -U user myproject_db > "$BACKUP_DIR/backup_$DATE.sql"

# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
```

#### Backup Verification

```bash
# Test backup restoration
docker-compose exec db createdb -U user test_restore
docker-compose exec -T db psql -U user test_restore < backup.sql
docker-compose exec db dropdb -U user test_restore
```

## Security Considerations

### Production Security

- Use strong, unique passwords
- Enable SSL/TLS for all connections
- Regularly update dependencies
- Monitor for security vulnerabilities
- Implement rate limiting
- Use secrets management (Vault, AWS Secrets Manager)

### Network Security

```bash
# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

# SSL configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:...;
ssl_prefer_server_ciphers off;
```

This deployment guide provides a comprehensive foundation for deploying your application safely and efficiently. Adjust the configurations based on your specific requirements and infrastructure.
