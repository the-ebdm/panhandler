-- Test database initialization script
-- This runs when the PostgreSQL container starts

-- Create additional test user if needed
-- (main test_user is created via environment variables)

-- Enable extensions that we might need for testing
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Set timezone to UTC for consistent testing
SET timezone = 'UTC';

-- Create a test schema for isolation if needed
CREATE SCHEMA IF NOT EXISTS test_schema;

-- Grant permissions
GRANT USAGE ON SCHEMA test_schema TO test_user;
GRANT CREATE ON SCHEMA test_schema TO test_user; 