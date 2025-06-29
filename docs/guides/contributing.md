# Contributing Guide

## Welcome Contributors!

Thank you for your interest in contributing to Panhandler! This guide will help you get started with contributing effectively to our AI agent orchestration system.

## Quick Start for Contributors

1. **Read the Documentation**: Familiarize yourself with `docs/PLAN.md` and `docs/guides/development-setup.md`
2. **Set up Development Environment**: Follow the development setup guide
3. **Check Open Issues**: Look for issues labeled `good-first-issue` or `help-wanted`
4. **Fork and Clone**: Create your own fork and work on feature branches
5. **Follow Code Standards**: Ensure all quality checks pass before submitting

## Development Process

### 1. Planning and Documentation

**Before Writing Code**:
- Check `docs/PLAN.md` for current phase objectives
- Review relevant architecture documentation in `docs/architecture/`
- Ensure your contribution aligns with project goals
- For significant changes, open an issue for discussion first

### 2. Code Standards

**Quality Requirements**:
- ✅ All TypeScript must pass strict mode compilation
- ✅ ESLint rules must pass with zero warnings
- ✅ Code must be formatted with Prettier
- ✅ Pre-commit hooks must pass (includes secret scanning)
- ✅ All tests must pass

**Run Quality Checks**:
```bash
# Before committing, ensure these all pass:
bun run type-check
bun run lint
bun run format:check
bun run test
```

### 3. Commit Standards

**Conventional Commits Format**:
```
type(scope): description

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

**Examples**:
```bash
feat(agents): add planning agent with cost estimation
fix(core): resolve database connection pooling issue
docs(architecture): update runtime performance benchmarks
test(core): add unit tests for migration framework
```

### 4. Performance Tracking

**For Development Tasks**:
- Always use real timestamps: `date -u`
- Track actual vs estimated time
- Update estimates based on performance data
- Document complexity factors that affected timing

**Example Documentation**:
```markdown
## Task: Add New Agent Type

- **Traditional Estimate**: 120 minutes
- **AI-Assisted Estimate**: 24 minutes (20% multiplier, medium complexity)
- **Actual Time**: 18 minutes
- **Start**: Sun 29 Jun 15:30:45 UTC 2025
- **End**: Sun 29 Jun 15:48:22 UTC 2025
- **Performance**: 85% faster than traditional, 25% faster than AI estimate
```

## Code Architecture Guidelines

### Package Structure

```
packages/
├── types/          # Shared TypeScript definitions
├── core/           # Framework and utilities
├── agents/         # Agent implementations  
└── web/           # React frontend
```

**Dependency Rules**:
- All packages depend on `@panhandler/types`
- `agents` and `web` depend on `@panhandler/core`
- No circular dependencies between packages
- Core should remain framework-agnostic

### TypeScript Guidelines

**Type Safety**:
```typescript
// ✅ Good: Explicit types for public APIs
export interface AgentConfig {
  id: string;
  type: AgentType;
  parameters: Record<string, unknown>;
}

// ✅ Good: Use unknown instead of any
function processData(data: unknown): ProcessedData {
  // Type guards for validation
}

// ❌ Avoid: any types
function badProcess(data: any): any {
  return data.whatever;
}
```

**Database Operations**:
```typescript
// ✅ Good: Use migration context interface
export async function up(ctx: MigrationContext): Promise<void> {
  await ctx.execute('CREATE TABLE...');
}

// ✅ Good: Type-safe queries
const result = await ctx.query<UserRow>('SELECT * FROM users WHERE id = $1', [id]);
```

### Testing Guidelines

**Test Structure**:
```typescript
// tests/feature.test.ts
import { describe, test, expect } from 'bun:test';

describe('Feature Name', () => {
  test('should handle expected case', () => {
    // Arrange
    const input = createTestInput();
    
    // Act
    const result = processFeature(input);
    
    // Assert
    expect(result).toEqual(expectedOutput);
  });
});
```

**Coverage Requirements**:
- Minimum 80% code coverage
- All public APIs must have tests
- Critical business logic requires comprehensive test coverage
- Database operations should have integration tests

## Documentation Standards

### Code Documentation

**JSDoc for Public APIs**:
```typescript
/**
 * Executes an agent workflow with the given configuration.
 * 
 * @param config - The agent configuration including type and parameters
 * @param context - Execution context with database and logging
 * @returns Promise resolving to execution result with metrics
 * 
 * @example
 * ```typescript
 * const result = await executeAgent({
 *   id: 'planner-001',
 *   type: 'planner',
 *   parameters: { project: 'my-project' }
 * }, context);
 * ```
 */
export async function executeAgent(
  config: AgentConfig, 
  context: ExecutionContext
): Promise<ExecutionResult> {
  // Implementation
}
```

### Architecture Documentation

**For Significant Changes**:
- Update relevant files in `docs/architecture/`
- Include decision rationale and alternatives considered
- Add performance implications
- Update decision logs with dates and reasoning

## Contributing Workflow

### 1. Fork and Branch

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/your-username/panhandler.git
cd panhandler

# Create feature branch
git checkout -b feature/your-feature-name
```

### 2. Development

```bash
# Set up development environment
bun run setup:dev

# Make your changes
# ... code, test, document ...

# Ensure quality checks pass
bun run precommit
```

### 3. Testing

```bash
# Run full test suite
bun run test:ci

# Check specific package
bun run --filter '@panhandler/package' test

# Generate coverage report
bun run test:coverage
```

### 4. Documentation

```bash
# Update API documentation
bun run docs:generate

# Review generated docs
bun run docs:serve
```

### 5. Submit Pull Request

**Pull Request Checklist**:
- [ ] All quality checks pass locally
- [ ] Tests added for new functionality
- [ ] Documentation updated for changes
- [ ] Performance impact considered and documented
- [ ] Breaking changes clearly documented
- [ ] Conventional commit messages used

**PR Description Template**:
```markdown
## Summary
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature  
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Performance Impact
- Traditional estimate: X minutes
- Actual time: Y minutes
- Complexity: Easy/Medium/Hard

## Documentation
- [ ] Code comments updated
- [ ] API documentation generated
- [ ] Architecture docs updated if needed

## Breaking Changes
List any breaking changes and migration steps
```

## Review Process

### What We Look For

**Code Quality**:
- TypeScript strict mode compliance
- Clear, maintainable code structure
- Appropriate test coverage
- Performance considerations

**Architecture**:
- Follows established patterns
- Maintains package boundaries
- Considers scalability implications
- Documents significant decisions

**Documentation**:
- Clear commit messages
- Updated API documentation
- Architecture changes documented
- Performance data tracked

### Response Time

- **Initial Review**: Within 48 hours
- **Follow-up**: Within 24 hours of updates
- **Final Approval**: Within 72 hours of last change

## Getting Help

### Communication Channels

- **Issues**: For bugs, feature requests, questions
- **Discussions**: For design discussions and ideas
- **Email**: For security-related concerns

### Common Questions

**Q: How do I add a new agent type?**
A: Check `docs/architecture/agents.md` for patterns, extend the base agent class, add proper typing in `@panhandler/types`

**Q: How do I modify the database schema?**
A: Create a new migration file in TypeScript, test with `bun run db:migrate`, ensure proper rollback

**Q: How do I update performance estimates?**
A: Track actual vs estimated time, update complexity categories in documentation, follow established patterns

**Q: What if CI fails?**
A: Check the specific failure, run quality checks locally, fix issues, and push updates

## Recognition

Contributors will be:
- Listed in project README
- Mentioned in release notes for significant contributions
- Invited to contributor discussions for major features

Thank you for contributing to Panhandler! 🎉 