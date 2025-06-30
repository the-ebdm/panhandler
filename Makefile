# Panhandler Development Makefile
# AI Agent Orchestration System

.PHONY: help dev build test lint clean setup deploy docs services database env workspace release

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

##@ Development Commands

help: ## Display this help message
	@echo "$(BLUE)Panhandler Development Makefile$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(BLUE)<target>$(RESET)\n\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

dev: ## Start web development server
	@echo "$(GREEN)Starting web development server...$(RESET)"
	bun run --filter '@panhandler/web' dev

dev-api: ## Start API development server
	@echo "$(GREEN)Starting API development server...$(RESET)"
	bun run --filter '@panhandler/agents' dev

dev-all: build-deps ## Start all development servers
	@echo "$(GREEN)Starting all development servers...$(RESET)"
	concurrently "bun run --filter '@panhandler/agents' dev" "bun run --filter '@panhandler/web' dev"

dev-full: services-start dev-all ## Start services and all development servers

watch: build-deps ## Watch mode for all packages
	@echo "$(GREEN)Starting watch mode...$(RESET)"
	bun run --filter '@panhandler/types' build && bun run --filter '@panhandler/core' build && bun run --filter '*' dev

##@ Build Commands

build-deps: ## Build dependency packages (types, core)
	@echo "$(GREEN)Building dependency packages...$(RESET)"
	bun run --filter '@panhandler/types' build && bun run --filter '@panhandler/core' build

build: build-deps ## Build all packages
	@echo "$(GREEN)Building all packages...$(RESET)"
	bun run --filter '*' build

build-sequential: ## Build packages in dependency order
	@echo "$(GREEN)Building packages sequentially...$(RESET)"
	bun run --filter '@panhandler/types' build && \
	bun run --filter '@panhandler/core' build && \
	bun run --filter '@panhandler/agents' build && \
	bun run --filter '@panhandler/web' build

build-production: ## Build for production
	@echo "$(GREEN)Building for production...$(RESET)"
	NODE_ENV=production $(MAKE) build-sequential

##@ Testing Commands

test: ## Run all tests
	@echo "$(GREEN)Running tests...$(RESET)"
	bun test

test-watch: ## Run tests in watch mode
	@echo "$(GREEN)Running tests in watch mode...$(RESET)"
	bun test --watch

test-coverage: ## Run tests with coverage
	@echo "$(GREEN)Running tests with coverage...$(RESET)"
	bun test --coverage

test-integration: ## Run integration tests only
	@echo "$(GREEN)Running integration tests...$(RESET)"
	bun test tests/integration/

test-unit: ## Run unit tests only
	@echo "$(GREEN)Running unit tests...$(RESET)"
	bun test packages/

test-ci: type-check lint test ## Run full CI test suite

test-db-up: ## Start test database
	@echo "$(GREEN)Starting test database...$(RESET)"
	docker-compose -f docker-compose.test.yml up -d

test-db-down: ## Stop test database
	@echo "$(GREEN)Stopping test database...$(RESET)"
	docker-compose -f docker-compose.test.yml down

test-db-logs: ## View test database logs
	docker-compose -f docker-compose.test.yml logs -f test-postgres

test-full: test-db-up ## Run complete test cycle with database
	@echo "$(GREEN)Running full test cycle...$(RESET)"
	@sleep 5
	$(MAKE) test
	$(MAKE) test-db-down

##@ Code Quality

lint: ## Run linting
	@echo "$(GREEN)Running linter...$(RESET)"
	bun run --filter '*' lint

lint-fix: ## Fix linting issues
	@echo "$(GREEN)Fixing linting issues...$(RESET)"
	bun run --filter '*' lint:fix

format: ## Format code
	@echo "$(GREEN)Formatting code...$(RESET)"
	prettier --write .

format-check: ## Check code formatting
	@echo "$(GREEN)Checking code formatting...$(RESET)"
	prettier --check .

type-check: ## Run TypeScript type checking
	@echo "$(GREEN)Running type checks...$(RESET)"
	bun run --filter '*' type-check

precommit: type-check lint format-check ## Run pre-commit checks

##@ Database Commands

db-setup: ## Setup database with migrations
	@echo "$(GREEN)Setting up database...$(RESET)"
	bun scripts/migrate.ts migrate

db-migrate: ## Run database migrations
	@echo "$(GREEN)Running database migrations...$(RESET)"
	bun scripts/migrate.ts migrate

db-rollback: ## Rollback last migration
	@echo "$(GREEN)Rolling back migration...$(RESET)"
	bun scripts/migrate.ts rollback

db-status: ## Check migration status
	@echo "$(GREEN)Checking migration status...$(RESET)"
	bun scripts/migrate.ts status

db-reset: db-rollback db-migrate ## Reset database (rollback + migrate)

##@ Services Management

services-start: ## Start background services
	@echo "$(GREEN)Starting services...$(RESET)"
	scripts/start-services.sh

services-stop: ## Stop background services
	@echo "$(GREEN)Stopping services...$(RESET)"
	scripts/stop-services.sh

services-status: ## Check services status
	@echo "$(GREEN)Checking services status...$(RESET)"
	scripts/services-status.sh

##@ Environment Management

env-validate: ## Validate environment configuration
	@echo "$(GREEN)Validating environment...$(RESET)"
	bun run scripts/validate-env.js

env-generate: ## Generate environment files
	@echo "$(GREEN)Generating environment files...$(RESET)"
	scripts/generate-env.sh

setup: install build-deps db-setup ## Complete project setup

setup-dev: ## Setup for development (copy dev env)
	@echo "$(GREEN)Setting up development environment...$(RESET)"
	cp env.development .env
	$(MAKE) setup

setup-fresh: clean-full setup ## Fresh setup (clean + setup)

##@ Workspace Management

install: ## Install dependencies
	@echo "$(GREEN)Installing dependencies...$(RESET)"
	bun install

clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(RESET)"
	bun run --filter '*' clean
	rm -rf node_modules/.cache

clean-full: clean ## Full clean (including node_modules)
	@echo "$(GREEN)Full clean...$(RESET)"
	rm -rf node_modules
	bun install

workspace-info: ## Show workspace information
	@echo "$(GREEN)Workspace information:$(RESET)"
	bun run --filter '*' --

workspace-clean: ## Clean all workspace packages
	@echo "$(GREEN)Cleaning workspace packages...$(RESET)"
	bun run --filter '*' clean

workspace-update: ## Update workspace dependencies
	@echo "$(GREEN)Updating workspace dependencies...$(RESET)"
	bun update
	bun run --filter '*' update

##@ Production Commands

start: build-production services-start ## Start production server
	@echo "$(GREEN)Starting production server...$(RESET)"
	bun run --filter '@panhandler/agents' start

deploy-build: build-production ## Build for deployment
	@echo "$(GREEN)Building for deployment...$(RESET)"
	scripts/docker-build.sh

##@ Release Management

release-patch: ## Release patch version
	@echo "$(GREEN)Releasing patch version...$(RESET)"
	bun version patch
	git push --tags

release-minor: ## Release minor version
	@echo "$(GREEN)Releasing minor version...$(RESET)"
	bun version minor
	git push --tags

release-major: ## Release major version
	@echo "$(GREEN)Releasing major version...$(RESET)"
	bun version major
	git push --tags

##@ Documentation Commands

docs-generate: ## Generate API documentation
	@echo "$(GREEN)Generating documentation...$(RESET)"
	typedoc

docs-serve: docs-generate ## Serve documentation locally
	@echo "$(GREEN)Serving documentation on http://localhost:8080$(RESET)"
	cd docs/api && python3 -m http.server 8080

docs-clean: ## Clean documentation
	@echo "$(GREEN)Cleaning documentation...$(RESET)"
	rm -rf docs/api

docs-watch: ## Watch and regenerate documentation
	@echo "$(GREEN)Watching documentation...$(RESET)"
	typedoc --watch

##@ Docker Commands

docker-build: ## Build Docker images
	@echo "$(GREEN)Building Docker images...$(RESET)"
	scripts/docker-build.sh all

docker-build-agents: ## Build agents Docker image
	@echo "$(GREEN)Building agents Docker image...$(RESET)"
	scripts/docker-build.sh agents

docker-build-web: ## Build web Docker image
	@echo "$(GREEN)Building web Docker image...$(RESET)"
	scripts/docker-build.sh web

docker-push: ## Build and push Docker images
	@echo "$(GREEN)Building and pushing Docker images...$(RESET)"
	scripts/docker-build.sh --push --latest all

docker-push-agents: ## Build and push agents image
	@echo "$(GREEN)Building and pushing agents image...$(RESET)"
	scripts/docker-build.sh --push agents

docker-push-web: ## Build and push web image
	@echo "$(GREEN)Building and pushing web image...$(RESET)"
	scripts/docker-build.sh --push web

docker-run: ## Run Docker container
	@echo "$(GREEN)Running Docker container...$(RESET)"
	docker run -p 3000:3000 panhandler:latest

docker-clean: ## Clean Docker artifacts
	@echo "$(GREEN)Cleaning Docker artifacts...$(RESET)"
	docker system prune -f

docker-login: ## Login to container registry
	@echo "$(GREEN)Logging into container registry...$(RESET)"
	scripts/registry-auth.sh login

docker-status: ## Check registry authentication status
	@echo "$(GREEN)Checking registry status...$(RESET)"
	scripts/registry-auth.sh status

##@ Deployment Automation

deploy: deploy-development ## Deploy to development environment (default)

deploy-development: ## Deploy to development
	@echo "$(GREEN)Deploying to development environment...$(RESET)"
	@$(MAKE) deploy-env ENV=development ARGS="--force"

deploy-staging: ## Deploy to staging
	@echo "$(GREEN)Deploying to staging environment...$(RESET)"
	@$(MAKE) deploy-env ENV=staging

deploy-production: ## Deploy to production
	@echo "$(GREEN)Deploying to production environment...$(RESET)"
	@$(MAKE) deploy-env ENV=production

deploy-env: ## Deploy to specific environment (requires ENV variable)
	@if [ -z "$(ENV)" ]; then echo "$(RED)Error: ENV variable required$(RESET)"; exit 1; fi
	@echo "$(GREEN)Deploying to $(ENV) environment...$(RESET)"
	scripts/deploy.sh $(ENV) $(ARGS)

deploy-local: ## Deploy locally with docker-compose
	@echo "$(GREEN)Deploying locally with docker-compose...$(RESET)"
	docker-compose up -d

deploy-local-full: services-stop deploy-local db-migrate ## Full local deployment
	@echo "$(GREEN)Full local deployment...$(RESET)"
	@sleep 5
	$(MAKE) deploy-check-local

deploy-check: ## Check deployment status
	@echo "$(GREEN)Checking deployment status...$(RESET)"
	scripts/deploy-check.sh

deploy-check-local: ## Check local deployment status
	@echo "$(GREEN)Checking local deployment status...$(RESET)"
	scripts/deploy-check.sh local

deploy-health: ## Check deployment health
	@echo "$(GREEN)Checking deployment health...$(RESET)"
	scripts/health-check.sh

deploy-logs: ## View deployment logs
	@echo "$(GREEN)Viewing deployment logs...$(RESET)"
	scripts/deploy-logs.sh

deploy-status: ## Show deployment status across environments
	@echo "$(GREEN)Deployment status:$(RESET)"
	@echo "$(BLUE)Development:$(RESET)"
	@scripts/deploy-check.sh development || echo "$(RED)Not deployed$(RESET)"
	@echo "$(BLUE)Staging:$(RESET)"
	@scripts/deploy-check.sh staging || echo "$(RED)Not deployed$(RESET)"
	@echo "$(BLUE)Production:$(RESET)"
	@scripts/deploy-check.sh production || echo "$(RED)Not deployed$(RESET)"

deploy-rollback: ## Rollback last deployment
	@echo "$(YELLOW)Rolling back last deployment...$(RESET)"
	scripts/deploy-rollback.sh

deploy-rollback-to: ## Rollback to specific version (requires VERSION variable)
	@if [ -z "$(VERSION)" ]; then echo "$(RED)Error: VERSION variable required$(RESET)"; exit 1; fi
	@echo "$(YELLOW)Rolling back to version $(VERSION)...$(RESET)"
	scripts/deploy-rollback.sh $(VERSION)

deploy-stop: ## Stop deployment
	@echo "$(YELLOW)Stopping deployment...$(RESET)"
	scripts/deploy-stop.sh

deploy-restart: ## Restart deployment
	@echo "$(GREEN)Restarting deployment...$(RESET)"
	scripts/deploy-restart.sh

deploy-scale: ## Scale deployment (requires REPLICAS variable)
	@if [ -z "$(REPLICAS)" ]; then echo "$(RED)Error: REPLICAS variable required$(RESET)"; exit 1; fi
	@echo "$(GREEN)Scaling deployment to $(REPLICAS) replicas...$(RESET)"
	scripts/deploy-scale.sh $(REPLICAS)

##@ Quick Commands

quick-start: install build-deps dev ## Quick start for new developers

quick-test: lint type-check test ## Quick validation

quick-deploy: clean build-production deploy-build ## Quick deployment build

##@ Utility Commands

check-tools: ## Check required tools are installed
	@echo "$(GREEN)Checking required tools...$(RESET)"
	@which bun > /dev/null || (echo "$(RED)Error: bun not installed$(RESET)" && exit 1)
	@which docker > /dev/null || (echo "$(RED)Error: docker not installed$(RESET)" && exit 1)
	@which git > /dev/null || (echo "$(RED)Error: git not installed$(RESET)" && exit 1)
	@echo "$(GREEN)All required tools are installed$(RESET)"

list-ports: ## List ports used by services
	@echo "$(BLUE)Service Ports:$(RESET)"
	@echo "  Web Dev Server: 3000"
	@echo "  API Server: 3001"
	@echo "  PostgreSQL: 5432"
	@echo "  Test PostgreSQL: 5433"
	@echo "  Redis: 6379"
	@echo "  Test Redis: 6380"
	@echo "  Documentation: 8080"

health-check: ## Basic health check
	@echo "$(GREEN)Running health check...$(RESET)"
	$(MAKE) check-tools
	$(MAKE) type-check
	@echo "$(GREEN)Health check passed$(RESET)"

##@ Special Targets

# Ensure certain directories exist
logs:
	@mkdir -p logs

tmp:
	@mkdir -p tmp

# Clean up on SIGINT
.PHONY: cleanup
cleanup:
	@echo "$(YELLOW)Cleaning up...$(RESET)"
	$(MAKE) services-stop || true
	$(MAKE) test-db-down || true 