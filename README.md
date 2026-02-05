# vagrant-nomad-federation

# Topology
```
                                 NOMAD FEDERATION

   EMEA REGION (3 Servers + 2 Clients)          USA REGION (3 Servers + 2 Clients)
   
   ┌─────────────────────────────────┐         ┌─────────────────────────────────┐
   │  emea-server-1 (.71)            │         │  usa-server-1 (.81)             │
   │  ├─ Nomad Server                │         │  ├─ Nomad Server                │
   │  └─ Consul Server               │         │  └─ Consul Server               │
   │                                 │         │                                 │
   │  emea-server-2 (.72)            │         │  usa-server-2 (.82)             │
   │  ├─ Nomad Server                │         │  ├─ Nomad Server                │
   │  └─ Consul Server               │         │  └─ Consul Server               │
   │                                 │         │                                 │
   │  emea-server-3 (.73)            │         │  usa-server-3 (.83)             │
   │  ├─ Nomad Server                │         │  ├─ Nomad Server                │
   │  └─ Consul Server               │         │  └─ Consul Server               │
   │                                 │         │                                 │
   │  emea-client-1 (.74)            │         │  usa-client-1 (.84)             │
   │  ├─ Nomad Client                │         │  ├─ Nomad Client                │
   │  └─ Consul Client               │         │  └─ Consul Client               │
   │                                 │         │                                 │
   │  emea-client-2 (.75)            │         │  usa-client-2 (.85)             │
   │  ├─ Nomad Client                │         │  ├─ Nomad Client                │
   │  └─ Consul Client               │         │  └─ Consul Client               │
   │                                 │         │                                 │
   │  Region: emea                   │         │  Region: usa                    │
   │  Datacenter: emea-dc1           │         │  Datacenter: usa-dc1            │
   │  (Authoritative)                │◄───────►│  (Non-authoritative)            │
   └─────────────────────────────────┘         └─────────────────────────────────┘
            Consul WAN Federation + Nomad Cross-Region Federation
```

## Access Points

### EMEA Region
- **Main portal**: http://192.168.56.71
- **Nomad UI**: http://192.168.56.71:4646, http://192.168.56.72:4646, http://192.168.56.73:4646
- **Consul UI**: http://192.168.56.71:8500, http://192.168.56.72:8500, http://192.168.56.73:8500
- **VSCode**: http://192.168.56.71:3000

### USA Region
- **Main portal**: http://192.168.56.81
- **Nomad UI**: http://192.168.56.81:4646, http://192.168.56.82:4646, http://192.168.56.83:4646
- **Consul UI**: http://192.168.56.81:8500, http://192.168.56.82:8500, http://192.168.56.83:8500

## Architecture Overview

This lab demonstrates a **production-like Nomad federation** with:
- **8 VMs total**: 3 Nomad servers + 2 Nomad clients per region
- **2 Consul datacenters**: `emea-dc1` and `usa-dc1` with WAN federation
- **2 Nomad regions**: `emea` (authoritative) and `usa` (non-authoritative)
- **High availability**: 3-node quorum per region for both Consul and Nomad
- **Dedicated roles**: Servers handle orchestration, clients run workloads

## Quick Start

### Automated Setup (Recommended)

The easiest way to get started is using the provided automation scripts:

```bash
# Clone the repository
git clone https://github.com/MikaelHashiCorp/vagrant-nomad-federation
cd vagrant-nomad-federation

# Create license files
touch lic/nomad.hclic
touch lic/consul.hclic
# Add your license content to these files

# Deploy the entire environment (10-15 minutes)
./deploy-environment.sh
```

That's it! The script will:
- Check prerequisites
- Provision all 8 VMs
- Wait for services to stabilize
- Verify federation is working
- Display access points

**See [`SCRIPTS_GUIDE.md`](SCRIPTS_GUIDE.md) for complete automation documentation.**

### Manual Setup

If you prefer manual control:

```bash
# Install Parallels Desktop and Vagrant plugin
vagrant plugin install vagrant-parallels

# Create license files
touch lic/nomad.hclic
touch lic/consul.hclic
# Add your license content to these files

# Provision all 8 VMs
vagrant up

# Wait for services to stabilize (60 seconds)
sleep 60

# Verify federation
./check-federation.sh
```

### Daily Operations

```bash
# Stop environment (saves state)
./stop-environment.sh

# Resume environment (restores state)
./resume-environment.sh

# Check federation status
./check-federation.sh

# Test multi-region job deployment
./test-multi-region-job.sh
```

### SSH into VMs
```bash
# EMEA servers
vagrant ssh emea-server-1
vagrant ssh emea-server-2
vagrant ssh emea-server-3

# EMEA clients
vagrant ssh emea-client-1
vagrant ssh emea-client-2

# USA servers
vagrant ssh usa-server-1
vagrant ssh usa-server-2
vagrant ssh usa-server-3

# USA clients
vagrant ssh usa-client-1
vagrant ssh usa-client-2
```

Optional SSH config for VSCode remote explorer:
```bash
vagrant ssh-config
```

## Confirm Federation

### Check Nomad Federation
From any server node:
```bash
nomad server members
```

Expected output:
```
Name                    Address        Port  Status  Leader  Protocol  Build      Datacenter  Region
emea-server-1.emea      192.168.56.71  4648  alive   true    2         1.10.4+ent emea-dc1    emea
emea-server-2.emea      192.168.56.72  4648  alive   false   2         1.10.4+ent emea-dc1    emea
emea-server-3.emea      192.168.56.73  4648  alive   false   2         1.10.4+ent emea-dc1    emea
usa-server-1.usa        192.168.56.81  4648  alive   true    2         1.10.4+ent usa-dc1     usa
usa-server-2.usa        192.168.56.82  4648  alive   false   2         1.10.4+ent usa-dc1     usa
usa-server-3.usa        192.168.56.83  4648  alive   false   2         1.10.4+ent usa-dc1     usa
```

### Check Consul WAN Federation
From any server node:
```bash
consul members -wan
```

Expected output:
```
Node                      Address             Status  Type    Build      Protocol  DC        Partition  Segment
emea-server-1.emea-dc1    192.168.56.71:8302  alive   server  1.21.4+ent 2         emea-dc1  default    <all>
emea-server-2.emea-dc1    192.168.56.72:8302  alive   server  1.21.4+ent 2         emea-dc1  default    <all>
emea-server-3.emea-dc1    192.168.56.73:8302  alive   server  1.21.4+ent 2         emea-dc1  default    <all>
usa-server-1.usa-dc1      192.168.56.81:8302  alive   server  1.21.4+ent 2         usa-dc1   default    <all>
usa-server-2.usa-dc1      192.168.56.82:8302  alive   server  1.21.4+ent 2         usa-dc1   default    <all>
usa-server-3.usa-dc1      192.168.56.83:8302  alive   server  1.21.4+ent 2         usa-dc1   default    <all>
```

### Check Nomad Clients
```bash
nomad node status
```

Expected output showing 4 client nodes (2 per region).

## Running Multi-Region Jobs

### Deploy to Both Regions
From any server node in `/vagrant/examples`:
```bash
nomad job run redis-multi-region.nomad
```

### Check Job Status Per Region
```bash
nomad job status -region emea redis-multi-region
nomad job status -region usa redis-multi-region
```

### Example Multi-Region Job
```hcl
job "redis-multi-region" {
  multiregion {
    region "emea" {
      count       = 1
      datacenters = ["emea-dc1"]
    }
    region "usa" {
      count       = 1
      datacenters = ["usa-dc1"]
    }
  }

  type = "service"

  group "cache" {
    count = 1
    
    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:3.2"
        ports = ["db"]
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
```

## Testing Service Discovery

Deploy a test service:
```bash
nomad job run client2-svc2.nomad
```

Test DNS resolution:
```bash
dig @127.0.0.1 -p 8600 0.client2-svc2.service.emea-dc1.consul
```

## Key Features

### High Availability
- **3-node Consul quorum** per datacenter ensures fault tolerance
- **3-node Nomad quorum** per region provides leader election resilience
- Clients can fail without affecting cluster availability

### Separation of Concerns
- **Server nodes**: Handle cluster management, scheduling, and state
- **Client nodes**: Execute workloads with full Docker and raw_exec support

### Cross-Region Federation
- **Nomad federation**: Jobs can be deployed across regions with `multiregion` blocks
- **Consul WAN federation**: Service discovery works across datacenters
- **EMEA as authoritative**: Central control plane for global operations

### Enterprise Features
- Nomad Enterprise with multi-region deployments
- Consul Enterprise with WAN federation
- Namespace support and advanced ACLs (when configured)

## Troubleshooting

### Check Service Status
```bash
sudo systemctl status nomad consul
sudo journalctl -xeu nomad.service
sudo journalctl -xeu consul.service
```

### Verify Nomad-Consul Integration
```bash
nomad node status  # Should show nodes if Consul integration works
consul catalog services  # Should include nomad and nomad-client
```

### Manual Service Restart
```bash
sudo systemctl restart consul
sleep 5
sudo systemctl restart nomad
```

### Check Nomad API
```bash
curl -s http://192.168.56.71:4646/v1/status/leader  # EMEA
curl -s http://192.168.56.81:4646/v1/status/leader  # USA
```

### Check Consul Health
```bash
curl -s http://192.168.56.71:8500/v1/health/service/nomad  # EMEA
curl -s http://192.168.56.81:8500/v1/health/service/nomad  # USA
```

## Technical Details

### IP Address Allocation
- **EMEA Servers**: 192.168.56.71-73
- **EMEA Clients**: 192.168.56.74-75
- **USA Servers**: 192.168.56.81-83
- **USA Clients**: 192.168.56.84-85

### Software Versions
- **Nomad**: 1.10.4+ent (ARM64)
- **Consul**: 1.21.4+ent (ARM64)
- **Platform**: Ubuntu 24.04 LTS on Parallels/ARM64

### Installed Components
- Docker CE with privileged container support
- Envoy proxy via func-e
- Nginx for local dashboards
- VSCode Server for browser-based development
- Liquidprompt for enhanced shell experience

## License Requirements

This lab requires HashiCorp Enterprise licenses:
- Place Nomad Enterprise license in `lic/nomad.hclic`
- Place Consul Enterprise license in `lic/consul.hclic`

Both files are gitignored and must be created manually.
