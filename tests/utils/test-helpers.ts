/**
 * Simple test utilities for Bun test runner
 * Focused on real integration testing, not mocks
 */

import { expect } from 'bun:test';

/**
 * Sleep utility for testing async operations
 */
export const sleep = (ms: number): Promise<void> =>
  new Promise(resolve => setTimeout(resolve, ms));

/**
 * Assert that a function throws with a specific error message
 */
export const expectToThrow = async (
  fn: () => Promise<unknown> | unknown,
  expectedMessage?: string
): Promise<void> => {
  try {
    await fn();
    throw new Error('Expected function to throw, but it did not');
  } catch (error) {
    if (expectedMessage && error instanceof Error) {
      expect(error.message).toContain(expectedMessage);
    }
  }
};

/**
 * Wait for a condition to become true (useful for integration tests)
 */
export const waitFor = async (
  condition: () => boolean | Promise<boolean>,
  timeoutMs = 5000,
  intervalMs = 100
): Promise<void> => {
  const start = Date.now();

  while (Date.now() - start < timeoutMs) {
    if (await condition()) {
      return;
    }
    await sleep(intervalMs);
  }

  throw new Error(`Condition not met within ${timeoutMs}ms`);
};

/**
 * Test data utilities
 */
export const TestData = {
  randomString: (length = 10): string => {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return Array.from({ length }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  },

  randomId: (): string => TestData.randomString(8),

  futureDate: (daysFromNow = 30): Date =>
    new Date(Date.now() + daysFromNow * 24 * 60 * 60 * 1000),
}; 