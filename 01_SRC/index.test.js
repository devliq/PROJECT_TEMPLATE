const { greet, getAppInfo, loadConfiguration, initialize } = require("./index.js");
const fs = require("fs");
const path = require("path");
const dotenv = require("dotenv");

// Mock external dependencies
const mockFs = {
  promises: {
    access: jest.fn(),
  },
};

const mockPath = {
  resolve: jest.fn(),
};

const mockDotenv = {
  config: jest.fn(),
};

jest.mock("fs", () => mockFs);
jest.mock("path", () => mockPath);
jest.mock("dotenv", () => mockDotenv);

// Mock console methods
const mockConsole = {
  log: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
};

global.console = mockConsole;

// Mock process methods
const mockProcessExit = jest.spyOn(process, "exit").mockImplementation(() => {});
jest.spyOn(process, "uptime").mockReturnValue(123.45);
jest.spyOn(Object, "defineProperty").mockImplementation((obj, prop, descriptor) => {
  // eslint-disable-next-line security/detect-object-injection
  obj[prop] = descriptor.value;
});
Object.defineProperty(process, "version", { value: "v16.0.0", writable: true });
Object.defineProperty(process, "platform", { value: "linux", writable: true });

// Unused mock variables removed

// Removed mock for './index' as it's not needed for JS version

describe("greet", () => {
  test("should generate greeting for valid names", () => {
    expect(greet("John")).toBe("Hello, John! Welcome to Project Template");
    expect(greet("Alice")).toBe("Hello, Alice! Welcome to Project Template");
    expect(greet("Bob", "MyApp")).toBe("Hello, Bob! Welcome to MyApp");
  });

  test("should handle names with spaces, hyphens, and apostrophes", () => {
    expect(greet("Mary Jane")).toBe("Hello, Mary Jane! Welcome to Project Template");
    expect(greet("Jean-Paul")).toBe("Hello, Jean-Paul! Welcome to Project Template");
    expect(greet("O'Connor")).toBe("Hello, O'Connor! Welcome to Project Template");
  });

  test.each([
    [null, "Name must be a non-empty string"],
    [undefined, "Name must be a non-empty string"],
    [123, "Name must be a non-empty string"],
    ["", "Name cannot be empty after trimming"],
    ["   ", "Name cannot be empty after trimming"],
    ["A".repeat(51), "Name must be between 1 and 50 characters (received 51)"],
    ["John@", "Name can only contain letters, spaces, hyphens, and apostrophes"],
    ["John123", "Name can only contain letters, spaces, hyphens, and apostrophes"],
    ["John!", "Name can only contain letters, spaces, hyphens, and apostrophes"],
  ])("should throw error for invalid name: %s", (name, expectedError) => {
    expect(() => greet(name)).toThrow(expectedError);
  });

  test("should trim whitespace from names", () => {
    expect(greet("  John  ")).toBe("Hello, John! Welcome to Project Template");
  });
});

describe("getAppInfo", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset the module to clear any global state
    jest.resetModules();
    const indexModule = require("./index");
    Object.assign(global, indexModule);
  });

  test("should return application info object", async () => {
    // Initialize the app first to set the config
    await initialize();

    const appInfo = getAppInfo();
    expect(appInfo).toHaveProperty("name");
    expect(appInfo).toHaveProperty("version");
    expect(appInfo).toHaveProperty("environment");
    expect(appInfo).toHaveProperty("uptime");
    expect(appInfo).toHaveProperty("nodeVersion");
    expect(appInfo).toHaveProperty("platform");
  });

  test("should use actual process values", async () => {
    await initialize();

    const appInfo = getAppInfo();
    expect(appInfo.uptime).toBe(123.45);
    expect(appInfo.nodeVersion).toBe("v16.0.0");
    expect(appInfo.platform).toBe("linux");
  });

  test("should throw error when not initialized", () => {
    // Reset modules to clear initialization
    jest.resetModules();
    const freshModule = require("./index");
    // Create a new instance of the module functions
    const { getAppInfo: freshGetAppInfo } = freshModule;
    expect(() => freshGetAppInfo()).toThrow(
      "Application not initialized. Call initialize() first.",
    );
  });
});

describe("loadConfiguration", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env = {};
  });

  test("should load configuration from .env file successfully", async () => {
    process.env.APP_NAME = "Test App";
    process.env.APP_VERSION = "1.2.3";
    process.env.NODE_ENV = "production";
    process.env.PORT = "3001";
    process.env.DEBUG = "false";

    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});

    const config = await loadConfiguration();

    expect(config).toEqual({
      appName: "Test App",
      appVersion: "1.2.3",
      environment: "production",
      port: 3001,
      debug: false,
    });
  });

  test("should return default config when .env file not found", async () => {
    mockFs.promises.access.mockRejectedValue(new Error("File not found"));

    const config = await loadConfiguration();

    expect(config).toEqual({
      appName: "Project Template",
      appVersion: "1.0.0",
      environment: "development",
      port: 3000,
      debug: false,
    });
    expect(mockConsole.warn).toHaveBeenCalledWith(
      "⚠️ .env file not found. Using default configuration.",
    );
  });

  test("should return default config when dotenv fails", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({ error: new Error("Dotenv error") });

    const config = await loadConfiguration();

    expect(config).toEqual({
      appName: "Project Template",
      appVersion: "1.0.0",
      environment: "development",
      port: 3000,
      debug: false,
    });
    expect(mockConsole.error).toHaveBeenCalledWith("❌ Failed to load dotenv:", "Dotenv error");
  });

  test.each([
    ["", "APP_NAME must be a non-empty string"],
    ["   ", "APP_NAME must be a non-empty string"],
    ["1.0", "APP_VERSION must be in semantic version format (e.g., 1.0.0)"],
    ["invalid", "NODE_ENV must be one of: development, production, test"],
    ["abc", "PORT must be a valid number between 1 and 65535"],
    ["70000", "PORT must be a valid number between 1 and 65535"],
    ["0", "PORT must be a valid number between 1 and 65535"],
  ])("should return default config for invalid env vars: %s", async (value, expectedError) => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});

    if (expectedError.includes("APP_NAME")) {
      process.env.APP_NAME = value;
    } else if (expectedError.includes("APP_VERSION")) {
      process.env.APP_VERSION = value;
    } else if (expectedError.includes("NODE_ENV")) {
      process.env.NODE_ENV = value;
    } else if (expectedError.includes("PORT")) {
      process.env.PORT = value;
    }

    const config = await loadConfiguration();
    // JavaScript version returns default config on validation errors
    expect(config).toEqual({
      appName: "Project Template",
      appVersion: "1.0.0",
      environment: "development",
      port: 3000,
      debug: false,
    });
  });

  test("should handle missing optional env vars", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});

    process.env.APP_NAME = "Test";
    process.env.APP_VERSION = "1.0.0";
    // NODE_ENV, PORT, DEBUG are optional

    const config = await loadConfiguration();

    expect(config.environment).toBe("development");
    expect(config.port).toBe(3000);
    expect(config.debug).toBe(false);
  });

  test("should handle valid port values", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});

    process.env.APP_NAME = "Test";
    process.env.APP_VERSION = "1.0.0";
    process.env.PORT = "8080";

    const config = await loadConfiguration();
    expect(config.port).toBe(8080);
  });

  test("should handle debug flag correctly", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});

    process.env.APP_NAME = "Test";
    process.env.APP_VERSION = "1.0.0";
    process.env.DEBUG = "true";

    const config = await loadConfiguration();
    expect(config.debug).toBe(true);
  });
});

describe("initialize", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env = {
      APP_NAME: "Test App",
      APP_VERSION: "1.0.0",
      NODE_ENV: "test",
      PORT: "3000",
      DEBUG: "true",
    };
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});
  });

  test("should initialize application successfully", async () => {
    await initialize();

    expect(mockConsole.info).toHaveBeenCalledWith("🚀 Starting Node.js application...");
    expect(mockConsole.info).toHaveBeenCalledWith("📱 App: Test App v1.0.0");
    expect(mockConsole.info).toHaveBeenCalledWith("🌍 Environment: test");
    expect(mockConsole.info).toHaveBeenCalledWith("🔧 Node.js: v16.0.0");
    expect(mockConsole.info).toHaveBeenCalledWith("📂 Platform: linux");
    expect(mockConsole.debug).toHaveBeenCalledWith("🐛 Debug mode enabled");
    expect(mockConsole.info).toHaveBeenCalledWith("\n📝 Example Usage:");
    expect(mockConsole.info).toHaveBeenCalledWith(greet("Developer", "Test App"));
    expect(mockConsole.info).toHaveBeenCalledWith(greet("World", "Test App"));
    expect(mockConsole.info).toHaveBeenCalledWith("\n✅ Application initialized successfully!");
  });

  test("should handle missing .env file during initialization", async () => {
    mockFs.promises.access.mockRejectedValue(new Error("File not found"));

    await initialize();

    expect(mockConsole.warn).toHaveBeenCalledWith(
      ".env file not found. Using default configuration.",
    );
    expect(mockConsole.info).toHaveBeenCalledWith("\n✅ Application initialized successfully!");
  });

  test("should exit on configuration error", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});
    process.env.APP_NAME = ""; // Invalid app name

    await initialize();

    expect(mockProcessExit).toHaveBeenCalledWith(1);
    expect(mockConsole.error).toHaveBeenCalledWith(
      "❌ Application initialization failed:",
      expect.any(String),
    );
  });

  test("should handle debug mode disabled", async () => {
    process.env.DEBUG = "false";

    await initialize();

    expect(mockConsole.debug).not.toHaveBeenCalledWith("🐛 Debug mode enabled");
  });
});

describe("Integration Tests", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    process.env = {
      APP_NAME: "Integration Test App",
      APP_VERSION: "1.0.0",
      NODE_ENV: "test",
      PORT: "4000",
      DEBUG: "false",
    };
    fs.promises.access.mockResolvedValue();
    path.resolve.mockReturnValue("/path/to/.env");
    dotenv.config.mockReturnValue({});
  });

  test("should execute full application flow", async () => {
    await initialize();

    // Verify config was loaded
    const config = await loadConfiguration();
    expect(config.appName).toBe("Integration Test App");

    // Verify logging occurred
    expect(mockConsole.info).toHaveBeenCalledWith("🚀 Starting Node.js application...");
    expect(mockConsole.info).toHaveBeenCalledWith("\n✅ Application initialized successfully!");
  });

  test("should handle full flow with missing .env", async () => {
    mockFs.promises.access.mockRejectedValue(new Error("File not found"));

    await initialize();

    expect(mockConsole.warn).toHaveBeenCalledWith(
      ".env file not found. Using default configuration.",
    );
    expect(mockConsole.info).toHaveBeenCalledWith("\n✅ Application initialized successfully!");
  });

  test("should handle configuration errors gracefully", async () => {
    process.env.APP_NAME = "";

    await initialize();

    expect(mockProcessExit).toHaveBeenCalledWith(1);
  });
});
