/**
 * Vercel Serverless Function Entry Point
 *
 * This file demonstrates a well-structured serverless function with:
 * - Proper error handling
 * - Environment configuration management
 * - Modular code organization
 * - Comprehensive logging
 * - Serverless-compatible design
 */

const path = require('path');
const fs = require('fs');
const dotenv = require('dotenv');
const url = require('url');

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

// =============================================================================
// CONFIGURATION MANAGEMENT
// =============================================================================

/**
 * Load and validate environment configuration synchronously
 * @returns {Object} Configuration object
 */
function loadConfiguration() {
  // Check if running in CI environment
  const isCI =
    process.env.NODE_ENV === 'production' || process.env.CI === 'true';

  if (isCI) {
    logger.info(
      '🔧 Running in CI environment. Using environment variables directly.'
    );
  } else {
    // Resolve the .env file path relative to the current working directory
    const envPath = path.resolve(process.cwd(), '.env');

    // Check if .env file exists and load it
    try {
      fs.accessSync(envPath, fs.constants.R_OK);
      logger.info(`📄 Loading configuration from: ${envPath}`);

      // Load environment variables with error handling
      const dotenvConfig = dotenv.config({ path: envPath });
      if (dotenvConfig.error) {
        throw new Error(
          `Failed to load configuration: ${dotenvConfig.error.message}`
        );
      } else {
        logger.info('✅ .env file loaded successfully.');
      }
    } catch (error) {
      if (
        error.message &&
        error.message.includes('Failed to load configuration')
      ) {
        throw error;
      } else {
        logger.warn('.env file not found. Using default configuration.');
      }
    }
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
    if (error.message.includes('Failed to load configuration')) {
      throw error;
    } else {
      logger.error('Failed to load configuration:', error.message);
      return {
        appName: 'Project Template',
        appVersion: '1.0.0',
        environment: 'development',
        port: 3000,
        debug: false,
      };
    }
  }
}

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

// Load configuration synchronously at startup
const appConfig = loadConfiguration();

// =============================================================================
// BUSINESS LOGIC
// =============================================================================

/**
 * Get comprehensive application information
 * @returns {Object} Application info including runtime details
 */
function getAppInfo() {
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
 * Sanitize input string by removing harmful characters and applying options
 * @param {string} input - The input string to sanitize
 * @param {Object} [options={}] - Sanitization options
 * @param {boolean} [options.stripHtml=false] - Whether to strip HTML tags
 * @param {number} [options.maxLength] - Maximum length of the sanitized string
 * @returns {string} Sanitized string
 */
function sanitizeInput(input, options = {}) {
  if (typeof input !== 'string') {
    throw new Error('Input must be a string');
  }

  let sanitized = input;

  // Remove null bytes and control characters
  sanitized = sanitized
    .split('')
    .filter(char => {
      const code = char.charCodeAt(0);
      return code >= 32 && (code < 127 || code > 159);
    })
    .join('');

  // Remove script tags
  sanitized = sanitized.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '');

  // Strip HTML if option is true
  if (options.stripHtml) {
    sanitized = sanitized.replace(/<[^>]*>/g, '');
  }

  // Trim
  sanitized = sanitized.trim();

  // Remove some chars if not stripping HTML
  if (!options.stripHtml) {
    sanitized = sanitized.replace(/[<>"'&]/g, '');
  }

  // Limit length
  if (
    options.maxLength &&
    typeof options.maxLength === 'number' &&
    options.maxLength > 0
  ) {
    sanitized = sanitized.slice(0, options.maxLength);
  }

  return sanitized;
}

// =============================================================================
// SERVERLESS HANDLER
// =============================================================================

/**
 * Vercel serverless function handler
 * @param {Object} req - Request object
 * @param {Object} res - Response object
 */
function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Log request
  const timestamp = new Date().toISOString();
  logger.info(
    `[${timestamp}] ${req.method} ${req.url} - ${req.headers['x-forwarded-for'] || req.connection.remoteAddress}`
  );

  try {
    const parsedUrl = url.parse(req.url, true);
    const { pathname, query } = parsedUrl;

    if (req.method === 'GET') {
      if (pathname === '/') {
        // Serve index.html
        const filePath = path.join(__dirname, 'index.html');
        try {
          const content = fs.readFileSync(filePath, 'utf8');
          res.setHeader('Content-Type', 'text/html');
          res.status(200).send(content);
        } catch (err) {
          logger.error('Error reading index.html:', err.message);
          res.status(404).json({ error: 'File not found' });
        }
      } else if (pathname === '/package.json') {
        // Serve package.json
        const filePath = path.join(__dirname, '..', 'package.json');
        try {
          const content = fs.readFileSync(filePath, 'utf8');
          res.setHeader('Content-Type', 'application/json');
          res.status(200).send(content);
        } catch (err) {
          logger.error('Error reading package.json:', err.message);
          res.status(404).json({ error: 'File not found' });
        }
      } else if (pathname === '/README.md') {
        // Serve README.md
        const filePath = path.join(__dirname, '..', 'README.md');
        try {
          const content = fs.readFileSync(filePath, 'utf8');
          res.setHeader('Content-Type', 'text/markdown');
          res.status(200).send(content);
        } catch (err) {
          logger.error('Error reading README.md:', err.message);
          res.status(404).json({ error: 'File not found' });
        }
      } else if (pathname === '/api/info') {
        // API endpoint for app info
        const info = getAppInfo();
        res.json(info);
      } else if (pathname.startsWith('/api/greet/')) {
        // API endpoint for greeting
        const [, name] = pathname.split('/api/greet/');
        if (!name) {
          res.status(400).json({ error: 'Name parameter is required' });
          return;
        }
        try {
          const appName = query.appName || 'Project Template';
          const greeting = greet(name, appName);
          res.json({ greeting });
        } catch (err) {
          res.status(400).json({ error: err.message });
        }
      } else if (pathname === '/api/health') {
        // Health check endpoint
        res.json({ status: 'ok', timestamp: new Date().toISOString() });
      } else if (pathname === '/api/config') {
        // Config endpoint (without sensitive info)
        res.json({
          appName: appConfig.appName,
          appVersion: appConfig.appVersion,
          environment: appConfig.environment,
          debug: appConfig.debug,
        });
      } else {
        res.status(404).json({ error: 'Not found' });
      }
    } else {
      res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (err) {
    logger.error('Handler error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = handler;

module.exports.greet = greet;
module.exports.sanitizeInput = sanitizeInput;
module.exports.isSensitiveValue = isSensitiveValue;
module.exports.getAppInfo = getAppInfo;
