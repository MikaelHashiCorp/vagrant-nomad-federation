#!/bin/bash

echo "=== Consul WAN Federation ==="
consul members -wan

echo ""
echo "=== Nomad Server Members ==="
nomad server members

echo ""
echo "=== Nomad Client Nodes ==="
nomad node status

echo ""
echo "=== Consul Services ==="
consul catalog services

# Made with Bob
