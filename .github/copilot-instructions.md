# HashiCorp Nomad Federation Lab

This is a Vagrant-based demo environment showcasing Nomad Federation across two regions (EMEA/USA) with Consul WAN federation.

**⚠️ Migration Status**: Currently migrated to Parallels/ARM64 architecture. Project targets macOS with Parallels Desktop for clean builds and complete functionality.

## Architecture Overview

**Production-like federation topology with high availability:**
- **EMEA region**: 3 Nomad servers + 2 Nomad clients (192.168.56.71-75)
  - Datacenter: `emea-dc1` (authoritative region)
  - 3 Consul servers for HA quorum
  - 2 Consul clients on Nomad client nodes
- **USA region**: 3 Nomad servers + 2 Nomad clients (192.168.56.81-85)
  - Datacenter: `usa-dc1` (non-authoritative region)
  - 3 Consul servers for HA quorum
  - 2 Consul clients on Nomad client nodes
- **Total**: 8 VMs (6 Nomad servers + 4 Nomad clients)
- Consul provides cross-region WAN federation between `emea-dc1` and `usa-dc1`
- Nomad federation uses `authoritative_region = "emea"` pattern

## Platform Requirements

**Current Target Platform:**
- **Hypervisor**: Parallels Desktop (replacing VirtualBox)
- **Architecture**: ARM64/Apple Silicon (migrated from AMD64)
- **Guest OS**: Ubuntu 24.04 LTS ARM64
- **Host OS**: macOS with Apple Silicon
- **Required Plugin**: `vagrant-parallels` (auto-checked in Vagrantfile)

## Key Components & File Structure

### Core Configuration
- `Vagrantfile`: Defines 8 VMs with Parallels provider, static IPs, and node-specific provisioning
- `scripts/{emea,usa}-{server,client}-{1,2,3}.sh`: Node-specific provision scripts installing HashiCorp stack + dependencies (ARM64 binaries)
- `conf/{emea,usa}-{server,client}-{1,2,3}-{nomad,consul}.hcl`: Node-specific configurations with federation settings
- `conf/{emea,usa}-{server,client}-{1,2,3}-env.sh`: Environment setup with `NOMAD_ADDR` and CLI autocompletion
- `examples/`: Sample Nomad job files demonstrating multi-region deployments
- `lic/`: License files directory (gitignored, must be manually populated)

### Node Roles
**Server Nodes (6 total):**
- Run both Nomad server and Consul server
- Handle cluster management, scheduling, and state
- Form 3-node quorum per region for HA

**Client Nodes (4 total):**
- Run Nomad client and Consul client
- Execute workloads (Docker, raw_exec)
- Connect to local Consul agents for service discovery

## Critical Networking & Federation Setup

**IP Configuration:**
- **EMEA Servers**: 192.168.56.71 (server-1), .72 (server-2), .73 (server-3)
- **EMEA Clients**: 192.168.56.74 (client-1), .75 (client-2)
- **USA Servers**: 192.168.56.81 (server-1), .82 (server-2), .83 (server-3)
- **USA Clients**: 192.168.56.84 (client-1), .85 (client-2)

**Federation Patterns:**
- **Nomad**: Cross-region server join via `server_join.retry_join` with explicit ports (`:4648`)
  - Each region has `bootstrap_expect = 3` for 3-node quorum
  - USA servers include EMEA leader IP for cross-region federation
- **Consul**: WAN federation via `retry_join_wan` between datacenters
  - Each datacenter has `bootstrap_expect = 3` for 3-node quorum
  - EMEA servers join USA servers via WAN, and vice versa
- Both use EMEA as authoritative region for leadership

## Essential Workflows

**Prerequisites:**
```bash
# Install Parallels Desktop and Vagrant plugin
vagrant plugin install vagrant-parallels
```

**Setup:**
```bash
# Requires manual license placement for Enterprise features
touch lic/nomad.hclic && echo "LICENSE_CONTENT" > lic/nomad.hclic
touch lic/consul.hclic && echo "LICENSE_CONTENT" > lic/consul.hclic

# Provision ARM64 VMs with Parallels (all 8 nodes)
vagrant up
```

**Migration Notes:**
- All HashiCorp binaries use ARM64 architecture (`linux_arm64.zip`)
- Parallels provider configured with adaptive hypervisor optimization
- Guest tools management disabled to avoid conflicts during provisioning

**Access Points:**
- Main portals: `http://192.168.56.71` (EMEA) or `http://192.168.56.81` (USA)
- Nomad UI: `:4646` on any server node
- Consul UI: `:8500` on any server node
- VSCode: `:3000` on emea-server-1

**Multi-region Job Operations:**
```bash
vagrant ssh emea-server-1
cd /vagrant/examples
nomad job run redis-multi-region.nomad  # Deploys to both regions automatically
nomad job status -region emea redis-multi-region
nomad job status -region usa redis-multi-region
```

**Federation Verification:**
```bash
# Check Nomad federation (should show 6 servers)
nomad server members

# Check Consul WAN federation (should show 6 servers)
consul members -wan

# Check Nomad clients (should show 4 clients)
nomad node status

# Check Consul registration
consul catalog services | grep nomad
curl -s http://192.168.56.71:8500/v1/health/service/nomad  # EMEA
curl -s http://192.168.56.81:8500/v1/health/service/nomad  # USA

# Test Nomad API directly
curl -s http://192.168.56.71:4646/v1/status/leader  # EMEA
curl -s http://192.168.56.81:4646/v1/status/leader  # USA
```

**Troubleshooting:**
```bash
# Check service status on any node
sudo systemctl status nomad consul
sudo journalctl -xeu nomad.service
sudo journalctl -xeu consul.service

# Check Nomad-Consul integration
nomad node status  # Should show 4 client nodes
consul catalog services  # Should include nomad and nomad-client

# Manual service restart if needed
sudo systemctl restart consul
sleep 5
sudo systemctl restart nomad
```

## Project-Specific Patterns

**Multi-region Job Structure:**
```hcl
job "example" {
  multiregion {
    region "emea" { 
      count = 1
      datacenters = ["emea-dc1"] 
    }
    region "usa" { 
      count = 1
      datacenters = ["usa-dc1"] 
    }
  }
}
```

**Configuration Conventions:**
- Node-specific configs use `{region}-{role}-{number}-{service}.hcl` naming
- License paths always point to `/vagrant/lic/{service}.hclic`
- All services use systemd with dedicated user accounts
- Server nodes: Nomad server + Consul server (no client mode)
- Client nodes: Nomad client + Consul client (no server mode)
- Both roles enable raw_exec plugin and Docker driver

**Service Integration:**
- Consul service discovery with Nomad integration
- DNS resolution testing via `dig @127.0.0.1 -p 8600 service.consul`
- Code-server provides in-browser IDE access to job files

## Development Environment

- Ubuntu 24.04 VMs with HashiCorp Enterprise binaries (ARM64)
- Nginx serves local dashboard with service links
- VSCode Server accessible via browser for remote development
- Docker + Envoy proxy pre-installed for service mesh capabilities
- Vagrant shared folders mount project at `/vagrant/`

## Migration Considerations

**ARM64 Binary Downloads:**
- Provision scripts download `*_linux_arm64.zip` binaries for Nomad/Consul Enterprise
- Envoy proxy installed via func-e with ARM64 support
- Docker CE configured for ARM64 Ubuntu repositories

**Parallels-Specific Configuration:**
- Guest tools disabled to prevent provisioning conflicts
- Adaptive hypervisor enabled for performance optimization
- Shared folders use Parallels provider for `/vagrant` mount

## High Availability Features

**Consul HA:**
- 3 servers per datacenter provide fault tolerance
- Can lose 1 server per datacenter without losing quorum
- WAN federation maintains cross-datacenter connectivity

**Nomad HA:**
- 3 servers per region provide fault tolerance
- Can lose 1 server per region without losing quorum
- Cross-region federation enables global job deployment

**Client Resilience:**
- 2 clients per region provide workload distribution
- Client failures don't affect cluster availability
- Workloads automatically rescheduled on healthy clients

## SSH Access

```bash
# EMEA region
vagrant ssh emea-server-1  # Primary server
vagrant ssh emea-server-2
vagrant ssh emea-server-3
vagrant ssh emea-client-1
vagrant ssh emea-client-2

# USA region
vagrant ssh usa-server-1   # Primary server
vagrant ssh usa-server-2
vagrant ssh usa-server-3
vagrant ssh usa-client-1
vagrant ssh usa-client-2
```

When modifying configurations, remember federation requires both regions to be configured consistently for cross-region communication to work properly. Server nodes must have matching `bootstrap_expect` values within their region, and client nodes must point to their regional servers for proper cluster joining.