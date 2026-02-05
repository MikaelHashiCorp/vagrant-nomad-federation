#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Nomad Federation Deployment & Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

# Step 1: Check prerequisites
print_step "Step 1: Checking prerequisites..."

if ! command -v vagrant &> /dev/null; then
    print_error "Vagrant is not installed"
    exit 1
fi
print_status "Vagrant is installed"

if ! vagrant plugin list | grep -q vagrant-parallels; then
    print_error "vagrant-parallels plugin is not installed"
    echo "Run: vagrant plugin install vagrant-parallels"
    exit 1
fi
print_status "vagrant-parallels plugin is installed"

# Check for license files
if [ ! -f "lic/nomad.hclic" ]; then
    print_error "Nomad license file not found at lic/nomad.hclic"
    print_info "Creating placeholder - you must add your license content"
    mkdir -p lic
    touch lic/nomad.hclic
fi

if [ ! -f "lic/consul.hclic" ]; then
    print_error "Consul license file not found at lic/consul.hclic"
    print_info "Creating placeholder - you must add your license content"
    mkdir -p lic
    touch lic/consul.hclic
fi

echo ""

# Step 2: Provision VMs
print_step "Step 2: Provisioning 8 VMs (this will take 15-30 minutes)..."
print_info "Starting vagrant up..."

if vagrant up; then
    print_status "All VMs provisioned successfully"
else
    print_error "VM provisioning failed"
    print_info "Check logs with: vagrant status"
    exit 1
fi

echo ""

# Step 3: Wait for services to stabilize
print_step "Step 3: Waiting for services to stabilize (60 seconds)..."
sleep 60
print_status "Services should be ready"

echo ""

# Step 4: Verify Consul Federation
print_step "Step 4: Verifying Consul WAN Federation..."

print_info "Checking Consul members across datacenters..."
CONSUL_WAN_OUTPUT=$(vagrant ssh emea-server-1 -c "consul members -wan" 2>/dev/null || echo "FAILED")

if echo "$CONSUL_WAN_OUTPUT" | grep -q "emea-server-1" && echo "$CONSUL_WAN_OUTPUT" | grep -q "usa-server-1"; then
    print_status "Consul WAN federation is working"
    echo "$CONSUL_WAN_OUTPUT" | grep -E "emea-server|usa-server"
else
    print_error "Consul WAN federation verification failed"
    echo "$CONSUL_WAN_OUTPUT"
fi

echo ""

# Step 5: Verify Nomad Federation
print_step "Step 5: Verifying Nomad Server Federation..."

print_info "Checking Nomad server members across regions..."
NOMAD_SERVERS_OUTPUT=$(vagrant ssh emea-server-1 -c "nomad server members" 2>/dev/null || echo "FAILED")

if echo "$NOMAD_SERVERS_OUTPUT" | grep -q "emea-server-1" && echo "$NOMAD_SERVERS_OUTPUT" | grep -q "usa-server-1"; then
    print_status "Nomad federation is working"
    echo "$NOMAD_SERVERS_OUTPUT" | grep -E "emea-server|usa-server"
else
    print_error "Nomad federation verification failed"
    echo "$NOMAD_SERVERS_OUTPUT"
fi

echo ""

# Step 6: Verify Nomad Clients
print_step "Step 6: Verifying Nomad Clients..."

print_info "Checking Nomad client nodes..."
NOMAD_NODES_OUTPUT=$(vagrant ssh emea-server-1 -c "nomad node status" 2>/dev/null || echo "FAILED")

CLIENT_COUNT=$(echo "$NOMAD_NODES_OUTPUT" | grep -c "ready" || echo "0")

if [ "$CLIENT_COUNT" -ge "4" ]; then
    print_status "Found $CLIENT_COUNT Nomad clients (expected 4)"
    echo "$NOMAD_NODES_OUTPUT"
else
    print_error "Expected 4 Nomad clients, found $CLIENT_COUNT"
    echo "$NOMAD_NODES_OUTPUT"
fi

echo ""

# Step 7: Deploy Multi-Region Job
print_step "Step 7: Deploying multi-region test job..."

print_info "Deploying redis-multi-region job..."
DEPLOY_OUTPUT=$(vagrant ssh emea-server-1 -c "cd /vagrant/examples && nomad job run redis-multi-region.nomad" 2>/dev/null || echo "FAILED")

if echo "$DEPLOY_OUTPUT" | grep -q "Job registration successful"; then
    print_status "Multi-region job deployed successfully"
    
    # Wait for deployment
    print_info "Waiting for deployment to complete (30 seconds)..."
    sleep 30
    
    # Check job status in both regions
    print_info "Checking job status in EMEA region..."
    EMEA_STATUS=$(vagrant ssh emea-server-1 -c "nomad job status -region emea redis-multi-region" 2>/dev/null || echo "FAILED")
    
    if echo "$EMEA_STATUS" | grep -q "running"; then
        print_status "Job running in EMEA region"
    else
        print_error "Job not running in EMEA region"
    fi
    
    print_info "Checking job status in USA region..."
    USA_STATUS=$(vagrant ssh emea-server-1 -c "nomad job status -region usa redis-multi-region" 2>/dev/null || echo "FAILED")
    
    if echo "$USA_STATUS" | grep -q "running"; then
        print_status "Job running in USA region"
    else
        print_error "Job not running in USA region"
    fi
else
    print_error "Multi-region job deployment failed"
    echo "$DEPLOY_OUTPUT"
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verification Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_info "Access Points:"
echo "  EMEA Nomad UI:  http://192.168.56.71:4646"
echo "  EMEA Consul UI: http://192.168.56.71:8500"
echo "  USA Nomad UI:   http://192.168.56.81:4646"
echo "  USA Consul UI:  http://192.168.56.81:8500"
echo ""

print_info "SSH Access:"
echo "  vagrant ssh emea-server-1"
echo "  vagrant ssh usa-server-1"
echo "  (and 6 other nodes)"
echo ""

print_info "Useful Commands:"
echo "  nomad server members      # View all Nomad servers"
echo "  consul members -wan       # View Consul WAN federation"
echo "  nomad node status         # View all Nomad clients"
echo "  nomad job status redis-multi-region -region emea"
echo "  nomad job status redis-multi-region -region usa"
echo ""

print_status "Deployment and verification complete!"

# Made with Bob
