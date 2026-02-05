#!/bin/bash

set -e

echo "=========================================="
echo "Resuming Nomad Federation Environment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check current status
echo "Checking VM status..."
vagrant status

echo ""
echo "=========================================="
echo "Resuming all VMs"
echo "=========================================="
echo ""

vagrant resume

if [ $? -eq 0 ]; then
    print_status "All VMs resumed successfully"
else
    print_error "Failed to resume VMs"
    exit 1
fi

echo ""
echo "=========================================="
echo "Waiting for services to stabilize"
echo "=========================================="
echo ""
print_warning "Waiting 180 seconds for Consul and Nomad services to fully start..."
echo "This ensures all nodes can discover each other and form quorum."
sleep 180

echo ""
echo "=========================================="
echo "Verifying Federation"
echo "=========================================="
echo ""

# Run verification
./check-federation.sh

echo ""
echo "=========================================="
echo "Environment Resumed!"
echo "=========================================="
echo ""
print_status "All services are running"
echo ""
echo "Access Points:"
echo "  EMEA Nomad UI:  http://192.168.56.71:4646/ui"
echo "  EMEA Consul UI: http://192.168.56.71:8500/ui"
echo "  USA Nomad UI:   http://192.168.56.81:4646/ui"
echo "  USA Consul UI:  http://192.168.56.81:8500/ui"
echo ""

# Made with Bob
