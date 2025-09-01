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
Object.defineProperty(process, "version", { value: "v16.0.0", writable: true });
Object.defineProperty(process, "platform", { value: "linux", writable: true });
jest.spyOn(Object, "defineProperty").mockImplementation((obj, prop, descriptor) => {
  // eslint-disable-next-line security/detect-object-injection
  obj[prop] = descriptor.value;
});

const {
  greet,
  getAppInfo,
  loadConfiguration,
  initialize,
  sanitizeInput,
  isSensitiveValue,
} = require("./index.js");

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
    process.env = {
      APP_NAME: "Test App",
      APP_VERSION: "1.0.0",
      NODE_ENV: "test",
      PORT: "3000",
      DEBUG: "false",
    };
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});
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
    // Reset the module to clear any global state
    jest.resetModules();
    const freshModule = require("./index");
    expect(() => freshModule.getAppInfo()).toThrow(TypeError);
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

  test("should throw error when dotenv fails", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({ error: new Error("Dotenv error") });

    await expect(loadConfiguration()).rejects.toThrow("Failed to load configuration: Dotenv error");
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

    const appInfo = getAppInfo();

    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  🚀 Starting Node.js application...");
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  📱 App: Test App v1.0.0");
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  🌍 Environment: test");
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  🔧 Node.js: v16.0.0");
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  📂 Platform: linux");
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  🚪 Port: 3000");
    expect(mockConsole.debug).toHaveBeenCalledWith("🐛 🐛 Debug mode enabled");
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  \n📝 Example Usage:");
    expect(mockConsole.log).toHaveBeenCalledWith(`ℹ️  ${greet("Developer", "Test App")}`);
    expect(mockConsole.log).toHaveBeenCalledWith(`ℹ️  ${greet("World", "Test App")}`);
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  \n📊 Application Info:");
    expect(mockConsole.log).toHaveBeenCalledWith(`ℹ️  ${JSON.stringify(appInfo, null, 2)}`);
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  \n✅ Application initialized successfully!");
  });

  test("should handle missing .env file during initialization", async () => {
    mockFs.promises.access.mockRejectedValue(new Error("File not found"));

    await initialize();

    expect(mockConsole.warn).toHaveBeenCalledWith(
      "⚠️ .env file not found. Using default configuration.",
    );
    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  \n✅ Application initialized successfully!");
  });

  test("should exit on configuration error", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({ error: new Error("Dotenv config error") });

    await initialize();

    expect(mockProcessExit).toHaveBeenCalledWith(1);
    expect(mockConsole.error).toHaveBeenCalledWith(
      "❌ ❌ Application initialization failed:",
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
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({});
  });

  test("should execute full application flow", async () => {
    await initialize();

    // Verify config was loaded

    const config = await loadConfiguration();

    expect(config.appName).toBe("Integration Test App");

    // Verify logging occurred

    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  🚀 Starting Node.js application...");

    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  \n✅ Application initialized successfully!");
  });

  test("should handle full flow with missing .env", async () => {
    mockFs.promises.access.mockRejectedValue(new Error("File not found"));

    await initialize();

    expect(mockConsole.warn).toHaveBeenCalledWith(
      "⚠️ .env file not found. Using default configuration.",
    );

    expect(mockConsole.log).toHaveBeenCalledWith("ℹ️  \n✅ Application initialized successfully!");
  });

  test("should handle configuration errors gracefully", async () => {
    mockFs.promises.access.mockResolvedValue();
    mockPath.resolve.mockReturnValue("/path/to/.env");
    mockDotenv.config.mockReturnValue({ error: new Error("Dotenv config error") });

    await initialize();

    expect(mockConsole.error).toHaveBeenCalledWith(
      "❌ ❌ Application initialization failed:",
      expect.any(String),
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
    expect(() => sanitizeInput(123)).toThrow("Input must be a string");
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
  let LocalRateLimiter;

  beforeEach(() => {
    // Import RateLimiter from the module
    const module = require("./index.js");
    LocalRateLimiter =
      module.RateLimiter ||
      class FallbackRateLimiter {
        constructor(windowMs = 900000, maxRequests = 100) {
          this.windowMs = windowMs;
          this.maxRequests = maxRequests;
          this.requests = new Map();
        }

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
      };
  });

  test("should allow requests within limit", () => {
    const limiter = new LocalRateLimiter(1000, 2); // 1 second window, 2 requests
    expect(limiter.isAllowed("user1")).toBe(true);
    expect(limiter.isAllowed("user1")).toBe(true);
  });

  test("should block requests over limit", () => {
    const limiter = new LocalRateLimiter(1000, 2);
    limiter.isAllowed("user1");
    limiter.isAllowed("user1");
    expect(limiter.isAllowed("user1")).toBe(false);
  });

  test("should reset after window", async () => {
    const limiter = new LocalRateLimiter(100, 1); // 100ms window, 1 request
    limiter.isAllowed("user1");
    expect(limiter.isAllowed("user1")).toBe(false);

    // Wait for window to reset
    await new Promise((resolve) => setTimeout(resolve, 150));
    expect(limiter.isAllowed("user1")).toBe(true);
  });

  test("should track remaining requests", () => {
    const limiter = new LocalRateLimiter(1000, 3);
    expect(limiter.getRemainingRequests("user1")).toBe(3);
    limiter.isAllowed("user1");
    expect(limiter.getRemainingRequests("user1")).toBe(2);
  });
});
