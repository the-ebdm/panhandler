/**
 * Database Migration Framework Types
 */

export interface MigrationContext {
  query: (sql: string, params?: unknown[]) => Promise<unknown[]>;
  execute: (sql: string, params?: unknown[]) => Promise<void>;
  transaction: <T>(fn: (ctx: MigrationContext) => Promise<T>) => Promise<T>;
}

export interface Migration {
  id: string;
  description: string;
  up: (ctx: MigrationContext) => Promise<void>;
  down: (ctx: MigrationContext) => Promise<void>;
}

export interface MigrationRecord {
  id: string;
  applied_at: Date;
  checksum: string;
}

export interface DatabaseConfig {
  host: string;
  port: number;
  database: string;
  username: string;
  password: string;
  ssl?: boolean;
  pool?: {
    min: number;
    max: number;
  };
}

export interface MigrationResult {
  id: string;
  status: 'applied' | 'rolled_back' | 'failed';
  duration_ms: number;
  error?: string;
}
