/**
 * Test factories for generating consistent test data
 * Provides factory functions for creating test objects with defaults
 */

import { randomUUID } from 'crypto';

export interface TestProject {
  id: string;
  name: string;
  description: string;
  status: 'planning' | 'active' | 'completed' | 'cancelled';
  created_at: Date;
}

export interface TestTask {
  id: string;
  project_id: string;
  title: string;
  description: string;
  status: 'pending' | 'in_progress' | 'completed' | 'cancelled';
  priority: 'low' | 'medium' | 'high' | 'critical';
  created_at: Date;
}

export interface TestAgent {
  id: string;
  name: string;
  type: string;
  status: 'active' | 'inactive' | 'error';
  capabilities: string[];
  created_at: Date;
}

export interface TestCostEstimate {
  id: string;
  project_id: string;
  estimated_tokens: number;
  estimated_cost_usd: number;
  confidence_level: number;
  created_at: Date;
}

/**
 * Factory for creating test project objects
 */
export const createTestProject = (overrides: Partial<TestProject> = {}): TestProject => ({
  id: randomUUID(),
  name: 'Test Project',
  description: 'A test project for integration testing',
  status: 'active',
  created_at: new Date(),
  ...overrides,
});

/**
 * Factory for creating test task objects
 */
export const createTestTask = (overrides: Partial<TestTask> = {}): TestTask => ({
  id: randomUUID(),
  project_id: randomUUID(),
  title: 'Test Task',
  description: 'A test task for integration testing',
  status: 'pending',
  priority: 'medium',
  created_at: new Date(),
  ...overrides,
});

/**
 * Factory for creating test agent objects
 */
export const createTestAgent = (overrides: Partial<TestAgent> = {}): TestAgent => ({
  id: randomUUID(),
  name: 'Test Agent',
  type: 'test',
  status: 'active',
  capabilities: ['testing', 'validation'],
  created_at: new Date(),
  ...overrides,
});

/**
 * Factory for creating test cost estimate objects
 */
export const createTestCostEstimate = (overrides: Partial<TestCostEstimate> = {}): TestCostEstimate => ({
  id: randomUUID(),
  project_id: randomUUID(),
  estimated_tokens: 100000,
  estimated_cost_usd: 15.00,
  confidence_level: 0.8,
  created_at: new Date(),
  ...overrides,
});

/**
 * Utility function to create multiple test objects
 */
export const createMultiple = <T>(factory: () => T, count: number): T[] => {
  return Array.from({ length: count }, factory);
};

/**
 * Batch factory for creating related test data
 */
export const createProjectWithTasks = (taskCount: number = 3): { project: TestProject; tasks: TestTask[] } => {
  const project = createTestProject();
  const tasks = createMultiple(() => createTestTask({ project_id: project.id }), taskCount);

  return { project, tasks };
};

/**
 * Random data generators for testing edge cases
 */
export const randomTestData = {
  projectName: () => `Project ${Math.random().toString(36).substring(7)}`,
  taskTitle: () => `Task ${Math.random().toString(36).substring(7)}`,
  agentName: () => `Agent ${Math.random().toString(36).substring(7)}`,
  costEstimate: () => Math.floor(Math.random() * 100000) + 10000,
  confidenceLevel: () => Math.random() * 0.4 + 0.6, // 0.6 to 1.0
};

/**
 * Cleanup utilities for test data
 */
export const cleanupTestData = {
  /**
   * Generate cleanup SQL for test data
   */
  generateCleanupSQL: (projectId: string): string => {
    return `
      DELETE FROM event_logs WHERE payload LIKE '%${projectId}%';
      DELETE FROM cost_estimates WHERE project_id = '${projectId}';
      DELETE FROM tasks WHERE project_id = '${projectId}';
      DELETE FROM projects WHERE id = '${projectId}';
    `;
  },

  /**
   * Generate cleanup for multiple projects
   */
  generateBatchCleanupSQL: (projectIds: string[]): string => {
    const projectList = projectIds.map(id => `'${id}'`).join(', ');
    return `
      DELETE FROM event_logs WHERE payload::text LIKE ANY(ARRAY[${projectList.split("'").join("'%")}]);
      DELETE FROM cost_estimates WHERE project_id IN (${projectList});
      DELETE FROM tasks WHERE project_id IN (${projectList});
      DELETE FROM projects WHERE id IN (${projectList});
    `;
  },
}; 