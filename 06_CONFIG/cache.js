/**
 * Caching Configuration and Utilities
 * Supports multiple caching strategies and backends
 */

const cache = {
  // Cache configuration
  config: {
    defaultTtl: 3600, // 1 hour in seconds
    maxMemory: '256mb',
    compression: true,
    serialization: 'json',
    keyPrefix: 'app:',
    redis: {
      host: process.env.REDIS_HOST || 'localhost',
      port: process.env.REDIS_PORT || 6379,
      password: process.env.REDIS_PASSWORD || '',
      db: process.env.REDIS_DB || 0,
      keyPrefix: 'app:'
    }
  },

  // Cache stores
  stores: {},

  // Cache statistics
  stats: {
    hits: 0,
    misses: 0,
    sets: 0,
    deletes: 0,
    clears: 0
  },

  // Initialize cache
  init(options = {}) {
    this.config = { ...this.config, ...options };

    // Initialize Redis store if available
    if (this.isRedisAvailable()) {
      this.stores.redis = this.createRedisStore();
    }

    // Initialize memory store as fallback
    this.stores.memory = this.createMemoryStore();

    console.log('Cache initialized with stores:', Object.keys(this.stores));
  },

  // Check if Redis is available
  isRedisAvailable() {
    try {
      // In Node.js environment, check if redis package is available
      if (typeof require !== 'undefined') {
        require('redis');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  },

  // Create Redis store
  createRedisStore() {
    const redis = require('redis');
    const client = redis.createClient(this.config.redis);

    client.on('error', (err) => {
      console.error('Redis Client Error:', err);
    });

    client.on('connect', () => {
      console.log('Connected to Redis');
    });

    client.connect();

    return {
      get: async (key) => {
        try {
          const value = await client.get(this.config.redis.keyPrefix + key);
          return value ? JSON.parse(value) : null;
        } catch (err) {
          console.error('Redis get error:', err);
          return null;
        }
      },

      set: async (key, value, ttl = this.config.defaultTtl) => {
        try {
          const serializedValue = JSON.stringify(value);
          if (ttl > 0) {
            await client.setEx(this.config.redis.keyPrefix + key, ttl, serializedValue);
          } else {
            await client.set(this.config.redis.keyPrefix + key, serializedValue);
          }
          return true;
        } catch (err) {
          console.error('Redis set error:', err);
          return false;
        }
      },

      delete: async (key) => {
        try {
          await client.del(this.config.redis.keyPrefix + key);
          return true;
        } catch (err) {
          console.error('Redis delete error:', err);
          return false;
        }
      },

      clear: async () => {
        try {
          const keys = await client.keys(`${this.config.redis.keyPrefix}*`);
          if (keys.length > 0) {
            await client.del(keys);
          }
          return true;
        } catch (err) {
          console.error('Redis clear error:', err);
          return false;
        }
      },

      has: async (key) => {
        try {
          const exists = await client.exists(this.config.redis.keyPrefix + key);
          return exists === 1;
        } catch (err) {
          console.error('Redis has error:', err);
          return false;
        }
      }
    };
  },

  // Create in-memory store
  createMemoryStore() {
    const store = new Map();

    return {
      get: async (key) => {
        const item = store.get(key);
        if (!item) return null;

        if (item.expires && item.expires < Date.now()) {
          store.delete(key);
          return null;
        }

        return item.value;
      },

      set: async (key, value, ttl = this.config.defaultTtl) => {
        const expires = ttl > 0 ? Date.now() + (ttl * 1000) : null;
        store.set(key, { value, expires });
        return true;
      },

      delete: async (key) => {
        return store.delete(key);
      },

      clear: async () => {
        store.clear();
        return true;
      },

      has: async (key) => {
        const item = store.get(key);
        if (!item) return false;

        if (item.expires && item.expires < Date.now()) {
          store.delete(key);
          return false;
        }

        return true;
      }
    };
  },

  // Get cache store (Redis preferred, fallback to memory)
  getStore() {
    return this.stores.redis || this.stores.memory;
  },

  // Cache operations
  async get(key) {
    const store = this.getStore();
    const value = await store.get(key);

    if (value !== null) {
      this.stats.hits++;
    } else {
      this.stats.misses++;
    }

    return value;
  },

  async set(key, value, ttl = this.config.defaultTtl) {
    const store = this.getStore();
    const result = await store.set(key, value, ttl);

    if (result) {
      this.stats.sets++;
    }

    return result;
  },

  async delete(key) {
    const store = this.getStore();
    const result = await store.delete(key);

    if (result) {
      this.stats.deletes++;
    }

    return result;
  },

  async clear() {
    const store = this.getStore();
    const result = await store.clear();

    if (result) {
      this.stats.clears++;
    }

    return result;
  },

  async has(key) {
    const store = this.getStore();
    return await store.has(key);
  },

  // Cache decorators
  memoize(fn, ttl = this.config.defaultTtl, keyFn = null) {
    return async (...args) => {
      const key = keyFn ? keyFn(...args) : `${fn.name}:${JSON.stringify(args)}`;

      let result = await this.get(key);
      if (result !== null) {
        return result;
      }

      result = await fn(...args);
      await this.set(key, result, ttl);

      return result;
    };
  },

  // Cache middleware for Express.js
  middleware(ttl = this.config.defaultTtl, keyFn = null) {
    return async (req, res, next) => {
      const key = keyFn ? keyFn(req) : `http:${req.method}:${req.originalUrl}`;

      // Try to get cached response
      const cached = await this.get(key);
      if (cached) {
        res.set(cached.headers);
        res.status(cached.status).send(cached.body);
        return;
      }

      // Intercept response
      const originalSend = res.send;
      const originalStatus = res.status;

      let responseBody = '';
      let responseStatus = 200;
      const responseHeaders = {};

      res.send = function(body) {
        responseBody = body;
        return originalSend.call(this, body);
      };

      res.status = function(code) {
        responseStatus = code;
        return originalStatus.call(this, code);
      };

      res.on('finish', async () => {
        // Cache successful GET responses
        if (req.method === 'GET' && responseStatus >= 200 && responseStatus < 300) {
          const cacheData = {
            body: responseBody,
            status: responseStatus,
            headers: responseHeaders,
            timestamp: Date.now()
          };

          await this.set(key, cacheData, ttl);
        }
      });

      next();
    };
  },

  // Cache warming
  async warm(keys) {
    console.log(`Warming cache with ${keys.length} keys...`);

    for (const key of keys) {
      // Implement cache warming logic based on your application needs
      console.log(`Warming key: ${key}`);
    }
  },

  // Get cache statistics
  getStats() {
    const total = this.stats.hits + this.stats.misses;
    const hitRate = total > 0 ? (this.stats.hits / total * 100).toFixed(2) : 0;

    return {
      ...this.stats,
      totalRequests: total,
      hitRate: `${hitRate}%`,
      store: this.stores.redis ? 'redis' : 'memory'
    };
  },

  // Reset statistics
  resetStats() {
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0,
      clears: 0
    };
  }
};

// Cache strategies
cache.strategies = {
  // Cache-Aside (Lazy Loading)
  cacheAside: {
    async get(key, fetchFn, ttl = cache.config.defaultTtl) {
      let value = await cache.get(key);
      if (value === null) {
        value = await fetchFn();
        await cache.set(key, value, ttl);
      }
      return value;
    }
  },

  // Write-Through
  writeThrough: {
    async set(key, value, ttl = cache.config.defaultTtl) {
      await cache.set(key, value, ttl);
      // Also write to database
      return value;
    }
  },

  // Write-Behind (Write-Back)
  writeBehind: {
    queue: [],
    async set(key, value, ttl = cache.config.defaultTtl) {
      // Add to cache immediately
      await cache.set(key, value, ttl);

      // Queue for background write to database
      this.queue.push({ key, value });

      // Process queue in background (implement based on your needs)
      this.processQueue();
    },

    processQueue() {
      // Implement background processing
      setTimeout(() => {
        while (this.queue.length > 0) {
          const item = this.queue.shift();
          // Write to database
          console.log('Processing write-behind:', item.key);
        }
      }, 1000);
    }
  },

  // Cache invalidation patterns
  invalidation: {
    // Direct invalidation
    direct: async (key) => {
      return await cache.delete(key);
    },

    // Pattern-based invalidation
    pattern: async (pattern) => {
      // This would require scanning keys in Redis
      // Implementation depends on your Redis setup
      console.log(`Invalidating pattern: ${pattern}`);
    },

    // Time-based expiration (handled automatically by TTL)
    timeBased: (ttl) => {
      return ttl;
    }
  }
};

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = cache;
} else if (typeof window !== 'undefined') {
  window.cache = cache;
}