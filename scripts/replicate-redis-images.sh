#!/bin/bash

# Replicate Redis Images Script
# Pulls official Bitnami images and pushes them to GHCR

set -euo pipefail

# Configuration
GHCR_REGISTRY="ghcr.io/the-ebdm"
BITNAMI_REGISTRY="docker.io/bitnami"

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

# Redis images that need to be replicated based on the error message
REDIS_IMAGES=(
    "redis:8.0.2-debian-12-r4"
    "redis-sentinel:8.0.2-debian-12-r2"
    "redis-exporter:1.74.0-debian-12-r1"
    "os-shell:12-debian-12-r47"
    "kubectl:1.33.2-debian-12-r0"
)

# Function to pull and push an image
replicate_image() {
    local image=$1
    local source_image="${BITNAMI_REGISTRY}/${image}"
    local target_image="${GHCR_REGISTRY}/bitnami/${image}"
    
    log "Replicating ${image}..."
    
    # Pull from Bitnami
    log "Pulling ${source_image}..."
    docker pull "${source_image}"
    
    # Tag for GHCR
    log "Tagging as ${target_image}..."
    docker tag "${source_image}" "${target_image}"
    
    # Push to GHCR
    log "Pushing ${target_image}..."
    docker push "${target_image}"
    
    success "Successfully replicated ${image}"
}

# Main execution
main() {
    log "Starting Redis image replication to GHCR..."
    
    # Check prerequisites
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running or not accessible"
    fi
    
    # Check if logged into GHCR
    log "Checking GHCR authentication..."
    if ! docker info | grep -q "ghcr.io"; then
        warning "Make sure you're logged into GHCR: docker login ghcr.io"
        log "Attempting to login..."
        docker login ghcr.io
    fi
    
    # Replicate each image
    for image in "${REDIS_IMAGES[@]}"; do
        replicate_image "$image"
    done
    
    success "All Redis images have been replicated to GHCR!"
    log "Images are now available at: ${GHCR_REGISTRY}/bitnami/*"
    
    # Show replicated images
    log "Replicated images:"
    for image in "${REDIS_IMAGES[@]}"; do
        echo "  - ${GHCR_REGISTRY}/bitnami/${image}"
    done
}

# Execute main function
main "$@" 