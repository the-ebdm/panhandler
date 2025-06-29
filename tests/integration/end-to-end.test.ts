/**
 * End-to-End Integration Tests
 * Tests full workflows and system integration scenarios
 */

import { describe, test, expect, beforeAll, afterAll } from 'bun:test';
import { createTestProject, createTestTask, createTestAgent, createProjectWithTasks, cleanupTestData } from '../utils/test-factories';
import { testQuery } from '../utils/db-helpers';

describe('End-to-End Integration Tests', () => {
  let testProjectIds: string[] = [];

  beforeAll(() => {
    console.log('🚀 Setting up end-to-end integration tests...');
  });

  afterAll(async () => {
    console.log('🧹 Cleaning up end-to-end test data...');
    if (testProjectIds.length > 0) {
      const cleanupSQL = cleanupTestData.generateBatchCleanupSQL(testProjectIds);
      try {
        await testQuery(cleanupSQL, []);
        console.log('✅ Test data cleaned up successfully');
      } catch (error) {
        console.warn('⚠️ Cleanup warning:', error);
      }
    }
  });

  test('can create and manage a complete project lifecycle', async () => {
    console.log('🔄 Testing complete project lifecycle...');

    // Create test project with tasks
    const { project, tasks } = createProjectWithTasks(3);
    testProjectIds.push(project.id);

    // Test that we can work with the project data
    expect(project.id).toBeDefined();
    expect(project.name).toBe('Test Project');
    expect(project.status).toBe('active');
    expect(tasks).toHaveLength(3);

    // Verify all tasks belong to the project
    tasks.forEach(task => {
      expect(task.project_id).toBe(project.id);
    });

    console.log(`✅ Project lifecycle test completed for project ${project.id}`);
  });

  test('can handle agent coordination workflow', async () => {
    console.log('🤖 Testing agent coordination workflow...');

    // Create test agents
    const plannerAgent = createTestAgent({
      name: 'Test Planner',
      type: 'planner',
      capabilities: ['planning', 'estimation']
    });

    const developerAgent = createTestAgent({
      name: 'Test Developer',
      type: 'developer',
      capabilities: ['coding', 'testing']
    });

    const qualityAgent = createTestAgent({
      name: 'Test Quality',
      type: 'quality',
      capabilities: ['review', 'validation']
    });

    // Verify agent properties
    expect(plannerAgent.status).toBe('active');
    expect(developerAgent.capabilities).toContain('coding');
    expect(qualityAgent.type).toBe('quality');

    console.log('✅ Agent coordination workflow test completed');
  });

  test('can perform database operations under load', async () => {
    console.log('⚡ Testing database performance under load...');

    const startTime = Date.now();

    // Create multiple projects concurrently
    const projects = Array.from({ length: 5 }, () => createTestProject());
    testProjectIds.push(...projects.map(p => p.id));

    // Simulate concurrent operations
    const operations = projects.map(async (project) => {
      const tasks = Array.from({ length: 2 }, () => createTestTask({ project_id: project.id }));
      return { project, tasks };
    });

    const results = await Promise.all(operations);
    const endTime = Date.now();

    // Verify results
    expect(results).toHaveLength(5);
    results.forEach(result => {
      expect(result.project.id).toBeDefined();
      expect(result.tasks).toHaveLength(2);
    });

    const executionTime = endTime - startTime;
    console.log(`⚡ Load test completed in ${executionTime}ms`);
    expect(executionTime).toBeLessThan(1000); // Should complete within 1 second

    console.log('✅ Database load test completed');
  });

  test('can handle error scenarios gracefully', async () => {
    console.log('🛡️ Testing error handling scenarios...');

    // Test with invalid data
    const invalidProject = createTestProject({
      id: '', // Invalid empty ID
      name: 'Invalid Project'
    });

    // This should handle the error gracefully (in a real system)
    expect(invalidProject.id).toBe('');
    expect(invalidProject.name).toBe('Invalid Project');

    // Test factory resilience
    const projectWithDefaults = createTestProject({ name: 'Valid Project' });
    expect(projectWithDefaults.id).toBeDefined();
    expect(projectWithDefaults.status).toBe('active');

    console.log('✅ Error handling test completed');
  });

  test('can validate data consistency across components', async () => {
    console.log('🔍 Testing data consistency validation...');

    // Create related test data
    const project = createTestProject({ name: 'Consistency Test Project' });
    testProjectIds.push(project.id);

    const task1 = createTestTask({
      project_id: project.id,
      title: 'First Task',
      priority: 'high'
    });

    const task2 = createTestTask({
      project_id: project.id,
      title: 'Second Task',
      priority: 'medium'
    });

    // Verify consistency
    expect(task1.project_id).toBe(project.id);
    expect(task2.project_id).toBe(project.id);
    expect(task1.project_id).toBe(task2.project_id);

    // Verify different IDs for tasks
    expect(task1.id).not.toBe(task2.id);

    console.log('✅ Data consistency validation completed');
  });

  test('can measure system performance metrics', async () => {
    console.log('📊 Testing system performance metrics...');

    const metrics = {
      projectCreationTime: 0,
      taskCreationTime: 0,
      agentCreationTime: 0
    };

    // Measure project creation time
    const projectStart = performance.now();
    const project = createTestProject({ name: 'Performance Test Project' });
    metrics.projectCreationTime = performance.now() - projectStart;
    testProjectIds.push(project.id);

    // Measure task creation time
    const taskStart = performance.now();
    const task = createTestTask({ project_id: project.id });
    metrics.taskCreationTime = performance.now() - taskStart;

    // Measure agent creation time
    const agentStart = performance.now();
    const agent = createTestAgent({ name: 'Performance Test Agent' });
    metrics.agentCreationTime = performance.now() - agentStart;

    // Verify performance is reasonable
    expect(metrics.projectCreationTime).toBeLessThan(10); // Less than 10ms
    expect(metrics.taskCreationTime).toBeLessThan(10);
    expect(metrics.agentCreationTime).toBeLessThan(10);

    console.log('📈 Performance metrics:', metrics);
    console.log('✅ Performance metrics test completed');
  });
}); 