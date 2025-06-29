import { BaseAgent } from '@panhandler/core';
import { AgentConfig } from '@panhandler/types';

/**
 * Planner Agent - Breaks down projects into detailed execution plans
 */
export class PlannerAgent extends BaseAgent {
  constructor(config: AgentConfig) {
    super(config);
  }

  async execute(): Promise<void> {
    // TODO: Implement planner logic
    console.log("Planner agent executing...");
  }
} 