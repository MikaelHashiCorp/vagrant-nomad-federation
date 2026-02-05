#!/bin/bash

set -e

echo "=========================================="
echo "Stopping Nomad Federation Environment"
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
echo "Suspending all VMs"
echo "=========================================="
echo ""
print_warning "This will save the current state of all VMs..."
echo ""

vagrant suspend

if [ $? -eq 0 ]; then
    print_status "All VMs suspended successfully"
else
    print_error "Failed to suspend VMs"
    exit 1
fi

echo ""
echo "=========================================="
echo "Environment Stopped"
echo "=========================================="
echo ""
print_status "All VMs are suspended and can be resumed later"
echo ""
echo "To resume the environment, run:"
echo "  ./resume-environment.sh"
echo ""
echo "To completely destroy the environment, run:"
echo "  vagrant destroy -f"
echo ""

# Made with Bob
