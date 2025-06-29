#!/bin/bash

# Deployment Status Check Script for Panhandler
# Checks the status and health of deployed services

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
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [ENVIRONMENT] [OPTIONS]

Check deployment status and health for Panhandler services.

ENVIRONMENTS:
    development         Check development environment
    staging             Check staging environment
    production          Check production environment
    local               Check local deployment
    all                 Check all environments

OPTIONS:
    --detailed          Show detailed service information
    --health-only       Only perform health checks
    --json              Output in JSON format
    -h, --help          Show this help message

EXAMPLES:
    $0 development              # Check development deployment
    $0 all --detailed          # Detailed check of all environments
    $0 production --health-only # Only health check for production
EOF
}

# Configuration
ENVIRONMENT=""
DETAILED=false
HEALTH_ONLY=false
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        development|staging|production|local|all)
            ENVIRONMENT="$1"
            shift
            ;;
        --detailed)
            DETAILED=true
            shift
            ;;
        --health-only)
            HEALTH_ONLY=true
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
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

# Default to checking all environments
if [[ -z "$ENVIRONMENT" ]]; then
    ENVIRONMENT="all"
fi

# Environment configuration
get_env_config() {
    local env=$1
    
    case "$env" in
        development)
            echo "docker-compose.yml|http://localhost:3001|dev"
            ;;
        staging)
            echo "docker-compose.staging.yml|https://staging-api.panhandler.ai|staging"
            ;;
        production)
            echo "docker-compose.prod.yml|https://api.panhandler.ai|production"
            ;;
        local)
            echo "docker-compose.yml|http://localhost:3001|local"
            ;;
        *)
            error "Unknown environment: $env"
            ;;
    esac
}

# Check if Docker Compose services are running
check_docker_services() {
    local env=$1
    local compose_file=$2
    
    if [[ ! -f "$compose_file" ]]; then
        warning "Docker Compose file $compose_file not found"
        return 1
    fi
    
    log "Checking Docker services for $env..."
    
    # Get running services
    local running_services
    if running_services=$(docker-compose -f "$compose_file" ps --services --filter "status=running" 2>/dev/null); then
        if [[ -n "$running_services" ]]; then
            success "Services running: $(echo "$running_services" | tr '\n' ' ')"
            
            if [[ "$DETAILED" == "true" ]]; then
                docker-compose -f "$compose_file" ps
            fi
            
            return 0
        else
            warning "No services running"
            return 1
        fi
    else
        warning "Could not check Docker services"
        return 1
    fi
}

# Health check function
check_health() {
    local env=$1
    local health_url=$2
    
    log "Checking health endpoint for $env: $health_url"
    
    local response
    local status_code
    
    if response=$(curl -sSL -w "HTTPSTATUS:%{http_code}" "$health_url" 2>/dev/null); then
        status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        body=$(echo "$response" | sed -E 's/HTTPSTATUS\:[0-9]+$//')
        
        if [[ "$status_code" == "200" ]]; then
            success "Health check passed (HTTP $status_code)"
            
            if [[ "$DETAILED" == "true" ]]; then
                echo "Response: $body"
            fi
            
            return 0
        else
            warning "Health check failed (HTTP $status_code)"
            return 1
        fi
    else
        warning "Health endpoint unreachable"
        return 1
    fi
}

# Check container resource usage
check_resources() {
    local env=$1
    local compose_file=$2
    
    if [[ "$DETAILED" != "true" ]]; then
        return
    fi
    
    log "Checking resource usage for $env..."
    
    # Get container stats
    local containers
    if containers=$(docker-compose -f "$compose_file" ps -q 2>/dev/null); then
        if [[ -n "$containers" ]]; then
            docker stats --no-stream $containers
        fi
    fi
}

# Check logs for errors
check_logs() {
    local env=$1
    local compose_file=$2
    
    if [[ "$DETAILED" != "true" ]]; then
        return
    fi
    
    log "Checking recent logs for errors in $env..."
    
    # Check last 50 lines for ERROR or FATAL
    local error_logs
    if error_logs=$(docker-compose -f "$compose_file" logs --tail=50 2>/dev/null | grep -i "error\|fatal" | head -5); then
        if [[ -n "$error_logs" ]]; then
            warning "Recent errors found:"
            echo "$error_logs"
        else
            success "No recent errors in logs"
        fi
    fi
}

# Single environment check
check_environment() {
    local env=$1
    
    log "Checking $env environment..."
    
    # Get configuration
    local config
    config=$(get_env_config "$env")
    
    local compose_file
    local health_url
    local tag
    
    IFS='|' read -r compose_file health_url tag <<< "$config"
    
    local services_ok=false
    local health_ok=false
    
    # Check Docker services
    if [[ "$HEALTH_ONLY" != "true" ]]; then
        if check_docker_services "$env" "$compose_file"; then
            services_ok=true
        fi
        
        check_resources "$env" "$compose_file"
        check_logs "$env" "$compose_file"
    fi
    
    # Check health endpoint
    if check_health "$env" "$health_url"; then
        health_ok=true
    fi
    
    # Overall status
    if [[ "$HEALTH_ONLY" == "true" ]]; then
        if [[ "$health_ok" == "true" ]]; then
            success "$env environment is healthy"
            return 0
        else
            warning "$env environment is unhealthy"
            return 1
        fi
    else
        if [[ "$services_ok" == "true" && "$health_ok" == "true" ]]; then
            success "$env environment is fully operational"
            return 0
        elif [[ "$services_ok" == "true" ]]; then
            warning "$env environment has services running but health check failed"
            return 1
        elif [[ "$health_ok" == "true" ]]; then
            warning "$env environment is healthy but services status unclear"
            return 1
        else
            error "$env environment is not operational"
            return 1
        fi
    fi
}

# JSON output format
output_json() {
    local env=$1
    local status=$2
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat << EOF
{
  "environment": "$env",
  "status": "$status",
  "timestamp": "$timestamp",
  "checked_by": "deploy-check.sh"
}
EOF
}

# Main execution
main() {
    if [[ "$ENVIRONMENT" == "all" ]]; then
        log "Checking all environments..."
        
        local overall_status=0
        
        for env in development staging production; do
            echo
            if check_environment "$env"; then
                if [[ "$JSON_OUTPUT" == "true" ]]; then
                    output_json "$env" "healthy"
                fi
            else
                overall_status=1
                if [[ "$JSON_OUTPUT" == "true" ]]; then
                    output_json "$env" "unhealthy"
                fi
            fi
        done
        
        echo
        if [[ $overall_status -eq 0 ]]; then
            success "All environments are operational"
        else
            warning "Some environments have issues"
        fi
        
        exit $overall_status
    else
        if check_environment "$ENVIRONMENT"; then
            if [[ "$JSON_OUTPUT" == "true" ]]; then
                output_json "$ENVIRONMENT" "healthy"
            fi
            exit 0
        else
            if [[ "$JSON_OUTPUT" == "true" ]]; then
                output_json "$ENVIRONMENT" "unhealthy"
            fi
            exit 1
        fi
    fi
}

# Run main function
main "$@" 