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
