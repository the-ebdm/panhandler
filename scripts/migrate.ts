#!/usr/bin/env bun

import { MigrationManager } from '@panhandler/core';
import { getEnvironmentConfig } from '@panhandler/core';
import type { DatabaseConfig } from '@panhandler/types';

const command = process.argv[2];
const args = process.argv.slice(3);

async function main() {
  // Get database configuration from environment
  const env = getEnvironmentConfig();

  // Parse DATABASE_URL to extract connection parameters
  const dbUrl = new URL(env.DATABASE_URL);
  const dbConfig: DatabaseConfig = {
    host: dbUrl.hostname,
    port: parseInt(dbUrl.port) || 5432,
    database: dbUrl.pathname.slice(1), // Remove leading slash
    username: dbUrl.username,
    password: dbUrl.password,
    ssl: dbUrl.searchParams.get('sslmode') === 'require',
    pool: {
      min: 2,
      max: 10
    }
  };

  const manager = new MigrationManager(dbConfig);

  // Load migrations from the migrations directory
  await loadMigrations(manager);

  switch (command) {
    case 'migrate':
    case 'up':
      console.log('🚀 Running migrations...');
      const results = await manager.migrate();
      console.log(`✅ Applied ${results.filter(r => r.status === 'applied').length} migrations`);
      break;

    case 'rollback':
    case 'down':
      const targetId = args[0];
      console.log(`🔄 Rolling back${targetId ? ` to ${targetId}` : ' last migration'}...`);
      const rollbackResults = await manager.rollback(targetId);
      console.log(`✅ Rolled back ${rollbackResults.filter(r => r.status === 'rolled_back').length} migrations`);
      break;

    case 'status':
      const status = await manager.status();
      console.log(`📊 Migration Status:`);
      console.log(`   Applied: ${status.applied.length}`);
      console.log(`   Pending: ${status.pending.length}`);
      if (status.pending.length > 0) {
        console.log(`\n📋 Pending migrations:`);
        status.pending.forEach(m => console.log(`   - ${m.id}: ${m.description}`));
      }
      break;

    default:
      console.log(`Usage: migrate <command> [args]

Commands:
  migrate, up         Apply pending migrations
  rollback, down [id] Rollback migrations (to specific id if provided)
  status              Show migration status

Examples:
  bun scripts/migrate.ts migrate
  bun scripts/migrate.ts rollback
  bun scripts/migrate.ts rollback 001_initial_schema
  bun scripts/migrate.ts status`);
      process.exit(1);
  }
}

async function loadMigrations(manager: MigrationManager) {
  // This is where you would load migration files
  // For now, we'll add a simple example migration

  manager.addMigration({
    id: '001_initial_schema',
    description: 'Create initial database schema',
    up: async (ctx) => {
      await ctx.execute(`
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) UNIQUE NOT NULL,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `);

      await ctx.execute(`
        CREATE TABLE IF NOT EXISTS agents (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          type VARCHAR(100) NOT NULL,
          status VARCHAR(50) DEFAULT 'idle',
          config JSONB,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )
      `);
    },
    down: async (ctx) => {
      await ctx.execute('DROP TABLE IF EXISTS agents');
      await ctx.execute('DROP TABLE IF EXISTS users');
    }
  });
}

// Run if this script is executed directly
if (import.meta.main) {
  main().catch((error) => {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  });
} 