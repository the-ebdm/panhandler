/**
 * Environment configuration types for the Panhandler system
 */

export type NodeEnvironment = 'development' | 'staging' | 'production' | 'test';

export type LogLevel = 'error' | 'warn' | 'info' | 'debug';

export type GitProvider = 'github' | 'gitlab';

/**
 * Complete environment configuration interface
 */
export interface EnvironmentConfig {
  // Application Configuration
  NODE_ENV: NodeEnvironment;
  APP_NAME: string;
  APP_VERSION: string;
  APP_PORT: number;
  API_PORT: number;

  // OpenRouter API Configuration
  OPENROUTER_API_KEY: string;
  OPENROUTER_DEFAULT_MODEL?: string;
  OPENROUTER_BASE_URL: string;

  // Database Configuration
  DATABASE_URL: string;
  REDIS_URL: string;

  // Security Configuration
  JWT_SECRET: string;
  SESSION_SECRET: string;
  CORS_ORIGINS: string[];

  // Logging and Monitoring
  LOG_LEVEL: LogLevel;
  REQUEST_LOGGING: boolean;
  SENTRY_DSN?: string;

  // Development Configuration
  DEV_MODE: boolean;
  AGENT_HOT_RELOAD: boolean;
  DEBUG_MODE: boolean;

  // Git Repository Configuration
  GIT_PROVIDER: GitProvider;
  GITHUB_TOKEN?: string;
  GITLAB_TOKEN?: string;
  DEFAULT_REPO_URL?: string;

  // Performance Configuration
  MAX_CONCURRENT_AGENTS: number;
  REQUEST_TIMEOUT_MS: number;
  AGENT_TIMEOUT_MS: number;

  // File System Configuration
  TEMP_DIR: string;
  MAX_FILE_SIZE: number;
  CLEANUP_INTERVAL_MS: number;
}

/**
 * Required environment variables (must be present)
 */
export const REQUIRED_ENV_VARS = [
  'NODE_ENV',
  'APP_NAME',
  'APP_VERSION',
  'APP_PORT',
  'API_PORT',
  'OPENROUTER_API_KEY',
  'OPENROUTER_BASE_URL',
  'DATABASE_URL',
  'REDIS_URL',
  'JWT_SECRET',
  'SESSION_SECRET',
  'CORS_ORIGINS',
  'LOG_LEVEL',
  'REQUEST_LOGGING',
  'DEV_MODE',
  'AGENT_HOT_RELOAD',
  'DEBUG_MODE',
  'GIT_PROVIDER',
  'MAX_CONCURRENT_AGENTS',
  'REQUEST_TIMEOUT_MS',
  'AGENT_TIMEOUT_MS',
  'TEMP_DIR',
  'MAX_FILE_SIZE',
  'CLEANUP_INTERVAL_MS',
] as const;

/**
 * Optional environment variables with defaults
 */
export const OPTIONAL_ENV_VARS = [
  'OPENROUTER_DEFAULT_MODEL',
  'SENTRY_DSN',
  'GITHUB_TOKEN',
  'GITLAB_TOKEN',
  'DEFAULT_REPO_URL',
] as const;

/**
 * Environment variable validation rules
 */
export interface ValidationRule {
  type: 'string' | 'number' | 'boolean' | 'array' | 'url' | 'enum';
  required: boolean;
  default?: unknown;
  enum?: readonly string[];
  min?: number;
  max?: number;
  pattern?: RegExp;
}

export const ENV_VALIDATION_RULES: Record<keyof EnvironmentConfig, ValidationRule> = {
  NODE_ENV: { type: 'enum', required: true, enum: ['development', 'staging', 'production', 'test'] },
  APP_NAME: { type: 'string', required: true },
  APP_VERSION: { type: 'string', required: true, pattern: /^\d+\.\d+\.\d+/ },
  APP_PORT: { type: 'number', required: true, min: 1000, max: 65535 },
  API_PORT: { type: 'number', required: true, min: 1000, max: 65535 },
  OPENROUTER_API_KEY: { type: 'string', required: true, pattern: /^sk-/ },
  OPENROUTER_DEFAULT_MODEL: { type: 'string', required: false },
  OPENROUTER_BASE_URL: { type: 'url', required: true },
  DATABASE_URL: { type: 'url', required: true },
  REDIS_URL: { type: 'url', required: true },
  JWT_SECRET: { type: 'string', required: true, min: 32 },
  SESSION_SECRET: { type: 'string', required: true, min: 32 },
  CORS_ORIGINS: { type: 'array', required: true },
  LOG_LEVEL: { type: 'enum', required: true, enum: ['error', 'warn', 'info', 'debug'] },
  REQUEST_LOGGING: { type: 'boolean', required: true },
  SENTRY_DSN: { type: 'url', required: false },
  DEV_MODE: { type: 'boolean', required: true },
  AGENT_HOT_RELOAD: { type: 'boolean', required: true },
  DEBUG_MODE: { type: 'boolean', required: true },
  GIT_PROVIDER: { type: 'enum', required: true, enum: ['github', 'gitlab'] },
  GITHUB_TOKEN: { type: 'string', required: false },
  GITLAB_TOKEN: { type: 'string', required: false },
  DEFAULT_REPO_URL: { type: 'url', required: false },
  MAX_CONCURRENT_AGENTS: { type: 'number', required: true, min: 1, max: 50 },
  REQUEST_TIMEOUT_MS: { type: 'number', required: true, min: 1000, max: 300000 },
  AGENT_TIMEOUT_MS: { type: 'number', required: true, min: 10000, max: 1800000 },
  TEMP_DIR: { type: 'string', required: true },
  MAX_FILE_SIZE: { type: 'number', required: true, min: 1024, max: 104857600 },
  CLEANUP_INTERVAL_MS: { type: 'number', required: true, min: 60000 },
};

/**
 * Environment validation error
 */
export class EnvironmentValidationError extends Error {
  constructor(
    public readonly field: string,
    public readonly value: unknown,
    public readonly rule: ValidationRule,
    message: string
  ) {
    super(`Environment validation error for ${field}: ${message}`);
    this.name = 'EnvironmentValidationError';
  }
} 