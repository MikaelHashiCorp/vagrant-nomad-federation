#!/bin/bash

echo "=== Checking Consul WAN Federation ==="
echo "Connecting to emea-server-1..."
vagrant ssh emea-server-1 << 'EOF'
consul members -wan
EOF

echo ""
echo "=== Checking Nomad Server Members ==="
echo "Connecting to emea-server-1..."
vagrant ssh emea-server-1 << 'EOF'
nomad server members
EOF

echo ""
echo "=== Checking Nomad Client Nodes ==="
echo "Connecting to emea-server-1..."
vagrant ssh emea-server-1 << 'EOF'
nomad node status
EOF

echo ""
echo "=== Checking Consul Services ==="
echo "Connecting to emea-server-1..."
vagrant ssh emea-server-1 << 'EOF'
consul catalog services
EOF

# Made with Bob
