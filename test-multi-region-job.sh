#!/bin/bash

set -e

echo "=========================================="
echo "Testing Multi-Region Job Deployment"
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

# Check if example job exists
if [ ! -f "examples/redis-multi-region.nomad" ]; then
    print_error "Example job file not found: examples/redis-multi-region.nomad"
    exit 1
fi

print_status "Found example job file"

echo ""
echo "=========================================="
echo "Step 1: Validating job file"
echo "=========================================="
echo ""

vagrant ssh emea-server-1 << 'EOF'
cd /vagrant
nomad job validate examples/redis-multi-region.nomad
EOF

if [ $? -eq 0 ]; then
    print_status "Job file is valid"
else
    print_error "Job validation failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "Step 2: Planning job deployment"
echo "=========================================="
echo ""

vagrant ssh emea-server-1 << 'EOF'
cd /vagrant
nomad job plan examples/redis-multi-region.nomad
EOF

echo ""
echo "=========================================="
echo "Step 3: Running job"
echo "=========================================="
echo ""

vagrant ssh emea-server-1 << 'EOF'
cd /vagrant
nomad job run examples/redis-multi-region.nomad
EOF

if [ $? -eq 0 ]; then
    print_status "Job submitted successfully"
else
    print_error "Job submission failed"
    exit 1
fi

echo ""
print_warning "Waiting 10 seconds for allocations to start..."
sleep 10

echo ""
echo "=========================================="
echo "Step 4: Checking job status"
echo "=========================================="
echo ""

vagrant ssh emea-server-1 << 'EOF'
echo "=== Job Status ==="
nomad job status redis-multi-region

echo ""
echo "=== Allocations by Region ==="
echo "EMEA Region:"
nomad job status redis-multi-region | grep -A 20 "Allocations" | grep "emea-dc1" || echo "No allocations in EMEA"

echo ""
echo "USA Region:"
nomad job status redis-multi-region | grep -A 20 "Allocations" | grep "usa-dc1" || echo "No allocations in USA"
EOF

echo ""
echo "=========================================="
echo "Multi-Region Job Test Complete"
echo "=========================================="
echo ""
print_status "Job is running across regions"
echo ""
echo "To check job status:"
echo "  vagrant ssh emea-server-1 -c 'nomad job status redis-multi-region'"
echo ""
echo "To stop the job:"
echo "  vagrant ssh emea-server-1 -c 'nomad job stop redis-multi-region'"
echo ""
echo "View in Web UI:"
echo "  EMEA: http://192.168.56.71:4646/ui/jobs/redis-multi-region"
echo "  USA:  http://192.168.56.81:4646/ui/jobs/redis-multi-region"
echo ""

# Made with Bob
