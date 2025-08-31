/**
 * Example TypeScript Application Entry Point
 *
 * This file demonstrates a well-structured TypeScript application with:
 * - Strong typing and type safety
 * - Proper error handling
 * - Environment configuration management
 * - Modular code organization
 * - Comprehensive logging
 * - Graceful shutdown handling
 */

import * as path from 'path';
import * as fs from 'fs/promises';

// =============================================================================
// TYPE DEFINITIONS
// =============================================================================

interface AppConfig {
    appName: string;
    appVersion: string;
    environment: string;
    port: number;
    debug: boolean;
}

interface AppInfo {
    name: string;
    version: string;
    environment: string;
    uptime: number;
    nodeVersion: string;
    platform: string;
}

class ConfigurationError extends Error {
    constructor(message: string, public readonly cause?: Error) {
        super(message);
        this.name = 'ConfigurationError';
    }
}

class ValidationError extends Error {
    constructor(message: string, public readonly field: string) {
        super(message);
        this.name = 'ValidationError';
    }
}

// =============================================================================
// CONFIGURATION MANAGEMENT
// =============================================================================

/**
 * Load and validate environment configuration
 * @returns Promise<AppConfig> Configuration object
 */
async function loadConfiguration(): Promise<AppConfig> {
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

        const config: AppConfig = {
            appName: process.env.APP_NAME || 'Project Template',
            appVersion: process.env.APP_VERSION || '1.0.0',
            environment: process.env.NODE_ENV || 'development',
            port: parseInt(process.env.PORT || '3000', 10),
            debug: process.env.DEBUG === 'true'
        };

        // Validate configuration
        validateConfig(config);

        return config;
    } catch (error) {
        if (error instanceof ConfigurationError) {
            throw error;
        }
        throw new ConfigurationError(`Failed to load configuration: ${error}`, error as Error);
    }
}

/**
 * Validate configuration object
 * @param config Configuration to validate
 * @throws ValidationError if validation fails
 */
function validateConfig(config: AppConfig): void {
    if (!config.appName.trim()) {
        throw new ValidationError('App name cannot be empty', 'appName');
    }

    if (config.port < 1 || config.port > 65535) {
        throw new ValidationError('Port must be between 1 and 65535', 'port');
    }

    const validEnvironments = ['development', 'staging', 'production'];
    if (!validEnvironments.includes(config.environment)) {
        throw new ValidationError(`Environment must be one of: ${validEnvironments.join(', ')}`, 'environment');
    }
}

/**
 * Get default configuration values
 * @returns Default configuration
 */
function getDefaultConfig(): AppConfig {
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
 * Service for generating personalized greetings
 */
class GreetingService {
    constructor(private config: AppConfig) {}

    /**
     * Generate a personalized greeting message
     * @param name The name to greet
     * @returns Greeting message
     * @throws ValidationError if name is invalid
     */
    public greet(name: string): string {
        this.validateName(name);

        const trimmedName = name.trim();
        const greeting = `Hello, ${trimmedName}! Welcome to ${this.config.appName}`;

        if (this.config.debug) {
            console.log(`Generated greeting for: ${trimmedName}`);
        }

        return greeting;
    }

    /**
     * Generate greetings for multiple names
     * @param names Array of names to greet
     * @returns Array of greeting messages
     */
    public getMultipleGreetings(names: string[]): string[] {
        return names.map(name => this.greet(name));
    }

    /**
     * Validate name input
     * @param name Name to validate
     * @throws ValidationError if validation fails
     */
    private validateName(name: string): void {
        if (!name || typeof name !== 'string') {
            throw new ValidationError('Name must be a non-empty string', 'name');
        }

        const trimmedName = name.trim();
        if (!trimmedName) {
            throw new ValidationError('Name cannot be empty after trimming', 'name');
        }

        if (trimmedName.length > 100) {
            throw new ValidationError('Name cannot be longer than 100 characters', 'name');
        }
    }
}

/**
 * Service for retrieving application information
 */
class AppInfoService {
    constructor(private config: AppConfig) {}

    /**
     * Get comprehensive application information
     * @returns Application information object
     */
    public getAppInfo(): AppInfo {
        return {
            name: this.config.appName,
            version: this.config.appVersion,
            environment: this.config.environment,
            uptime: process.uptime(),
            nodeVersion: process.version,
            platform: process.platform
        };
    }
}

// =============================================================================
// MAIN APPLICATION LOGIC
// =============================================================================

let config: AppConfig | null = null;
let greetingService: GreetingService | null = null;
let appInfoService: AppInfoService | null = null;

/**
 * Initialize the application
 */
async function initialize(): Promise<void> {
    try {
        // Load configuration
        config = await loadConfiguration();

        // Initialize services
        greetingService = new GreetingService(config);
        appInfoService = new AppInfoService(config);

        // Log startup information
        logStartupInfo();

        // Example usage
        console.log('\n📝 Example Usage:');
        console.log(greetingService.greet('Developer'));
        console.log(greetingService.greet('TypeScript User'));

        // Multiple greetings example
        const names = ['Alice', 'Bob', 'Charlie'];
        const greetings = greetingService.getMultipleGreetings(names);
        console.log('\n👥 Multiple Greetings:');
        greetings.forEach(greeting => console.log(`  ${greeting}`));

        // Display app info
        if (appInfoService) {
            const appInfo = appInfoService.getAppInfo();
            console.log('\n📊 Application Info:');
            Object.entries(appInfo).forEach(([key, value]) => {
                console.log(`  ${key}: ${value}`);
            });
        }

        console.log('\n✅ Application initialized successfully!');

    } catch (error) {
        if (error instanceof ValidationError) {
            console.error(`❌ Validation Error [${error.field}]:`, error.message);
        } else if (error instanceof ConfigurationError) {
            console.error('❌ Configuration Error:', error.message);
        } else {
            console.error('❌ Application initialization failed:', error);
        }
        process.exit(1);
    }
}

/**
 * Log application startup information
 */
function logStartupInfo(): void {
    if (!config) return;

    console.log('🚀 Starting TypeScript application...');
    console.log(`📱 App: ${config.appName} v${config.appVersion}`);
    console.log(`🌍 Environment: ${config.environment}`);
    console.log(`🔧 Node.js: ${process.version}`);
    console.log(`📂 Platform: ${process.platform}`);

    if (config.debug) {
        console.log('🐛 Debug mode enabled');
    }
}

/**
 * Graceful shutdown handler
 */
function gracefulShutdown(): void {
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
process.on('uncaughtException', (error: Error) => {
    console.error('💥 Uncaught Exception:', error.message);
    process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason: any, promise: Promise<any>) => {
    console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Handle shutdown signals
process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);

// Start the application
if (require.main === module) {
    initialize().catch((error: Error) => {
        console.error('💥 Failed to start application:', error.message);
        process.exit(1);
    });
}

// =============================================================================
// EXPORTS
// =============================================================================

export {
    AppConfig,
    AppInfo,
    ConfigurationError,
    ValidationError,
    GreetingService,
    AppInfoService,
    loadConfiguration,
    initialize
};