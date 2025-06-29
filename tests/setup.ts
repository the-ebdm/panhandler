/**
 * Global test setup for Bun test runner
 * This file is preloaded before any tests run
 */

import { beforeAll, afterAll } from 'bun:test';

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.LOG_LEVEL = 'error'; // Suppress logs during testing

// Database test configuration
process.env.DATABASE_HOST = 'localhost';
process.env.DATABASE_PORT = '5433'; // Use different port for test DB
process.env.DATABASE_NAME = 'panhandler_test';
process.env.DATABASE_USER = 'test_user';
process.env.DATABASE_PASSWORD = 'test_password';
process.env.DATABASE_SSL = 'false';

// API configuration for testing
process.env.OPENROUTER_API_KEY = 'test-api-key-not-real';
process.env.PORT = '0'; // Use random port for tests

// Global test hooks
beforeAll(async () => {
  console.log('🧪 Bun test suite starting...');
});

afterAll(async () => {
  console.log('✅ Bun test suite completed');
});

// Export utilities for test files
export * from './utils/test-helpers';
export * from './utils/db-helpers'; 