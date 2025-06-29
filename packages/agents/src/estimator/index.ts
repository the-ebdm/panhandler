import { BaseAgent } from '@panhandler/core';
import { AgentConfig } from '@panhandler/types';

/**
 * Estimator Agent - Estimates time, cost, and resource requirements
 */
export class EstimatorAgent extends BaseAgent {
  constructor(config: AgentConfig) {
    super(config);
  }

  async execute(): Promise<void> {
    // TODO: Implement estimator logic
    console.log('Estimator agent executing...');
  }
}
