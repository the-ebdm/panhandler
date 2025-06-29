// Core Types
export interface AgentConfig {
  agentId: string;
  model: string;
  maxTokens: number;
  temperature?: number;
}

export interface AgentState {
  status: 'idle' | 'running' | 'paused' | 'error' | 'completed';
  lastUpdated: Date;
  currentTask?: string;
}

export interface SystemConfig {
  openRouterApiKey: string;
  defaultModel: string;
  maxConcurrentAgents: number;
}

// Project Types
export interface ProjectRequirements {
  id: string;
  title: string;
  description: string;
  constraints?: {
    budget?: number;
    timeline?: string;
    requirements?: string[];
  };
}

export interface ProjectPlan {
  id: string;
  projectId: string;
  phases: ProjectPhase[];
  estimates: CostEstimate;
  dependencies: ProjectDependency[];
}

export interface ProjectPhase {
  id: string;
  name: string;
  description: string;
  estimatedHours: number;
  dependencies: string[];
  tasks: ProjectTask[];
}

export interface ProjectTask {
  id: string;
  title: string;
  description: string;
  estimatedHours: number;
  dependencies: string[];
  status: 'pending' | 'in-progress' | 'completed' | 'blocked';
}

export interface ProjectDependency {
  from: string;
  to: string;
  type: 'blocks' | 'requires' | 'enables';
}

// Cost Tracking
export interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
  totalCost: number;
  model: string;
  timestamp: Date;
}

export interface CostEstimate {
  estimatedTokens: {
    input: number;
    output: number;
  };
  estimatedCost: number;
  confidence: number;
}

export interface BudgetConstraints {
  maxCost: number;
  alertThreshold: number;
  emergencyStop: number;
}

// Event System
export interface EventPayload {
  type: string;
  agentId: string;
  timestamp: Date;
  data: Record<string, unknown>;
}

export interface AgentMessage {
  from: string;
  to: string;
  type: string;
  payload: unknown;
  timestamp: Date;
}

// API Contracts
export interface APIRequest {
  endpoint: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  data?: unknown;
}

export interface APIResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: Date;
}

// Environment Configuration
export * from './environment';
