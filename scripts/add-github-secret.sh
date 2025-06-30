#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [NAMESPACES...]

Create GitHub Container Registry authentication secret in Kubernetes namespaces.

OPTIONS:
    -h, --help          Show this help message
    -s, --secret-name   Secret name (default: ghcr-auth)
    -u, --username      GitHub username (interactive if not provided)
    -t, --token         GitHub Personal Access Token (interactive if not provided)
    --all-panhandler    Create in all panhandler namespaces (dev, staging, prod)

NAMESPACES:
    Space-separated list of namespaces to create the secret in.
    If no namespaces are provided, creates in current namespace.

EXAMPLES:
    $0                                    # Create in current namespace
    $0 panhandler-dev panhandler-staging  # Create in specific namespaces
    $0 --all-panhandler                   # Create in all panhandler environments
    $0 -u myuser -t ghp_token default     # Non-interactive with credentials
EOF
}

# Default configuration
SECRET_NAME="ghcr-auth"
USERNAME=""
TOKEN=""
NAMESPACES=()
ALL_PANHANDLER=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -s|--secret-name)
            SECRET_NAME="$2"
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
        --all-panhandler)
            ALL_PANHANDLER=true
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            NAMESPACES+=("$1")
            shift
            ;;
    esac
done

# Set default namespaces
if [[ "$ALL_PANHANDLER" == "true" ]]; then
    NAMESPACES=("panhandler-dev" "panhandler-staging" "panhandler-production")
elif [[ ${#NAMESPACES[@]} -eq 0 ]]; then
    # Use current namespace if no namespaces specified
    CURRENT_NS=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    NAMESPACES=("${CURRENT_NS:-default}")
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_status "Setting up GitHub Container Registry authentication secret: $SECRET_NAME"
print_status "Target namespaces: ${NAMESPACES[*]}"

# Get username - from argument or interactive
if [[ -z "$USERNAME" ]]; then
    while true; do
        read -p "Enter your GitHub username: " USERNAME
        if [[ -n "$USERNAME" ]]; then
            break
        else
            print_warning "Username cannot be empty"
        fi
    done
fi

# Get token - from argument, GitHub CLI, or interactive
if [[ -z "$TOKEN" ]]; then
    if command -v gh &> /dev/null; then
        print_status "Using GitHub CLI to get PAT"
        TOKEN=$(gh auth token 2>/dev/null || true)
    else
        print_warning "GitHub CLI is not installed"
    fi
    
    if [[ -z "$TOKEN" ]]; then
        while true; do
            read -s -p "Enter your GitHub Personal Access Token: " TOKEN
            echo
            if [[ -n "$TOKEN" ]]; then
                break
            else
                print_warning "Personal Access Token cannot be empty"
            fi
        done
    fi
fi

# Function to create secret in a namespace
create_secret_in_namespace() {
    local namespace="$1"
    
    print_status "Processing namespace: $namespace"
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        print_status "Creating namespace: $namespace"
        kubectl create namespace "$namespace"
    fi
    
    # Check if secret already exists in this namespace
    if kubectl get secret "$SECRET_NAME" -n "$namespace" &> /dev/null; then
        print_warning "Secret '$SECRET_NAME' already exists in namespace '$namespace'"
        read -p "Do you want to replace it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting existing secret in namespace '$namespace'..."
            kubectl delete secret "$SECRET_NAME" -n "$namespace"
        else
            print_status "Skipping namespace '$namespace'"
            return 0
        fi
    fi
    
    # Create the secret in this namespace
    print_status "Creating secret '$SECRET_NAME' in namespace '$namespace'..."
    if kubectl create secret docker-registry "$SECRET_NAME" \
        --docker-server=ghcr.io \
        --docker-username="$USERNAME" \
        --docker-password="$TOKEN" \
        -n "$namespace"; then
        print_status "Secret created successfully in namespace '$namespace'"
        
        # Verify the secret was created
        if kubectl get secret "$SECRET_NAME" -n "$namespace" &> /dev/null; then
            print_status "Secret verification successful for namespace '$namespace'"
            return 0
        else
            print_error "Secret was not created properly in namespace '$namespace'"
            return 1
        fi
    else
        print_error "Failed to create secret in namespace '$namespace'"
        return 1
    fi
}

# Create secrets in all specified namespaces
failed_namespaces=()
successful_namespaces=()

for namespace in "${NAMESPACES[@]}"; do
    if create_secret_in_namespace "$namespace"; then
        successful_namespaces+=("$namespace")
    else
        failed_namespaces+=("$namespace")
    fi
done

# Summary
echo
print_status "Summary:"
if [[ ${#successful_namespaces[@]} -gt 0 ]]; then
    print_status "Successfully created secret '$SECRET_NAME' in namespaces: ${successful_namespaces[*]}"
fi

if [[ ${#failed_namespaces[@]} -gt 0 ]]; then
    print_error "Failed to create secret in namespaces: ${failed_namespaces[*]}"
    exit 1
fi

print_status "You can now use this secret in your deployments by adding:"
echo "  imagePullSecrets:"
echo "  - name: $SECRET_NAME"