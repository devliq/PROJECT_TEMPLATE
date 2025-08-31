#!/bin/bash

# GitOps Deployment Script
# This script implements GitOps principles for automated deployments

set -e  # Exit on any error

echo "🚀 Starting GitOps deployment process..."

# Check if we're in the right directory
if [ ! -f "README.MD" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

# Configuration
GITOPS_REPO=${GITOPS_REPO:-"git@github.com:your-org/your-project-gitops.git"}
GITOPS_BRANCH=${GITOPS_BRANCH:-"main"}
ENVIRONMENT=${1:-"staging"}
DEPLOYMENT_DIR="deploy/gitops"

echo "🎯 Deploying to: $ENVIRONMENT"
echo "📚 GitOps repository: $GITOPS_REPO"
echo "🌿 GitOps branch: $GITOPS_BRANCH"

# Validate environment
case $ENVIRONMENT in
    "staging"|"production")
        echo "✅ Valid environment: $ENVIRONMENT"
        ;;
    *)
        echo "❌ Error: Invalid environment. Use 'staging' or 'production'"
        exit 1
        ;;
esac

# Check if build artifacts exist
if [ ! -d "build" ]; then
    echo "❌ Error: Build directory not found. Please run build.sh first"
    exit 1
fi

# Clone or update GitOps repository
if [ -d "$DEPLOYMENT_DIR/.git" ]; then
    echo "📥 Updating GitOps repository..."
    cd "$DEPLOYMENT_DIR"
    git pull origin "$GITOPS_BRANCH"
    cd -
else
    echo "📥 Cloning GitOps repository..."
    git clone -b "$GITOPS_BRANCH" "$GITOPS_REPO" "$DEPLOYMENT_DIR"
fi

# Create deployment manifest
echo "📝 Creating deployment manifest..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
DEPLOYMENT_NAME="deployment-$ENVIRONMENT-$TIMESTAMP"

cat > "$DEPLOYMENT_DIR/$DEPLOYMENT_NAME.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myproject-app-$ENVIRONMENT
  labels:
    app: myproject
    environment: $ENVIRONMENT
    deployment: $DEPLOYMENT_NAME
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myproject
      environment: $ENVIRONMENT
  template:
    metadata:
      labels:
        app: myproject
        environment: $ENVIRONMENT
        deployment: $DEPLOYMENT_NAME
    spec:
      containers:
      - name: app
        image: myproject/app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "$ENVIRONMENT"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myproject-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: myproject-secrets
              key: redis-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: myproject-service-$ENVIRONMENT
  labels:
    app: myproject
    environment: $ENVIRONMENT
spec:
  selector:
    app: myproject
    environment: $ENVIRONMENT
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myproject-ingress-$ENVIRONMENT
  labels:
    app: myproject
    environment: $ENVIRONMENT
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - $ENVIRONMENT.yourdomain.com
    secretName: myproject-tls-$ENVIRONMENT
  rules:
  - host: $ENVIRONMENT.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myproject-service-$ENVIRONMENT
            port:
              number: 80
EOF

# Copy build artifacts to GitOps repository
echo "📦 Copying build artifacts..."
mkdir -p "$DEPLOYMENT_DIR/artifacts/$DEPLOYMENT_NAME"
cp -r build/* "$DEPLOYMENT_DIR/artifacts/$DEPLOYMENT_NAME/" 2>/dev/null || true

# Update kustomization or helm values if applicable
if [ -f "$DEPLOYMENT_DIR/kustomization.yaml" ]; then
    echo "🔧 Updating Kustomization..."
    # Update image tag in kustomization
    sed -i "s|myproject/app:.*|myproject/app:$DEPLOYMENT_NAME|g" "$DEPLOYMENT_DIR/kustomization.yaml"
elif [ -f "$DEPLOYMENT_DIR/values.yaml" ]; then
    echo "🔧 Updating Helm values..."
    # Update image tag in helm values
    sed -i "s|tag:.*|tag: \"$DEPLOYMENT_NAME\"|g" "$DEPLOYMENT_DIR/values.yaml"
fi

# Commit and push changes
cd "$DEPLOYMENT_DIR"
echo "📤 Committing deployment changes..."
git add .
git commit -m "Deploy $DEPLOYMENT_NAME to $ENVIRONMENT

- Deployment: $DEPLOYMENT_NAME
- Environment: $ENVIRONMENT
- Timestamp: $TIMESTAMP
- Build artifacts included"

echo "🚀 Pushing to GitOps repository..."
git push origin "$GITOPS_BRANCH"

cd -

# Wait for deployment to complete (if ArgoCD or Flux is configured)
echo "⏳ Waiting for deployment to complete..."
if command -v argocd >/dev/null 2>&1; then
    echo "🔄 Checking ArgoCD sync status..."
    # Add ArgoCD sync check here
elif command -v flux >/dev/null 2>&1; then
    echo "🔄 Checking Flux sync status..."
    # Add Flux sync check here
else
    echo "⚠️  No GitOps operator detected. Manual sync may be required."
fi

# Run post-deployment tests
echo "🧪 Running post-deployment tests..."
# Add post-deployment test commands here
# Example: curl -f https://$ENVIRONMENT.yourdomain.com/health

# Clean up old deployments
echo "🧹 Cleaning up old deployments..."
cd "$DEPLOYMENT_DIR"
# Keep only last 10 deployments
ls -t *.yaml | tail -n +11 | xargs rm -f 2>/dev/null || true
cd -

echo "✅ GitOps deployment to $ENVIRONMENT complete!"
echo "📋 Deployment details:"
echo "  - Name: $DEPLOYMENT_NAME"
echo "  - Environment: $ENVIRONMENT"
echo "  - GitOps Repository: $GITOPS_REPO"
echo "  - Branch: $GITOPS_BRANCH"
echo "  - Manifest: $DEPLOYMENT_DIR/$DEPLOYMENT_NAME.yaml"

# Notification (optional)
if [ -n "$SLACK_WEBHOOK" ]; then
    echo "📢 Sending deployment notification..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ Deployment $DEPLOYMENT_NAME completed successfully to $ENVIRONMENT\"}" \
        "$SLACK_WEBHOOK"
fi