/**
 * Example Node.js Application Entry Point
 *
 * This file demonstrates a well-structured Node.js application with:
 * - Proper error handling
 * - Environment configuration management
 * - Modular code organization
 * - Comprehensive logging
 * - Graceful shutdown handling
 */

const path = require('path');
const fs = require('fs').promises;
const express = require('express');

// =============================================================================
// LOGGING UTILITIES
// =============================================================================

/**
 * Simple logging abstraction with consistent formatting
 */
const logger = {
  info: (message, ...args) => console.log(`ℹ️  ${message}`, ...args),
  warn: (message, ...args) => console.warn(`⚠️ ${message}`, ...args),
  error: (message, ...args) => console.error(`❌ ${message}`, ...args),
  debug: (message, ...args) => console.debug(`🐛 ${message}`, ...args),
};

// Global configuration object
let appConfig = null;

/**
 * Check if a configuration value appears to contain sensitive information
 * @param {string} key - Configuration key
 * @param {string} value - Configuration value
 * @returns {boolean} True if value appears sensitive
 */
function isSensitiveValue(key, value) {
  const sensitiveKeys = ['password', 'secret', 'key', 'token', 'credential'];
  const sensitivePatterns = [
    /^[a-zA-Z0-9+/=]{10,}$/, // Base64-like
    /^[a-f0-9]{32,}$/i, // Hex hash
  ];

  const lowerKey = key.toLowerCase();
  const lowerValue = value.toLowerCase();

  // Check key name
  if (sensitiveKeys.some(sensitive => lowerKey.includes(sensitive))) {
    return true;
  }

  // Check value patterns
  if (sensitivePatterns.some(pattern => pattern.test(value))) {
    return true;
  }

  // Check for common secret indicators
  if (
    lowerValue.includes('secret') ||
    lowerValue.includes('password') ||
    lowerValue.includes('token') ||
    lowerValue.includes('key')
  ) {
    return true;
  }

  return false;
}

// =============================================================================
// EXPRESS SERVER SETUP
// =============================================================================

/**
 * Create and configure Express application
 */
function createServer() {
  const app = express();

  // Middleware for logging requests
  app.use((req, res, next) => {
    const timestamp = new Date().toISOString();
    logger.info(`[${timestamp}] ${req.method} ${req.url} - ${req.ip}`);
    next();
  });

  // Serve static files from project root directory
  app.use(express.static(path.join(__dirname, '..')));

  // Also serve src directory for backward compatibility
  app.use('/src', express.static(__dirname));

  // Specific routes for package.json and README.md
  app.get('/package.json', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'package.json'));
  });

  app.get('/README.md', (req, res) => {
    res.sendFile(path.join(__dirname, '..', 'README.md'));
  });

  // Update the log message to reflect the correct directory
  logger.info(`📁 Serving static files from: ${path.join(__dirname, '..')}`);

  // API endpoint for app info
  app.get('/api/info', (req, res) => {
    if (!appConfig) {
      return res.status(500).json({ error: 'Application not initialized' });
    }
    res.json(getAppInfo());
  });

  // Root route
  app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
  });

  // API endpoint for greeting
  app.get('/api/greet/:name', (req, res) => {
    try {
      const { name } = req.params;
      const appName = req.query.appName || 'Project Template';
      const greeting = greet(name, appName);
      res.json({ greeting });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  });

  return app;
}

// Load configuration and create app
if (process.env.NODE_ENV !== 'test') {
  (async () => {
    appConfig = await loadConfiguration();
    logStartupInfo();
  })();
}
const app = createServer();

/**
 * Initialize the application by loading configuration and logging startup info
 * @returns {Promise<void>}
 */
async function initialize() {
  try {
    appConfig = await loadConfiguration();
    logStartupInfo();
  } catch (error) {
    logger.error('❌ Application initialization failed:', error.message);
    process.exit(1);
  }
}

// =============================================================================
// CONFIGURATION MANAGEMENT
// =============================================================================

/**
 * Load and validate environment configuration
 * @returns {Object} Configuration object
 */
async function loadConfiguration() {
  // Resolve the .env file path relative to the project root
  const envPath = path.resolve(__dirname, '../.env');

  // Check if .env file exists
  try {
    await fs.access(envPath);
  } catch {
    logger.warn('.env file not found. Using default configuration.');
    return getDefaultConfig();
  }

  // Load environment variables with error handling
  let dotenvConfig;
  try {
    dotenvConfig = require('dotenv').config({ path: envPath });
    if (dotenvConfig.error) {
      throw dotenvConfig.error;
    }
  } catch (error) {
    throw new Error(`Failed to load configuration: ${error.message}`);
  }

  try {
    // Validate and parse environment variables
    const appName = process.env.APP_NAME ?? 'Project Template';
    if (typeof appName !== 'string' || appName.trim().length === 0) {
      throw new Error('APP_NAME must be a non-empty string');
    }

    const appVersion = process.env.APP_VERSION || '1.0.0';
    if (!/^\d+\.\d+\.\d+$/.test(appVersion)) {
      throw new Error(
        'APP_VERSION must be in semantic version format (e.g., 1.0.0)'
      );
    }

    const environment = process.env.NODE_ENV || 'development';
    const validEnvs = ['development', 'production', 'test'];
    if (!validEnvs.includes(environment)) {
      throw new Error(`NODE_ENV must be one of: ${validEnvs.join(', ')}`);
    }

    const portStr = process.env.PORT;
    let port = 3000;
    if (portStr) {
      const parsedPort = parseInt(portStr, 10);
      if (isNaN(parsedPort) || parsedPort < 1 || parsedPort > 65535) {
        throw new Error('PORT must be a valid number between 1 and 65535');
      }
      port = parsedPort;
    }

    const debug = process.env.DEBUG === 'true';

    const config = {
      appName: appName.trim(),
      appVersion,
      environment,
      port,
      debug,
    };

    // Check for sensitive information in configuration
    for (const [key, value] of Object.entries(process.env)) {
      if (isSensitiveValue(key, value)) {
        logger.warn(
          `⚠️  Potential sensitive information detected in environment variable: ${key}`
        );
        logger.warn(
          'Consider using secure vaults or encrypted storage for sensitive data.'
        );
      }
    }

    return config;
  } catch (error) {
    logger.error('Failed to load configuration:', error.message);
    return getDefaultConfig();
  }
}

/**
 * Get default configuration values
 * @returns {Object} Default configuration
 */
function getDefaultConfig() {
  return {
    appName: 'Project Template',
    appVersion: '1.0.0',
    environment: 'development',
    port: 3000,
    debug: false,
  };
}

// =============================================================================
// BUSINESS LOGIC
// =============================================================================

/**
 * Get comprehensive application information
 * @returns {Object} Application info including runtime details
 */
function getAppInfo() {
  if (!appConfig) {
    throw new TypeError(
      'Application not initialized. Call initialize() first.'
    );
  }

  return {
    name: appConfig.appName,
    version: appConfig.appVersion,
    environment: appConfig.environment,
    port: appConfig.port,
    debug: appConfig.debug,
    uptime: process.uptime(),
    nodeVersion: process.version,
    platform: process.platform,
  };
}

/**
 * Generate a personalized greeting message
 * @param {string} name - The name to greet
 * @param {string} [appName='Project Template'] - The app name for the greeting
 * @returns {string} Greeting message
 */
function greet(name, appName = 'Project Template') {
  if (typeof name !== 'string') {
    throw new Error('Name must be a non-empty string');
  }
  const trimmed = name.trim();
  if (!trimmed) {
    throw new Error('Name cannot be empty after trimming');
  }
  if (trimmed.length > 50) {
    throw new Error(
      `Name must be between 1 and 50 characters (received ${trimmed.length})`
    );
  }
  if (!/^[a-zA-Z\s\-']+$/.test(trimmed)) {
    throw new Error(
      'Name can only contain letters, spaces, hyphens, and apostrophes'
    );
  }
  return `Hello, ${trimmed}! Welcome to ${appName}`;
}

/**
 * Log detailed application startup information
 */
function logStartupInfo() {
  if (!appConfig) {
    logger.warn('Cannot log startup info: configuration not loaded');
    return;
  }

  logger.info('🚀 Starting Node.js application...');
  logger.info(`📱 App: ${appConfig.appName} v${appConfig.appVersion}`);
  logger.info(`🌍 Environment: ${appConfig.environment}`);
  logger.info(`🔧 Node.js: ${process.version}`);
  logger.info(`📂 Platform: ${process.platform}`);
  logger.info(`🚪 Port: ${appConfig.port}`);

  if (appConfig.debug) {
    logger.debug('🐛 Debug mode enabled');
  }
}

// =============================================================================
// MAIN APPLICATION LOGIC
// =============================================================================

/**
 * Graceful shutdown handler
 */
function gracefulShutdown() {
  logger.info('Received shutdown signal. Cleaning up...');

  // Perform cleanup operations
  const cleanupPromises = [];

  // Example: Clear any timers
  if (global.gc && typeof global.gc === 'function') {
    // Force garbage collection if available (not recommended in production)
    global.gc();
  }

  // Example: Close any open file handles or connections
  // In a real app, close database connections, HTTP servers, etc.
  // For now, simulate async cleanup
  cleanupPromises.push(
    new Promise(resolve => {
      setTimeout(() => {
        logger.info('Simulated cleanup of resources completed');
        resolve();
      }, 100);
    })
  );

  // Wait for all cleanup to complete
  Promise.all(cleanupPromises)
    .then(() => {
      logger.info('Cleanup completed. Exiting...');
      process.exit(0);
    })
    .catch(error => {
      logger.error('Error during cleanup:', error);
      process.exit(1);
    });
}

/**
 * Sanitize input string by removing potentially harmful content
 * @param {string} input - The input string to sanitize
 * @param {Object} [options] - Sanitization options
 * @param {boolean} [options.stripHtml=false] - Whether to strip HTML tags
 * @param {number} [options.maxLength] - Maximum length of the output
 * @returns {string} Sanitized string
 */
function sanitizeInput(input, options = {}) {
  if (typeof input !== 'string') {
    throw new Error('Input must be a string');
  }

  let sanitized = input.trim();

  // Remove null bytes and control characters
  sanitized = sanitized.replace(/\0/g, '').replace(String.fromCharCode(31), '');

  // Remove script tags
  sanitized = sanitized.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '');

  // Strip HTML if requested
  if (options.stripHtml) {
    sanitized = sanitized.replace(/<[^>]*>/g, '');
  }

  // Limit length if specified
  if (options.maxLength && sanitized.length > options.maxLength) {
    sanitized = sanitized.substring(0, options.maxLength);
  }

  return sanitized;
}

/**
 * Rate limiter class to control request frequency per identifier
 */
class RateLimiter {
  /**
   * @param {number} windowMs - Time window in milliseconds
   * @param {number} maxRequests - Maximum requests allowed in the window
   */
  constructor(windowMs = 900000, maxRequests = 100) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    this.requests = new Map();
  }

  /**
   * Check if a request is allowed for the given identifier
   * @param {string} identifier - Unique identifier (e.g., IP address, user ID)
   * @returns {boolean} True if request is allowed
   */
  isAllowed(identifier) {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    if (!this.requests.has(identifier)) {
      this.requests.set(identifier, []);
    }

    const userRequests = this.requests.get(identifier);

    // Remove old requests outside the window
    const validRequests = userRequests.filter(time => time > windowStart);
    this.requests.set(identifier, validRequests);

    if (validRequests.length >= this.maxRequests) {
      return false;
    }

    // Add current request
    validRequests.push(now);
    return true;
  }

  /**
   * Get the number of remaining requests for the identifier
   * @param {string} identifier - Unique identifier
   * @returns {number} Number of remaining requests
   */
  getRemainingRequests(identifier) {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    if (!this.requests.has(identifier)) {
      return this.maxRequests;
    }

    const userRequests = this.requests.get(identifier);
    const validRequests = userRequests.filter(time => time > windowStart);

    return Math.max(0, this.maxRequests - validRequests.length);
  }
}

// =============================================================================
// APPLICATION ENTRY POINT
// =============================================================================

// Handle uncaught exceptions
process.on('uncaughtException', error => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Handle shutdown signals
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
  app,
  greet,
  getAppInfo,
  loadConfiguration,
  isSensitiveValue,
  initialize,
  sanitizeInput,
  RateLimiter,
};
