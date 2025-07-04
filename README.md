# Panhandler

AI Agent Orchestration System for Autonomous Software Development

## Overview

Panhandler is a collection of AI agents that operate based on someone putting money in the pan. It takes a git repository and builds a development plan for it, estimating the cost involved along the way (the cost being the OpenRouter token cost). Maybe we'll add a small service fee if it's running on our servers. It's a sad twisted metaphor for the position it will put real developers in.

## Quick Start

### Prerequisites

- [Bun](https://bun.sh/) >= 1.0.0
- [Docker](https://www.docker.com/) for database testing
- [Git](https://git-scm.com/) for version control

### Development Setup

```bash
# Clone and setup
git clone <repository-url>
cd panhandler

# Quick start for new developers
make quick-start

# Or manual setup
make install        # Install dependencies
make setup-dev      # Copy development environment and run setup
```

### Available Commands

The project uses a **Makefile-based workflow** for better organization and more powerful automation:

```bash
# Development
make dev            # Start web development server
make dev-api        # Start API development server  
make dev-all        # Start all development servers
make watch          # Watch mode for all packages

# Building
make build          # Build all packages
make build-deps     # Build only dependencies (types, core)
make build-production # Build for production

# Testing (with real PostgreSQL integration)
make test           # Run all tests
make test-watch     # Run tests in watch mode
make test-full      # Complete test cycle with database

# Code Quality
make lint           # Run linting
make format         # Format code
make type-check     # TypeScript type checking

# Database
make db-migrate     # Run migrations
make db-status      # Check migration status
make db-reset       # Reset database

# Utilities
make help           # Show all available commands
make check-tools    # Verify required tools
make list-ports     # Show service ports
```

### NPM Script Compatibility

The essential npm scripts still work and delegate to the Makefile:

```bash
bun run dev         # Same as: make dev
bun run build       # Same as: make build
bun run test        # Same as: make test
```

## Architecture

### Monorepo Structure

```
packages/
├── types/      # Shared TypeScript definitions
├── core/       # Base classes and framework  
├── agents/     # Agent implementations
└── web/        # React interface
```

### Technology Stack

- **Runtime**: [Bun](https://bun.sh/) for package management and execution
- **Language**: TypeScript with strict mode
- **Database**: PostgreSQL with Bun's native client
- **Testing**: Bun test runner with real integration testing
- **Frontend**: React with Vite
- **Code Quality**: ESLint + Prettier with automated enforcement

### Key Design Principles

1. **Real Integration Testing**: Test against actual databases and services, not mocks
2. **Type Safety First**: TypeScript strict mode throughout
3. **Performance Focused**: Leverage Bun's speed for development velocity
4. **Atomic Development**: One logical change per commit
5. **Documentation-Driven**: Always update docs with code changes

## Development Workflow

### Testing Philosophy

We avoid mocks and focus on **real integration testing**:

- **PostgreSQL**: Docker container for isolated test database
- **File System**: Real temporary directories and files
- **HTTP Clients**: Real API calls with test data
- **Performance**: 9 tests running in ~65ms with coverage

```bash
# Start test database
make test-db-up

# Run integration tests
make test-integration

# View database logs
make test-db-logs

# Full test cycle
make test-full
```

### Database Development

TypeScript-based migration system using Bun's native PostgreSQL client:

```bash
make db-migrate     # Run pending migrations
make db-rollback    # Rollback last migration
make db-status      # Check what's applied
make db-reset       # Fresh database state
```

### Code Quality

Automated quality enforcement via pre-commit hooks:

```bash
make precommit      # Run all quality checks
make lint-fix       # Auto-fix linting issues
make format         # Format all code
```

## Environment Configuration

Environment management with type safety:

```bash
# Copy development environment
cp env.development .env

# Validate configuration
make env-validate

# Generate new environment files
make env-generate
```

## Production

```bash
# Build for production
make build-production

# Start production server
make start

# Build deployment artifacts
make deploy-build
```

## Documentation

- **Architecture**: `docs/architecture/` - Design decisions and technical details
- **Testing**: `docs/testing/strategy.md` - Testing philosophy and patterns
- **Development**: `docs/guides/development-setup.md` - Setup and workflows
- **API Reference**: Generated with `make docs-generate`

## Contributing

See `docs/guides/contributing.md` for detailed contribution guidelines.

## Performance

Current development performance (Phase 1 data):
- **AI-Assisted Development**: 80-90% faster than traditional estimates
- **Build Times**: Sub-second incremental builds with Bun
- **Test Suite**: 9 tests in ~65ms with full PostgreSQL integration
- **Development Server**: Hot reload in milliseconds

## License

MIT

## Methodologies

The panhandler will focus predominantly on the planning and cost estimation of the operation. The idea is that you want to entice the user to put more money in the pan, so you can continue to do the actual work. Ideally if the user puts in a repo with a very small scope, you can complete the work very quickly and they will either give you a new repo or expand the scope even further. We want to ensure repeat custom so we shouldn't do anything that might decieve the user into thinking that we're doing more work than we are or that we're trying to extract more money than we're actually doing.

The essential architecture of the panhandler will be a pubsub system that will transform the repository into an ever branching tree of operations. When a new project is created, a planning event will be triggered. This will then be processed by the planner agent. The planner agent will then create a comprehensive documentation structure centered around a `docs/` directory that serves as the project's knowledge hub. This documentation-centric approach ensures that projects don't just get built, but become maintainable, operable systems with complete knowledge preservation.

## Order of Operations

- User adds a new project
- User puts money in the pan (to start it will be an openrouter key to avoid handling payments)
- Planning event is triggered
- Planner agent creates a structured PLAN.md file
- Estimator agent estimates the cost of the plan

## Documentation Structure

All project knowledge is centralized in a curated `docs/` directory that evolves throughout the project lifecycle:

**Core Documents**:

- `docs/PLAN.md` - Main project plan with overview and high-level phases
- `docs/ARCHITECTURE.md` - System architecture and design decisions

**Specialized Directories**:

- `docs/plans/` - Detailed plans for individual phases and macro steps
- `docs/architecture/` - Architectural Decision Records (ADRs) and design rationale
- `docs/guides/` - User guides and operational procedures
- `docs/runbooks/` - Step-by-step operational procedures and troubleshooting
- `docs/deployment/` - Environment-specific deployment guides
- `docs/api/` - API documentation and schemas
- `docs/testing/` - Testing strategies and procedures
- `docs/security/` - Security considerations and compliance
- `docs/performance/` - Performance benchmarks and optimization guides

This structure transforms each project into a comprehensive knowledge base that maintains institutional memory and enables effective handoffs, maintenance, and future development.

## Plan Structure

The structured plan will include the following:

- A high level "Project Overview" section in `docs/PLAN.md` that will include the vision, the scope, and the expected deliverables.
- A "Plan" section that will include the steps to complete the project.
  - The plan will be broken down into a series of phases.
  - Each phase will be broken down into a macro step.
  - The high level plan, phases and macro steps will be the sole responsibility of the planner agent.
  - When the planning agent submits the plan, each macro step will have a new event published to the pubsub system.
  - The plan expander agent will take the macro step and expand it into detailed plans stored in `docs/plans/` with a list of smaller steps achievable by the developer agent. Each micro step should be atomic and as minimal in scope as possible. The plan expander agent will be be able to generate any number of micro steps from a macro step. And so must lean on producing more steps rather than overcomplicating any one step. It will also be responsible for generating an order of operations, can steps be run in parallel or do they need to be run in sequence? I want to see a tree graph of the operations and the dependencies between them.
    - The cost estimator agent will take a each macro step with the tree of micro steps and estimate the cost of the macro step.
    - The timeline agent will take a each macro step with the tree of micro steps and estimate the time to complete the macro step.
    - The risk agent will take a each macro step with the tree of micro steps and estimate the risks associated with the macro step.
    - The adjudicator agent will take the decisions of the cost estimator, timeline agent, and risk agent and decide if the macro step is worth pursuing or requires further investigation. The adjudicator uses user-configurable weights (cost, timeline, risk) to make transparent decisions rather than opaque AI judgment. Users can adjust these weights based on project priorities (e.g., startup speed vs enterprise risk-aversion) and choose from preset profiles like "Speed-focused", "Cost-conscious", or "Risk-averse". If the macro step is worth pursuing, the developer agent will be triggered to complete the micro steps via the decision tree created by the plan expander agent. This will spin up a number of developer agents to complete the micro steps in parallel albeit some steps may be dependent on other steps.
      - The developer agent will take a micro step and complete it.
      - The quality agent will take a micro step and assess the quality of the work.
      - Every agent will be constantly emiting events to the pubsub system. This will be the central brain of the panhandler system. New agents will be triggered by events from the pubsub system. And some events may cancel the operation of running agents or force them to restart.
      - The supervisor agent provides strategic oversight of the entire project, monitoring macro step performance and making high-level decisions about project direction. The frequency and autonomy of supervision scales with the user's budget through a tiered service model.

## Tiered Supervision Model

The supervisor agent operates at different intensity levels based on the money in the pan and user's cost-sensitivity:

**Premium Tier**: Continuous autonomous supervision

- Supervisor runs constantly, optimizing project in real-time
- Full authority to reallocate resources, adjust priorities, and make strategic pivots
- Proactive optimization for maximum efficiency

**Standard Tier**: Periodic threshold-based supervision

- Supervisor activates when weighted event thresholds are exceeded
- Scheduled health checks (hourly/daily intervals)
- Reactive intervention for significant issues

**Budget Tier**: Emergency-only supervision

- Only critical failures trigger supervisor activation
- Basic health monitoring with user alerts
- Manual decision-making for most issues

Each event type carries a weight (micro step failure: 10, timeline overrun >50%: 15, cost overrun >25%: 20, quality gate failure: 12, dependency deadlock: 25, stalled progress: 8). The supervisor activates when cumulative weights exceed the user's tier threshold (Budget: 25, Standard: 15, Premium: 5).

## Scope Creep Handling

The system handles scope creep through a smart escalation mechanism that determines whether to handle changes locally or trigger full re-planning:

**Local Handling (Plan Expander Agent)**:

- Additional micro steps don't affect other macro steps
- Total effort increase <25% of original macro step estimate
- No new dependencies introduced to other macro steps
- Same skill sets/technologies required
- Timeline impact contained within current phase

**Escalation to Re-planning (Supervisor → Planner)**:

- Ripple effects across multiple macro steps detected
- Effort increase >25% or new major components discovered
- New external dependencies or technology requirements identified
- Changes affect project deliverables or core architecture
- Budget/timeline impact exceeds user's risk tolerance threshold

**Process Flow**:

1. Developer agent detects and reports scope expansion during micro step execution
2. Plan Expander assesses impact by mapping dependencies and estimating effort delta
3. Decision made based on impact scope: generate additional micro steps locally or escalate
4. If escalated, Supervisor calls "down tools" and passes context to Planner for full project re-evaluation
5. Re-planning loop: Planner reassesses entire project structure with new information

**Safeguards**:

- Scope creep accumulation tracking across the entire project
- Automatic user notification for all scope changes, regardless of handling level
- Cost gate triggers based on user's budget variance tolerance
- Learning feedback to improve future initial planning accuracy

## Agents

- Planner: This agent will take a git repository and build a development plan for it. Focus around taking a tree of the files and the README.md and then building a PLAN.md file that will be used to guide the development of the project. This plan will be created using a basic structure that will allow for future agents to rely on that structure to keep operational.

- Estimator: This agent will take the PLAN.md file and estimate the cost of a single step in the plan. This can be spun up in parralel to assess all points in the plan concurrently. As the steps are completed, we can use the data to re-estimate the cost of the remaining steps. This data can eventually be used to fine-tune a new estimation model.

- Plan expander: This agent will take a macro step in the plan and expand it into a list of smaller steps. This will be used to allow for more detailed planning and estimation.

- Developer: This agent will take a micro step from the plan expander and complete the actual implementation work. It will execute code changes, file modifications, and any other development tasks required to fulfill the micro step requirements.

- Quality: This agent will assess the quality of work completed by developer agents. It will check code quality, test coverage, adherence to requirements, and overall implementation standards.

- Timeline: This agent will estimate the time required to complete macro steps based on the tree of micro steps and their dependencies.

- Risk: This agent will analyze potential risks associated with macro steps, including technical complexity, dependency risks, and implementation challenges.

- Adjudicator: This agent uses user-configurable weights to make decisions about whether macro steps should proceed. Users have full control over how cost, timeline, and risk factors are weighted in the decision-making process.

- Supervisor: This agent provides C-Suite level strategic oversight, monitoring overall project health and making high-level decisions about project direction. It handles feedback loops, scope changes, resource reallocation, and strategic pivots. The supervisor's operational frequency and autonomy scale with the user's budget tier, ensuring cost-conscious users aren't paying for supervision they don't need while premium users get continuous optimization.

- Documentation: This agent curates and maintains the project's knowledge base throughout the development lifecycle. It ensures documentation stays current as code evolves, auto-generates API docs and deployment guides from code, reviews for outdated information, maintains consistent formatting and organization, and cross-references related documents and decisions. The documentation agent subscribes to all other agent events via pubsub and continuously updates documentation based on project changes, transforming development work into comprehensive project knowledge.

## Development Setup

### Prerequisites

- [BunJS](https://bun.sh/) - JavaScript runtime and package manager
- Git - Version control

### Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd panhandler

# Set up git hooks (conventional commits, basic validation)
./scripts/setup-hooks.sh

# Install dependencies (when available)
bun install

# Start development (when implemented)
bun run dev
```

### Git Workflow

- **Conventional Commits**: Use format `<type>[scope]: <description>`
- **Pre-commit Checks**: Automatic validation for large files, sensitive data, TypeScript errors
- **No External Dependencies**: Simple shell scripts, no Husky bullshit

Example commits:

```bash
feat: add user authentication system
fix(api): resolve timeout issues in agent communication
docs: update installation guide
refactor(core): simplify agent lifecycle management
```

## Architecture

- **BunJS / TypeScript** - All software implementation
- **LangGraph / LangChain** - AI agent framework
- **OpenRouter** - AI API integration
- **Deepstream.io** - Real-time pubsub system inspired by financial trading technology
- **PostgreSQL** - Relational database
- **Kubernetes / Helm** - Container orchestration and deployment

## Future Considerations

- **ML-Powered Decision Making**: As the system collects data on project outcomes, cost accuracy, and timeline performance, we could train a custom ML model to suggest optimal weight configurations for different project types. This model could learn from successful projects and recommend weight adjustments that historically lead to better outcomes.

- **Adaptive Weights**: The system could automatically adjust weights during project execution based on changing circumstances (e.g., increasing risk weight if multiple micro steps fail).

- **Project Type Classification**: An ML model could automatically classify incoming repositories and suggest appropriate weight presets based on project characteristics (web app, data science, mobile app, etc.).

- **Predictive Cost Modeling**: Use historical execution data to build more accurate cost prediction models that account for project complexity, team size, and technology stack.

- **Quality Feedback Loops**: Implement feedback mechanisms where post-project quality assessments improve future risk and timeline estimations.
