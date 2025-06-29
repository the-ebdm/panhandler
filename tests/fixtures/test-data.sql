-- Test data fixtures for integration testing
-- Additional test scenarios beyond the basic init.sql

-- Create sample project data
INSERT INTO projects (id, name, description, status, created_at) VALUES
('test-project-1', 'Sample Web App', 'A sample web application for testing', 'active', NOW()),
('test-project-2', 'API Service', 'REST API service for testing', 'completed', NOW()),
('test-project-3', 'Mobile App', 'Mobile application project', 'planning', NOW());

-- Create sample task data
INSERT INTO tasks (id, project_id, title, description, status, priority, created_at) VALUES
('task-1', 'test-project-1', 'Setup Database', 'Initialize database schema', 'completed', 'high', NOW()),
('task-2', 'test-project-1', 'Build Authentication', 'Implement user authentication', 'in_progress', 'high', NOW()),
('task-3', 'test-project-1', 'Create UI Components', 'Build reusable UI components', 'pending', 'medium', NOW()),
('task-4', 'test-project-2', 'API Documentation', 'Document REST API endpoints', 'completed', 'medium', NOW());

-- Create sample agent data
INSERT INTO agents (id, name, type, status, capabilities, created_at) VALUES
('agent-1', 'Planner Agent', 'planner', 'active', '["planning", "estimation", "task_breakdown"]', NOW()),
('agent-2', 'Developer Agent', 'developer', 'active', '["coding", "testing", "debugging"]', NOW()),
('agent-3', 'Quality Agent', 'quality', 'active', '["code_review", "testing", "compliance"]', NOW());

-- Create sample cost estimates
INSERT INTO cost_estimates (id, project_id, estimated_tokens, estimated_cost_usd, confidence_level, created_at) VALUES
('cost-1', 'test-project-1', 150000, 25.50, 0.85, NOW()),
('cost-2', 'test-project-2', 80000, 14.20, 0.92, NOW()),
('cost-3', 'test-project-3', 200000, 35.00, 0.70, NOW());

-- Create sample event log data
INSERT INTO event_logs (id, event_type, source_agent, target_agent, payload, created_at) VALUES
('event-1', 'task_created', 'planner', 'developer', '{"task_id": "task-1", "priority": "high"}', NOW()),
('event-2', 'code_reviewed', 'quality', 'developer', '{"task_id": "task-2", "status": "approved"}', NOW()),
('event-3', 'cost_updated', 'estimator', 'planner', '{"project_id": "test-project-1", "new_estimate": 25.50}', NOW()); 