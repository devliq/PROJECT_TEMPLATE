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

import * as path from "path";
import * as fs from "fs/promises";
import * as dotenv from "dotenv";

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
  constructor(
    message: string,
    public readonly cause?: Error,
  ) {
    super(message);
    this.name = "ConfigurationError";
    // Use the cause parameter to avoid ESLint warning
    if (cause) {
      this.cause = cause;
    }
  }
}

class ValidationError extends Error {
  constructor(
    message: string,
    public readonly field: string,
  ) {
    super(message);
    this.name = "ValidationError";
    // Use the field parameter to avoid ESLint warning
    this.field = field;
  }
}

/**
 * Logger service for application logging
 */
class Logger {
  constructor(private debugMode: boolean = false) {}

  info(message: string): void {
    console.log(message);
  }

  warn(message: string): void {
    console.warn(message);
  }

  error(message: string): void {
    console.error(message);
  }

  debug(message: string): void {
    if (this.debugMode) {
      console.debug(message);
    }
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
    const envPath = path.resolve(__dirname, "../06_CONFIG/.env");

    // Check if .env file exists
    try {
      await fs.access(envPath);
    } catch {
      console.warn("⚠️  .env file not found. Using default configuration.");
      return getDefaultConfig();
    }

    // Load environment variables
    dotenv.config({ path: envPath });

    const config: AppConfig = {
      appName: process.env.APP_NAME ?? "Project Template",
      appVersion: process.env.APP_VERSION || "1.0.0",
      environment: process.env.NODE_ENV || "development",
      port: parseInt(process.env.PORT || "3000", 10),
      debug: process.env.DEBUG === "true",
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
    throw new ValidationError("App name cannot be empty", "appName");
  }

  if (isNaN(config.port) || config.port < 1 || config.port > 65535) {
    throw new ValidationError("Port must be a valid number between 1 and 65535", "port");
  }

  const validEnvironments = ["development", "staging", "production"];
  if (!validEnvironments.includes(config.environment)) {
    throw new ValidationError(
      `Environment must be one of: ${validEnvironments.join(", ")}`,
      "environment",
    );
  }

  if (!/^\d+\.\d+\.\d+$/.test(config.appVersion)) {
    throw new ValidationError("Version must be in semantic format (e.g., 1.0.0)", "appVersion");
  }
}

/**
 * Get default configuration values
 * @returns Default configuration
 */
function getDefaultConfig(): AppConfig {
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
 * Service for generating personalized greetings
 */
class GreetingService {
  constructor(
    private config: AppConfig,
    private logger: Logger,
  ) {
    // Validate config on initialization
    if (!config) {
      throw new Error("Configuration is required for GreetingService");
    }
    if (!logger) {
      throw new Error("Logger is required for GreetingService");
    }
  }

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

    this.logger.debug(`Generated greeting for: ${trimmedName}`);

    return greeting;
  }

  /**
   * Generate greetings for multiple names
   * @param names Array of names to greet
   * @returns Array of greeting messages
   */
  public getMultipleGreetings(names: string[]): string[] {
    return names.map((name) => this.greet(name));
  }

  /**
   * Validate name input
   * @param name Name to validate
   * @throws ValidationError if validation fails
   */
  private validateName(name: string): void {
    if (typeof name !== "string") {
      throw new ValidationError("Name must be a non-empty string", "name");
    }

    const trimmedName = name.trim();
    if (!trimmedName) {
      throw new ValidationError("Name cannot be empty after trimming", "name");
    }

    if (trimmedName.length < 1 || trimmedName.length > 50) {
      throw new ValidationError("Name must be between 1 and 50 characters", "name");
    }

    if (!/^[a-zA-Z\s\-']+$/.test(trimmedName)) {
      throw new ValidationError(
        "Name can only contain letters, spaces, hyphens, and apostrophes",
        "name",
      );
    }
  }
}

/**
 * Service for retrieving application information
 */
class AppInfoService {
  constructor(
    private config: AppConfig,
    private logger: Logger,
  ) {
    // Validate config on initialization
    if (!config) {
      throw new Error("Configuration is required for AppInfoService");
    }
    if (!logger) {
      throw new Error("Logger is required for AppInfoService");
    }
  }

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
      platform: process.platform,
    };
  }
}

// =============================================================================
// APPLICATION STATE MANAGEMENT
// =============================================================================

/**
 * Global application state container
 */
class ApplicationState {
  public config: AppConfig | null = null;
  public logger: Logger | null = null;
  public greetingService: GreetingService | null = null;
  public appInfoService: AppInfoService | null = null;

  /**
   * Check if all services are properly initialized
   */
  public isInitialized(): boolean {
    return !!(this.config && this.logger && this.greetingService && this.appInfoService);
  }

  /**
   * Reset all services to null
   */
  public reset(): void {
    this.config = null;
    this.logger = null;
    this.greetingService = null;
    this.appInfoService = null;
  }
}

// Global application state instance
const appState = new ApplicationState();

/**
 * Initialize the application with all required services
 */
async function initialize(): Promise<void> {
  try {
    // Load configuration
    appState.config = await loadConfiguration();

    // Initialize logger
    appState.logger = new Logger(appState.config.debug);

    // Initialize services
    appState.greetingService = new GreetingService(appState.config, appState.logger);
    appState.appInfoService = new AppInfoService(appState.config, appState.logger);

    // Log startup information
    logStartupInfo();

    // Verify all services are initialized
    if (!appState.isInitialized()) {
      throw new Error("One or more services failed to initialize");
    }

    // Demonstrate core functionality
    appState.logger.info("\n📝 Example Usage:");
    appState.logger.info(appState.greetingService.greet("Developer"));
    appState.logger.info(appState.greetingService.greet("TypeScript User"));

    // Multiple greetings example
    const names = ["Alice", "Bob", "Charlie"];
    const greetings = appState.greetingService.getMultipleGreetings(names);
    appState.logger.info("\n👥 Multiple Greetings:");
    greetings.forEach((greeting) => appState.logger!.info(`  ${greeting}`));

    // Display comprehensive app information
    const appInfo = appState.appInfoService.getAppInfo();
    appState.logger.info("\n📊 Application Info:");
    Object.entries(appInfo).forEach(([key, value]) => {
      appState.logger!.info(`  ${key}: ${value}`);
    });

    appState.logger.info("\n✅ Application initialized successfully!");
  } catch (error) {
    if (appState.logger) {
      if (error instanceof ValidationError) {
        appState.logger.error(`❌ Validation Error [${error.field}]: ${error.message}`);
      } else if (error instanceof ConfigurationError) {
        appState.logger.error(`❌ Configuration Error: ${error.message}`);
      } else {
        appState.logger.error(`❌ Application initialization failed: ${error}`);
      }
    } else {
      // Fallback to console if logger not initialized
      if (error instanceof ValidationError) {
        console.error(`❌ Validation Error [${error.field}]:`, error.message);
      } else if (error instanceof ConfigurationError) {
        console.error("❌ Configuration Error:", error.message);
      } else {
        console.error("❌ Application initialization failed:", error);
      }
    }
    process.exit(1);
  }
}

/**
 * Log comprehensive application startup information
 */
function logStartupInfo(): void {
  if (!appState.config || !appState.logger) {
    console.warn("⚠️  Cannot log startup info: application not properly initialized");
    return;
  }

  appState.logger.info("🚀 Starting TypeScript application...");
  appState.logger.info(`📱 App: ${appState.config.appName} v${appState.config.appVersion}`);
  appState.logger.info(`🌍 Environment: ${appState.config.environment}`);
  appState.logger.info(`🔧 Node.js: ${process.version}`);
  appState.logger.info(`📂 Platform: ${process.platform}`);
  appState.logger.info(`🚪 Port: ${appState.config.port}`);

  if (appState.config.debug) {
    appState.logger.debug("🐛 Debug mode enabled");
  }
}

/**
 * Graceful shutdown handler with cleanup
 */
function gracefulShutdown(): void {
  if (appState.logger) {
    appState.logger.info("\n🛑 Received shutdown signal. Cleaning up...");
  } else {
    console.log("\n🛑 Received shutdown signal. Cleaning up...");
  }

  // Perform cleanup operations
  // - Close database connections
  // - Stop background services
  // - Save application state
  appState.reset();

  if (appState.logger) {
    appState.logger.info("✅ Cleanup completed. Exiting...");
  } else {
    console.log("✅ Cleanup completed. Exiting...");
  }
  process.exit(0);
}

// =============================================================================
// APPLICATION ENTRY POINT
// =============================================================================

// Handle uncaught exceptions
process.on("uncaughtException", (error: Error) => {
  if (appState.logger) {
    appState.logger.error(`💥 Uncaught Exception: ${error.message}`);
  } else {
    console.error("💥 Uncaught Exception:", error.message);
  }
  process.exit(1);
});

// Handle unhandled promise rejections
process.on("unhandledRejection", (reason: unknown, promise: Promise<unknown>) => {
  if (appState.logger) {
    appState.logger.error(`💥 Unhandled Rejection at: ${promise}, reason: ${reason}`);
  } else {
    console.error("💥 Unhandled Rejection at:", promise, "reason:", reason);
  }
  process.exit(1);
});

// Handle shutdown signals
process.on("SIGINT", gracefulShutdown);
process.on("SIGTERM", gracefulShutdown);

// Start the application
if (require.main === module) {
  initialize().catch((error: Error) => {
    if (appState.logger) {
      appState.logger.error(`💥 Failed to start application: ${error.message}`);
    } else {
      console.error("💥 Failed to start application:", error.message);
    }
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
  Logger,
  GreetingService,
  AppInfoService,
  loadConfiguration,
  initialize,
};
