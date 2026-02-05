# Quick Reference Card

## One-Command Operations

```bash
# First time setup
./deploy-environment.sh

# Daily start
./resume-environment.sh

# Daily stop
./stop-environment.sh

# Check status
./check-federation.sh

# Test deployment
./test-multi-region-job.sh
```

## Access Points

| Service | EMEA | USA |
|---------|------|-----|
| Nomad UI | http://192.168.56.71:4646/ui | http://192.168.56.81:4646/ui |
| Consul UI | http://192.168.56.71:8500/ui | http://192.168.56.81:8500/ui |

## SSH Access

```bash
# Servers
vagrant ssh emea-server-1    # or 2, 3
vagrant ssh usa-server-1     # or 2, 3

# Clients
vagrant ssh emea-client-1    # or 2
vagrant ssh usa-client-1     # or 2
```

## Common Commands

```bash
# Inside any server VM
nomad server members         # Show all 6 servers
consul members -wan          # Show WAN federation
nomad node status            # Show all 4 clients

# Deploy a job
nomad job run my-job.nomad

# Check job status
nomad job status my-job

# Stop a job
nomad job stop my-job
```

## Troubleshooting

```bash
# Check service status
vagrant ssh emea-server-1 -c "systemctl status consul nomad"

# View logs
vagrant ssh emea-server-1 -c "journalctl -u consul -f"
vagrant ssh emea-server-1 -c "journalctl -u nomad -f"

# Restart services
vagrant ssh emea-server-1 -c "sudo systemctl restart consul nomad"

# Full rebuild
vagrant destroy -f && ./deploy-environment.sh
```

## Architecture Summary

- **8 VMs**: 3 servers + 2 clients per region
- **2 Regions**: EMEA (authoritative), USA
- **2 Datacenters**: emea-dc1, usa-dc1 (WAN federated)
- **6 Nomad Servers**: 3-node quorum per region
- **4 Nomad Clients**: 2 per region
- **IP Range**: EMEA (.71-.75), USA (.81-.85)

## Documentation

- [`README.md`](README.md) - Main documentation
- [`SCRIPTS_GUIDE.md`](SCRIPTS_GUIDE.md) - Detailed script documentation
- [`FEDERATION_VERIFICATION.md`](FEDERATION_VERIFICATION.md) - Verification results
- [`MIGRATION_SUMMARY.md`](MIGRATION_SUMMARY.md) - Architecture changes