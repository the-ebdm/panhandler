#!/bin/bash

# Docker Build and Push Script for Panhandler
# Builds and optionally pushes images to container registry

set -euo pipefail

# Configuration
REGISTRY="docker.io"
NAMESPACE="panhandler"
VERSION=${VERSION:-$(cat package.json | grep version | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')}
GIT_COMMIT=${GIT_COMMIT:-$(git rev-parse HEAD)}
GIT_SHORT_COMMIT=${GIT_COMMIT:0:7}
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

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
Usage: $0 [OPTIONS] [SERVICE]

Build and push Docker images for Panhandler services.

OPTIONS:
    -h, --help          Show this help message
    -p, --push          Push images to registry after building
    -l, --latest        Tag as latest (default: false)
    -v, --version       Version tag (default: from package.json)
    -r, --registry      Registry URL (default: docker.io)
    -n, --namespace     Registry namespace (default: panhandler)
    --no-cache          Build without cache
    --platform          Target platform (default: linux/amd64)

SERVICES:
    agents              Build agents service image
    web                 Build web interface image
    all                 Build all images (default)

EXAMPLES:
    $0 agents                           # Build agents image only
    $0 --push --latest all             # Build and push all images with latest tag
    $0 -p -v 1.0.0 web                # Build and push web image with version 1.0.0
EOF
}

# Parse command line arguments
PUSH_IMAGES=false
TAG_LATEST=false
NO_CACHE=""
PLATFORM="linux/amd64"
SERVICE="all"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--push)
            PUSH_IMAGES=true
            shift
            ;;
        -l|--latest)
            TAG_LATEST=true
            shift
            ;;
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE="--no-cache"
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        agents|web|all)
            SERVICE="$1"
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running or not accessible"
    fi
    
    if [[ "$PUSH_IMAGES" == "true" ]] && ! docker info | grep -q "Username"; then
        warning "Not logged into Docker registry. Run 'docker login' first."
    fi
    
    success "Prerequisites check passed"
}

# Build a single image
build_image() {
    local service=$1
    local dockerfile=$2
    local image_name="${REGISTRY}/${NAMESPACE}/${service}"
    
    log "Building ${service} image..."
    
    # Create tags
    local tags=()
    tags+=("${image_name}:${GIT_SHORT_COMMIT}")
    tags+=("${image_name}:${VERSION}")
    
    if [[ "$TAG_LATEST" == "true" ]]; then
        tags+=("${image_name}:latest")
    fi
    
    # Build tag arguments
    local tag_args=""
    for tag in "${tags[@]}"; do
        tag_args="$tag_args -t $tag"
    done
    
    # Build the image
    local build_cmd="docker build $NO_CACHE $tag_args"
    build_cmd="$build_cmd --platform $PLATFORM"
    build_cmd="$build_cmd --build-arg BUILD_DATE=$BUILD_DATE"
    build_cmd="$build_cmd --build-arg VERSION=$VERSION"
    build_cmd="$build_cmd --build-arg GIT_COMMIT=$GIT_COMMIT"
    build_cmd="$build_cmd -f $dockerfile ."
    
    log "Running: $build_cmd"
    eval $build_cmd
    
    success "Built ${service} image with tags: ${tags[*]}"
    
    # Push images if requested
    if [[ "$PUSH_IMAGES" == "true" ]]; then
        for tag in "${tags[@]}"; do
            log "Pushing $tag..."
            docker push "$tag"
            success "Pushed $tag"
        done
    fi
}

# Main execution
main() {
    log "Starting Docker build process..."
    log "Version: $VERSION"
    log "Git Commit: $GIT_COMMIT"
    log "Registry: $REGISTRY"
    log "Namespace: $NAMESPACE"
    log "Platform: $PLATFORM"
    
    check_prerequisites
    
    case $SERVICE in
        agents)
            build_image "agents" "Dockerfile"
            ;;
        web)
            build_image "web" "Dockerfile.web"
            ;;
        all)
            build_image "agents" "Dockerfile"
            build_image "web" "Dockerfile.web"
            ;;
        *)
            error "Unknown service: $SERVICE"
            ;;
    esac
    
    success "Docker build process completed!"
    
    if [[ "$PUSH_IMAGES" == "false" ]]; then
        log "Images built locally. Use --push to push to registry."
    fi
}

# Run main function
main "$@" 