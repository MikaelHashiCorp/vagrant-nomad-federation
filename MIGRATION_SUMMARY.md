# Migration Summary: 2-Node to 8-Node Nomad Federation

## Overview

This document summarizes the changes made to transform the vagrant-nomad-federation environment from a **2-node setup** (1 VM per region) to a **production-like 8-node setup** (3 servers + 2 clients per region).

## Architecture Changes

### Before (2 Nodes)
- **EMEA**: 1 VM running Nomad server+client + Consul server
- **USA**: 1 VM running Nomad server+client + Consul server
- Single point of failure per region
- No high availability

### After (8 Nodes)
- **EMEA**: 3 Nomad servers + 2 Nomad clients (5 VMs)
- **USA**: 3 Nomad servers + 2 Nomad clients (5 VMs)
- High availability with 3-node quorum per region
- Separation of concerns (servers vs clients)

## Files Created

### 1. Consul Server Configurations (6 files)
- `conf/emea-server-1-consul.hcl` (192.168.56.71)
- `conf/emea-server-2-consul.hcl` (192.168.56.72)
- `conf/emea-server-3-consul.hcl` (192.168.56.73)
- `conf/usa-server-1-consul.hcl` (192.168.56.81)
- `conf/usa-server-2-consul.hcl` (192.168.56.82)
- `conf/usa-server-3-consul.hcl` (192.168.56.83)

**Key Settings:**
- `bootstrap_expect = 3` (3-node quorum per datacenter)
- `retry_join` points to all 3 servers in same datacenter
- `retry_join_wan` points to all 3 servers in other datacenter
- Separate datacenters: `emea-dc1` and `usa-dc1`

### 2. Nomad Server Configurations (6 files)
- `conf/emea-server-1-nomad.hcl` (192.168.56.71)
- `conf/emea-server-2-nomad.hcl` (192.168.56.72)
- `conf/emea-server-3-nomad.hcl` (192.168.56.73)
- `conf/usa-server-1-nomad.hcl` (192.168.56.81)
- `conf/usa-server-2-nomad.hcl` (192.168.56.82)
- `conf/usa-server-3-nomad.hcl` (192.168.56.83)

**Key Settings:**
- `server.enabled = true`, `client.enabled = false`
- `bootstrap_expect = 3` (3-node quorum per region)
- `server_join.retry_join` points to all 3 servers in same region
- USA servers also include EMEA leader for cross-region federation
- `authoritative_region = "emea"` on all servers

### 3. Nomad Client Configurations (4 files)
- `conf/emea-client-1-nomad.hcl` (192.168.56.74)
- `conf/emea-client-2-nomad.hcl` (192.168.56.75)
- `conf/usa-client-1-nomad.hcl` (192.168.56.84)
- `conf/usa-client-2-nomad.hcl` (192.168.56.85)

**Key Settings:**
- `server.enabled = false`, `client.enabled = true`
- `client.server_join.retry_join` points to regional servers
- Consul client mode (connects to local agent at 127.0.0.1:8500)

### 4. Provisioning Scripts (8 files)
- `scripts/emea-server-{1,2,3}.sh`
- `scripts/emea-client-{1,2}.sh`
- `scripts/usa-server-{1,2,3}.sh`
- `scripts/usa-client-{1,2}.sh`

**Server Scripts:**
- Install Consul server + Nomad server
- Install Docker, Envoy, nginx, code-server
- Wait for Consul readiness before starting Nomad

**Client Scripts:**
- Install Consul client (inline config) + Nomad client
- Install Docker, Envoy
- Simpler setup focused on workload execution

### 5. Environment Files (8 files)
- `conf/emea-server-{1,2,3}-env.sh`
- `conf/emea-client-{1,2}-env.sh`
- `conf/usa-server-{1,2,3}-env.sh`
- `conf/usa-client-{1,2}-env.sh`

**Purpose:**
- Set `NOMAD_ADDR` to local/regional server
- Enable CLI autocompletion for Nomad and Consul

## Files Modified

### 1. Vagrantfile
**Changes:**
- Expanded from 2 VM definitions to 8
- New IP scheme:
  - EMEA: .71-.75 (servers .71-.73, clients .74-.75)
  - USA: .81-.85 (servers .81-.83, clients .84-.85)
- Each VM points to its specific provisioning script

### 2. README.md
**Changes:**
- Updated topology diagram showing 8 nodes
- New architecture section explaining HA setup
- Updated access points for all nodes
- Added federation verification commands
- Expanded troubleshooting section
- Added SSH access for all 8 nodes

### 3. .github/copilot-instructions.md
**Changes:**
- Updated architecture overview with 8-node topology
- New IP configuration documentation
- Updated federation patterns for 3-node quorum
- Added node roles section (servers vs clients)
- Updated SSH access commands
- Added HA features section

### 4. Example Job Files
**Status:** No changes needed
- `examples/redis-multi-region.nomad` - Already uses correct datacenter names
- `examples/client2-svc2.nomad` - Already references `emea-dc1`

## IP Address Allocation

| Node | IP Address | Role | Consul | Nomad |
|------|------------|------|--------|-------|
| emea-server-1 | 192.168.56.71 | Server | Server | Server |
| emea-server-2 | 192.168.56.72 | Server | Server | Server |
| emea-server-3 | 192.168.56.73 | Server | Server | Server |
| emea-client-1 | 192.168.56.74 | Client | Client | Client |
| emea-client-2 | 192.168.56.75 | Client | Client | Client |
| usa-server-1 | 192.168.56.81 | Server | Server | Server |
| usa-server-2 | 192.168.56.82 | Server | Server | Server |
| usa-server-3 | 192.168.56.83 | Server | Server | Server |
| usa-client-1 | 192.168.56.84 | Client | Client | Client |
| usa-client-2 | 192.168.56.85 | Client | Client | Client |

## Key Configuration Decisions

### 1. Consul Architecture
- **Two separate datacenters**: `emea-dc1` and `usa-dc1`
- **WAN federation**: Enables cross-datacenter service discovery
- **3-node quorum per datacenter**: Can tolerate 1 server failure per DC
- **Client nodes**: Run Consul clients for local service discovery

### 2. Nomad Architecture
- **Two regions**: `emea` (authoritative) and `usa` (non-authoritative)
- **3-node quorum per region**: Can tolerate 1 server failure per region
- **Dedicated servers**: No client mode on server nodes
- **Dedicated clients**: No server mode on client nodes
- **Cross-region federation**: USA servers join EMEA for global coordination

### 3. High Availability Benefits
- **Consul**: Lose 1 server per DC without losing quorum (3 → 2 still majority)
- **Nomad**: Lose 1 server per region without losing quorum (3 → 2 still majority)
- **Clients**: Lose clients without affecting cluster availability
- **Workload distribution**: 2 clients per region for load distribution

## Testing the New Setup

### 1. Provision All Nodes
```bash
vagrant up
```

### 2. Verify Consul Federation
```bash
vagrant ssh emea-server-1
consul members -wan
# Should show 6 servers (3 per datacenter)
```

### 3. Verify Nomad Federation
```bash
nomad server members
# Should show 6 servers (3 per region)
```

### 4. Verify Nomad Clients
```bash
nomad node status
# Should show 4 clients (2 per region)
```

### 5. Deploy Multi-Region Job
```bash
cd /vagrant/examples
nomad job run redis-multi-region.nomad
nomad job status -region emea redis-multi-region
nomad job status -region usa redis-multi-region
```

## Troubleshooting Common Issues

### Issue: Consul servers not forming quorum
**Solution:**
- Check all 3 servers in a datacenter are running: `systemctl status consul`
- Verify `retry_join` includes all 3 server IPs
- Check logs: `journalctl -xeu consul.service`

### Issue: Nomad servers not forming quorum
**Solution:**
- Ensure Consul is healthy first (Nomad depends on Consul)
- Check all 3 servers in a region are running: `systemctl status nomad`
- Verify `server_join.retry_join` includes all 3 server IPs
- Check logs: `journalctl -xeu nomad.service`

### Issue: Clients not joining cluster
**Solution:**
- Verify Consul client can reach Consul servers
- Check `client.server_join.retry_join` points to correct server IPs
- Ensure firewall allows port 4647 (Nomad RPC)

### Issue: Cross-region federation not working
**Solution:**
- Verify Consul WAN federation is working: `consul members -wan`
- Check USA servers include EMEA leader in `server_join.retry_join`
- Ensure port 4648 (Nomad Serf) is open between regions

## Benefits of New Architecture

1. **High Availability**: Can tolerate server failures without downtime
2. **Scalability**: Easy to add more client nodes for capacity
3. **Production-Ready**: Mirrors real-world deployment patterns
4. **Separation of Concerns**: Servers manage, clients execute
5. **Fault Tolerance**: Multiple failure domains per region
6. **Load Distribution**: Multiple clients share workload
7. **Testing Platform**: Realistic environment for testing HA scenarios

## Next Steps

1. Test the setup with `vagrant up`
2. Verify all services are healthy
3. Deploy sample jobs to test federation
4. Experiment with failure scenarios (stop 1 server per region)
5. Monitor resource usage and adjust VM specs if needed

## Files Summary

**Total Files Created:** 26
- 6 Consul server configs
- 6 Nomad server configs
- 4 Nomad client configs
- 8 provisioning scripts
- 8 environment files

**Total Files Modified:** 3
- Vagrantfile
- README.md
- .github/copilot-instructions.md

**Total Files Unchanged:** 2
- examples/redis-multi-region.nomad
- examples/client2-svc2.nomad