/**
 * Unit tests for index.ts TypeScript classes and functions
 */

// Create mock console
// eslint-disable @typescript-eslint/no-explicit-any
type MockConsole = {
  log: jest.MockedFunction<(message?: unknown, ...optionalParams: unknown[]) => void>;
  warn: jest.MockedFunction<(message?: unknown, ...optionalParams: unknown[]) => void>;
  error: jest.MockedFunction<(message?: unknown, ...optionalParams: unknown[]) => void>;
  debug: jest.MockedFunction<(message?: unknown, ...optionalParams: unknown[]) => void>;
  info: jest.MockedFunction<(message?: unknown, ...optionalParams: unknown[]) => void>;
};

const mockConsole: MockConsole = {
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
};

global.console = mockConsole as unknown as typeof global.console;

// Create mock objects for external dependencies
const mockFs = {
  access: jest.fn(),
};

const mockPath = {
  resolve: jest.fn(),
};

const mockDotenv = {
  config: jest.fn(),
};

jest.mock("fs/promises", () => mockFs);
jest.mock("path", () => mockPath);
jest.mock("dotenv", () => mockDotenv);

import {
  AppConfig,
  ConfigurationError,
  ValidationError,
  Logger,
  GreetingService,
  AppInfoService,
  loadConfiguration,
  initialize,
  sanitizeInput,
  isSensitiveValue,
  RateLimiter,
} from "./index";

// Import the security functions (they are not exported, so we need to test them indirectly or export them)

// Mock process methods
const mockProcessExit = jest.fn();
Object.defineProperty(process, "exit", {
  value: mockProcessExit,
  writable: true,
});

// Mock process properties
Object.defineProperty(process, "version", { value: "v16.0.0", writable: true });
Object.defineProperty(process, "platform", { value: "linux", writable: true });

describe("Logger", () => {
  let logger: Logger;

  beforeEach(() => {
    logger = new Logger(false);
  });

  test("should log info messages", () => {
    const consoleSpy = jest.spyOn(console, "log").mockImplementation();
    logger.info("Test message");
    expect(consoleSpy).toHaveBeenCalledWith("Test message");
    consoleSpy.mockRestore();
  });

  test("should log warn messages", () => {
    const consoleSpy = jest.spyOn(console, "warn").mockImplementation();
    logger.warn("Test warning");
    expect(consoleSpy).toHaveBeenCalledWith("Test warning");
    consoleSpy.mockRestore();
  });

  test("should log error messages", () => {
    const consoleSpy = jest.spyOn(console, "error").mockImplementation();
    logger.error("Test error");
    expect(consoleSpy).toHaveBeenCalledWith("Test error");
    consoleSpy.mockRestore();
  });

  test("should log debug messages when debug mode is enabled", () => {
    const debugLogger = new Logger(true);
    const consoleSpy = jest.spyOn(console, "debug").mockImplementation();
    debugLogger.debug("Test debug");
    expect(consoleSpy).toHaveBeenCalledWith("Test debug");
    consoleSpy.mockRestore();
  });

  test("should not log debug messages when debug mode is disabled", () => {
    const consoleSpy = jest.spyOn(console, "debug").mockImplementation();
    logger.debug("Test debug");
    expect(consoleSpy).not.toHaveBeenCalled();
    consoleSpy.mockRestore();
  });
});

describe("GreetingService", () => {
  let config: AppConfig;
  let logger: Logger;
  let greetingService: GreetingService;

  beforeEach(() => {
    config = {
      appName: "Test App",
      appVersion: "1.0.0",
      environment: "test",
      port: 3000,
      debug: false,
    };
    logger = new Logger(false);
    greetingService = new GreetingService(config, logger);
  });

  test("should greet valid names", () => {
    expect(greetingService.greet("John")).toBe("Hello, John! Welcome to Test App");
    expect(greetingService.greet("Alice")).toBe("Hello, Alice! Welcome to Test App");
  });

  test("should handle multiple greetings", () => {
    const names = ["Alice", "Bob"];
    const greetings = greetingService.getMultipleGreetings(names);
    expect(greetings).toEqual([
      "Hello, Alice! Welcome to Test App",
      "Hello, Bob! Welcome to Test App",
    ]);
  });

  test.each([
    [null, "Name must be a non-empty string"],
    [undefined, "Name must be a non-empty string"],
    [123, "Name must be a non-empty string"],
    ["", "Name cannot be empty after trimming"],
    ["   ", "Name cannot be empty after trimming"],
    ["A".repeat(51), "Name must be between 1 and 50 characters"],
    ["John@", "Name can only contain letters, spaces, hyphens, and apostrophes"],
    ["John123", "Name can only contain letters, spaces, hyphens, and apostrophes"],
  ])(
    "should throw ValidationError for invalid name: %s",
    (name: string | number | null | undefined, expectedError: string) => {
      expect(() => greetingService.greet(name as string)).toThrow(expectedError);
    },
  );

  test("should handle edge cases with valid characters", () => {
    expect(greetingService.greet("O'Connor")).toBe("Hello, O'Connor! Welcome to Test App");
    expect(greetingService.greet("Jean-Paul")).toBe("Hello, Jean-Paul! Welcome to Test App");
    expect(greetingService.greet("Mary Jane")).toBe("Hello, Mary Jane! Welcome to Test App");
  });

  test("should log debug message when debug is enabled", () => {
    const debugConfig: AppConfig = { ...config, debug: true };
    const debugLogger = new Logger(true);
    const debugService = new GreetingService(debugConfig, debugLogger);
    const debugSpy = jest.spyOn(debugLogger, "debug");
    debugService.greet("John");
    expect(debugSpy).toHaveBeenCalledWith("Generated greeting for: John");
  });

  test("should throw error when config is null", () => {
    expect(() => new GreetingService(null as unknown as AppConfig, logger)).toThrow(
      "Configuration is required for GreetingService",
    );
  });

  test("should throw error when logger is null", () => {
    expect(() => new GreetingService(config, null as unknown as Logger)).toThrow(
      "Logger is required for GreetingService",
    );
  });
});

describe("AppInfoService", () => {
  let config: AppConfig;
  let logger: Logger;
  let appInfoService: AppInfoService;

  beforeEach(() => {
    config = {
      appName: "Test App",
      appVersion: "1.0.0",
      environment: "test",
      port: 3000,
      debug: false,
    };
    logger = new Logger(false);
    appInfoService = new AppInfoService(config, logger);
  });

  test("should return correct application info", () => {
    const mockUptime = 123.45;
    const mockVersion = "v16.0.0";
    const mockPlatform = "linux";

    jest.spyOn(process, "uptime").mockReturnValue(mockUptime);
    Object.defineProperty(process, "version", {
      value: mockVersion,
      writable: true,
    });
    Object.defineProperty(process, "platform", {
      value: mockPlatform,
      writable: true,
    });

    const appInfo = appInfoService.getAppInfo();
    expect(appInfo).toEqual({
      name: "Test App",
      version: "1.0.0",
      environment: "test",
      uptime: mockUptime,
      nodeVersion: mockVersion,
      platform: mockPlatform,
    });
  });

  test("should throw error when config is null", () => {
    expect(() => new AppInfoService(null as unknown as AppConfig, logger)).toThrow(
      "Configuration is required for AppInfoService",
    );
  });

  test("should throw error when logger is null", () => {
    expect(() => new AppInfoService(config, null as unknown as Logger)).toThrow(
      "Logger is required for AppInfoService",
    );
  });
});

describe("ValidationError", () => {
  test("should create ValidationError with message and field", () => {
    const error = new ValidationError("Invalid value", "testField");
    expect(error.message).toBe("Invalid value");
    expect(error.field).toBe("testField");
    expect(error.name).toBe("ValidationError");
  });
});

describe("ConfigurationError", () => {
  test("should create ConfigurationError with message", () => {
    const error = new ConfigurationError("Config failed");
    expect(error.message).toBe("Config failed");
    expect(error.name).toBe("ConfigurationError");
  });

  test("should create ConfigurationError with cause", () => {
    const cause = new Error("Original error");
    const error = new ConfigurationError("Config failed", cause);
    expect(error.message).toBe("Config failed");
    expect(error.cause).toBe(cause);
  });
});

describe("loadConfiguration TS", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env = {};
    mockDotenv.config.mockImplementation(() => {
      // Default mock - can be overridden in tests
      return {};
    });
  });

  test("should load configuration from .env file successfully", async () => {
    mockFs.access.mockResolvedValue(undefined);
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockImplementation(() => {
      process.env.APP_NAME = "Test App";
      process.env.APP_VERSION = "1.2.3";
      process.env.NODE_ENV = "production";
      process.env.PORT = "3001";
      process.env.DEBUG = "false";
      return {};
    });

    const config = await loadConfiguration();

    expect(config).toEqual({
      appName: "Test App",
      appVersion: "1.2.3",
      environment: "production",
      port: 3001,
      debug: false,
    });
  });

  test("should throw ConfigurationError for invalid configuration", async () => {
    mockFs.access.mockResolvedValue(undefined);
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockImplementation(() => {
      throw new Error("Dotenv error");
    });

    await expect(loadConfiguration()).rejects.toThrow(ConfigurationError);
  });
});

describe("initialize TS", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env = {
      APP_NAME: "Test App",
      APP_VERSION: "1.0.0",
      NODE_ENV: "test",
      PORT: "3000",
      DEBUG: "true",
    };
    mockFs.access.mockResolvedValue(undefined);
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockImplementation(() => {
      // Only set if not already set (to allow test overrides)
      if (process.env.APP_NAME === undefined) process.env.APP_NAME = "Test App";
      if (process.env.APP_VERSION === undefined) process.env.APP_VERSION = "1.0.0";
      if (process.env.NODE_ENV === undefined) process.env.NODE_ENV = "test";
      if (process.env.PORT === undefined) process.env.PORT = "3000";
      if (process.env.DEBUG === undefined) process.env.DEBUG = "true";
      return {};
    });
  });

  test("should initialize application successfully", async () => {
    await initialize();

    expect(mockConsole.log).toHaveBeenCalledWith("🚀 Starting TypeScript application...");
    expect(mockConsole.log).toHaveBeenCalledWith("📱 App: Test App v1.0.0");
    expect(mockConsole.log).toHaveBeenCalledWith("🌍 Environment: test");
    expect(mockConsole.log).toHaveBeenCalledWith("🔧 Node.js: v16.0.0");
    expect(mockConsole.log).toHaveBeenCalledWith("📂 Platform: linux");
    expect(mockConsole.debug).toHaveBeenCalledWith("🐛 Debug mode enabled");
    expect(mockConsole.log).toHaveBeenCalledWith("\n📝 Example Usage:");
    expect(mockConsole.log).toHaveBeenCalledWith("Hello, Developer! Welcome to Test App");
    expect(mockConsole.log).toHaveBeenCalledWith("Hello, TypeScript User! Welcome to Test App");
    expect(mockConsole.log).toHaveBeenCalledWith("\n👥 Multiple Greetings:");
    expect(mockConsole.log).toHaveBeenCalledWith("  Hello, Alice! Welcome to Test App");
    expect(mockConsole.log).toHaveBeenCalledWith("  Hello, Bob! Welcome to Test App");
    expect(mockConsole.log).toHaveBeenCalledWith("  Hello, Charlie! Welcome to Test App");
    expect(mockConsole.log).toHaveBeenCalledWith("\n📊 Application Info:");
    expect(mockConsole.log).toHaveBeenCalledWith("  name: Test App");
    expect(mockConsole.log).toHaveBeenCalledWith("  version: 1.0.0");
    expect(mockConsole.log).toHaveBeenCalledWith("  environment: test");
    expect(mockConsole.log).toHaveBeenCalledWith("  uptime: 123.45");
    expect(mockConsole.log).toHaveBeenCalledWith("  nodeVersion: v16.0.0");
    expect(mockConsole.log).toHaveBeenCalledWith("  platform: linux");
    expect(mockConsole.log).toHaveBeenCalledWith("\n✅ Application initialized successfully!");
  });

  test("should handle ValidationError during initialization", async () => {
    // Mock to cause validation error
    process.env.APP_NAME = "";

    await initialize();

    expect(mockConsole.error).toHaveBeenCalledWith(
      "❌ Validation Error [appName]: App name cannot be empty",
    );
    expect(mockProcessExit).toHaveBeenCalledWith(1);
  });

  test("should handle ConfigurationError during initialization", async () => {
    mockFs.access.mockResolvedValue(undefined);
    mockDotenv.config.mockReturnValue({ error: new Error("Dotenv error") });

    await initialize();

    expect(mockConsole.error).toHaveBeenCalledWith(
      "❌ Configuration Error: Failed to load configuration: Dotenv error",
    );
    expect(mockProcessExit).toHaveBeenCalledWith(1);
  });
});

describe("sanitizeInput", () => {
  test("should sanitize basic input", () => {
    expect(sanitizeInput("  hello  ")).toBe("hello");
  });

  test("should remove null bytes and control characters", () => {
    expect(sanitizeInput("hello\x00world\x1F")).toBe("helloworld");
  });

  test("should remove script tags", () => {
    expect(sanitizeInput("hello<script>alert('xss')</script>world")).toBe("helloworld");
  });

  test("should strip HTML when specified", () => {
    expect(sanitizeInput("<b>hello</b>", { stripHtml: true })).toBe("hello");
  });

  test("should limit length when specified", () => {
    expect(sanitizeInput("verylongstring", { maxLength: 5 })).toBe("veryl");
  });

  test("should throw error for non-string input", () => {
    expect(() => sanitizeInput(123 as unknown as string)).toThrow("Input must be a string");
  });
});

describe("isSensitiveValue", () => {
  test("should detect sensitive keys", () => {
    expect(isSensitiveValue("DB_PASSWORD", "secret123")).toBe(true);
    expect(isSensitiveValue("API_KEY", "key123")).toBe(true);
    expect(isSensitiveValue("JWT_SECRET", "token")).toBe(true);
  });

  test("should detect base64-like values", () => {
    expect(isSensitiveValue("SOME_VAR", "SGVsbG8gV29ybGQ=")).toBe(true);
  });

  test("should detect hex values", () => {
    expect(
      isSensitiveValue("HASH", "a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3"),
    ).toBe(true);
  });

  test("should not flag normal values", () => {
    expect(isSensitiveValue("APP_NAME", "My App")).toBe(false);
    expect(isSensitiveValue("PORT", "3000")).toBe(false);
  });
});

describe("RateLimiter", () => {
  test("should allow requests within limit", () => {
    const limiter = new RateLimiter(1000, 2); // 1 second window, 2 requests
    expect(limiter.isAllowed("user1")).toBe(true);
    expect(limiter.isAllowed("user1")).toBe(true);
  });

  test("should block requests over limit", () => {
    const limiter = new RateLimiter(1000, 2);
    limiter.isAllowed("user1");
    limiter.isAllowed("user1");
    expect(limiter.isAllowed("user1")).toBe(false);
  });

  test("should track remaining requests", () => {
    const limiter = new RateLimiter(1000, 3);
    expect(limiter.getRemainingRequests("user1")).toBe(3);
    limiter.isAllowed("user1");
    expect(limiter.getRemainingRequests("user1")).toBe(2);
  });
});
