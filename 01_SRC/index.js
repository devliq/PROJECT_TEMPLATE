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

const path = require("path");
const fs = require("fs").promises;

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
 * Sanitize user input to prevent injection attacks
 * @param {string} input - Input string to sanitize
 * @param {Object} options - Sanitization options
 * @returns {string} Sanitized input
 */
function sanitizeInput(input, options = {}) {
  if (typeof input !== "string") {
    throw new Error("Input must be a string");
  }

  let sanitized = input.trim();

  // Remove null bytes and control characters
  sanitized = [...sanitized]
    .filter((char) => {
      const code = char.charCodeAt(0);
      return code >= 32 && code !== 127; // Keep printable characters only
    })
    .join("");

  // Remove potential script tags (safer version to avoid ReDoS)
  sanitized = sanitized.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "");

  // Remove HTML tags if specified
  if (options.stripHtml) {
    sanitized = sanitized.replace(/<[^>]*>/g, "");
  }

  // Limit length
  if (options.maxLength && sanitized.length > options.maxLength) {
    sanitized = sanitized.substring(0, options.maxLength);
  }

  return sanitized;
}

/**
 * Check if a configuration value appears to contain sensitive information
 * @param {string} key - Configuration key
 * @param {string} value - Configuration value
 * @returns {boolean} True if value appears sensitive
 */
function isSensitiveValue(key, value) {
  const sensitiveKeys = ["password", "secret", "key", "token", "credential"];
  const sensitivePatterns = [
    /^[a-zA-Z0-9+/=]{10,}$/, // Base64-like
    /^[a-f0-9]{32,}$/i, // Hex hash
  ];

  const lowerKey = key.toLowerCase();
  const lowerValue = value.toLowerCase();

  // Check key name
  if (sensitiveKeys.some((sensitive) => lowerKey.includes(sensitive))) {
    return true;
  }

  // Check value patterns
  if (sensitivePatterns.some((pattern) => pattern.test(value))) {
    return true;
  }

  // Check for common secret indicators
  if (
    lowerValue.includes("secret") ||
    lowerValue.includes("password") ||
    lowerValue.includes("token") ||
    lowerValue.includes("key")
  ) {
    return true;
  }

  return false;
}

/**
 * Simple in-memory rate limiter
 */
class RateLimiter {
  constructor(windowMs = 900000, maxRequests = 100) {
    // 15 minutes, 100 requests
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    this.requests = new Map();
  }

  /**
   * Check if request is allowed
   * @param {string} identifier - Unique identifier (e.g., IP address)
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
    const validRequests = userRequests.filter((time) => time > windowStart);
    this.requests.set(identifier, validRequests);

    if (validRequests.length >= this.maxRequests) {
      return false;
    }

    // Add current request
    validRequests.push(now);
    return true;
  }

  /**
   * Get remaining requests for identifier
   * @param {string} identifier - Unique identifier
   * @returns {number} Remaining requests
   */
  getRemainingRequests(identifier) {
    const now = Date.now();
    const windowStart = now - this.windowMs;

    if (!this.requests.has(identifier)) {
      return this.maxRequests;
    }

    const userRequests = this.requests.get(identifier);
    const validRequests = userRequests.filter((time) => time > windowStart);

    return Math.max(0, this.maxRequests - validRequests.length);
  }
}

// Global rate limiter instance
const rateLimiter = new RateLimiter();

// =============================================================================
// CONFIGURATION MANAGEMENT
// =============================================================================

/**
 * Load and validate environment configuration
 * @returns {Object} Configuration object
 */
async function loadConfiguration() {
  // Resolve the .env file path relative to the project root
  const envPath = path.resolve(__dirname, "../06_CONFIG/.env");

  // Check if .env file exists
  try {
    await fs.access(envPath);
  } catch {
    logger.warn(".env file not found. Using default configuration.");
    return getDefaultConfig();
  }

  // Load environment variables with error handling
  let dotenvConfig;
  try {
    dotenvConfig = require("dotenv").config({ path: envPath });
    if (dotenvConfig.error) {
      throw dotenvConfig.error;
    }
  } catch (error) {
    throw new Error(`Failed to load configuration: ${error.message}`);
  }

  try {
    // Validate and parse environment variables
    const appName = process.env.APP_NAME ?? "Project Template";
    if (typeof appName !== "string" || appName.trim().length === 0) {
      throw new Error("APP_NAME must be a non-empty string");
    }

    const appVersion = process.env.APP_VERSION || "1.0.0";
    if (!/^\d+\.\d+\.\d+$/.test(appVersion)) {
      throw new Error("APP_VERSION must be in semantic version format (e.g., 1.0.0)");
    }

    const environment = process.env.NODE_ENV || "development";
    const validEnvs = ["development", "production", "test"];
    if (!validEnvs.includes(environment)) {
      throw new Error(`NODE_ENV must be one of: ${validEnvs.join(", ")}`);
    }

    const portStr = process.env.PORT;
    let port = 3000;
    if (portStr) {
      const parsedPort = parseInt(portStr, 10);
      if (isNaN(parsedPort) || parsedPort < 1 || parsedPort > 65535) {
        throw new Error("PORT must be a valid number between 1 and 65535");
      }
      port = parsedPort;
    }

    const debug = process.env.DEBUG === "true";

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
        logger.warn(`⚠️  Potential sensitive information detected in environment variable: ${key}`);
        logger.warn("Consider using secure vaults or encrypted storage for sensitive data.");
      }
    }

    return config;
  } catch (error) {
    logger.error("Failed to load configuration:", error.message);
    return getDefaultConfig();
  }
}

/**
 * Get default configuration values
 * @returns {Object} Default configuration
 */
function getDefaultConfig() {
  return {
    appName: "Project Template",
    appVersion: "1.0.0",
    environment: "development",
    port: 3000,
    debug: false,
  };
}

// =============================================================================
// BUSINESS LOGIC
// =============================================================================

/**
 * Generate a personalized greeting message with validation
 * @param {string} name - The name to greet (must be 1-50 chars, letters/spaces/hyphens/apostrophes only)
 * @param {string} [appName="Project Template"] - The application name to reference in greeting
 * @returns {string} Formatted greeting message
 * @throws {Error} If name validation fails
 */
function greet(name, appName = "Project Template") {
  // Input validation
  if (typeof name !== "string") {
    throw new Error("Name must be a non-empty string");
  }

  const trimmedName = name.trim();
  if (trimmedName.length === 0) {
    throw new Error("Name cannot be empty after trimming whitespace");
  }

  // Rate limiting check
  const identifier = "greet_function"; // In a real app, use IP or user ID
  if (!rateLimiter.isAllowed(identifier)) {
    throw new Error("Rate limit exceeded. Please try again later.");
  }

  // Length validation
  if (trimmedName.length < 1 || trimmedName.length > 50) {
    throw new Error(`Name must be between 1 and 50 characters (received ${trimmedName.length})`);
  }

  // Input sanitization
  const sanitizedName = sanitizeInput(trimmedName, { stripHtml: true });

  // Character validation - only allow letters, spaces, hyphens, and apostrophes
  if (!/^[a-zA-Z\s\-']+$/.test(sanitizedName)) {
    throw new Error("Name can only contain letters, spaces, hyphens, and apostrophes");
  }

  return `Hello, ${sanitizedName}! Welcome to ${appName}`;
}

/**
 * Get comprehensive application information
 * @returns {Object} Application info including runtime details
 */
function getAppInfo() {
  if (!appConfig) {
    throw new Error("Application not initialized. Call initialize() first.");
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
 * Log detailed application startup information
 */
function logStartupInfo() {
  if (!appConfig) {
    logger.warn("Cannot log startup info: configuration not loaded");
    return;
  }

  logger.info("🚀 Starting Node.js application...");
  logger.info(`📱 App: ${appConfig.appName} v${appConfig.appVersion}`);
  logger.info(`🌍 Environment: ${appConfig.environment}`);
  logger.info(`🔧 Node.js: ${process.version}`);
  logger.info(`📂 Platform: ${process.platform}`);
  logger.info(`🚪 Port: ${appConfig.port}`);

  if (appConfig.debug) {
    logger.debug("🐛 Debug mode enabled");
  }
}

// =============================================================================
// MAIN APPLICATION LOGIC
// =============================================================================

/**
 * Initialize the application with configuration and services
 * @returns {Promise<void>}
 */
async function initialize() {
  try {
    // Load and validate configuration
    appConfig = await loadConfiguration();

    // Log startup information
    logStartupInfo();

    // Demonstrate core functionality
    logger.info("\n📝 Example Usage:");
    logger.info(greet("Developer", appConfig.appName));
    logger.info(greet("World", appConfig.appName));

    // Display comprehensive app information
    const appInfo = getAppInfo();
    logger.info("\n📊 Application Info:");
    logger.info(JSON.stringify(appInfo, null, 2));

    logger.info("\n✅ Application initialized successfully!");
  } catch (error) {
    logger.error("❌ Application initialization failed:", error.message);
    process.exit(1);
  }
}

/**
 * Graceful shutdown handler
 */
function gracefulShutdown() {
  logger.info("Received shutdown signal. Cleaning up...");

  // Perform cleanup operations
  const cleanupPromises = [];

  // Example: Clear any timers
  if (global.gc && typeof global.gc === "function") {
    // Force garbage collection if available (not recommended in production)
    global.gc();
  }

  // Example: Close any open file handles or connections
  // In a real app, close database connections, HTTP servers, etc.
  // For now, simulate async cleanup
  cleanupPromises.push(
    new Promise((resolve) => {
      setTimeout(() => {
        logger.info("Simulated cleanup of resources completed");
        resolve();
      }, 100);
    }),
  );

  // Wait for all cleanup to complete
  Promise.all(cleanupPromises)
    .then(() => {
      logger.info("Cleanup completed. Exiting...");
      process.exit(0);
    })
    .catch((error) => {
      logger.error("Error during cleanup:", error);
      process.exit(1);
    });
}

// =============================================================================
// APPLICATION ENTRY POINT
// =============================================================================

// Handle uncaught exceptions
process.on("uncaughtException", (error) => {
  logger.error("Uncaught Exception:", error);
  process.exit(1);
});

// Handle unhandled promise rejections
process.on("unhandledRejection", (reason, promise) => {
  logger.error("Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});

// Handle shutdown signals
process.on("SIGINT", gracefulShutdown);
process.on("SIGTERM", gracefulShutdown);

// Start the application
if (require.main === module) {
  initialize().catch((error) => {
    logger.error("Failed to start application:", error);
    process.exit(1);
  });
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
  greet,
  getAppInfo,
  loadConfiguration,
  initialize,
  sanitizeInput,
  isSensitiveValue,
  RateLimiter,
};
