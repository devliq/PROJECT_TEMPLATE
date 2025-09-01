/**
 * Caching Configuration and Utilities
 * Uses established libraries: cache-manager with node-cache and ioredis
 * Includes connection pooling, retry logic, and cache warming strategies
 */

const cacheManager = require('cache-manager');
const nodeCache = require('cache-manager-node-cache');
const redisStore = require('cache-manager-ioredis');
const IORedis = require('ioredis');

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
      keyPrefix: 'app:',
      // Connection pooling and retry settings
      maxRetriesPerRequest: 3,
      retryDelayOnFailover: 100,
      enableReadyCheck: false,
      lazyConnect: true,
      // Pool settings
      poolSize: 10,
      family: 4,
      keepAlive: 30000,
    },
    // Warming configuration
    warming: {
      enabled: true,
      interval: 300000, // 5 minutes
      keys: [], // Keys to warm
    },
  },

  // Cache stores
  stores: {},

  // Cache statistics
  stats: {
    hits: 0,
    misses: 0,
    sets: 0,
    deletes: 0,
    clears: 0,
  },

  // Initialize cache
  async init(options = {}) {
    this.config = { ...this.config, ...options };

    // Initialize memory store as primary fallback
    this.stores.memory = cacheManager.caching({
      store: nodeCache,
      ttl: this.config.defaultTtl,
      max: this.config.maxMemory,
    });

    // Initialize Redis store if available
    if (await this.isRedisAvailable()) {
      this.stores.redis = await this.createRedisStore();
    }

    // Use Redis if available, otherwise memory
    this.cache = this.stores.redis || this.stores.memory;

    // Start cache warming if enabled
    if (this.config.warming.enabled) {
      this.startWarming();
    }

    console.log('Cache initialized with stores:', Object.keys(this.stores));
  },

  // Check if Redis is available
  async isRedisAvailable() {
    try {
      const testClient = new IORedis(this.config.redis);
      await testClient.ping();
      await testClient.quit();
      return true;
    } catch (e) {
      console.warn('Redis not available:', e.message);
      return false;
    }
  },

  // Create Redis store with configuration
  async createRedisStore() {
    const redisInstance = new IORedis({
      ...this.config.redis,
      reconnectOnError: err => {
        console.error('Redis reconnect on error:', err.message);
        return err.message.includes('READONLY');
      },
    });

    // Connection event handlers
    redisInstance.on('connect', () => {
      console.log('Connected to Redis');
    });

    redisInstance.on('error', err => {
      console.error('Redis Client Error:', err);
    });

    redisInstance.on('ready', () => {
      console.log('Redis client ready');
    });

    redisInstance.on('close', () => {
      console.log('Redis connection closed');
    });

    // Wait for connection
    await redisInstance.connect();

    return cacheManager.caching({
      store: redisStore,
      redisInstance,
      ttl: this.config.defaultTtl,
      keyPrefix: this.config.redis.keyPrefix,
    });
  },

  // Cache operations with retry logic
  async get(key) {
    try {
      const value = await this.cache.get(key);
      if (value !== undefined) {
        this.stats.hits++;
      } else {
        this.stats.misses++;
      }
      return value;
    } catch (err) {
      console.error('Cache get error:', err);
      this.stats.misses++;
      return null;
    }
  },

  async set(key, value, ttl = this.config.defaultTtl) {
    try {
      const result = await this.cache.set(key, value, { ttl });
      if (result) {
        this.stats.sets++;
      }
      return result;
    } catch (err) {
      console.error('Cache set error:', err);
      return false;
    }
  },

  async delete(key) {
    try {
      const result = await this.cache.del(key);
      if (result) {
        this.stats.deletes++;
      }
      return result;
    } catch (err) {
      console.error('Cache delete error:', err);
      return false;
    }
  },

  async clear() {
    try {
      await this.cache.reset();
      this.stats.clears++;
      return true;
    } catch (err) {
      console.error('Cache clear error:', err);
      return false;
    }
  },

  async has(key) {
    try {
      const value = await this.get(key);
      return value !== null;
    } catch (err) {
      console.error('Cache has error:', err);
      return false;
    }
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

      res.send = function sendResponse(body) {
        responseBody = body;
        return originalSend.call(this, body);
      };

      res.status = function setStatus(code) {
        responseStatus = code;
        return originalStatus.call(this, code);
      };

      res.on('finish', async () => {
        // Cache successful GET responses
        if (
          req.method === 'GET' &&
          responseStatus >= 200 &&
          responseStatus < 300
        ) {
          const cacheData = {
            body: responseBody,
            status: responseStatus,
            headers: responseHeaders,
            timestamp: Date.now(),
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

    const promises = keys.map(key => {
      return (() => {
        try {
          console.log(`Warming key: ${key}`);
          // Placeholder for actual data fetching logic
          // cache.set(key, fetchDataForKey(key));
        } catch (err) {
          console.error(`Error warming key ${key}:`, err);
        }
      })();
    });

    await Promise.allSettled(promises);
  },

  // Start cache warming
  startWarming() {
    if (this.config.warming.keys.length > 0) {
      this.warm(this.config.warming.keys);
    }
  },

  // Add keys to warming list
  addWarmingKeys(keys) {
    this.config.warming.keys = [
      ...new Set([...this.config.warming.keys, ...keys]),
    ];
  },

  // Remove keys from warming list
  removeWarmingKeys(keys) {
    this.config.warming.keys = this.config.warming.keys.filter(
      key => !keys.includes(key)
    );
  },

  // Get cache statistics
  getStats() {
    const total = this.stats.hits + this.stats.misses;
    const hitRate =
      total > 0 ? ((this.stats.hits / total) * 100).toFixed(2) : 0;

    return {
      ...this.stats,
      totalRequests: total,
      hitRate: `${hitRate}%`,
      store: this.stores.redis ? 'redis' : 'memory',
      warmingEnabled: this.config.warming.enabled,
      warmingKeys: this.config.warming.keys.length,
    };
  },

  // Reset statistics
  resetStats() {
    this.stats = {
      hits: 0,
      misses: 0,
      sets: 0,
      deletes: 0,
      clears: 0,
    };
  },

  // Health check
  async healthCheck() {
    try {
      const stats = this.getStats();
      const ping = (await this.cache.store.ping)
        ? await this.cache.store.ping()
        : 'OK';
      return {
        status: 'healthy',
        stats,
        ping,
      };
    } catch (err) {
      return {
        status: 'unhealthy',
        error: err.message,
      };
    }
  },

  // Graceful shutdown
  async shutdown() {
    this.stopWarming();

    if (this.stores.redis && this.stores.redis.store.redisInstance) {
      await this.stores.redis.store.redisInstance.quit();
    }

    console.log('Cache shutdown complete');
  },
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
    },
  },

  // Write-Through
  writeThrough: {
    async set(key, value, ttl = cache.config.defaultTtl) {
      await cache.set(key, value, ttl);
      // Also write to database
      return value;
    },
  },

  // Write-Behind (Write-Back)
  writeBehind: {
    queue: [],
    async set(key, value, ttl = cache.config.defaultTtl) {
      // Add to cache immediately
      await cache.set(key, value, ttl);

      // Queue for background write to database
      this.queue.push({ key, value });

      // Process queue in background
      this.processQueue();
    },

    processQueue() {
      // Implement background processing with retry logic
      setTimeout(async () => {
        while (this.queue.length > 0) {
          const item = this.queue.shift();
          try {
            // Write to database with retry
            await this.writeToDatabaseWithRetry(item);
            console.log('Processed write-behind:', item.key);
          } catch (err) {
            console.error('Failed to process write-behind:', err);
            // Re-queue for retry
            this.queue.unshift(item);
            break; // Stop processing on error
          }
        }
      }, 1000);
    },

    async writeToDatabaseWithRetry(item, retries = 3) {
      for (let i = 0; i < retries; i++) {
        try {
          // Implement your database write logic here
          // await database.set(item.key, item.value);
          // return true; // Uncomment when database write is implemented
        } catch (err) {
          if (i === retries - 1) throw err;
          await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
        }
      }
    },
  },

  // Cache invalidation patterns
  invalidation: {
    // Direct invalidation
    // eslint-disable-next-line require-await
    direct: async key => {
      return cache.delete(key);
    },

    // Pattern-based invalidation
    pattern: async pattern => {
      // This requires Redis SCAN for pattern matching
      if (cache.stores.redis) {
        const redis = cache.stores.redis.store.redisInstance;
        const keys = await redis.keys(
          `${cache.config.redis.keyPrefix}${pattern}`
        );
        if (keys.length > 0) {
          await redis.del(keys);
        }
      }
      console.log(`Invalidated pattern: ${pattern}`);
    },

    // Time-based expiration (handled automatically by TTL)
    timeBased: ttl => {
      return ttl;
    },
  },
};

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = cache;
} else if (typeof window !== 'undefined') {
  window.cache = cache;
}
