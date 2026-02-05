#!/bin/bash

set -e

echo "=========================================="
echo "Nomad Federation Environment Deployment"
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

# Check if Vagrant is installed
if ! command -v vagrant &> /dev/null; then
    print_error "Vagrant is not installed. Please install Vagrant first."
    exit 1
fi

print_status "Vagrant is installed"

# Check if Parallels provider is available
if ! vagrant plugin list | grep -q "vagrant-parallels"; then
    print_warning "Vagrant Parallels plugin not found. Installing..."
    vagrant plugin install vagrant-parallels
fi

print_status "Vagrant Parallels plugin is available"

echo ""
echo "=========================================="
echo "Step 1: Destroying any existing VMs"
echo "=========================================="
echo ""

if vagrant status | grep -q "running\|saved\|poweroff"; then
    print_warning "Found existing VMs. Destroying them..."
    vagrant destroy -f
    print_status "Existing VMs destroyed"
else
    print_status "No existing VMs found"
fi

echo ""
echo "=========================================="
echo "Step 2: Provisioning 8 VMs"
echo "=========================================="
echo ""
echo "This will create:"
echo "  - 3 Nomad servers in EMEA region"
echo "  - 2 Nomad clients in EMEA region"
echo "  - 3 Nomad servers in USA region"
echo "  - 2 Nomad clients in USA region"
echo ""
print_warning "This may take 10-15 minutes..."
echo ""

vagrant up

if [ $? -eq 0 ]; then
    print_status "All VMs provisioned successfully"
else
    print_error "VM provisioning failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 3: Waiting for services to stabilize"
echo "=========================================="
echo ""
print_warning "Waiting 60 seconds for Consul and Nomad services to start..."
sleep 60

echo ""
echo "=========================================="
echo "Step 4: Verifying Federation"
echo "=========================================="
echo ""

# Run verification
./check-federation.sh

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
print_status "Environment is ready for use"
echo ""
echo "Access Points:"
echo "  EMEA Nomad UI:  http://192.168.56.71:4646/ui"
echo "  EMEA Consul UI: http://192.168.56.71:8500/ui"
echo "  USA Nomad UI:   http://192.168.56.81:4646/ui"
echo "  USA Consul UI:  http://192.168.56.81:8500/ui"
echo ""
echo "Quick Commands:"
echo "  Check status:     ./check-federation.sh"
echo "  SSH to EMEA:      vagrant ssh emea-server-1"
echo "  SSH to USA:       vagrant ssh usa-server-1"
echo "  Stop all VMs:     vagrant suspend"
echo "  Resume all VMs:   ./resume-environment.sh"
echo "  Destroy all VMs:  vagrant destroy -f"
echo ""

# Made with Bob
