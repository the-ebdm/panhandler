import { BaseAgent } from '@panhandler/core';
import { AgentConfig } from '@panhandler/types';

/**
 * Adjudicator Agent - Makes decisions between competing plans
 */
export class AdjudicatorAgent extends BaseAgent {
  constructor(config: AgentConfig) {
    super(config);
  }

  async execute(): Promise<void> {
    // TODO: Implement adjudicator logic
    console.log("Adjudicator agent executing...");
  }
} 