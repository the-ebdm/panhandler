# @panhandler/types

Shared TypeScript types for the Panhandler AI agent orchestration system.

## Purpose

This package provides a centralized collection of TypeScript types, interfaces, and type definitions used across all Panhandler packages. It ensures type safety and consistency throughout the entire system.

## Type Categories

### Core Types

- `AgentConfig` - Configuration for individual agents
- `AgentState` - Agent lifecycle and status types
- `EventPayload` - Event system message types
- `SystemConfig` - Global system configuration

### Project Types

- `ProjectRequirements` - User-submitted project specifications
- `ProjectPlan` - Generated execution plans
- `ProjectEstimate` - Cost and time estimates
- `ProjectStatus` - Execution status and progress

### Agent Communication

- `AgentMessage` - Inter-agent communication format
- `EventType` - Enumeration of system events
- `WorkflowState` - Agent workflow status types

### Cost Tracking

- `TokenUsage` - OpenRouter API token consumption
- `CostEstimate` - Financial cost projections
- `BudgetConstraints` - User-defined spending limits

### API Contracts

- `APIRequest` - Web interface API request types
- `APIResponse` - Web interface API response types
- `WebSocketMessage` - Real-time communication types

## Usage

```typescript
import { AgentConfig, ProjectPlan, CostEstimate } from '@panhandler/types';

const config: AgentConfig = {
  agentId: 'planner-001',
  model: 'gemini-2.5-flash-preview',
  maxTokens: 100000
};

const plan: ProjectPlan = {
  phases: [...],
  estimates: [...],
  dependencies: [...]
};
```

## Development

This package is purely TypeScript definitions and does not require a build step for type checking. However, it does compile for runtime usage by other packages.

```bash
# Type check definitions
bun run type-check

# Build for distribution
bun run build
```
