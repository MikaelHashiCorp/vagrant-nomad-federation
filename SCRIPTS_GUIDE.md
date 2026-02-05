# Scripts Guide

This directory contains automated scripts to manage the Nomad Federation environment. All scripts are executable and handle the complete workflow.

## Quick Start

### First Time Setup

```bash
# Deploy the entire environment (10-15 minutes)
./deploy-environment.sh
```

This script will:
1. Destroy any existing VMs
2. Provision 8 new VMs (3 servers + 2 clients per region)
3. Wait for services to stabilize
4. Verify federation is working
5. Display access points and next steps

### Daily Operations

```bash
# Stop the environment (saves state)
./stop-environment.sh

# Resume the environment (restores state)
./resume-environment.sh

# Check federation status anytime
./check-federation.sh

# Test multi-region job deployment
./test-multi-region-job.sh
```

## Script Details

### [`deploy-environment.sh`](deploy-environment.sh:1)

**Purpose**: Complete environment deployment from scratch

**What it does**:
- Checks for Vagrant and Parallels plugin
- Destroys any existing VMs
- Runs `vagrant up` to provision all 8 VMs
- Waits 60 seconds for services to start
- Runs federation verification
- Displays access points

**When to use**: 
- First time setup
- After making configuration changes
- When you want a clean environment

**Runtime**: 10-15 minutes

**Usage**:
```bash
./deploy-environment.sh
```

### [`resume-environment.sh`](resume-environment.sh:1)

**Purpose**: Resume suspended VMs and verify services

**What it does**:
- Checks VM status
- Runs `vagrant resume` to wake up all VMs
- Waits 180 seconds for services to fully stabilize
- Runs federation verification
- Displays access points

**When to use**:
- After running `./stop-environment.sh`
- After system reboot
- When VMs are in suspended state

**Runtime**: 3-4 minutes

**Usage**:
```bash
./resume-environment.sh
```

### [`stop-environment.sh`](stop-environment.sh:1)

**Purpose**: Suspend all VMs to save resources

**What it does**:
- Checks current VM status
- Runs `vagrant suspend` to save VM state
- Displays resume instructions

**When to use**:
- End of work day
- When you need to free up system resources
- Before system shutdown

**Runtime**: 30 seconds

**Usage**:
```bash
./stop-environment.sh
```

### [`check-federation.sh`](check-federation.sh:1)

**Purpose**: Quick federation status check

**What it does**:
- Connects to emea-server-1 via SSH
- Runs `consul members -wan` (shows all 6 Consul servers)
- Runs `nomad server members` (shows all 6 Nomad servers)
- Runs `nomad node status` (shows all 4 client nodes)
- Runs `consul catalog services` (shows registered services)

**When to use**:
- After resume to verify services
- To check cluster health
- Before deploying jobs
- Troubleshooting

**Runtime**: 10 seconds

**Usage**:
```bash
./check-federation.sh
```

**Expected Output**:
```
=== Consul WAN Federation ===
6 servers across 2 datacenters (emea-dc1, usa-dc1)

=== Nomad Server Members ===
6 servers across 2 regions (emea, usa)

=== Nomad Client Nodes ===
4 clients (2 per region)

=== Consul Services ===
consul, nomad, nomad-client
```

### [`test-multi-region-job.sh`](test-multi-region-job.sh:1)

**Purpose**: Deploy and verify a multi-region test job

**What it does**:
- Validates the example job file
- Runs `nomad job plan` to preview changes
- Runs `nomad job run` to deploy the job
- Waits for allocations to start
- Shows job status and allocation distribution

**When to use**:
- After initial deployment
- To verify cross-region job placement
- To test federation functionality

**Runtime**: 30 seconds

**Usage**:
```bash
./test-multi-region-job.sh
```

### [`verify-federation.sh`](verify-federation.sh:1)

**Purpose**: Internal verification script (used by other scripts)

**What it does**:
- Contains verification commands
- Used by deploy and resume scripts

**When to use**:
- Not meant to be run directly
- Use `check-federation.sh` instead

## Workflow Examples

### Example 1: First Time Setup

```bash
# Clone the repository
git clone <repo-url>
cd vagrant-nomad-federation

# Deploy everything
./deploy-environment.sh

# Test multi-region job
./test-multi-region-job.sh

# When done for the day
./stop-environment.sh
```

### Example 2: Daily Development

```bash
# Morning: Resume environment
./resume-environment.sh

# Check status
./check-federation.sh

# Deploy your jobs
vagrant ssh emea-server-1 -c "nomad job run my-job.nomad"

# Evening: Stop environment
./stop-environment.sh
```

### Example 3: Troubleshooting

```bash
# Check federation status
./check-federation.sh

# If services aren't ready, wait and check again
sleep 60
./check-federation.sh

# SSH into a node for detailed inspection
vagrant ssh emea-server-1
systemctl status consul nomad
journalctl -u consul -f
```

### Example 4: Clean Rebuild

```bash
# Destroy everything
vagrant destroy -f

# Deploy fresh environment
./deploy-environment.sh
```

## Manual Vagrant Commands

If you prefer manual control:

```bash
# Start all VMs
vagrant up

# Start specific VM
vagrant up emea-server-1

# Stop all VMs (suspend)
vagrant suspend

# Resume all VMs
vagrant resume

# Restart all VMs
vagrant reload

# Destroy all VMs
vagrant destroy -f

# Check status
vagrant status

# SSH into a VM
vagrant ssh emea-server-1

# Run command on VM
vagrant ssh emea-server-1 -c "consul members"
```

## Access Points

After running any deployment or resume script:

### Web UIs

**EMEA Region:**
- Nomad: http://192.168.56.71:4646/ui
- Consul: http://192.168.56.71:8500/ui

**USA Region:**
- Nomad: http://192.168.56.81:4646/ui
- Consul: http://192.168.56.81:8500/ui

### SSH Access

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

## Troubleshooting

### Services not starting

```bash
# SSH into a node
vagrant ssh emea-server-1

# Check service status
systemctl status consul
systemctl status nomad

# View logs
journalctl -u consul -f
journalctl -u nomad -f

# Restart services
sudo systemctl restart consul
sudo systemctl restart nomad
```

### Federation not working

```bash
# Check Consul WAN
vagrant ssh emea-server-1 -c "consul members -wan"

# Check Nomad servers
vagrant ssh emea-server-1 -c "nomad server members"

# Check network connectivity
vagrant ssh emea-server-1 -c "ping -c 3 192.168.56.81"
```

### VMs won't start

```bash
# Check Parallels
prlctl list -a

# Restart Parallels service
sudo launchctl stop com.parallels.desktop.launchdaemon
sudo launchctl start com.parallels.desktop.launchdaemon

# Destroy and recreate
vagrant destroy -f
./deploy-environment.sh
```

## Performance Tips

1. **Suspend vs Destroy**: Use suspend (`./stop-environment.sh`) to save time on next startup
2. **Resource Allocation**: Each VM uses 2GB RAM, ensure you have 16GB+ available
3. **Parallel Provisioning**: Vagrant provisions VMs in parallel when possible
4. **Service Startup**: Services need 60-180 seconds to fully stabilize after resume

## Script Maintenance

All scripts are located in the root directory:
- `deploy-environment.sh` - Full deployment
- `resume-environment.sh` - Resume suspended VMs
- `stop-environment.sh` - Suspend VMs
- `check-federation.sh` - Status check
- `test-multi-region-job.sh` - Job deployment test
- `verify-federation.sh` - Internal verification

Scripts are version controlled and can be modified as needed.