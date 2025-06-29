/**
 * Environment configuration management for Panhandler
 * Provides type-safe environment variable loading and validation
 */

import {
  EnvironmentConfig,
  EnvironmentValidationError,
  ENV_VALIDATION_RULES,
  NodeEnvironment,
  LogLevel,
  GitProvider,
  ValidationRule,
} from '@panhandler/types';

/**
 * Parse and validate environment variable value according to rule
 */
function parseEnvironmentValue(key: string, value: string | undefined, rule: ValidationRule): unknown {
  // Handle required but missing values
  if (rule.required && (value === undefined || value === '')) {
    throw new EnvironmentValidationError(
      key,
      value,
      rule,
      'Required environment variable is missing or empty'
    );
  }

  // Handle optional missing values
  if (!rule.required && (value === undefined || value === '')) {
    return rule.default ?? undefined;
  }

  if (value === undefined) {
    return undefined;
  }

  // Type-specific parsing and validation
  switch (rule.type) {
    case 'string': {
      if (rule.pattern && !rule.pattern.test(value)) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          `String does not match required pattern: ${rule.pattern}`
        );
      }
      if (rule.min && value.length < rule.min) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          `String is too short. Minimum length: ${rule.min}`
        );
      }
      if (rule.max && value.length > rule.max) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          `String is too long. Maximum length: ${rule.max}`
        );
      }
      return value;
    }

    case 'number': {
      const parsed = Number(value);
      if (isNaN(parsed)) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          'Value is not a valid number'
        );
      }
      if (rule.min !== undefined && parsed < rule.min) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          `Number is too small. Minimum: ${rule.min}`
        );
      }
      if (rule.max !== undefined && parsed > rule.max) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          `Number is too large. Maximum: ${rule.max}`
        );
      }
      return parsed;
    }

    case 'boolean': {
      const lower = value.toLowerCase();
      if (['true', '1', 'yes', 'on'].includes(lower)) {
        return true;
      }
      if (['false', '0', 'no', 'off'].includes(lower)) {
        return false;
      }
      throw new EnvironmentValidationError(
        key,
        value,
        rule,
        'Value is not a valid boolean (true/false, 1/0, yes/no, on/off)'
      );
    }

    case 'array': {
      // Split on commas and trim whitespace
      const parsed = value.split(',').map(item => item.trim()).filter(item => item.length > 0);
      return parsed;
    }

    case 'url': {
      try {
        new URL(value);
        return value;
      } catch {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          'Value is not a valid URL'
        );
      }
    }

    case 'enum': {
      if (!rule.enum || !rule.enum.includes(value)) {
        throw new EnvironmentValidationError(
          key,
          value,
          rule,
          `Value must be one of: ${rule.enum?.join(', ')}`
        );
      }
      return value;
    }

    default:
      throw new EnvironmentValidationError(
        key,
        value,
        rule,
        `Unknown validation rule type: ${rule.type}`
      );
  }
}

/**
 * Load and validate environment configuration
 */
export function loadEnvironmentConfig(): EnvironmentConfig {
  const config: Partial<EnvironmentConfig> = {};
  const errors: EnvironmentValidationError[] = [];

  // Process each environment variable according to its validation rule
  for (const [key, rule] of Object.entries(ENV_VALIDATION_RULES)) {
    try {
      const value = process.env[key];
      const parsed = parseEnvironmentValue(key, value, rule);

      if (parsed !== undefined) {
        (config as any)[key] = parsed;
      }
    } catch (error) {
      if (error instanceof EnvironmentValidationError) {
        errors.push(error);
      } else {
        errors.push(
          new EnvironmentValidationError(
            key,
            process.env[key],
            rule,
            `Unexpected error: ${error instanceof Error ? error.message : String(error)}`
          )
        );
      }
    }
  }

  // If there were validation errors, throw them all
  if (errors.length > 0) {
    const errorMessage = `Environment validation failed with ${errors.length} error(s):\n` +
      errors.map(err => `  - ${err.message}`).join('\n');

    const combinedError = new Error(errorMessage);
    combinedError.name = 'EnvironmentValidationError';
    throw combinedError;
  }

  // Additional cross-field validation
  validateEnvironmentConstraints(config as EnvironmentConfig);

  return config as EnvironmentConfig;
}

/**
 * Validate cross-field constraints and business rules
 */
function validateEnvironmentConstraints(config: EnvironmentConfig): void {
  // Validate port conflicts
  if (config.APP_PORT === config.API_PORT) {
    throw new Error('APP_PORT and API_PORT cannot be the same');
  }

  // Validate Git provider tokens
  if (config.GIT_PROVIDER === 'github' && !config.GITHUB_TOKEN) {
    console.warn('Warning: GITHUB_TOKEN is not set but GIT_PROVIDER is set to github');
  }
  if (config.GIT_PROVIDER === 'gitlab' && !config.GITLAB_TOKEN) {
    console.warn('Warning: GITLAB_TOKEN is not set but GIT_PROVIDER is set to gitlab');
  }

  // Production environment validation
  if (config.NODE_ENV === 'production') {
    // Check for development secrets in production
    if (config.JWT_SECRET.includes('dev_') || config.JWT_SECRET.includes('change_in_production')) {
      throw new Error('Production environment cannot use development JWT secrets');
    }
    if (config.SESSION_SECRET.includes('dev_') || config.SESSION_SECRET.includes('change_in_production')) {
      throw new Error('Production environment cannot use development session secrets');
    }

    // Require HTTPS URLs in production
    if (config.CORS_ORIGINS.some(origin => origin.startsWith('http://') && !origin.includes('localhost'))) {
      throw new Error('Production environment should not allow non-HTTPS CORS origins (except localhost)');
    }
  }

  // Development environment warnings
  if (config.NODE_ENV === 'development') {
    if (config.OPENROUTER_API_KEY === 'your_openrouter_api_key_here') {
      console.warn('Warning: Using placeholder OpenRouter API key in development');
    }
  }
}

/**
 * Global environment configuration instance
 * Loaded once and reused throughout the application
 */
let environmentConfig: EnvironmentConfig | null = null;

/**
 * Get the current environment configuration
 * Loads and validates on first call, returns cached instance on subsequent calls
 */
export function getEnvironmentConfig(): EnvironmentConfig {
  if (!environmentConfig) {
    try {
      environmentConfig = loadEnvironmentConfig();
      console.log(`✅ Environment configuration loaded successfully (${environmentConfig.NODE_ENV})`);
    } catch (error) {
      console.error('❌ Failed to load environment configuration:');
      console.error(error instanceof Error ? error.message : String(error));
      process.exit(1);
    }
  }
  return environmentConfig;
}

/**
 * Reload environment configuration (useful for testing)
 */
export function reloadEnvironmentConfig(): EnvironmentConfig {
  environmentConfig = null;
  return getEnvironmentConfig();
}

/**
 * Check if we're in development mode
 */
export function isDevelopment(): boolean {
  return getEnvironmentConfig().NODE_ENV === 'development';
}

/**
 * Check if we're in production mode
 */
export function isProduction(): boolean {
  return getEnvironmentConfig().NODE_ENV === 'production';
}

/**
 * Check if we're in test mode
 */
export function isTest(): boolean {
  return getEnvironmentConfig().NODE_ENV === 'test';
}

/**
 * Get environment-specific configuration value with type safety
 */
export function getEnvValue<K extends keyof EnvironmentConfig>(key: K): EnvironmentConfig[K] {
  return getEnvironmentConfig()[key];
} 