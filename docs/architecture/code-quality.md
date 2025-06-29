# Code Quality Architecture

**Document Version**: 1.0  
**Last Updated**: Sun 29 Jun 18:11:17 UTC 2025  
**Status**: Implemented  

## Overview

Panhandler's code quality architecture enforces consistent coding standards, prevents common errors, and maintains high code quality through automated tooling. The system combines **ESLint 9** with flat config, **Prettier** for formatting, **Gitleaks** for secret scanning, and **Git hooks** for automated enforcement.

## Core Quality Tools

### ESLint 9 with Flat Configuration

**Why ESLint 9 Flat Config**:
- **Simplified Configuration**: Single configuration object vs complex hierarchical configs
- **Better Performance**: Faster rule resolution and processing
- **TypeScript Integration**: Native support for TypeScript without complex setup
- **Modern Standards**: Latest ESLint architecture and best practices

**Configuration Structure**:
```javascript
// eslint.config.js (workspace root)
import js from '@eslint/js';
import tsParser from '@typescript-eslint/parser';
import tsPlugin from '@typescript-eslint/eslint-plugin';
import prettier from 'eslint-config-prettier';
import react from 'eslint-plugin-react';

export default [
  // Base JavaScript configuration
  js.configs.recommended,
  
  // TypeScript configuration
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        project: './tsconfig.json'
      }
    },
    plugins: {
      '@typescript-eslint': tsPlugin
    },
    rules: {
      ...tsPlugin.configs.strict.rules,
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/no-explicit-any': 'error'
    }
  },
  
  // React configuration (web package only)
  {
    files: ['packages/web/**/*.tsx'],
    plugins: { react },
    settings: {
      react: { version: 'detect' }
    },
    rules: {
      ...react.configs.recommended.rules,
      'react/react-in-jsx-scope': 'off'
    }
  },
  
  // Prettier integration (disables conflicting rules)
  prettier
];
```

### Workspace-Specific Rules

**Stricter Rules for Core Packages**:
```javascript
// Agents and Core packages have stricter requirements
{
  files: ['packages/{agents,core}/**/*.ts'],
  rules: {
    '@typescript-eslint/no-any': 'error',
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/no-unsafe-assignment': 'error',
    'complexity': ['error', { max: 10 }],
    'max-depth': ['error', 4]
  }
}

// Web package allows more flexibility for UI code
{
  files: ['packages/web/**/*.tsx'],
  rules: {
    '@typescript-eslint/no-any': 'warn',
    'complexity': ['warn', { max: 15 }]
  }
}
```

**Design Rationale**:
- **Foundation Quality**: Core and agent code must be bulletproof
- **UI Flexibility**: React components often need flexibility for UX
- **Gradual Adoption**: Warnings in UI, errors in business logic
- **Maintainability**: Complexity limits prevent unmaintainable code

### Prettier Code Formatting

**Configuration**:
```json
// .prettierrc.json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
```

**Prettier Integration Strategy**:
- **ESLint Integration**: `eslint-config-prettier` disables conflicting rules
- **Automatic Formatting**: Format on save in editors
- **Pre-commit Formatting**: Ensure all committed code is formatted
- **CI Validation**: Verify formatting in continuous integration

**Why These Settings**:
- **Semicolons**: Explicit statement termination prevents ASI issues
- **Single Quotes**: Consistent with TypeScript/JavaScript conventions
- **100 Character Width**: Balance readability vs horizontal space
- **2-Space Indentation**: Standard for TypeScript/React projects
- **Trailing Commas**: Git diff noise reduction

## Git Hooks Architecture

### Pre-commit Hook Implementation

**Hook Strategy**: Manual git hooks (no Husky dependency)

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 Running pre-commit checks..."

# 1. Secret scanning with Gitleaks
echo "🔑 Scanning for secrets with Gitleaks..."
if ! gitleaks protect --staged --no-banner; then
    echo "❌ Secret scan failed! Please review and fix flagged secrets."
    exit 1
fi

# 2. TypeScript type checking
echo "📝 Running TypeScript check..."
if ! bun run type-check; then
    echo "❌ TypeScript check failed! Please fix type errors."
    exit 1
fi

# 3. ESLint validation
echo "🔍 Running ESLint..."
if ! bun run lint; then
    echo "❌ Linting failed! Run 'bun run lint:fix' to fix auto-fixable issues."
    exit 1
fi

# 4. Prettier formatting check
echo "💅 Checking code formatting..."
if ! bun run format:check; then
    echo "❌ Code formatting issues found! Run 'bun run format' to fix."
    exit 1
fi

echo "✅ Pre-commit checks passed!"
```

### Pre-push Hook Implementation

```bash
#!/bin/sh
# .git/hooks/pre-push

echo "🚀 Running pre-push validation..."

# 1. Full build verification
echo "🔨 Building all packages..."
if ! bun run build:sequential; then
    echo "❌ Build failed! Please fix build errors."
    exit 1
fi

# 2. Test suite execution
echo "🧪 Running test suite..."
if ! bun run test; then
    echo "❌ Tests failed! Please fix failing tests."
    exit 1
fi

echo "✅ Pre-push validation passed!"
```

**Hook Benefits**:
- **Early Detection**: Catch issues before they reach the repository
- **Consistent Quality**: All commits meet quality standards
- **Team Alignment**: Shared quality gates across all developers
- **CI/CD Efficiency**: Reduce CI failures by catching issues locally

### Secret Scanning with Gitleaks

**Why Gitleaks Over Custom Solutions**:
- **Battle-tested Patterns**: 100+ built-in secret detection rules
- **Low False Positives**: Mature pattern matching algorithms
- **Performance**: Fast scanning with minimal overhead
- **Industry Standard**: Used by major organizations and security teams

**Gitleaks Configuration**:
```toml
# .gitleaks.toml
[allowlist]
description = "Allowlist for false positives"
paths = [
  "docs/**",  # Documentation may reference API patterns
  "**/*.md"   # Markdown files often contain example tokens
]

[allowlist.regexes]
description = "Allowed patterns"
regexes = [
  '''env\.example''',  # Environment template files
  '''DATABASE_URL=postgres://''',  # Example connection strings
]
```

**Secret Detection Patterns**:
- **API Keys**: OpenRouter, GitHub, AWS, etc.
- **Database URLs**: Connection strings with credentials
- **JWT Secrets**: High-entropy strings used for signing
- **Private Keys**: RSA, SSH, and certificate private keys
- **Tokens**: OAuth tokens, session secrets, etc.

## Automated Quality Enforcement

### Package-Level Scripts

**Each Package Configuration**:
```json
// packages/*/package.json
{
  "scripts": {
    "lint": "eslint src --max-warnings 0",
    "lint:fix": "eslint src --fix",
    "type-check": "tsc --noEmit",
    "format": "prettier --write src",
    "format:check": "prettier --check src"
  }
}
```

**Workspace-Level Scripts**:
```json
// package.json (root)
{
  "scripts": {
    "lint": "bun run --filter '*' lint",
    "lint:fix": "bun run --filter '*' lint:fix",
    "type-check": "bun run --filter '*' type-check",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "precommit": "bun run type-check && bun run lint && bun run format:check"
  }
}
```

### Continuous Integration Integration

**Quality Gates in CI**:
```yaml
# .gitlab-ci.yml (quality stage)
quality:
  stage: test
  script:
    - bun install
    - bun run type-check
    - bun run lint
    - bun run format:check
    - gitleaks detect --source . --no-git
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "master"
```

## Performance Optimizations

### ESLint Performance

**Flat Config Benefits**:
- **Faster Startup**: 20-30% faster than traditional config
- **Better Caching**: Improved rule resolution caching
- **Parallel Processing**: Better support for concurrent linting

**Performance Tuning**:
```javascript
// eslint.config.js optimization
export default [
  {
    ignores: [
      'dist/**',
      'node_modules/**',
      '**/*.d.ts',
      'coverage/**'
    ]
  },
  // ... other configs
];
```

### Incremental Checking

**TypeScript Performance**:
- **Project References**: Only check changed packages
- **Incremental Mode**: Cache type checking results
- **Build Info Files**: Reuse compilation metadata

**Linting Performance**:
- **File Filtering**: Only lint staged files in pre-commit
- **Cache Usage**: ESLint cache for unchanged files
- **Parallel Execution**: Multiple workers for large codebases

## Quality Metrics and Monitoring

### Code Quality Metrics

**Tracked Metrics**:
```typescript
interface QualityMetrics {
  eslintErrors: number;
  eslintWarnings: number;
  typeScriptErrors: number;
  formattingIssues: number;
  secretsDetected: number;
  codeComplexity: number;
  testCoverage: number;
}
```

**Quality Thresholds**:
- **ESLint Errors**: 0 (enforced by CI)
- **TypeScript Errors**: 0 (enforced by CI)
- **Code Complexity**: Max 10 for core, 15 for UI
- **Test Coverage**: 80% minimum
- **Secret Detection**: 0 secrets in repository

### Performance Tracking

**Quality Tool Performance** (measured in Step 6):
- **ESLint Setup**: 7 minutes vs 35 minutes estimated (80% faster)
- **Real-time Linting**: <100ms for typical file
- **Pre-commit Hooks**: 2-5 seconds total execution time
- **CI Quality Stage**: 30-60 seconds typical execution

## Alternative Technologies Considered

### Linting Alternatives

| Technology | Pros | Cons | Decision |
|------------|------|------|----------|
| **ESLint 8** | Mature, stable | Legacy config format, slower | Not chosen - performance |
| **Rome/Biome** | Very fast, Rust-based | Limited ecosystem, beta quality | Not chosen - maturity |
| **TSLint** | TypeScript native | Deprecated by TypeScript team | Not chosen - deprecated |
| **ESLint 9** | Latest features, flat config, fast | Newer, some plugin compatibility | Chosen - best balance |

### Formatting Alternatives

| Technology | Pros | Cons | Decision |
|------------|------|------|----------|
| **Prettier** | Industry standard, excellent editor support | Limited configuration options | Chosen - reliability |
| **dprint** | Very fast, configurable | Smaller ecosystem, less mature | Not chosen - ecosystem |
| **Rome Formatter** | Extremely fast | Limited availability, beta | Not chosen - stability |

### Secret Scanning Alternatives

| Technology | Pros | Cons | Decision |
|------------|------|------|----------|
| **Gitleaks** | Battle-tested, comprehensive rules | Go dependency | Chosen - effectiveness |
| **TruffleHog** | Good detection, Python-based | Performance issues | Not chosen - performance |
| **Custom Regex** | Lightweight, customizable | High false positives, maintenance | Not chosen - accuracy |
| **GitGuardian** | Commercial grade, cloud-based | Requires external service | Not chosen - self-hosted preference |

## Future Enhancements

### Planned Improvements

1. **Advanced Metrics**: Code quality trend analysis and reporting
2. **Custom Rules**: Project-specific ESLint rules for business logic
3. **Performance Monitoring**: Real-time quality tool performance tracking
4. **Team Integration**: Quality metrics in development workflows
5. **Automated Fixes**: More sophisticated auto-fixing capabilities

### Scalability Considerations

- **Distributed Linting**: Parallel linting across multiple machines
- **Incremental Analysis**: Only analyze changed code in large repositories
- **Custom Rule Distribution**: Shared rule packages across projects
- **Quality Dashboards**: Team-wide quality metrics and trends

## Best Practices

### Developer Workflow

**Recommended Development Flow**:
1. **Before Coding**: `bun run lint` to check current state
2. **During Development**: Auto-format on save, real-time linting
3. **Before Commit**: `bun run precommit` to verify quality
4. **After Issues**: `bun run lint:fix` and `bun run format` to auto-fix

### Team Guidelines

**Code Review Focus**:
- **Logic and Architecture**: Focus on business logic, not formatting
- **Type Safety**: Ensure proper TypeScript usage
- **Performance**: Review for potential performance issues
- **Security**: Look for security vulnerabilities not caught by tools

**Quality Standards**:
- **Zero Tolerance**: No ESLint errors or TypeScript errors in main branch
- **Consistent Style**: All code follows Prettier formatting
- **Type Safety**: Explicit types for public APIs, inference for internals
- **Documentation**: JSDoc for public APIs and complex logic

## Decision Log

| Date | Decision | Rationale | Alternatives Considered |
|------|----------|-----------|------------------------|
| 2025-06-29 | ESLint 9 Flat Config | Performance, modern architecture | ESLint 8, Rome/Biome, TSLint |
| 2025-06-29 | Prettier Integration | Industry standard, editor support | dprint, Rome formatter |
| 2025-06-29 | Gitleaks Secret Scanning | Battle-tested, comprehensive | TruffleHog, custom regex, GitGuardian |
| 2025-06-29 | Manual Git Hooks | Simplicity, no external dependencies | Husky, lint-staged, lefthook |
| 2025-06-29 | Workspace-Specific Rules | Targeted quality requirements | Uniform rules across packages |

---

**Related Documents**:
- [Development Workflow](./development-workflow.md)
- [Runtime Architecture](./runtime.md)
- [Security Architecture](./security.md) 