#!/bin/bash

# Container Registry Authentication Script for Panhandler
# Manages authentication and configuration for container registries

set -euo pipefail

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
Usage: $0 [COMMAND] [OPTIONS]

Manage container registry authentication for Panhandler.

COMMANDS:
    login               Login to container registry
    logout              Logout from container registry
    status              Check authentication status
    config              Configure registry settings
    test                Test registry connectivity

OPTIONS:
    -r, --registry      Registry URL (default: docker.io)
    -u, --username      Username for authentication
    -t, --token         Authentication token/password
    -f, --file          Credentials file path
    -h, --help          Show this help message

EXAMPLES:
    $0 login                            # Interactive login to Docker Hub
    $0 login -u myuser -t mytoken      # Login with credentials
    $0 status                          # Check current auth status
    $0 config -r registry.example.com  # Configure custom registry
EOF
}

# Default configuration
REGISTRY="docker.io"
USERNAME=""
TOKEN=""
CREDENTIALS_FILE=""

# Parse command line arguments
COMMAND=""

while [[ $# -gt 0 ]]; do
    case $1 in
        login|logout|status|config|test)
            COMMAND="$1"
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -t|--token)
            TOKEN="$2"
            shift 2
            ;;
        -f|--file)
            CREDENTIALS_FILE="$2"
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

# Validate prerequisites
check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! docker info &> /dev/null; then
        error "Docker daemon is not running or not accessible"
    fi
}

# Login to registry
login_registry() {
    log "Logging into registry: $REGISTRY"
    
    if [[ -n "$CREDENTIALS_FILE" ]] && [[ -f "$CREDENTIALS_FILE" ]]; then
        log "Using credentials from file: $CREDENTIALS_FILE"
        source "$CREDENTIALS_FILE"
    fi
    
    if [[ -n "$USERNAME" ]] && [[ -n "$TOKEN" ]]; then
        # Non-interactive login
        echo "$TOKEN" | docker login "$REGISTRY" --username "$USERNAME" --password-stdin
    else
        # Interactive login
        docker login "$REGISTRY"
    fi
    
    success "Successfully logged into $REGISTRY"
}

# Logout from registry
logout_registry() {
    log "Logging out from registry: $REGISTRY"
    docker logout "$REGISTRY"
    success "Successfully logged out from $REGISTRY"
}

# Check authentication status
check_status() {
    log "Checking authentication status for $REGISTRY..."
    
    # Check Docker config for auth
    local config_file="$HOME/.docker/config.json"
    
    if [[ ! -f "$config_file" ]]; then
        warning "No Docker configuration found"
        return 1
    fi
    
    if command -v jq &> /dev/null; then
        local auth_info=$(cat "$config_file" | jq -r ".auths[\"$REGISTRY\"] // empty")
        if [[ -n "$auth_info" ]]; then
            success "Authenticated to $REGISTRY"
            
            # Try to get username from auth
            local auth_data=$(echo "$auth_info" | jq -r '.auth // empty')
            if [[ -n "$auth_data" ]]; then
                local username=$(echo "$auth_data" | base64 -d | cut -d: -f1)
                log "Username: $username"
            fi
        else
            warning "Not authenticated to $REGISTRY"
        fi
    else
        # Fallback without jq
        if grep -q "\"$REGISTRY\"" "$config_file"; then
            success "Authenticated to $REGISTRY"
        else
            warning "Not authenticated to $REGISTRY"
        fi
    fi
}

# Configure registry settings
configure_registry() {
    log "Configuring registry settings..."
    
    # Create or update configuration file
    local config_dir=".dockerhub"
    local config_file="$config_dir/registry.env"
    
    mkdir -p "$config_dir"
    
    cat > "$config_file" << EOF
# Container Registry Configuration
# Generated on $(date)

REGISTRY="$REGISTRY"
NAMESPACE="panhandler"

# Build configuration
DEFAULT_PLATFORM="linux/amd64"
BUILD_CACHE=true

# Security settings
VULNERABILITY_SCANNING=true
SCAN_ON_PUSH=true

# Retention policy
KEEP_VERSIONS=10
KEEP_DAYS=90
EOF
    
    success "Registry configuration saved to $config_file"
    log "Edit this file to customize settings"
}

# Test registry connectivity
test_registry() {
    log "Testing connectivity to $REGISTRY..."
    
    # Test basic connectivity
    if ! curl -sSf "https://$REGISTRY" > /dev/null 2>&1; then
        error "Cannot connect to registry: $REGISTRY"
    fi
    
    success "Registry is accessible"
    
    # Test authentication if logged in
    check_status
    
    # Try to pull a small public image to test
    log "Testing registry functionality..."
    if docker pull hello-world:latest > /dev/null 2>&1; then
        success "Registry functionality test passed"
        docker rmi hello-world:latest > /dev/null 2>&1 || true
    else
        warning "Registry functionality test failed"
    fi
}

# Main execution
main() {
    check_prerequisites
    
    case "$COMMAND" in
        login)
            login_registry
            ;;
        logout)
            logout_registry
            ;;
        status)
            check_status
            ;;
        config)
            configure_registry
            ;;
        test)
            test_registry
            ;;
        "")
            error "No command specified. Use --help for usage information."
            ;;
        *)
            error "Unknown command: $COMMAND"
            ;;
    esac
}

# Run main function
main 