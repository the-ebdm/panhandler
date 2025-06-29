# @panhandler/web

Web interface for the Panhandler AI agent orchestration system.

## Purpose

This package provides a modern, responsive web interface for monitoring, controlling, and interacting with the Panhandler agent ecosystem. Users can submit projects, monitor progress, review estimates, and manage agent workflows through an intuitive dashboard.

## Key Features

### Project Management

- Submit new project requirements
- View project status and progress
- Review and approve cost estimates
- Monitor real-time execution

### Agent Monitoring

- Real-time agent status dashboard
- Event stream visualization
- Performance metrics and analytics
- Error monitoring and debugging

### Cost Transparency

- OpenRouter token usage tracking
- Real-time cost monitoring
- Budget alerts and controls
- Cost breakdown by agent and task

### Workflow Control

- Pause/resume agent execution
- Manual intervention and overrides
- Approval workflows for estimates
- Emergency stop controls

## Technology Stack

- **React 18** - Modern UI framework
- **TypeScript** - Type-safe development
- **Vite** - Fast build tooling
- **Tanstack Query** - Data fetching and caching
- **Zustand** - Lightweight state management
- **React Router** - Client-side routing

## Development

```bash
# Start development server
bun run dev

# Build for production
bun run build

# Preview production build
bun run preview
```

## Dependencies

- `@panhandler/types` - Shared TypeScript types for API contracts
