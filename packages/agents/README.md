# @panhandler/agents

Individual agent implementations for the Panhandler AI agent orchestration system.

## Purpose

This package contains the concrete implementations of all specialized agents that work together to autonomously plan, estimate, and execute software development projects.

## Agent Implementations

### Core Orchestration Agents

- **Planner Agent** (`./planner`) - Breaks down projects into detailed execution plans
- **Estimator Agent** (`./estimator`) - Estimates time, cost, and resource requirements
- **Executor Agent** (`./executor`) - Executes individual development tasks
- **Adjudicator Agent** (`./adjudicator`) - Makes decisions between competing plans

### Supporting Agents

- **Supervisor Agent** (`./supervisor`) - C-Suite level oversight and governance
- **Documentation Agent** (`./documentation`) - Maintains project documentation

## Usage

```typescript
import { PlannerAgent, EstimatorAgent } from '@panhandler/agents';

// Initialize agents
const planner = new PlannerAgent(config);
const estimator = new EstimatorAgent(config);

// Use agents in coordination
const plan = await planner.createPlan(requirements);
const estimate = await estimator.estimatePlan(plan);
```

## Agent Communication

All agents communicate through the centralized event system provided by `@panhandler/core`. This enables:

- Loosely coupled architecture
- Event-driven workflows
- Fault tolerance and recovery
- Transparent observability

## Dependencies

- `@panhandler/core` - Shared agent framework
- `@panhandler/types` - Shared TypeScript types
- `langchain` - LLM integration
- `langgraph` - Workflow orchestration 