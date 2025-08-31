# Multi-stage Dockerfile optimized for build performance
# Uses Node.js 20 with Alpine for smaller image size

# =============================================================================
# DEPENDENCIES CACHE STAGE
# =============================================================================
FROM node:20-alpine AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files for dependency installation
COPY package*.json ./
# Install dependencies with cache mount for better performance
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production --no-audit --no-fund --prefer-offline

# =============================================================================
# BUILDER STAGE
# =============================================================================
FROM node:20-alpine AS builder
WORKDIR /app

# Copy package files and install all dependencies (including dev)
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund --prefer-offline

# Copy source code
COPY . .

# Build the application with cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm run build || echo "No build script found - skipping build step"

# =============================================================================
# PRODUCTION STAGE
# =============================================================================
FROM node:20-alpine AS production
WORKDIR /app

# Install security updates and required packages
RUN apk add --no-cache \
    dumb-init \
    curl \
    && apk upgrade --no-cache \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY --from=deps --chown=nodejs:nodejs /app/package*.json ./

# Copy production dependencies
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy built application
COPY --from=builder --chown=nodejs:nodejs /app/01_SRC ./01_SRC
COPY --from=builder --chown=nodejs:nodejs /app/03_BUILD ./03_BUILD
COPY --from=builder --chown=nodejs:nodejs /app/05_ASSETS ./05_ASSETS
COPY --from=builder --chown=nodejs:nodejs /app/06_CONFIG ./06_CONFIG

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Health check with proper configuration
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:$PORT/health || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]

# Default command
CMD ["npm", "start"]