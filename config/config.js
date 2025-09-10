/**
 * Application Configuration
 * Handles environment variable interpolation
 */

const config = {
  app: {
    name: 'My Project',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
  },
  database: {
    host: process.env.DB_HOST || 'localhost',
    port: 5432,
    name: process.env.DB_NAME || 'myproject',
    username: process.env.DB_USERNAME || 'user',
    password: process.env.DB_PASSWORD || null,
  },
  api: {
    baseUrl: process.env.API_BASE_URL || 'https://api.example.com',
    timeout: 5000,
    retries: 3,
  },
  logging: {
    level: 'info',
    file: 'logs/app.log',
    maxSize: '10m',
    maxFiles: 5,
  },
  features: {
    debug: process.env.DEBUG === 'true',
    cache: true,
    analytics: false,
  },
  environments: {
    development: {
      database: {
        host: process.env.DB_HOST || 'localhost',
        name: process.env.DB_NAME || 'myproject_dev',
      },
      api: {
        baseUrl: process.env.API_BASE_URL || 'https://dev-api.example.com',
      },
    },
    production: {
      database: {
        host: process.env.DB_HOST || 'prod-db.example.com',
        name: process.env.DB_NAME || 'myproject_prod',
      },
      api: {
        baseUrl: process.env.API_BASE_URL || 'https://api.example.com',
      },
    },
  },
  schema: {
    $schema: 'http://json-schema.org/draft-07/schema#',
    type: 'object',
    properties: {
      app: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          version: { type: 'string' },
          environment: { type: 'string' },
        },
        required: ['name', 'version'],
      },
      database: {
        type: 'object',
        properties: {
          host: { type: 'string' },
          port: { type: 'integer' },
          name: { type: 'string' },
          username: { type: 'string' },
          password: { type: 'string' },
        },
        required: ['host', 'port', 'name', 'username', 'password'],
      },
    },
    required: ['app', 'database'],
  },
};

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = config;
} else if (typeof window !== 'undefined') {
  window.config = config;
}
