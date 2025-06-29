/**
 * Database testing utilities using Bun's native PostgreSQL client
 */

import { sql } from 'bun';
import type { DatabaseConfig } from '@panhandler/types';

/**
 * Test database configuration from environment
 */
export const getTestDbConfig = (): DatabaseConfig => ({
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5433'),
  database: process.env.DATABASE_NAME || 'panhandler_test',
  username: process.env.DATABASE_USER || 'test_user',
  password: process.env.DATABASE_PASSWORD || 'test_password',
  ssl: process.env.DATABASE_SSL === 'true',
  pool: {
    min: 1,
    max: 5,
  },
});

/**
 * Get database connection URL for testing
 */
export const getTestDbUrl = (): string => {
  const config = getTestDbConfig();
  return `postgresql://${config.username}:${config.password}@${config.host}:${config.port}/${config.database}`;
};

/**
 * Execute SQL query in test database 
 * Note: This will use Bun's native postgres client in the actual implementation
 */
export const testQuery = async <T = any>(query: string, params: any[] = []): Promise<T[]> => {
  const dbUrl = getTestDbUrl();

  // Placeholder - will implement with actual Bun postgres client
  console.log(`Executing query: ${query}`, { params, dbUrl });

  // For now return empty array - this will be replaced with real postgres calls
  return [] as T[];
};

/**
 * Clean up test database - remove all data but keep schema
 */
export const cleanTestDatabase = async (): Promise<void> => {
  await testQuery(`
    TRUNCATE TABLE 
      agent_executions,
      agent_instances, 
      projects,
      migrations
    RESTART IDENTITY CASCADE
  `);
};

/**
 * Set up test database with fresh schema
 */
export const setupTestDatabase = async (): Promise<void> => {
  // Run migrations to ensure schema is up to date
  // This would typically call the migration system
  console.log('Setting up test database schema...');
};

/**
 * Tear down test database
 */
export const teardownTestDatabase = async (): Promise<void> => {
  await cleanTestDatabase();
};

/**
 * Create test data factories
 */
export const TestDataFactory = {
  /**
   * Create a test project
   */
  project: async (overrides: Partial<any> = {}): Promise<any> => {
    const defaultProject = {
      id: `test-project-${Date.now()}`,
      name: `Test Project ${Date.now()}`,
      description: 'A test project for unit testing',
      repository_url: 'https://github.com/test/test-repo',
      created_at: new Date(),
      updated_at: new Date(),
      ...overrides,
    };

    await testQuery(
      `
      INSERT INTO projects (id, name, description, repository_url, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [
        defaultProject.id,
        defaultProject.name,
        defaultProject.description,
        defaultProject.repository_url,
        defaultProject.created_at,
        defaultProject.updated_at,
      ]
    );

    return defaultProject;
  },

  /**
   * Create a test agent instance
   */
  agentInstance: async (overrides: Partial<any> = {}): Promise<any> => {
    const defaultAgent = {
      id: `test-agent-${Date.now()}`,
      type: 'planner',
      status: 'idle',
      config: { test: true },
      created_at: new Date(),
      updated_at: new Date(),
      ...overrides,
    };

    await testQuery(
      `
      INSERT INTO agent_instances (id, type, status, config, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      `,
      [
        defaultAgent.id,
        defaultAgent.type,
        defaultAgent.status,
        JSON.stringify(defaultAgent.config),
        defaultAgent.created_at,
        defaultAgent.updated_at,
      ]
    );

    return defaultAgent;
  },

  /**
   * Create a test agent execution
   */
  agentExecution: async (overrides: Partial<any> = {}): Promise<any> => {
    const defaultExecution = {
      id: `test-execution-${Date.now()}`,
      agent_id: 'test-agent',
      project_id: 'test-project',
      status: 'completed',
      input_data: { test: true },
      output_data: { result: 'success' },
      started_at: new Date(),
      completed_at: new Date(),
      created_at: new Date(),
      ...overrides,
    };

    await testQuery(
      `
      INSERT INTO agent_executions 
      (id, agent_id, project_id, status, input_data, output_data, started_at, completed_at, created_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `,
      [
        defaultExecution.id,
        defaultExecution.agent_id,
        defaultExecution.project_id,
        defaultExecution.status,
        JSON.stringify(defaultExecution.input_data),
        JSON.stringify(defaultExecution.output_data),
        defaultExecution.started_at,
        defaultExecution.completed_at,
        defaultExecution.created_at,
      ]
    );

    return defaultExecution;
  },
};

/**
 * Database assertion helpers
 */
export const DbAssertions = {
  /**
   * Assert that a record exists in the database
   */
  recordExists: async (table: string, id: string): Promise<boolean> => {
    const result = await testQuery(`SELECT 1 FROM ${table} WHERE id = $1`, [id]);
    return result.length > 0;
  },

  /**
   * Assert record count in table
   */
  recordCount: async (table: string, expectedCount: number): Promise<void> => {
    const result = await testQuery(`SELECT COUNT(*) as count FROM ${table}`);
    const actualCount = parseInt(result[0].count);
    if (actualCount !== expectedCount) {
      throw new Error(`Expected ${expectedCount} records in ${table}, but found ${actualCount}`);
    }
  },

  /**
   * Get record by ID
   */
  getRecord: async <T = any>(table: string, id: string): Promise<T | null> => {
    const result = await testQuery(`SELECT * FROM ${table} WHERE id = $1`, [id]);
    return result.length > 0 ? (result[0] as T) : null;
  },
}; 