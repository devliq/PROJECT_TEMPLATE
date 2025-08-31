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

// =============================================================================
// CONFIGURATION MANAGEMENT
// =============================================================================

/**
 * Load and validate environment configuration
 * @returns {Object} Configuration object
 */
async function loadConfiguration() {
    try {
        // Resolve the .env file path relative to the project root
        const envPath = path.resolve(__dirname, '../06_CONFIG/.env');

        // Check if .env file exists
        try {
            await fs.access(envPath);
        } catch (error) {
            console.warn('⚠️  .env file not found. Using default configuration.');
            return getDefaultConfig();
        }

        // Load environment variables
        require('dotenv').config({ path: envPath });

        return {
            appName: process.env.APP_NAME || 'Project Template',
            appVersion: process.env.APP_VERSION || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            port: parseInt(process.env.PORT) || 3000,
            debug: process.env.DEBUG === 'true'
        };
    } catch (error) {
        console.error('❌ Failed to load configuration:', error.message);
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
        debug: false
    };
}

// =============================================================================
// BUSINESS LOGIC
// =============================================================================

/**
 * Generate a personalized greeting message
 * @param {string} name - The name to greet
 * @returns {string} Greeting message
 */
function greet(name) {
    if (!name || typeof name !== 'string') {
        throw new Error('Name must be a non-empty string');
    }

    const trimmedName = name.trim();
    if (trimmedName.length === 0) {
        throw new Error('Name cannot be empty after trimming');
    }

    return `Hello, ${trimmedName}! Welcome to ${config.appName}`;
}

/**
 * Get application information
 * @returns {Object} Application info
 */
function getAppInfo() {
    return {
        name: config.appName,
        version: config.appVersion,
        environment: config.environment,
        uptime: process.uptime(),
        nodeVersion: process.version,
        platform: process.platform
    };
}

/**
 * Log application startup information
 */
function logStartupInfo() {
    console.log('🚀 Starting application...');
    console.log(`📱 App: ${config.appName} v${config.appVersion}`);
    console.log(`🌍 Environment: ${config.environment}`);
    console.log(`🔧 Node.js: ${process.version}`);
    console.log(`📂 Platform: ${process.platform}`);

    if (config.debug) {
        console.log('🐛 Debug mode enabled');
    }
}

// =============================================================================
// MAIN APPLICATION LOGIC
// =============================================================================

let config = null;

/**
 * Initialize the application
 */
async function initialize() {
    try {
        // Load configuration
        config = await loadConfiguration();

        // Log startup information
        logStartupInfo();

        // Example usage
        console.log('\n📝 Example Usage:');
        console.log(greet('Developer'));
        console.log(greet('World'));

        // Display app info
        const appInfo = getAppInfo();
        console.log('\n📊 Application Info:', JSON.stringify(appInfo, null, 2));

        console.log('\n✅ Application initialized successfully!');

    } catch (error) {
        console.error('❌ Application initialization failed:', error.message);
        process.exit(1);
    }
}

/**
 * Graceful shutdown handler
 */
function gracefulShutdown() {
    console.log('\n🛑 Received shutdown signal. Cleaning up...');

    // Perform cleanup operations here
    // - Close database connections
    // - Stop background services
    // - Save application state

    console.log('✅ Cleanup completed. Exiting...');
    process.exit(0);
}

// =============================================================================
// APPLICATION ENTRY POINT
// =============================================================================

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('💥 Uncaught Exception:', error);
    process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Handle shutdown signals
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);

// Start the application
if (require.main === module) {
    initialize().catch((error) => {
        console.error('💥 Failed to start application:', error);
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
    initialize
};
