#!/bin/bash

# Deployment Script for Panhandler
# Handles Helm-based deployment to Kubernetes environments (development, staging, production)

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

Deploy Panhandler to Kubernetes using Helm.

ENVIRONMENTS:
    development         Deploy to development namespace
    staging             Deploy to staging namespace  
    production          Deploy to production namespace
    local               Deploy to local Kubernetes cluster

OPTIONS:
    --skip-rebuild      Skip rebuilding images (use existing)
    --skip-update       Skip updating Helm dependencies
    --dry-run           Show what would be deployed without executing
    --force             Force deployment without confirmation
    --version VERSION   Deploy specific version
    --namespace NAME    Override default namespace
    --context NAME      Use specific kubectl context
    -h, --help          Show this help message

EXAMPLES:
    $0 development                      # Deploy to development namespace
    $0 production --version v1.2.3     # Deploy specific version to production
    $0 staging --dry-run               # Dry run for staging deployment
    $0 local --skip-rebuild            # Deploy to local without rebuilding images
    $0 production --force              # Force deploy to production (auto-rebuild)
EOF
}

# Default configuration
ENVIRONMENT=""
SKIP_REBUILD=false
DRY_RUN=false
FORCE=false
VERSION=""
NAMESPACE="panhandler"
KUBE_CONTEXT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        development|staging|production|local)
            ENVIRONMENT="$1"
            shift
            ;;
        --skip-rebuild)
            SKIP_REBUILD=true
            shift
            ;;
        --skip-update)
            SKIP_UPDATE=true
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
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --context)
            KUBE_CONTEXT="$2"
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
        HELM_VALUES_FILE="charts/panhandler/values-dev.yaml"
        REGISTRY_TAG="dev"
        DEFAULT_NAMESPACE="panhandler-dev"
        RELEASE_NAME="panhandler-dev"
        HEALTH_CHECK_URL="http://localhost:3001/health"
        SKIP_UPDATE=true
        ;;
    staging)
        HELM_VALUES_FILE="charts/panhandler/values-dev.yaml"  # Use dev values for staging
        REGISTRY_TAG="staging"
        DEFAULT_NAMESPACE="panhandler-staging"
        RELEASE_NAME="panhandler-staging"
        HEALTH_CHECK_URL="https://staging-api.panhandler.ai/health"
        SKIP_UPDATE=true
        ;;
    production)
        HELM_VALUES_FILE="charts/panhandler/values-prod.yaml"
        REGISTRY_TAG="latest"
        DEFAULT_NAMESPACE="panhandler-production"
        RELEASE_NAME="panhandler-prod"
        HEALTH_CHECK_URL="https://api.panhandler.ai/health"
        ;;
    local)
        HELM_VALUES_FILE="charts/panhandler/values-dev.yaml"
        REGISTRY_TAG="local"
        DEFAULT_NAMESPACE="panhandler-local"
        RELEASE_NAME="panhandler-local"
        HEALTH_CHECK_URL="http://localhost:3001/health"
        SKIP_UPDATE=true
        ;;
    *)
        error "Unknown environment: $ENVIRONMENT"
        ;;
esac

# Set namespace (use override if provided)
if [[ -z "$NAMESPACE" ]]; then
    NAMESPACE="$DEFAULT_NAMESPACE"
fi

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
    
    # Check Helm
    if ! command -v helm &> /dev/null; then
        error "Helm is not installed. Please install Helm 3.x"
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed"
    fi
    
    # Check Docker (needed for building)
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running"
    fi
    
    # Set kubectl context if provided
    if [[ -n "$KUBE_CONTEXT" ]]; then
        log "Setting kubectl context to $KUBE_CONTEXT..."
        kubectl config use-context "$KUBE_CONTEXT"
    fi
    
    # Test kubectl connectivity
    if ! kubectl cluster-info &> /dev/null; then
        error "Cannot connect to Kubernetes cluster. Check your kubectl configuration"
    fi
    
    # Check Helm chart
    if [[ ! -f "charts/panhandler/Chart.yaml" ]]; then
        error "Helm chart not found at charts/panhandler/Chart.yaml"
    fi
    
    # Check Helm values file
    if [[ ! -f "$HELM_VALUES_FILE" ]]; then
        error "Helm values file $HELM_VALUES_FILE not found"
    fi
    
    # Check if namespace exists, create if it doesn't
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "Creating namespace $NAMESPACE..."
        if [[ "$DRY_RUN" != "true" ]]; then
            kubectl create namespace "$NAMESPACE"
        fi
    fi
    
    success "Prerequisites check passed"
}

handle_image_rebuild() {
    if [[ "$SKIP_REBUILD" == "true" ]]; then
        log "Skipping image rebuild step"
        return
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would prompt for image rebuild and call: scripts/docker-build.sh --push --version $DEPLOY_VERSION all"
        return
    fi
    
    # Check if we should rebuild images
    local rebuild_choice
    if [[ "$FORCE" == "true" ]]; then
        rebuild_choice="y"
        log "Force mode: rebuilding images automatically"
    else
        echo
        log "Do you want to rebuild and push images before deployment?"
        log "This will run: scripts/docker-build.sh --push --version $DEPLOY_VERSION all"
        read -p "Rebuild images? (y/N): " -n 1 -r rebuild_choice
        echo
    fi
    
    if [[ $rebuild_choice =~ ^[Yy]$ ]]; then
        log "Rebuilding and pushing images..."
        scripts/docker-build.sh --push --version "$DEPLOY_VERSION" all
        success "Images rebuilt and pushed successfully"
    else
        log "Skipping image rebuild - using existing images"
        warning "Make sure the required images exist in the registry with tag: $DEPLOY_VERSION"
    fi
}

deploy_environment() {
  log "Deploying to $ENVIRONMENT environment (namespace: $NAMESPACE)..."
  
  # Prepare Helm command
  local helm_cmd="helm upgrade --install $RELEASE_NAME ./charts/panhandler"
  helm_cmd="$helm_cmd --namespace $NAMESPACE"
  helm_cmd="$helm_cmd --values $HELM_VALUES_FILE"
  helm_cmd="$helm_cmd --set agents.image.tag=$DEPLOY_VERSION"
  helm_cmd="$helm_cmd --set web.image.tag=$DEPLOY_VERSION"
  helm_cmd="$helm_cmd --set-string global.gitCommit=$GIT_COMMIT"
  helm_cmd="$helm_cmd --wait --timeout=10m"
  
  if [[ "$DRY_RUN" == "true" ]]; then
      log "Would run: $helm_cmd --dry-run"
      helm upgrade --install "$RELEASE_NAME" ./charts/panhandler \
          --namespace "$NAMESPACE" \
          --values "$HELM_VALUES_FILE" \
          --set agents.image.tag="$DEPLOY_VERSION" \
          --set web.image.tag="$DEPLOY_VERSION" \
          --set-string global.gitCommit="$GIT_COMMIT" \
          --dry-run --debug
      return
  fi
  
  # Update Helm dependencies
  if [[ "$SKIP_UPDATE" != "true" ]]; then
    log "Updating Helm dependencies..."
    helm dependency update ./charts/panhandler
  else
    log "Skipping Helm dependency update"
  fi
  
  # Deploy with Helm
  log "Running Helm deployment..."
  helm upgrade --install "$RELEASE_NAME" ./charts/panhandler \
      --namespace "$NAMESPACE" \
      --values "$HELM_VALUES_FILE" \
      --set agents.image.tag="$DEPLOY_VERSION" \
      --set web.image.tag="$DEPLOY_VERSION" \
      --set-string global.gitCommit="$GIT_COMMIT" \
      --wait --timeout=10m
  
  success "Deployment completed"
}

wait_for_health() {
    log "Waiting for pods to become ready..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would check pod readiness in namespace: $NAMESPACE"
        log "Would check health at: $HEALTH_CHECK_URL"
        return
    fi
    
    # Wait for pods to be ready
    log "Waiting for all pods to be ready..."
    if ! kubectl wait --for=condition=ready pod \
        --selector=app.kubernetes.io/instance="$RELEASE_NAME" \
        --namespace="$NAMESPACE" \
        --timeout=300s; then
        error "Pods failed to become ready within 5 minutes"
    fi
    
    # Check deployment status
    log "Checking deployment status..."
    kubectl get pods,services,ingress \
        --namespace="$NAMESPACE" \
        --selector=app.kubernetes.io/instance="$RELEASE_NAME"
    
    # Optional: Try health check endpoint if available
    if command -v curl &> /dev/null; then
        log "Attempting health check..."
        local max_attempts=6
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            if curl -sSf "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
                success "Health check passed at $HEALTH_CHECK_URL"
                break
            fi
            
            log "Health check attempt $attempt/$max_attempts failed, retrying in 10 seconds..."
            sleep 10
            ((attempt++))
        done
        
        if [[ $attempt -gt $max_attempts ]]; then
            warning "Health check failed, but pods are ready. Service may not be externally accessible yet."
        fi
    else
        log "curl not available, skipping HTTP health check"
    fi
    
    success "Services are ready"
}

post_deploy_actions() {
    log "Running post-deployment actions..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "Would run post-deployment actions"
        log "Would run database migrations if needed"
        return
    fi
    
    # Run database migrations if needed
    if [[ "$ENVIRONMENT" != "local" ]]; then
        log "Running database migrations..."
        # Run migrations using a Kubernetes job or by executing in a pod
        if kubectl get pod --namespace="$NAMESPACE" --selector=app.kubernetes.io/component=agents --field-selector=status.phase=Running -o name | head -1 | grep -q pod; then
            local agent_pod=$(kubectl get pod --namespace="$NAMESPACE" --selector=app.kubernetes.io/component=agents --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
            log "Running migrations in pod: $agent_pod"
            kubectl exec -n "$NAMESPACE" "$agent_pod" -- bun run migrate
        else
            warning "No running agent pods found, skipping database migrations"
        fi
    fi
    
    # Show Helm release status
    log "Checking Helm release status..."
    helm status "$RELEASE_NAME" --namespace="$NAMESPACE"
    
    success "Post-deployment actions completed"
}

show_deployment_info() {
    log "Deployment information:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Namespace: $NAMESPACE"
    echo "  Release Name: $RELEASE_NAME"
    echo "  Version: $DEPLOY_VERSION"
    echo "  Git Commit: ${GIT_COMMIT:0:7}"
    echo "  Helm Values: $HELM_VALUES_FILE"
    echo "  Health Check: $HEALTH_CHECK_URL"
    if [[ -n "$KUBE_CONTEXT" ]]; then
        echo "  Kubernetes Context: $KUBE_CONTEXT"
    fi
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
    handle_image_rebuild
    deploy_environment
    wait_for_health
    post_deploy_actions
    
    success "Helm deployment to $ENVIRONMENT ($NAMESPACE) completed successfully!"
    log "Services are running in namespace: $NAMESPACE"
    log "Release name: $RELEASE_NAME"
    log "Health check available at: $HEALTH_CHECK_URL"
}

# Execute main function
main "$@" 