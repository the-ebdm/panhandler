# Multi-stage Dockerfile for Panhandler Agents
# Uses Bun for optimal performance and smaller container size

# Stage 1: Base image with Bun
FROM oven/bun:1.2-alpine AS base
WORKDIR /app

# Install system dependencies needed for native modules
RUN apk add --no-cache \
    curl \
    git \
    && rm -rf /var/cache/apk/*

# Stage 2: Dependencies
FROM base AS deps
COPY package.json bunfig.toml ./
COPY packages/types/package.json ./packages/types/
COPY packages/core/package.json ./packages/core/
COPY packages/agents/package.json ./packages/agents/

# Install all dependencies to ensure workspace linking works
RUN bun install --ignore-scripts

# Stage 3: Build
FROM base AS build
COPY package.json bunfig.toml ./
COPY packages/ ./packages/
COPY tsconfig.json ./
COPY scripts/ ./scripts/

# Install all dependencies (including dev, skip prepare script)
RUN bun install --ignore-scripts

# Build packages in dependency order
RUN bun run --filter '@panhandler/types' build && \
    bun run --filter '@panhandler/core' build && \
    bun run --filter '@panhandler/agents' build

# Stage 4: Production runtime
FROM oven/bun:1.2-alpine AS runtime

# Create non-root user for security
RUN addgroup -g 1001 -S bunjs && \
    adduser -S bunjs -u 1001

WORKDIR /app

# Copy workspace configuration to preserve workspace structure
COPY --from=deps --chown=bunjs:bunjs /app/package.json ./package.json
COPY --from=deps --chown=bunjs:bunjs /app/bunfig.toml ./bunfig.toml
COPY --from=deps --chown=bunjs:bunjs /app/node_modules ./node_modules

# Copy built packages with their complete structure
COPY --from=build --chown=bunjs:bunjs /app/packages/types/dist ./packages/types/dist
COPY --from=build --chown=bunjs:bunjs /app/packages/types/package.json ./packages/types/package.json
COPY --from=build --chown=bunjs:bunjs /app/packages/core/dist ./packages/core/dist
COPY --from=build --chown=bunjs:bunjs /app/packages/core/package.json ./packages/core/package.json
COPY --from=build --chown=bunjs:bunjs /app/packages/agents/dist ./packages/agents/dist
COPY --from=build --chown=bunjs:bunjs /app/packages/agents/package.json ./packages/agents/package.json

# Copy runtime scripts
COPY --from=build --chown=bunjs:bunjs /app/scripts ./scripts

# Switch to non-root user
USER bunjs

# Expose port (default for agents service)
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Default command (can be overridden)
CMD ["bun", "run", "packages/agents/dist/index.js"] 