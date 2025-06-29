#!/bin/bash

# Deployment Script for Panhandler
# Handles deployment to different environments (development, staging, production)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [ENVIRONMENT] [OPTIONS]

Deploy Panhandler to specified environment.

ENVIRONMENTS:
    development         Deploy to development environment
    staging             Deploy to staging environment
    production          Deploy to production environment
    local               Deploy locally with docker-compose

OPTIONS:
    --skip-build        Skip building before deployment
    --skip-push         Skip pushing images (use existing)
    --dry-run           Show what would be deployed without executing
    --force             Force deployment without confirmation
    --version VERSION   Deploy specific version
    -h, --help          Show this help message

EXAMPLES:
    $0 development                      # Deploy to development
    $0 production --version v1.2.3     # Deploy specific version to production
    $0 staging --dry-run               # Dry run for staging deployment
EOF
}

# Default configuration
ENVIRONMENT=""
SKIP_BUILD=false
SKIP_PUSH=false
DRY_RUN=false
FORCE=false
VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        development|staging|production|local)
            ENVIRONMENT="$1"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-push)
            SKIP_PUSH=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate environment
if [[ -z "$ENVIRONMENT" ]]; then
    error "Environment required. Use --help for usage information."
fi

# Set environment-specific configuration
case "$ENVIRONMENT" in
    development)
        DOCKER_COMPOSE_FILE="docker-compose.yml"
        REGISTRY_TAG="dev"
        HEALTH_CHECK_URL="http://localhost:3001/health"
        ;;
    staging)
        DOCKER_COMPOSE_FILE="docker-compose.staging.yml"
        REGISTRY_TAG="staging"
        HEALTH_CHECK_URL="https://staging-api.panhandler.ai/health"
        ;;
    production)
        DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
        REGISTRY_TAG="latest"
        HEALTH_CHECK_URL="https://api.panhandler.ai/health"
        ;;
    local)
        DOCKER_COMPOSE_FILE="docker-compose.yml"
        REGISTRY_TAG="local"
        HEALTH_CHECK_URL="http://localhost:3001/health"
        ;;
    *)
        error "Unknown environment: $ENVIRONMENT"
        ;;
esac

# Get version information
get_version() {
    if [[ -n "$VERSION" ]]; then
        echo "$VERSION"
    else
        cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]'
    fi
}

GIT_COMMIT=$(git rev-parse HEAD)
DEPLOY_VERSION=$(get_version)

# Deployment functions
check_prerequisites() {
    log "Checking deployment prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
    fi
    
    # Check environment file
    local env_file="env.${ENVIRONMENT}"
    if [[ ! -f "$env_file" ]]; then
        warning "Environment file $env_file not found, using defaults"
    fi
    
    # Check Docker Compose file
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        error "Docker Compose file $DOCKER_COMPOSE_FILE not found"
    fi
    
    success "Prerequisites check passed"
}

build_images() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        log "Skipping build step"
        return
    fi
    
    log "Building Docker images for $ENVIRONMENT..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would run: scripts/docker-build.sh --version $DEPLOY_VERSION all"
        return
    fi
    
    scripts/docker-build.sh --version "$DEPLOY_VERSION" all
    success "Images built successfully"
}

push_images() {
    if [[ "$SKIP_PUSH" == "true" ]]; then
        log "Skipping push step"
        return
    fi
    
    log "Pushing images to registry..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would run: scripts/docker-build.sh --push --version $DEPLOY_VERSION all"
        return
    fi
    
    scripts/docker-build.sh --push --version "$DEPLOY_VERSION" all
    success "Images pushed successfully"
}

deploy_environment() {
    log "Deploying to $ENVIRONMENT environment..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would run: docker-compose -f $DOCKER_COMPOSE_FILE up -d"
        log "Would set: VERSION=$DEPLOY_VERSION"
        log "Would set: GIT_COMMIT=$GIT_COMMIT"
        return
    fi
    
    # Set environment variables for docker-compose
    export VERSION="$DEPLOY_VERSION"
    export GIT_COMMIT="$GIT_COMMIT"
    export ENVIRONMENT="$ENVIRONMENT"
    
    # Deploy with docker-compose
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    success "Deployment completed"
}

wait_for_health() {
    log "Waiting for services to become healthy..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would check health at: $HEALTH_CHECK_URL"
        return
    fi
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -sSf "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            success "Health check passed"
            return
        fi
        
        log "Health check attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
        sleep 10
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
}

post_deploy_actions() {
    log "Running post-deployment actions..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would run post-deployment actions"
        return
    fi
    
    # Run database migrations if needed
    if [[ "$ENVIRONMENT" != "local" ]]; then
        log "Running database migrations..."
        # This would typically connect to the deployed service to run migrations
        # For now, we'll just log the action
        log "Database migrations would be run here"
    fi
    
    success "Post-deployment actions completed"
}

show_deployment_info() {
    log "Deployment information:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Version: $DEPLOY_VERSION"
    echo "  Git Commit: ${GIT_COMMIT:0:7}"
    echo "  Health Check: $HEALTH_CHECK_URL"
    echo "  Docker Compose: $DOCKER_COMPOSE_FILE"
}

confirm_deployment() {
    if [[ "$FORCE" == "true" || "$DRY_RUN" == "true" ]]; then
        return
    fi
    
    echo
    warning "You are about to deploy to $ENVIRONMENT environment!"
    show_deployment_info
    echo
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Deployment cancelled"
        exit 0
    fi
}

# Main deployment flow
main() {
    log "Starting deployment to $ENVIRONMENT..."
    
    show_deployment_info
    confirm_deployment
    
    check_prerequisites
    build_images
    push_images
    deploy_environment
    wait_for_health
    post_deploy_actions
    
    success "Deployment to $ENVIRONMENT completed successfully!"
    log "Services are running and healthy at: $HEALTH_CHECK_URL"
}

# Execute main function
main "$@" 