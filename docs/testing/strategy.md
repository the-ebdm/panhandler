# Testing Strategy

## Overview

Panhandler uses a comprehensive testing approach focused on **real integration testing** rather than extensive mocking. Our philosophy is to test systems as they will actually behave in production, using Bun's native test runner for optimal performance.

## Testing Philosophy

### Core Principles

1. **Real Systems Over Mocks**: Test against actual databases, real file systems, and live services wherever possible
2. **Integration-First**: Focus on testing how components work together, not just in isolation  
3. **Fast Feedback**: Use Bun's performance to enable rapid test execution
4. **Production Parity**: Test environments should closely mirror production
5. **Fail Fast**: Tests should quickly identify breaking changes

### When We Avoid Mocks

- **Database Operations**: Use real PostgreSQL test instance via Docker
- **File System Operations**: Use real temporary directories and files
- **HTTP Clients**: Use real HTTP calls to test endpoints (with test data)
- **Environment Configuration**: Use real environment variable parsing
- **Migration System**: Run actual migrations against test database

### Limited Mock Usage

We only use mocks for:
- External API calls that cost money (OpenRouter, etc.)
- Third-party services we don't control
- Slow operations that would make tests prohibitively slow

## Test Categories

### 1. Unit Tests (`packages/*/tests/`)

**Purpose**: Test individual functions and classes in isolation

**Scope**:
- Pure functions in utilities
- Individual class methods
- Type validation logic
- Error handling paths

**Location**: `packages/{package-name}/tests/`

**Example**:
```typescript
// packages/types/tests/environment.test.ts
import { test, expect } from 'bun:test';
import { validateEnvironmentVariable } from '../src/environment';

test('validates required environment variables', () => {
  expect(() => validateEnvironmentVariable('DATABASE_URL', undefined)).toThrow();
  expect(validateEnvironmentVariable('DATABASE_URL', 'postgresql://...')).toBe('postgresql://...');
});
```

### 2. Integration Tests (`tests/integration/`)

**Purpose**: Test how multiple components work together

**Scope**:
- Database + Migration system
- Agent orchestration workflows  
- API endpoints with real data flow
- Build system and packaging

**Location**: `tests/integration/`

**Example**:
```typescript
// tests/integration/database-setup.test.ts
import { test, expect, describe } from 'bun:test';

describe('Database Setup Integration', () => {
  test('can run migrations successfully', async () => {
    // Test actual migration execution against real PostgreSQL
  });
});
```

### 3. End-to-End Tests (`tests/e2e/`)

**Purpose**: Test complete user workflows

**Scope**:
- Web interface workflows
- CLI tool operations
- Full agent execution cycles
- Deployment validation

**Location**: `tests/e2e/`

## Test Infrastructure

### Database Testing

**Docker Compose Setup**:
```bash
# Start test database
bun run test:db-up

# Run database tests
bun run test:integration

# View database logs
bun run test:db-logs

# Stop test database
bun run test:db-down
```

**Test Database Configuration**:
- **Host**: localhost:5433 (separate from dev DB on 5432)
- **Database**: panhandler_test
- **User**: test_user / test_password
- **Features**: UUID, crypto extensions enabled
- **Isolation**: Fresh database for each test run

### Test Data Management

**Principles**:
- Use factories for consistent test data creation
- Clean database state between test suites
- Use realistic data that mirrors production patterns
- Avoid hard-coded IDs or timestamps

**Example**:
```typescript
// tests/utils/db-helpers.ts
export const TestDataFactory = {
  project: async (overrides = {}) => {
    const project = {
      id: TestData.randomId(),
      name: `Test Project ${Date.now()}`,
      ...overrides
    };
    await testQuery('INSERT INTO projects ...', [project.id, ...]);
    return project;
  }
};
```

## Test Runner Configuration

### Bun Test Setup

**Configuration** (`bunfig.toml`):
```toml
[test]
timeout = 10000
preload = ["./tests/setup.ts"]
coverage = true
coverage.threshold = 80
```

**Global Setup** (`tests/setup.ts`):
- Environment variable configuration
- Database connection validation
- Global test hooks

### Coverage Requirements

- **Minimum Coverage**: 80% across all packages
- **Critical Paths**: 95% coverage for database operations, migrations, security functions
- **Documentation**: Coverage reports generated in HTML and LCOV formats

### Performance Standards

- **Unit Tests**: < 100ms per test
- **Integration Tests**: < 2 seconds per test
- **Full Test Suite**: < 30 seconds total execution time
- **Database Operations**: < 500ms per query in tests

## Test Commands

### Development Workflow

```bash
# Run all tests
bun run test

# Watch mode for TDD
bun run test:watch

# Run only integration tests
bun run test:integration

# Run only unit tests in specific package
bun run test:unit

# Full test suite with coverage
bun run test:coverage

# Complete test cycle (DB + tests)
bun run test:full
```

### CI/CD Pipeline

```bash
# Complete CI test sequence
bun run test:ci

# This runs:
# 1. bun run type-check
# 2. bun run lint
# 3. bun run test (with coverage)
```

## Testing Patterns

### Database Integration Pattern

```typescript
import { test, expect, beforeAll, afterAll } from 'bun:test';
import { testQuery, cleanTestDatabase } from '../utils/db-helpers';

beforeAll(async () => {
  await cleanTestDatabase();
});

test('database operation test', async () => {
  // Create test data
  const project = await TestDataFactory.project();
  
  // Test the operation
  const result = await someFunction(project.id);
  
  // Assert against real database state
  const dbRecord = await testQuery('SELECT * FROM projects WHERE id = $1', [project.id]);
  expect(dbRecord[0].status).toBe('completed');
});
```

### Agent Testing Pattern

```typescript
import { test, expect } from 'bun:test';

test('agent execution workflow', async () => {
  // Use real agent configuration
  const config = {
    agentId: TestData.randomId(),
    model: 'test-model',
    maxTokens: 100
  };
  
  // Test real execution (with mocked external API calls)
  const result = await executeAgent(config, realTestContext);
  
  // Validate real state changes
  expect(result.success).toBe(true);
  expect(result.metadata.executionTime).toBeGreaterThan(0);
});
```

### Error Handling Pattern

```typescript
import { test, expect } from 'bun:test';
import { expectToThrow } from '../utils/test-helpers';

test('handles database connection failure', async () => {
  // Test with invalid database configuration
  const invalidConfig = { ...testDbConfig, port: 9999 };
  
  await expectToThrow(
    () => connectToDatabase(invalidConfig),
    'Connection failed'
  );
});
```

## Quality Gates

### Pre-commit Requirements

All tests must pass before code can be committed:
- Type checking: Zero TypeScript errors
- Linting: Zero ESLint warnings/errors
- Tests: 100% test pass rate
- Coverage: Must not decrease below threshold

### Pull Request Requirements

- All existing tests continue to pass
- New functionality has corresponding tests
- Integration tests validate feature works end-to-end
- Performance tests show no significant regression

### Release Requirements

- Full test suite passes on all supported platforms
- Integration tests pass against production-like environment
- End-to-end tests validate complete workflows
- Performance benchmarks meet established thresholds

## Common Testing Utilities

### Test Helpers

- `sleep(ms)`: Async delay for timing tests
- `waitFor(condition)`: Wait for async conditions
- `expectToThrow(fn, message)`: Assert function throws specific error

### Database Helpers

- `getTestDbConfig()`: Get test database configuration
- `testQuery(sql, params)`: Execute SQL against test database
- `cleanTestDatabase()`: Reset test database state

### Test Data Factories

- `TestData.randomString()`: Generate random strings
- `TestData.randomId()`: Generate unique IDs
- `TestData.futureDate()`: Generate future timestamps

## Debugging Tests

### Local Development

```bash
# Run single test file
bun test ./tests/integration/database-setup.test.ts

# Run tests matching pattern
bun test --test-name-pattern "migration"

# Verbose output for debugging
LOG_LEVEL=debug bun test
```

### Database Debugging

```bash
# View database logs during tests
bun run test:db-logs

# Connect to test database directly
psql postgresql://test_user:test_password@localhost:5433/panhandler_test

# Reset test database state
bun run test:db-down && bun run test:db-up
```

### Performance Debugging

```bash
# Run tests with timing information
bun test --verbose

# Generate coverage report for analysis
bun run test:coverage
open coverage/index.html
```

## Best Practices

### Writing Effective Tests

1. **Descriptive Names**: Test names should clearly describe what is being tested
2. **Arrange-Act-Assert**: Structure tests with clear setup, execution, and validation
3. **One Concept Per Test**: Each test should validate one specific behavior
4. **Realistic Data**: Use data that represents actual usage patterns
5. **Clean State**: Ensure tests don't depend on each other

### Performance Optimization

1. **Parallel Execution**: Bun runs tests in parallel by default
2. **Database Pooling**: Reuse database connections where possible
3. **Selective Testing**: Use filters to run only relevant tests during development
4. **Resource Cleanup**: Properly clean up resources to prevent memory leaks

### Maintenance

1. **Regular Review**: Review and update tests as system evolves
2. **Coverage Monitoring**: Track coverage trends over time
3. **Performance Monitoring**: Watch for test performance regressions
4. **Documentation Updates**: Keep testing docs current with practices

---

This testing strategy ensures high confidence in system reliability while maintaining fast development velocity through Bun's performance and real integration testing. 