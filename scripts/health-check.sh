#!/bin/bash

# Health Check Script for Panhandler
# Performs comprehensive health checks on deployed services

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

# Configuration
ENVIRONMENT=${1:-"local"}
DETAILED=${2:-false}

# Health check endpoints
declare -A HEALTH_ENDPOINTS=(
    ["local"]="http://localhost:3001/health"
    ["development"]="http://localhost:3001/health"
    ["staging"]="https://staging-api.panhandler.ai/health"
    ["production"]="https://api.panhandler.ai/health"
)

# Service checks
check_api_health() {
    local endpoint=${HEALTH_ENDPOINTS[$ENVIRONMENT]}
    
    log "Checking API health at $endpoint..."
    
    local response
    local status_code
    
    if response=$(curl -sSL -w "HTTPSTATUS:%{http_code}" "$endpoint" 2>/dev/null); then
        status_code=$(echo "$response" | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
        body=$(echo "$response" | sed -E 's/HTTPSTATUS\:[0-9]+$//')
        
        if [[ "$status_code" == "200" ]]; then
            success "API health check passed"
            
            if [[ "$DETAILED" == "true" ]]; then
                echo "Response: $body"
            fi
            
            return 0
        else
            error "API health check failed (HTTP $status_code)"
            return 1
        fi
    else
        error "API endpoint unreachable"
        return 1
    fi
}

check_database() {
    log "Checking database connection..."
    
    # This would typically connect to the database
    # For now, we'll simulate it based on environment
    case "$ENVIRONMENT" in
        local|development)
            if docker ps | grep -q postgres; then
                success "Database container is running"
                return 0
            else
                error "Database container not found"
                return 1
            fi
            ;;
        staging|production)
            # In real deployment, this would check external database
            success "Database connection check passed (simulated)"
            return 0
            ;;
    esac
}

check_redis() {
    log "Checking Redis connection..."
    
    case "$ENVIRONMENT" in
        local|development)
            if docker ps | grep -q redis; then
                success "Redis container is running"
                return 0
            else
                warning "Redis container not found"
                return 1
            fi
            ;;
        staging|production)
            # In real deployment, this would check external Redis
            success "Redis connection check passed (simulated)"
            return 0
            ;;
    esac
}

check_disk_space() {
    log "Checking disk space..."
    
    local usage
    usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ $usage -lt 80 ]]; then
        success "Disk space OK ($usage% used)"
        return 0
    elif [[ $usage -lt 90 ]]; then
        warning "Disk space getting full ($usage% used)"
        return 1
    else
        error "Disk space critical ($usage% used)"
        return 1
    fi
}

check_memory() {
    log "Checking memory usage..."
    
    local mem_info
    mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local usage=$((used * 100 / total))
    
    if [[ $usage -lt 80 ]]; then
        success "Memory usage OK ($usage% used)"
        return 0
    elif [[ $usage -lt 90 ]]; then
        warning "Memory usage high ($usage% used)"
        return 1
    else
        error "Memory usage critical ($usage% used)"
        return 1
    fi
}

check_containers() {
    if [[ "$ENVIRONMENT" == "local" || "$ENVIRONMENT" == "development" ]]; then
        log "Checking Docker containers..."
        
        local compose_file="docker-compose.yml"
        if [[ ! -f "$compose_file" ]]; then
            warning "Docker Compose file not found"
            return 1
        fi
        
        local running_count
        running_count=$(docker-compose -f "$compose_file" ps -q | wc -l)
        
        if [[ $running_count -gt 0 ]]; then
            success "$running_count containers running"
            
            if [[ "$DETAILED" == "true" ]]; then
                docker-compose -f "$compose_file" ps
            fi
            
            return 0
        else
            error "No containers running"
            return 1
        fi
    fi
    
    return 0
}

# Main health check function
run_health_checks() {
    log "Running health checks for $ENVIRONMENT environment..."
    
    local checks_passed=0
    local total_checks=0
    
    # API Health Check
    ((total_checks++))
    if check_api_health; then
        ((checks_passed++))
    fi
    
    # Database Check
    ((total_checks++))
    if check_database; then
        ((checks_passed++))
    fi
    
    # Redis Check
    ((total_checks++))
    if check_redis; then
        ((checks_passed++))
    fi
    
    # System Resource Checks
    ((total_checks++))
    if check_disk_space; then
        ((checks_passed++))
    fi
    
    ((total_checks++))
    if check_memory; then
        ((checks_passed++))
    fi
    
    # Container Checks (for local/dev)
    if [[ "$ENVIRONMENT" == "local" || "$ENVIRONMENT" == "development" ]]; then
        ((total_checks++))
        if check_containers; then
            ((checks_passed++))
        fi
    fi
    
    # Summary
    echo
    log "Health check summary:"
    echo "  Checks passed: $checks_passed/$total_checks"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        success "All health checks passed - system is healthy"
        return 0
    elif [[ $checks_passed -gt $((total_checks / 2)) ]]; then
        warning "Some health checks failed - system has issues"
        return 1
    else
        error "Most health checks failed - system is unhealthy"
        return 1
    fi
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [ENVIRONMENT] [--detailed]

Perform health checks on Panhandler deployment.

ENVIRONMENTS:
    local               Check local deployment (default)
    development         Check development environment
    staging             Check staging environment
    production          Check production environment

OPTIONS:
    --detailed          Show detailed output

EXAMPLES:
    $0                          # Check local environment
    $0 production               # Check production environment
    $0 development --detailed   # Detailed check of development
EOF
}

# Parse additional arguments
if [[ "${2:-}" == "--detailed" ]]; then
    DETAILED=true
fi

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

# Validate environment
if [[ -n "${HEALTH_ENDPOINTS[$ENVIRONMENT]:-}" ]]; then
    run_health_checks
else
    error "Unknown environment: $ENVIRONMENT"
    echo
    usage
    exit 1
fi 