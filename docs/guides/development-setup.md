# Development Setup Guide

## Prerequisites

- **Bun**: Version 1.0.0 or later
- **Node.js**: Version 18 or later (for compatibility)
- **Git**: Version 2.30 or later
- **PostgreSQL**: Version 14 or later (for database operations)

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-org/panhandler.git
cd panhandler

# Install dependencies and build foundation packages
bun install
bun run setup:dev
```

### 2. Environment Configuration

```bash
# Copy development environment template
cp env.development .env

# Edit environment variables as needed
# KEY VARIABLES:
# - DATABASE_URL: PostgreSQL connection string
# - OPENROUTER_API_KEY: API key for OpenRouter service
# - LOG_LEVEL: debug, info, warn, error
```

### 3. Database Setup

```bash
# Run database migrations
bun run db:migrate

# Check migration status
bun run db:status
```

### 4. Start Development

```bash
# Start all services (API + Web)
bun run dev:all

# Or start individually
bun run dev:api    # Agent orchestration API (port 3001)
bun run dev:web    # React web interface (port 3003)
```

## Development Workflow

### Building Packages

```bash
# Build foundation packages (types, core)
bun run build:deps

# Build all packages sequentially
bun run build:sequential

# Build for production
bun run build:production
```

### Code Quality

```bash
# Run linting across all packages
bun run lint

# Auto-fix linting issues
bun run lint:fix

# Format code with Prettier
bun run format

# Type checking
bun run type-check

# Run all quality checks (used by pre-commit hooks)
bun run precommit
```

### Testing

```bash
# Run all tests
bun run test

# Run tests with coverage
bun run test:coverage

# Watch mode for development
bun run test:watch

# CI test pipeline
bun run test:ci
```

### Documentation

```bash
# Generate API documentation
bun run docs:generate

# Serve documentation locally on http://localhost:8080
bun run docs:serve

# Watch for changes and regenerate
bun run docs:watch

# Clean generated documentation
bun run docs:clean
```

### Database Operations

```bash
# Run pending migrations
bun run db:migrate

# Rollback last migration
bun run db:rollback

# Check migration status
bun run db:status

# Reset database (rollback all + re-migrate)
bun run db:reset
```

## Package Structure

```
packages/
├── types/          # Shared TypeScript type definitions
├── core/           # Base classes, utilities, database framework
├── agents/         # AI agent implementations
└── web/           # React frontend interface
```

### Development Dependencies

- **Build Order**: `types` → `core` → `agents`, `web`
- **All packages** depend on `@panhandler/types`
- **`agents` and `web`** depend on `@panhandler/core`
- **Hot reload** watches foundation packages and restarts dependents

## Common Tasks

### Adding a New Package

1. Create package directory in `packages/`
2. Add `package.json` with proper workspace references
3. Configure `tsconfig.json` with project references
4. Update root build scripts if needed

### Adding Dependencies

```bash
# Add to workspace root
bun add package-name

# Add to specific package
bun add package-name --filter @panhandler/package-name

# Add dev dependency
bun add --dev package-name
```

### Creating Database Migrations

```bash
# Migration files are in TypeScript
# Create: migrations/001_create_table.ts

export async function up(ctx: MigrationContext): Promise<void> {
  await ctx.execute(`
    CREATE TABLE example (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT NOW()
    )
  `);
}

export async function down(ctx: MigrationContext): Promise<void> {
  await ctx.execute('DROP TABLE IF EXISTS example');
}
```

### Debugging

```bash
# Enable debug logging
export LOG_LEVEL=debug

# Database query logging
export DATABASE_LOG=true

# Verbose error reporting
export NODE_ENV=development
```

## IDE Setup

### VS Code Extensions

- **TypeScript**: Enhanced TypeScript support
- **ESLint**: Real-time linting
- **Prettier**: Auto-formatting
- **Bun**: Bun runtime support

### Settings

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.preferences.includePackageJsonAutoImports": "auto"
}
```

## Troubleshooting

### Build Issues

```bash
# Clear build cache
bun run clean

# Full clean and reinstall
bun run clean:full

# Rebuild foundation packages
bun run build:deps
```

### Git Hook Issues

```bash
# Skip hooks temporarily (emergency only)
git commit --no-verify -m "emergency: reason"

# Fix and re-commit normally
git add . && git commit -m "fix: resolve issue"
```

### Database Connection Issues

1. Verify PostgreSQL is running
2. Check DATABASE_URL in `.env`
3. Ensure database exists and is accessible
4. Check migration status: `bun run db:status`

### Port Conflicts

- **API**: Default port 3001 (configurable via `PORT`)
- **Web**: Default port 3003 (Vite auto-detects conflicts)
- **Docs**: Default port 8080 (configurable)

## Performance Tips

- **Incremental builds**: Use `bun run build` instead of `clean && build`
- **Parallel development**: Use `bun run dev:all` for optimal workflow
- **Type checking**: Foundation packages build much faster than full type-check
- **Hot reload**: Changes to `types` or `core` trigger dependent package rebuilds

## Contributing Guidelines

1. **Read the plan**: Check `docs/PLAN.md` before starting
2. **Follow conventions**: Use conventional commit messages
3. **Test your changes**: All quality checks must pass
4. **Update documentation**: Keep guides and API docs current
5. **Performance tracking**: Record actual vs estimated time for tasks

## Getting Help

- **Documentation**: `docs/` directory contains comprehensive guides
- **API Reference**: Generated at `docs/api/` via `bun run docs:generate`
- **Architecture**: See `docs/architecture/` for technical decisions
- **Issues**: Check existing issues for known problems and solutions 