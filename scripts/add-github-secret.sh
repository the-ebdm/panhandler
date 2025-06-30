#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

print_status "Setting up GitHub Container Registry authentication secret"

# Ask user for username with validation
while true; do
    read -p "Enter your GitHub username: " username
    if [[ -n "$username" ]]; then
        break
    else
        print_warning "Username cannot be empty"
    fi
done

# Ask user for PAT with validation
if command -v gh &> /dev/null; then
    print_status "Using GitHub CLI to get PAT"
    pat=$(gh auth token)
else
    print_warning "GitHub CLI is not installed"
fi

if [[ -z "$pat" ]]; then
while true; do
    read -s -p "Enter your GitHub Personal Access Token: " pat
    echo
    if [[ -n "$pat" ]]; then
        break
    else
        print_warning "Personal Access Token cannot be empty"
    fi
    done
fi

# Check if secret already exists
if kubectl get secret ghcr-auth &> /dev/null; then
    print_warning "Secret 'ghcr-auth' already exists"
    read -p "Do you want to replace it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting existing secret..."
        kubectl delete secret ghcr-auth
    else
        print_status "Operation cancelled"
        exit 0
    fi
fi

# Create the secret
print_status "Creating secret 'ghcr-auth'..."
if kubectl create secret docker-registry ghcr-auth \
    --docker-server=ghcr.io \
    --docker-username="$username" \
    --docker-password="$pat"; then
    print_status "Secret created successfully"
    
    # Verify the secret was created
    if kubectl get secret ghcr-auth &> /dev/null; then
        print_status "Secret verification successful"
    else
        print_error "Secret was not created properly"
        exit 1
    fi
else
    print_error "Failed to create secret"
    exit 1
fi

print_status "You can now use this secret in your deployments by adding:"
echo "  imagePullSecrets:"
echo "  - name: ghcr-auth"