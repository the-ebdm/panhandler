import { sql } from 'bun';
import type {
  Migration,
  MigrationContext,
  MigrationRecord,
  MigrationResult,
  DatabaseConfig,
} from '@panhandler/types';
import crypto from 'crypto';

export class PostgresMigrationRunner {
  private config: DatabaseConfig;

  constructor(config: DatabaseConfig) {
    this.config = config;
  }

  private createMigrationContext(): MigrationContext {
    return {
      query: async (query: string, _params?: unknown[]) => {
        // Use sql function directly for safe queries
        const result = await sql`${query}`;
        return Array.isArray(result) ? result : [result];
      },
      execute: async (query: string, _params?: unknown[]) => {
        await sql`${query}`;
      },
      transaction: async <T>(fn: (ctx: MigrationContext) => Promise<T>): Promise<T> => {
        return await sql.begin(async transaction => {
          const txContext: MigrationContext = {
            query: async (query: string, _params?: unknown[]) => {
              const result = await transaction`${query}`;
              return Array.isArray(result) ? result : [result];
            },
            execute: async (query: string, _params?: unknown[]) => {
              await transaction`${query}`;
            },
            transaction: async <U>(fn: (ctx: MigrationContext) => Promise<U>): Promise<U> => {
              // Nested transactions use savepoints
              const savepointName = `sp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
              await transaction`SAVEPOINT ${savepointName}`;
              try {
                const result = await fn(txContext);
                await transaction`RELEASE SAVEPOINT ${savepointName}`;
                return result;
              } catch (error) {
                await transaction`ROLLBACK TO SAVEPOINT ${savepointName}`;
                throw error;
              }
            },
          };
          return await fn(txContext);
        });
      },
    };
  }

  private calculateChecksum(migration: Migration): string {
    const content = migration.up.toString() + migration.down.toString();
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  async ensureMigrationsTable(): Promise<void> {
    await sql`
      CREATE TABLE IF NOT EXISTS migrations (
        id VARCHAR(255) PRIMARY KEY,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        checksum VARCHAR(64) NOT NULL
      )
    `;
  }

  async getAppliedMigrations(): Promise<MigrationRecord[]> {
    const rows = await sql`
      SELECT id, applied_at, checksum 
      FROM migrations 
      ORDER BY applied_at
    `;

    return rows.map((row: { id: string; applied_at: Date; checksum: string }) => ({
      id: row.id,
      applied_at: new Date(row.applied_at),
      checksum: row.checksum,
    }));
  }

  async applyMigration(migration: Migration): Promise<MigrationResult> {
    const startTime = Date.now();

    try {
      const checksum = this.calculateChecksum(migration);
      const context = this.createMigrationContext();

      await sql.begin(async transaction => {
        const txContext: MigrationContext = {
          query: async (query: string, _params?: unknown[]) => {
            const result = await transaction`${query}`;
            return Array.isArray(result) ? result : [result];
          },
          execute: async (query: string, _params?: unknown[]) => {
            await transaction`${query}`;
          },
          transaction: context.transaction, // Use the outer transaction context
        };

        // Run the migration
        await migration.up(txContext);

        // Record the migration
        await transaction`
          INSERT INTO migrations (id, checksum) 
          VALUES (${migration.id}, ${checksum})
        `;
      });

      return {
        id: migration.id,
        status: 'applied',
        duration_ms: Date.now() - startTime,
      };
    } catch (error) {
      return {
        id: migration.id,
        status: 'failed',
        duration_ms: Date.now() - startTime,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async rollbackMigration(migration: Migration): Promise<MigrationResult> {
    const startTime = Date.now();

    try {
      const context = this.createMigrationContext();

      await sql.begin(async transaction => {
        const txContext: MigrationContext = {
          query: async (query: string, _params?: unknown[]) => {
            const result = await transaction`${query}`;
            return Array.isArray(result) ? result : [result];
          },
          execute: async (query: string, _params?: unknown[]) => {
            await transaction`${query}`;
          },
          transaction: context.transaction, // Use the outer transaction context
        };

        // Run the rollback
        await migration.down(txContext);

        // Remove the migration record
        await transaction`
          DELETE FROM migrations WHERE id = ${migration.id}
        `;
      });

      return {
        id: migration.id,
        status: 'rolled_back',
        duration_ms: Date.now() - startTime,
      };
    } catch (error) {
      return {
        id: migration.id,
        status: 'failed',
        duration_ms: Date.now() - startTime,
        error: error instanceof Error ? error.message : String(error),
      };
    }
  }
}

export class MigrationManager {
  private runner: PostgresMigrationRunner;
  private migrations: Migration[] = [];

  constructor(config: DatabaseConfig) {
    this.runner = new PostgresMigrationRunner(config);
  }

  addMigration(migration: Migration): void {
    this.migrations.push(migration);
    // Sort by ID to ensure consistent order
    this.migrations.sort((a, b) => a.id.localeCompare(b.id));
  }

  addMigrations(migrations: Migration[]): void {
    migrations.forEach(m => this.addMigration(m));
  }

  async migrate(): Promise<MigrationResult[]> {
    await this.runner.ensureMigrationsTable();
    const applied = await this.runner.getAppliedMigrations();
    const appliedIds = new Set(applied.map(m => m.id));

    const results: MigrationResult[] = [];

    for (const migration of this.migrations) {
      if (!appliedIds.has(migration.id)) {
        console.log(`Applying migration: ${migration.id} - ${migration.description}`);
        const result = await this.runner.applyMigration(migration);
        results.push(result);

        if (result.status === 'failed') {
          console.error(`Migration failed: ${migration.id} - ${result.error}`);
          break;
        } else {
          console.log(`✅ Applied: ${migration.id} (${result.duration_ms}ms)`);
        }
      }
    }

    return results;
  }

  async rollback(targetId?: string): Promise<MigrationResult[]> {
    const applied = await this.runner.getAppliedMigrations();
    const results: MigrationResult[] = [];

    // Roll back from most recent to target (or all if no target)
    const toRollback = applied.reverse();

    for (const record of toRollback) {
      const migration = this.migrations.find(m => m.id === record.id);
      if (!migration) {
        console.warn(`Migration ${record.id} not found in current migrations`);
        continue;
      }

      console.log(`Rolling back: ${migration.id} - ${migration.description}`);
      const result = await this.runner.rollbackMigration(migration);
      results.push(result);

      if (result.status === 'failed') {
        console.error(`Rollback failed: ${migration.id} - ${result.error}`);
        break;
      } else {
        console.log(`✅ Rolled back: ${migration.id} (${result.duration_ms}ms)`);
      }

      if (targetId && migration.id === targetId) {
        break;
      }
    }

    return results;
  }

  async status(): Promise<{ pending: Migration[]; applied: MigrationRecord[] }> {
    await this.runner.ensureMigrationsTable();
    const applied = await this.runner.getAppliedMigrations();
    const appliedIds = new Set(applied.map(m => m.id));

    const pending = this.migrations.filter(m => !appliedIds.has(m.id));

    return { pending, applied };
  }
}
