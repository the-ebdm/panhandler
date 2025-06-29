# Phase 1: Database Schema

**Macro Step**: Database Schema  
**Phase**: Foundation Infrastructure  
**Estimated Effort**: 6-8 hours  
**Dependencies**: Project Setup (macro step 1), can run parallel with Pubsub Infrastructure  
**Parallel Execution**: Schema design and implementation can run in parallel after database setup

## Objective

Design and implement a comprehensive PostgreSQL database schema that supports project management, agent coordination, cost tracking, and documentation storage for the Panhandler system.

## Micro Steps

### Database Infrastructure Setup (Sequential - Foundation)

**Execution Order**: Must be completed first, establishes database foundation

1. **PostgreSQL Installation and Configuration** ⚡ _Priority: Critical_
   - Install PostgreSQL server with appropriate version
   - Configure database for development, staging, and production environments
   - Set up connection pooling and performance tuning
   - Configure backup and recovery procedures
   - **Estimated Time**: 40 minutes
   - **Dependencies**: Project Setup complete
   - **Output**: PostgreSQL server ready for schema creation

2. **Database Connection Management** ⚡ _Priority: Critical_
   - Install and configure database client libraries (pg, drizzle-orm)
   - Set up connection pool management and retry logic
   - Configure environment-specific database connections
   - Implement database health checks and monitoring
   - **Estimated Time**: 30 minutes
   - **Dependencies**: PostgreSQL installation
   - **Output**: Database connection infrastructure

### Core Entity Schema Design (Parallel Group A)

**Execution Order**: Can run in parallel after database setup

3. **Project Management Schema** 🔄 _Priority: High_
   - Design projects table with metadata and status tracking
   - Create phases table linked to projects
   - Implement macro_steps table with dependencies and status
   - Add micro_steps table with execution details and results
   - **Estimated Time**: 60 minutes
   - **Dependencies**: Database connection setup
   - **Output**: Project hierarchy schema

4. **Agent Management Schema** 🔄 _Priority: High_
   - Create agents table with capabilities and status
   - Design agent_instances table for running agent tracking
   - Implement agent_events table for lifecycle and health monitoring
   - Add agent_capabilities table for skill and resource tracking
   - **Estimated Time**: 50 minutes
   - **Dependencies**: Database connection setup
   - **Output**: Agent management schema

5. **Cost Tracking Schema** 🔄 _Priority: High_
   - Design cost_estimates table for project and step estimates
   - Create token_usage table for actual OpenRouter API consumption
   - Implement cost_models table for pattern recognition and learning
   - Add billing_records table for user cost tracking
   - **Estimated Time**: 55 minutes
   - **Dependencies**: Project management schema
   - **Output**: Cost tracking and billing schema

### Event and Communication Schema (Parallel Group B)

**Execution Order**: Can run in parallel with Group A

6. **Event Storage Schema** 🔄 _Priority: Medium_
   - Create events table for pubsub event persistence
   - Design event_subscriptions table for agent subscription tracking
   - Implement event_replay table for error recovery and debugging
   - Add event_metrics table for performance and monitoring data
   - **Estimated Time**: 45 minutes
   - **Dependencies**: Agent management schema
   - **Output**: Event storage and tracking schema

7. **User and Authentication Schema** 🔄 _Priority: Medium_
   - Design users table with authentication and profile data
   - Create user_projects table for project access control
   - Implement api_keys table for OpenRouter key management
   - Add user_preferences table for decision weights and settings
   - **Estimated Time**: 40 minutes
   - **Dependencies**: Database connection setup
   - **Output**: User management and security schema

### Documentation and Knowledge Schema (Parallel Group C)

**Execution Order**: Can run in parallel with Groups A & B

8. **Documentation Management Schema** 🔄 _Priority: Medium_
   - Create documents table for project documentation storage
   - Design document_versions table for change tracking
   - Implement document_links table for cross-references
   - Add documentation_templates table for standardized structures
   - **Estimated Time**: 50 minutes
   - **Dependencies**: Project management schema
   - **Output**: Documentation storage schema

9. **Knowledge Base Schema** 🔄 _Priority: Low_
   - Design patterns table for learned development patterns
   - Create complexity_metrics table for cost estimation improvements
   - Implement success_criteria table for project outcome tracking
   - Add feedback_loops table for continuous learning
   - **Estimated Time**: 45 minutes
   - **Dependencies**: Cost tracking schema
   - **Output**: Knowledge base and learning schema

### Database Operations and Utilities (Parallel Group D)

**Execution Order**: Can run in parallel with all other groups

10. **Migration System Setup** 🔄 _Priority: Medium_
    - Create database migration framework with versioning
    - Implement schema change tracking and rollback capabilities
    - Set up automated migration testing and validation
    - Create data seeding scripts for development and testing
    - **Estimated Time**: 55 minutes
    - **Dependencies**: Database connection setup
    - **Output**: Database migration and versioning system

11. **Database Indexes and Performance** 🔄 _Priority: Medium_
    - Design and implement performance indexes for all tables
    - Set up query optimization and execution plan analysis
    - Configure database monitoring and slow query logging
    - Implement database partitioning for large tables
    - **Estimated Time**: 50 minutes
    - **Dependencies**: All schema tables created
    - **Output**: Optimized database performance

12. **Data Access Layer** 🔄 _Priority: High_
    - Create TypeScript types for all database entities
    - Implement repository pattern for data access
    - Set up ORM configuration and query builders
    - Create database transaction management utilities
    - **Estimated Time**: 70 minutes
    - **Dependencies**: All schema design complete
    - **Output**: Type-safe data access layer

### Testing and Validation (Parallel Group E)

**Execution Order**: Can run in parallel with other groups

13. **Database Testing Framework** 🔄 _Priority: Medium_
    - Set up test database environment and fixtures
    - Create integration tests for all schema entities
    - Implement database performance and load testing
    - Set up data integrity and constraint validation tests
    - **Estimated Time**: 60 minutes
    - **Dependencies**: Data access layer complete
    - **Output**: Comprehensive database test suite

## Validation Criteria

- [ ] PostgreSQL server runs and accepts connections
- [ ] All schema tables create successfully with proper relationships
- [ ] Database migrations execute without errors
- [ ] Indexes improve query performance as expected
- [ ] Data access layer provides type-safe database operations
- [ ] Cost tracking accurately captures token usage
- [ ] Event storage supports pubsub system requirements
- [ ] All database operations pass integration tests

## Risk Mitigation

- **Schema Evolution**: Use migration system to handle schema changes gracefully
- **Performance Issues**: Monitor query performance and optimize indexes proactively
- **Data Integrity**: Implement comprehensive constraints and validation rules
- **Scaling Challenges**: Plan for database partitioning and read replicas

## Cost Estimation

**[To be properly implemented]** - Token usage cost estimation based on OpenRouter API pricing

**Target Model**: Gemini 2.5 Flash Preview 05-20 (thinking)

- Input: $0.15 per 1M tokens
- Output: $3.50 per 1M tokens
- Context Limit: 1M tokens

**Estimated Token Usage** (preliminary):

- Schema design and SQL generation: ~14,000 output tokens
- TypeScript type generation: ~10,000 output tokens
- Migration and setup scripts: ~8,000 output tokens
- Testing and validation code: ~12,000 output tokens
- Database optimization analysis: ~8,000 input tokens
- **Estimated Cost**: ~$0.16-0.22 (subject to actual usage patterns)

_Note: Database schema is foundational and changes will be infrequent but impactful._

## Next Steps

Upon completion, this database schema enables:

- **Phase 1, Macro Step 4**: Basic Agent Framework with persistent state management
- **Phase 2**: Core Agent Framework with full data persistence
- **All future development**: Reliable data storage and retrieval for all system components
