import { AgentConfig, AgentState } from '@panhandler/types';

/**
 * Abstract base class for all Panhandler agents
 * Provides common functionality for lifecycle management, event handling, and state persistence
 */
export abstract class BaseAgent {
  protected config: AgentConfig;
  protected state: AgentState;

  constructor(config: AgentConfig) {
    this.config = config;
    this.state = {
      status: 'idle',
      lastUpdated: new Date(),
    };
  }

  /**
   * Start the agent
   */
  async start(): Promise<void> {
    this.state.status = 'running';
    this.state.lastUpdated = new Date();
    await this.onStart();
  }

  /**
   * Stop the agent
   */
  async stop(): Promise<void> {
    this.state.status = 'idle';
    this.state.lastUpdated = new Date();
    await this.onStop();
  }

  /**
   * Pause the agent
   */
  async pause(): Promise<void> {
    this.state.status = 'paused';
    this.state.lastUpdated = new Date();
    await this.onPause();
  }

  /**
   * Resume the agent from paused state
   */
  async resume(): Promise<void> {
    this.state.status = 'running';
    this.state.lastUpdated = new Date();
    await this.onResume();
  }

  /**
   * Get current agent state
   */
  getState(): AgentState {
    return { ...this.state };
  }

  /**
   * Execute the agent's main functionality
   */
  abstract execute(): Promise<void>;

  /**
   * Lifecycle hooks - subclasses can override these
   */
  protected async onStart(): Promise<void> { }
  protected async onStop(): Promise<void> { }
  protected async onPause(): Promise<void> { }
  protected async onResume(): Promise<void> { }
}

/**
 * Simple event bus for agent communication
 * Will be replaced with Deepstream.io in later phases
 */
export class EventBus {
  private listeners: Map<string, Function[]> = new Map();

  /**
   * Subscribe to events
   */
  on(eventType: string, callback: Function): void {
    if (!this.listeners.has(eventType)) {
      this.listeners.set(eventType, []);
    }
    this.listeners.get(eventType)!.push(callback);
  }

  /**
   * Unsubscribe from events
   */
  off(eventType: string, callback: Function): void {
    const callbacks = this.listeners.get(eventType);
    if (callbacks) {
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
      }
    }
  }

  /**
   * Emit an event
   */
  emit(eventType: string, data: any): void {
    const callbacks = this.listeners.get(eventType);
    if (callbacks) {
      callbacks.forEach(callback => callback(data));
    }
  }
}

/**
 * Global event bus instance
 */
export const eventBus = new EventBus();

/**
 * Simple logger interface
 */
export class Logger {
  static info(message: string, meta?: any): void {
    console.log(`[INFO] ${new Date().toISOString()}: ${message}`, meta || '');
  }

  static error(message: string, error?: Error, meta?: any): void {
    console.error(`[ERROR] ${new Date().toISOString()}: ${message}`, error || '', meta || '');
  }

  static warn(message: string, meta?: any): void {
    console.warn(`[WARN] ${new Date().toISOString()}: ${message}`, meta || '');
  }

  static debug(message: string, meta?: any): void {
    if (process.env.NODE_ENV === 'development') {
      console.debug(`[DEBUG] ${new Date().toISOString()}: ${message}`, meta || '');
    }
  }
} 