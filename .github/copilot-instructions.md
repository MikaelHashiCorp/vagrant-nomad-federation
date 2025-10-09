# HashiCorp Nomad Federation Lab

This is a Vagrant-based demo environment showcasing Nomad Federation across two regions (EMEA/USA) with Consul WAN federation.

**⚠️ Migration Status**: Currently migrating from VirtualBox/AMD64 to Parallels/ARM64 architecture. Project targets macOS with Parallels Desktop for clean builds and complete functionality.

## Architecture Overview

**Two-region federation topology:**
- **EMEA region** (192.168.56.71): `emea-dc1` datacenter, authoritative region
- **USA region** (192.168.56.72): `usa-dc1` datacenter, non-authoritative region
- Both regions run Nomad Enterprise + Consul Enterprise with full server/client capabilities
- Consul provides cross-region WAN federation (`retry_join_wan` configuration)
- Nomad federation uses `authoritative_region = "emea"` pattern

## Platform Requirements

**Current Target Platform:**
- **Hypervisor**: Parallels Desktop (replacing VirtualBox)
- **Architecture**: ARM64/Apple Silicon (migrated from AMD64)
- **Guest OS**: Ubuntu 24.04 LTS ARM64
- **Host OS**: macOS with Apple Silicon
- **Required Plugin**: `vagrant-parallels` (auto-checked in Vagrantfile)

## Key Components & File Structure

- `Vagrantfile`: Defines two VMs with Parallels provider, static IPs, and region-specific provisioning
- `scripts/{emea,usa}.sh`: Region-specific provision scripts installing HashiCorp stack + dependencies (ARM64 binaries)
- `conf/{emea,usa}-{nomad,consul}.hcl`: Region-specific configurations with federation settings
- `conf/*-env.sh`: Environment setup with `NOMAD_ADDR` and CLI autocompletion
- `examples/`: Sample Nomad job files demonstrating multi-region deployments
- `lic/`: License files directory (gitignored, must be manually populated)

## Critical Networking & Federation Setup

**IP Configuration:**
- EMEA: `192.168.56.71` (bind_addr for both Nomad/Consul)
- USA: `192.168.56.72` (bind_addr for both Nomad/Consul)

**Federation Patterns:**
- Nomad: Cross-region server join via `server_join.retry_join` with explicit ports (`:4648`)
- Consul: WAN federation via `retry_join_wan` between datacenters
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

# Provision ARM64 VMs with Parallels
vagrant up
```

**Migration Notes:**
- All HashiCorp binaries use ARM64 architecture (`linux_arm64.zip`)
- Parallels provider configured with adaptive hypervisor optimization
- Guest tools management disabled to avoid conflicts during provisioning

**Access Points:**
- Main portal: `http://192.168.56.71` or `http://192.168.56.72` (nginx landing page)
- Nomad UI: `:4646`, Consul UI: `:8500`, VSCode: `:3000` (per region)

**Multi-region Job Operations:**
```bash
vagrant ssh emea
cd /vagrant/examples
nomad job run redis-multi-region.nomad  # Deploys to both regions automatically
nomad job status -region emea redis-multi-region
nomad job status -region usa redis-multi-region
```

**Federation Verification:**
```bash
# Check Nomad federation
nomad server members  # Shows cross-region Nomad servers
nomad status         # Should show no errors

# Check Consul federation and Nomad registration
consul members -wan   # Shows Consul WAN federation
consul catalog services | grep nomad  # Should show nomad service
curl -s http://192.168.56.71:8500/v1/health/service/nomad  # EMEA Nomad health
curl -s http://192.168.56.72:8500/v1/health/service/nomad  # USA Nomad health

# Test Nomad API directly
curl -s http://192.168.56.71:4646/v1/status/leader  # EMEA Nomad API
curl -s http://192.168.56.72:4646/v1/status/leader  # USA Nomad API
```

**Troubleshooting:**
```bash
# Check service status
sudo systemctl status nomad consul
sudo journalctl -xeu nomad.service  # View Nomad logs
sudo journalctl -xeu consul.service # View Consul logs

# Check Nomad-Consul integration
nomad node status  # Should show nodes if Consul integration works
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
    region "emea" { count = 1; datacenters = ["emea-dc1"] }
    region "usa" { count = 1; datacenters = ["usa-dc1"] }
  }
}
```

**Configuration Conventions:**
- Region-specific configs use `{region}-{service}.hcl` naming
- License paths always point to `/vagrant/lic/{service}.hclic`
- All services use systemd with dedicated user accounts
- Both regions enable raw_exec plugin and Docker driver

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

When modifying configurations, remember federation requires both regions to be configured consistently for cross-region communication to work properly.