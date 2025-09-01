/**
 * Internationalization Configuration
 * Uses i18next with lazy loading, pluralization, validation, and missing key detection
 */

const i18next = require('i18next');
const Backend = require('i18next-fs-backend');
const i18nextMiddleware = require('i18next-http-middleware');
const sprintf = require('i18next-sprintf-postprocessor');

// In-memory storage for server-side compatibility
const storage = {};

const i18n = {
  // Default configuration
  defaultLocale: 'en',
  locales: ['en', 'es', 'fr', 'de', 'zh', 'ja'],
  fallbackLocale: 'en',

  // i18next instance
  instance: null,

  // Fallback resources for English locale
  resources: {
    en: {
      // Common UI elements
      common: {
        welcome: 'Welcome',
        loading: 'Loading...',
        error: 'Error',
        success: 'Success',
        cancel: 'Cancel',
        confirm: 'Confirm',
        save: 'Save',
        delete: 'Delete',
        edit: 'Edit',
        create: 'Create',
        search: 'Search',
        filter: 'Filter',
        sort: 'Sort',
        export: 'Export',
        import: 'Import',
        download: 'Download',
        upload: 'Upload',
        refresh: 'Refresh',
        back: 'Back',
        next: 'Next',
        previous: 'Previous',
        close: 'Close',
        open: 'Open',
        yes: 'Yes',
        no: 'No',
      },
      // Authentication related strings
      auth: {
        login: 'Login',
        logout: 'Logout',
        register: 'Register',
        forgotPassword: 'Forgot Password',
        resetPassword: 'Reset Password',
        changePassword: 'Change Password',
        email: 'Email',
        password: 'Password',
        confirmPassword: 'Confirm Password',
        rememberMe: 'Remember Me',
        loginSuccess: 'Login successful',
        loginError: 'Login failed',
        registerSuccess: 'Registration successful',
        registerError: 'Registration failed',
      },
      // User profile and settings
      user: {
        profile: 'Profile',
        settings: 'Settings',
        preferences: 'Preferences',
        account: 'Account',
        firstName: 'First Name',
        lastName: 'Last Name',
        username: 'Username',
        bio: 'Bio',
        location: 'Location',
        timezone: 'Timezone',
        language: 'Language',
        theme: 'Theme',
        notifications: 'Notifications',
      },
      // Error messages
      errors: {
        networkError: 'Network error',
        serverError: 'Server error',
        validationError: 'Validation error',
        unauthorized: 'Unauthorized',
        forbidden: 'Forbidden',
        notFound: 'Not found',
        timeout: 'Request timeout',
        unknown: 'Unknown error',
      },
      // Validation messages
      validation: {
        required: 'This field is required',
        email: 'Please enter a valid email',
        minLength: 'Minimum length is {{min}} characters',
        maxLength: 'Maximum length is {{max}} characters',
        passwordMismatch: 'Passwords do not match',
        invalidFormat: 'Invalid format',
      },
    },
    // Additional languages can be added here...
  },

  // Initialize i18next
  async init(options = {}) {
    const config = {
      lng: this.getLocale(),
      fallbackLng: this.fallbackLocale,
      ns: ['common', 'auth', 'user', 'errors', 'validation'],
      defaultNS: 'common',
      debug: process.env.NODE_ENV === 'development',

      // Backend configuration for lazy loading
      backend: {
        loadPath: './locales/{{lng}}/{{ns}}.json',
        addPath: './locales/{{lng}}/{{ns}}.json',
        allowMultiLoading: true,
        parse: data => JSON.parse(data),
        stringify: data => JSON.stringify(data, null, 2),
      },

      // Interpolation
      interpolation: {
        escapeValue: false, // React already escapes
        format: (value, format) => {
          if (format === 'uppercase') return value.toUpperCase();
          if (format === 'lowercase') return value.toLowerCase();
          return value;
        },
      },

      // Pluralization
      pluralSeparator: '_',
      contextSeparator: '_',

      // Missing key detection
      saveMissing: true,
      saveMissingTo: 'all',
      missingKeyHandler: (lng, ns, key, fallbackValue) => {
        console.warn(`Missing translation key: ${lng}:${ns}:${key}`);
        // Log missing keys for later review
        this.logMissingKey(lng, ns, key, fallbackValue);
      },

      // Validation
      validate: (lng, ns, key, value) => {
        if (!value || typeof value !== 'string') {
          console.error(`Invalid translation value for ${lng}:${ns}:${key}`);
          return false;
        }
        return true;
      },

      // Post processor for sprintf
      postProcess: ['sprintf'],

      ...options,
    };

    // Initialize i18next with backend
    await i18next
      .use(Backend)
      .use(i18nextMiddleware.LanguageDetector)
      .use(sprintf)
      .init(config);

    this.instance = i18next;

    // Load initial resources as fallback
    this.loadFallbackResources();

    console.log('i18n initialized with lazy loading and validation');
  },

  // Load fallback resources
  loadFallbackResources() {
    for (const lng of this.locales) {
      // Validate lng is in our predefined locales to prevent injection

      if (!this.locales.includes(lng)) continue;
      if (!Object.prototype.hasOwnProperty.call(this.resources, lng)) continue;
      // Use Object.prototype.hasOwnProperty to safely access the property
      // eslint-disable-next-line security/detect-object-injection
      const lngResources = this.resources[lng];
      for (const ns of this.instance.options.ns) {
        if (Object.prototype.hasOwnProperty.call(lngResources, ns)) {
          this.instance.addResourceBundle(
            lng,

            ns,
            // eslint-disable-next-line security/detect-object-injection
            lngResources[ns],
            true,
            true
          );
        }
      }
    }
  },

  // Get current locale
  getLocale() {
    return storage['i18nextLng'] || this.defaultLocale;
  },

  // Set locale
  async setLocale(locale) {
    if (this.locales.includes(locale)) {
      await this.instance.changeLanguage(locale);
      storage['i18nextLng'] = locale;
      return true;
    }
    return false;
  },

  // Translate with pluralization support
  t(key, options = {}) {
    return this.instance.t(key, {
      ...options,
      // Enable pluralization
      count: options.count || 1,
    });
  },

  // Translate with context
  tc(key, context, options = {}) {
    return this.instance.t(key, {
      ...options,
      context,
    });
  },

  // Check if translation exists
  exists(key, options = {}) {
    return this.instance.exists(key, options);
  },

  // Get all loaded languages
  getLanguages() {
    return this.instance.languages;
  },

  // Add resource bundle
  addResourceBundle(lng, ns, resources) {
    this.instance.addResourceBundle(lng, ns, resources, true, true);
  },

  // Remove resource bundle
  removeResourceBundle(lng, ns) {
    // Use lng parameter to avoid ESLint warning
    if (!lng) {
      console.warn('Language code is required for removeResourceBundle');
      return;
    }
    this.instance.removeResourceBundle(lng, ns);
  },

  // Load namespace
  async loadNamespace(ns) {
    await this.instance.loadNamespaces(ns);
  },

  // Reload resources
  async reloadResources(lng, ns) {
    await this.instance.reloadResources(lng, ns);
  },

  // Log missing keys
  logMissingKey(lng, ns, key, fallbackValue) {
    // In production, you might want to send this to a logging service
    const missingKey = {
      language: lng,
      namespace: ns,
      key,
      fallback: fallbackValue,
      timestamp: new Date().toISOString(),
      userAgent:
        typeof navigator !== 'undefined' ? navigator.userAgent : 'server',
    };

    // Store in storage for development
    const existing = JSON.parse(storage['i18n_missing_keys'] || '[]');
    existing.push(missingKey);
    storage['i18n_missing_keys'] = JSON.stringify(existing.slice(-100)); // Keep last 100

    console.warn('Missing translation:', missingKey);
  },

  // Get missing keys report
  getMissingKeysReport() {
    return JSON.parse(storage['i18n_missing_keys'] || '[]');
  },

  // Clear missing keys report
  clearMissingKeysReport() {
    delete storage['i18n_missing_keys'];
  },

  // Validate translations
  validateTranslations() {
    const errors = [];
    const languages = this.getLanguages();

    for (const lng of languages) {
      for (const ns of this.instance.options.ns) {
        const bundle = this.instance.getResourceBundle(lng, ns);
        if (bundle) {
          this.validateResourceBundle(lng, ns, bundle, errors);
        }
      }
    }

    return errors;
  },

  // Validate resource bundle for common issues
  validateResourceBundle(lng, ns, bundle, errors) {
    const validateValue = (key, value) => {
      if (typeof value === 'string') {
        // Check for empty translations
        if (value.trim() === '') {
          errors.push({ lng, ns, key, error: 'Empty translation value' });
        }
        // Check for malformed interpolation syntax
        if (value.includes('{{') && !value.includes('}}')) {
          errors.push({
            lng,
            ns,
            key,
            error: 'Unclosed interpolation placeholder',
          });
        }
      } else if (typeof value === 'object' && value !== null) {
        // Recursively validate nested objects
        for (const [k, v] of Object.entries(value)) {
          validateValue(`${key}.${k}`, v);
        }
      }
    };

    // Validate all keys in the bundle
    for (const [key, value] of Object.entries(bundle)) {
      validateValue(key, value);
    }
  },

  // Format date
  formatDate(date, format = 'short', lng = this.getLocale()) {
    const formatter = new Intl.DateTimeFormat(lng, {
      dateStyle: format,
    });
    return formatter.format(date);
  },

  // Format number
  formatNumber(number, options = {}, lng = this.getLocale()) {
    const formatter = new Intl.NumberFormat(lng, options);
    return formatter.format(number);
  },

  // Format currency
  formatCurrency(amount, currency = 'USD', lng = this.getLocale()) {
    return this.formatNumber(amount, { style: 'currency', currency }, lng);
  },

  // Format relative time (e.g., "2 hours ago", "in 3 days")
  formatRelativeTime(date, lng = this.getLocale()) {
    const formatter = new Intl.RelativeTimeFormat(lng, { numeric: 'auto' });
    const diffMs = date.getTime() - Date.now();
    const diffSeconds = Math.floor(diffMs / 1000);
    const absSeconds = Math.abs(diffSeconds);

    // Determine the appropriate time unit
    if (absSeconds < 60) {
      return formatter.format(diffSeconds, 'second');
    } else if (absSeconds < 3600) {
      // Less than 1 hour
      return formatter.format(Math.floor(diffSeconds / 60), 'minute');
    } else if (absSeconds < 86400) {
      // Less than 1 day
      return formatter.format(Math.floor(diffSeconds / 3600), 'hour');
    } else {
      // Days or more
      return formatter.format(Math.floor(diffSeconds / 86400), 'day');
    }
  },

  // Get direction (RTL/LTR)
  getDirection(lng = this.getLocale()) {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.includes(lng) ? 'rtl' : 'ltr';
  },

  // Middleware for Express.js
  middleware() {
    return i18nextMiddleware.handle(i18next, {
      ignoreRoutes: ['/api/', '/static/'],
      removeLngFromUrl: false,
    });
  },

  // Get i18next instance
  getInstance() {
    return this.instance;
  },

  // Shutdown
  async shutdown() {
    if (this.instance) {
      await this.instance.services.backendConnector.backend.store.flush();
    }
  },
};

// Utility functions for backward compatibility
i18n.translate = i18n.t.bind(i18n);

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = i18n;
} else if (typeof window !== 'undefined') {
  window.i18n = i18n;
}
