# @panhandler/core

Core shared agent framework for the Panhandler AI agent orchestration system.

## Purpose

This package provides the foundational infrastructure and abstractions that all Panhandler agents build upon:

- **BaseAgent**: Abstract base class for all agent implementations
- **Event System**: Pub/sub communication infrastructure
- **Agent Lifecycle**: Start, stop, pause, resume functionality
- **State Management**: Agent state persistence and recovery
- **Error Handling**: Robust error handling and recovery mechanisms
- **Logging**: Structured logging and observability
- **Configuration**: Environment and agent configuration management

## Key Components

- `BaseAgent` - Abstract agent class with lifecycle management
- `EventBus` - Pub/sub event communication system
- `StateManager` - Agent state persistence and recovery
- `Logger` - Structured logging interface
- `ConfigManager` - Configuration management utilities

## Usage

```typescript
import { BaseAgent, EventBus } from '@panhandler/core';
import { AgentConfig } from '@panhandler/types';

class MyAgent extends BaseAgent {
  constructor(config: AgentConfig) {
    super(config);
  }

  async execute() {
    // Agent implementation
  }
}
```

## Dependencies

- `@panhandler/types` - Shared TypeScript types
- `langchain` - LLM integration framework
- `langgraph` - Agent workflow orchestration
